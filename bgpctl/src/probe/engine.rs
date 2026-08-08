use crate::config::ProbeConfig;
use crate::error::Result;
use crate::simulator::SimulationState;
use crate::types::{PathMetrics, PeerOrigin};
use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;
use tracing::{debug, info, warn};

use super::icmp::{IcmpProber, ProbeResult, SimulatedProber};

/// aggregated probe results for a peer
#[derive(Debug, Clone)]
pub struct PeerProbeResults {
    pub origin: PeerOrigin,
    pub results: Vec<ProbeResult>,
    pub metrics: PathMetrics,
    pub updated_at: Instant,
}

/// probe engine - runs periodic probes through each upstream
pub struct ProbeEngine {
    config: ProbeConfig,
    /// source ip to use for each peer (determines routing)
    peer_sources: HashMap<PeerOrigin, IpAddr>,
    /// cached results per peer
    results: Arc<RwLock<HashMap<PeerOrigin, PeerProbeResults>>>,
    /// use simulated probes (for dry-run)
    simulated: bool,
    /// simulation state for realistic scenarios
    sim_state: Option<Arc<SimulationState>>,
}

impl ProbeEngine {
    pub fn new(config: ProbeConfig, simulated: bool) -> Self {
        Self {
            config,
            peer_sources: HashMap::new(),
            results: Arc::new(RwLock::new(HashMap::new())),
            simulated,
            sim_state: None,
        }
    }

    pub fn with_simulation(config: ProbeConfig, state: Arc<SimulationState>) -> Self {
        Self {
            config,
            peer_sources: HashMap::new(),
            results: Arc::new(RwLock::new(HashMap::new())),
            simulated: true,
            sim_state: Some(state),
        }
    }

    /// register source ip for a peer (traffic from this ip routes via that peer)
    pub fn register_peer_source(&mut self, origin: PeerOrigin, source: IpAddr) {
        self.peer_sources.insert(origin, source);
    }

    /// run a single probe cycle for all peers
    pub async fn run_probe_cycle(&self) -> Result<()> {
        // if we have simulation state, use run_simulated_cycle for realistic metrics
        if self.sim_state.is_some() {
            return self.run_simulated_cycle().await;
        }

        let mut all_results: HashMap<PeerOrigin, Vec<ProbeResult>> = HashMap::new();

        if self.simulated {
            let mut prober = SimulatedProber::new();

            for (&origin, &source) in &self.peer_sources {
                let mut peer_results = Vec::new();

                for &target in &self.config.targets {
                    for _ in 0..self.config.count {
                        let result = prober.probe(target, Some(source));
                        peer_results.push(result);

                        // small delay between probes
                        tokio::time::sleep(Duration::from_millis(50)).await;
                    }
                }

                all_results.insert(origin, peer_results);
            }
        } else {
            let mut prober = IcmpProber::new()?;

            if !prober.is_available() {
                warn!("icmp prober not available (need cap_net_raw), using simulated probes");
                return self.run_simulated_cycle().await;
            }

            for (&origin, &source) in &self.peer_sources {
                let mut peer_results = Vec::new();

                for &target in &self.config.targets {
                    for _ in 0..self.config.count {
                        let result = prober.probe(target, Some(source), self.config.timeout);
                        peer_results.push(result);

                        tokio::time::sleep(Duration::from_millis(50)).await;
                    }
                }

                all_results.insert(origin, peer_results);
            }
        }

        // aggregate results and update cache
        let mut cache = self.results.write().await;

        for (origin, results) in all_results {
            let metrics = self.aggregate_metrics(&results);

            debug!(
                peer = %origin,
                rtt_ms = metrics.rtt_median.as_secs_f64() * 1000.0,
                loss = metrics.loss_ratio,
                "probe cycle complete"
            );

            cache.insert(
                origin,
                PeerProbeResults {
                    origin,
                    results,
                    metrics,
                    updated_at: Instant::now(),
                },
            );
        }

        Ok(())
    }

    async fn run_simulated_cycle(&self) -> Result<()> {
        let mut cache = self.results.write().await;

        for &origin in self.peer_sources.keys() {
            // use simulation state if available for realistic metrics
            let metrics = if let Some(ref state) = self.sim_state {
                let rtt_ms = state.get_latency_ms(origin);
                let loss = state.get_loss_ratio(origin);

                // add some jitter based on latency
                let jitter_ms = (rtt_ms as f64 * 0.1).max(1.0);

                PathMetrics {
                    rtt_median: Duration::from_millis(rtt_ms),
                    rtt_jitter: Duration::from_secs_f64(jitter_ms / 1000.0),
                    loss_ratio: loss,
                    measured_at: Instant::now(),
                }
            } else {
                // fallback to basic simulation
                let mut prober = SimulatedProber::new();
                let mut peer_results = Vec::new();

                if let Some(&source) = self.peer_sources.get(&origin) {
                    for &target in &self.config.targets {
                        for _ in 0..self.config.count {
                            let result = prober.probe(target, Some(source));
                            peer_results.push(result);
                        }
                    }
                }

                self.aggregate_metrics(&peer_results)
            };

            debug!(
                peer = %origin,
                rtt_ms = metrics.rtt_median.as_secs_f64() * 1000.0,
                loss = format!("{:.2}%", metrics.loss_ratio * 100.0),
                "probe cycle complete"
            );

            cache.insert(
                origin,
                PeerProbeResults {
                    origin,
                    results: Vec::new(),
                    metrics,
                    updated_at: Instant::now(),
                },
            );
        }

        Ok(())
    }

    #[allow(dead_code)]
    async fn run_basic_simulated_cycle(&self) -> Result<()> {
        let mut prober = SimulatedProber::new();
        let mut all_results: HashMap<PeerOrigin, Vec<ProbeResult>> = HashMap::new();

        for (&origin, &source) in &self.peer_sources {
            let mut peer_results = Vec::new();

            for &target in &self.config.targets {
                for _ in 0..self.config.count {
                    let result = prober.probe(target, Some(source));
                    peer_results.push(result);
                }
            }

            all_results.insert(origin, peer_results);
        }

        let mut cache = self.results.write().await;

        for (origin, results) in all_results {
            let metrics = self.aggregate_metrics(&results);
            cache.insert(
                origin,
                PeerProbeResults {
                    origin,
                    results,
                    metrics,
                    updated_at: Instant::now(),
                },
            );
        }

        Ok(())
    }

    /// aggregate raw probe results into metrics
    fn aggregate_metrics(&self, results: &[ProbeResult]) -> PathMetrics {
        let rtts: Vec<Duration> = results.iter().filter_map(|r| r.rtt).collect();

        if rtts.is_empty() {
            return PathMetrics {
                rtt_median: Duration::from_millis(999),
                rtt_jitter: Duration::from_millis(100),
                loss_ratio: 1.0,
                measured_at: Instant::now(),
            };
        }

        let total_probes = results.len();
        let successful = rtts.len();
        let loss_ratio = 1.0 - (successful as f64 / total_probes as f64);

        // calculate median rtt
        let mut sorted_rtts: Vec<f64> = rtts.iter().map(|d| d.as_secs_f64() * 1000.0).collect();
        sorted_rtts.sort_by(|a, b| a.partial_cmp(b).unwrap());

        let median_ms = if sorted_rtts.len() % 2 == 0 {
            let mid = sorted_rtts.len() / 2;
            (sorted_rtts[mid - 1] + sorted_rtts[mid]) / 2.0
        } else {
            sorted_rtts[sorted_rtts.len() / 2]
        };

        // calculate jitter (standard deviation)
        let mean_ms: f64 = sorted_rtts.iter().sum::<f64>() / sorted_rtts.len() as f64;
        let variance: f64 = sorted_rtts
            .iter()
            .map(|x| (x - mean_ms).powi(2))
            .sum::<f64>()
            / sorted_rtts.len() as f64;
        let jitter_ms = variance.sqrt();

        PathMetrics {
            rtt_median: Duration::from_secs_f64(median_ms / 1000.0),
            rtt_jitter: Duration::from_secs_f64(jitter_ms / 1000.0),
            loss_ratio,
            measured_at: Instant::now(),
        }
    }

    /// get current metrics for a peer
    pub async fn get_metrics(&self, origin: PeerOrigin) -> Option<PathMetrics> {
        let cache = self.results.read().await;
        cache.get(&origin).map(|r| r.metrics)
    }

    /// get all current metrics
    pub async fn get_all_metrics(&self) -> HashMap<PeerOrigin, PathMetrics> {
        let cache = self.results.read().await;
        cache.iter().map(|(k, v)| (*k, v.metrics)).collect()
    }

    /// check if metrics are stale
    pub async fn is_stale(&self, origin: PeerOrigin, max_age: Duration) -> bool {
        let cache = self.results.read().await;
        match cache.get(&origin) {
            Some(r) => r.updated_at.elapsed() > max_age,
            None => true,
        }
    }

    /// background task that runs probe cycles periodically
    pub async fn run_background(self: Arc<Self>, mut shutdown: tokio::sync::watch::Receiver<bool>) {
        info!(interval = ?self.config.interval, "starting probe engine");

        let mut interval = tokio::time::interval(self.config.interval);
        interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

        loop {
            tokio::select! {
                _ = interval.tick() => {
                    if let Err(e) = self.run_probe_cycle().await {
                        warn!(error = %e, "probe cycle failed");
                    }
                }
                _ = shutdown.changed() => {
                    if *shutdown.borrow() {
                        info!("probe engine shutting down");
                        break;
                    }
                }
            }
        }
    }
}
