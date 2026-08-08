use bgpctl::actuator::ActionExecutor;
use bgpctl::api::{HealthServer, MetricsExporter};
use bgpctl::collector::{MikrotikClient, SessionCollector};
use bgpctl::config::Config;
use bgpctl::decision::Optimizer;
use bgpctl::error::Result;
use bgpctl::probe::ProbeEngine;
use bgpctl::simulator::{parse_scenario, SimulationScenario, SimulationState};
use bgpctl::types::{PeerOrigin, RouterId};

use clap::Parser;
use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::{watch, RwLock};
use tracing::{info, warn};
use tracing_subscriber::EnvFilter;

#[derive(Parser, Debug)]
#[command(name = "bgpctl")]
#[command(about = "bgp route optimization daemon for as142108")]
#[command(version)]
struct Args {
    /// path to config file
    #[arg(short, long, default_value = "/etc/bgpctl/config.toml")]
    config: PathBuf,

    /// run in dry-run mode (no changes applied)
    #[arg(short = 'n', long)]
    dry_run: bool,

    /// run a single optimization cycle and exit
    #[arg(short = '1', long)]
    once: bool,

    /// show current status and exit
    #[arg(long)]
    status: bool,

    /// log level
    #[arg(short, long, default_value = "info")]
    log_level: String,

    /// simulate all routers (no real API calls)
    #[arg(long)]
    simulate: bool,

    /// simulation scenario (normal, congested, lossy, ramp, flash, down-hgc, down-bknix)
    #[arg(long, default_value = "normal")]
    scenario: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // setup logging
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(&args.log_level));

    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_target(false)
        .init();

    // parse simulation scenario
    let scenario = if args.simulate {
        parse_scenario(&args.scenario).unwrap_or(SimulationScenario::Normal)
    } else {
        SimulationScenario::Normal
    };

    info!(
        version = env!("CARGO_PKG_VERSION"),
        config = %args.config.display(),
        dry_run = args.dry_run,
        simulate = args.simulate,
        scenario = ?scenario,
        "starting bgpctl"
    );

    // load config
    let config = if args.dry_run || args.simulate {
        Config::load_dry_run(&args.config)?
    } else {
        Config::load(&args.config)?
    };

    let dry_run = args.dry_run || config.daemon.dry_run;
    let simulated = args.simulate;

    // create shared simulation state if simulating
    let sim_state = if simulated {
        Some(Arc::new(SimulationState::new(scenario)))
    } else {
        None
    };

    // create mikrotik clients
    let mut clients: HashMap<RouterId, MikrotikClient> = HashMap::new();

    for (name, router_config) in &config.routers {
        let router_id: RouterId = match name.parse() {
            Ok(id) => id,
            Err(e) => {
                warn!(router = name, error = %e, "skipping unknown router");
                continue;
            }
        };

        let client = if let Some(ref state) = sim_state {
            MikrotikClient::with_simulation(router_id, state.clone())
        } else if simulated {
            MikrotikClient::simulated(router_id)
        } else {
            MikrotikClient::new(router_id, router_config, dry_run)?
        };

        clients.insert(router_id, client);
    }

    // create session collector
    let session_collector = Arc::new(SessionCollector::new(
        clients.clone(),
        config.peers.clone(),
    ));

    // create probe engine
    let mut probe_engine = if let Some(ref state) = sim_state {
        ProbeEngine::with_simulation(config.probes.clone(), state.clone())
    } else {
        ProbeEngine::new(config.probes.clone(), simulated)
    };

    // register probe sources for each peer
    // in real deployment, these IPs would route through specific peers
    // for simulation, we just use placeholder IPs
    for origin in PeerOrigin::all() {
        // use origin code as last octet for demo
        let source_ip: IpAddr = format!("10.155.181.{}", *origin as u8).parse().unwrap();
        probe_engine.register_peer_source(*origin, source_ip);
    }

    let probe_engine = Arc::new(probe_engine);

    // create optimizer
    let optimizer = Arc::new(RwLock::new(Optimizer::new(
        &config,
        probe_engine.clone(),
        session_collector.clone(),
        dry_run,
    )));

    // create action executor
    let executor = ActionExecutor::new(clients, config.peers.clone(), dry_run);

    // create metrics exporter
    let metrics = Arc::new(MetricsExporter::new());

    // handle --status mode
    if args.status {
        // run initial collection
        session_collector.collect().await?;
        probe_engine.run_probe_cycle().await?;

        let opt = optimizer.read().await;
        let summary = opt.get_summary().await;
        println!("{}", summary);
        return Ok(());
    }

    // handle --once mode
    if args.once {
        info!("running single optimization cycle");

        // collect data
        session_collector.collect().await?;
        probe_engine.run_probe_cycle().await?;

        // run optimization
        let decision = {
            let mut opt = optimizer.write().await;
            opt.optimize().await
        };

        // show summary
        {
            let opt = optimizer.read().await;
            let summary = opt.get_summary().await;
            println!("{}", summary);
        }

        // show actions
        if decision.actions.is_empty() {
            println!("\nno actions required");
        } else {
            println!("\nactions ({}):", decision.actions.len());
            for action in &decision.actions {
                println!("  {}", action);
            }

            if !dry_run {
                println!("\napplying actions...");
                let results = executor.execute(&decision.actions).await;
                for result in &results {
                    println!("  {}", result);
                }
            }
        }

        return Ok(());
    }

    // daemon mode
    let (shutdown_tx, shutdown_rx) = watch::channel(false);

    // start health server
    let listen_addr: SocketAddr = config.metrics.listen.parse().unwrap_or_else(|_| {
        warn!("invalid metrics listen address, using default");
        "0.0.0.0:9100".parse().unwrap()
    });

    let health_server = HealthServer::new(
        listen_addr,
        config.metrics.path.clone(),
        metrics.clone(),
        optimizer.clone(),
    );

    let health_handle = tokio::spawn({
        let shutdown_rx = shutdown_rx.clone();
        async move {
            health_server.run(shutdown_rx).await;
        }
    });

    // start session collector background task
    let collector_handle = tokio::spawn({
        let collector = session_collector.clone();
        let interval = config.daemon.collect_interval;
        let shutdown_rx = shutdown_rx.clone();
        async move {
            collector.run_background(interval, shutdown_rx).await;
        }
    });

    // start probe engine background task
    let probe_handle = tokio::spawn({
        let engine = probe_engine.clone();
        let shutdown_rx = shutdown_rx.clone();
        async move {
            engine.run_background(shutdown_rx).await;
        }
    });

    // main decision loop
    info!(
        interval = ?config.daemon.decision_interval,
        "starting optimization loop"
    );

    let mut ticker = tokio::time::interval(config.daemon.decision_interval);
    ticker.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

    // wait a bit for initial data collection
    tokio::time::sleep(std::time::Duration::from_secs(5)).await;

    loop {
        tokio::select! {
            _ = ticker.tick() => {
                let decision = {
                    let mut opt = optimizer.write().await;
                    opt.optimize().await
                };

                metrics.record_cycle();

                if !decision.actions.is_empty() {
                    info!(
                        actions = decision.actions.len(),
                        "executing actions"
                    );

                    let results = executor.execute(&decision.actions).await;
                    let success_count = results.iter().filter(|r| r.success).count();

                    metrics.record_actions(success_count as u64);

                    if success_count < results.len() {
                        warn!(
                            total = results.len(),
                            success = success_count,
                            "some actions failed"
                        );
                    }
                }
            }
            _ = tokio::signal::ctrl_c() => {
                info!("received ctrl-c, shutting down");
                let _ = shutdown_tx.send(true);
                break;
            }
        }
    }

    // wait for background tasks
    let _ = tokio::join!(health_handle, collector_handle, probe_handle);

    info!("shutdown complete");
    Ok(())
}
