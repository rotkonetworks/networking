use crate::collector::{SessionCollector, PeerState};
use crate::config::{Config, PeerConfig};
use crate::probe::ProbeEngine;
use crate::types::{
    Action, ActionBatch, PathEvaluation, PathMetrics, PeerCapacity, PeerOrigin,
    RoutingDecision, ScoreBreakdown,
};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Instant;
use tracing::{debug, info, warn};

use super::hysteresis::Hysteresis;
use super::scorer::{score_to_local_pref, Scorer};

/// main optimization engine
/// combines probe data, session state, and scoring to make routing decisions
pub struct Optimizer {
    scorer: Scorer,
    hysteresis: Hysteresis,
    probe_engine: Arc<ProbeEngine>,
    session_collector: Arc<SessionCollector>,
    peer_configs: HashMap<String, PeerConfig>,
    /// minimum local_pref to assign
    min_pref: u16,
    /// maximum local_pref to assign
    max_pref: u16,
    /// target utilization for load balancing
    target_utilization: f64,
    /// dry run mode
    dry_run: bool,
}

impl Optimizer {
    pub fn new(
        config: &Config,
        probe_engine: Arc<ProbeEngine>,
        session_collector: Arc<SessionCollector>,
        dry_run: bool,
    ) -> Self {
        let scorer = Scorer::new(
            config.scoring.weights,
            config.scoring.baselines,
        );

        let hysteresis = Hysteresis::new(
            config.hysteresis.min_delta,
            config.hysteresis.hold_time,
        );

        Self {
            scorer,
            hysteresis,
            probe_engine,
            session_collector,
            peer_configs: config.peers.clone(),
            min_pref: 50,
            max_pref: 150,
            target_utilization: config.capacity.target_utilization,
            dry_run,
        }
    }

    /// run a single optimization cycle
    /// returns the actions to apply
    pub async fn optimize(&mut self) -> RoutingDecision {
        // gather all current state
        let peer_states = self.session_collector.get_all_states().await;
        let probe_metrics = self.probe_engine.get_all_metrics().await;

        // evaluate all paths
        let mut evaluations: Vec<PathEvaluation> = Vec::new();

        for (origin, state) in &peer_states {
            // get probe metrics or use defaults
            let metrics = probe_metrics.get(origin).copied().unwrap_or_else(|| {
                PathMetrics::default()
            });

            // find peer config
            let peer_config = self.find_peer_config(*origin);

            // score this path
            let (score, breakdown) = self.scorer.score(
                &metrics,
                &state.session,
                &state.capacity,
                peer_config,
            );

            // record observation for smoothing
            self.hysteresis.observe(state.router, *origin, score);

            // use smoothed score for decisions
            let smoothed = self.hysteresis
                .smoothed_score(state.router, *origin)
                .unwrap_or(score);

            evaluations.push(PathEvaluation {
                peer_id: state.session.peer_id,
                origin: *origin,
                session_name: state.session.name.clone(),
                metrics,
                session: state.session.clone(),
                capacity: state.capacity,
                score: smoothed,
                score_breakdown: breakdown,
            });
        }

        // sort by score descending
        evaluations.sort_by(|a, b| {
            b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal)
        });

        // log evaluation summary
        for eval in &evaluations {
            debug!(
                peer = %eval.origin,
                router = %eval.peer_id.router,
                score = format!("{:.3}", eval.score),
                rtt_ms = format!("{:.1}", eval.metrics.rtt_median.as_secs_f64() * 1000.0),
                loss = format!("{:.2}%", eval.metrics.loss_ratio * 100.0),
                util = format!("{:.1}%", eval.capacity.utilization * 100.0),
                "path evaluation"
            );
        }

        // generate actions based on load balancing strategy
        let actions = self.generate_actions(&evaluations, &peer_states);

        RoutingDecision {
            prefix: "default".to_string(),
            paths: evaluations,
            actions,
            decided_at: Instant::now(),
        }
    }

    /// generate actions to balance load across peers
    fn generate_actions(
        &mut self,
        evaluations: &[PathEvaluation],
        peer_states: &HashMap<PeerOrigin, PeerState>,
    ) -> Vec<Action> {
        let mut actions = Vec::new();

        // check for congested peers
        let congested: Vec<_> = evaluations
            .iter()
            .filter(|e| e.capacity.is_congested())
            .collect();

        let critical: Vec<_> = evaluations
            .iter()
            .filter(|e| e.capacity.is_critical())
            .collect();

        // handle critical peers first - immediate action needed
        for eval in &critical {
            let new_pref = self.min_pref; // minimum preference

            if self.hysteresis.should_change_pref(
                eval.peer_id.router,
                eval.origin,
                new_pref,
            ) {
                warn!(
                    peer = %eval.origin,
                    router = %eval.peer_id.router,
                    util = format!("{:.1}%", eval.capacity.utilization * 100.0),
                    "critical utilization, deprioritizing"
                );

                actions.push(Action::SetPreference {
                    router: eval.peer_id.router,
                    origin: eval.origin,
                    local_pref: new_pref,
                });

                self.hysteresis.record_change(
                    eval.peer_id.router,
                    eval.origin,
                    actions.last().unwrap().clone(),
                    new_pref,
                );
            }
        }

        // for congested (but not critical) peers, reduce preference
        for eval in &congested {
            if critical.iter().any(|c| c.origin == eval.origin) {
                continue; // already handled
            }

            // reduce preference based on congestion level
            let congestion_penalty = (eval.capacity.utilization - 0.75) / 0.15; // 0-1 scale
            let base_pref = score_to_local_pref(eval.score, self.min_pref, self.max_pref);
            let new_pref = base_pref.saturating_sub((congestion_penalty * 30.0) as u16);

            if self.hysteresis.should_change_pref(
                eval.peer_id.router,
                eval.origin,
                new_pref,
            ) {
                info!(
                    peer = %eval.origin,
                    router = %eval.peer_id.router,
                    util = format!("{:.1}%", eval.capacity.utilization * 100.0),
                    old_pref = self.hysteresis.current_pref(eval.peer_id.router, eval.origin),
                    new_pref = new_pref,
                    "congestion detected, reducing preference"
                );

                actions.push(Action::SetPreference {
                    router: eval.peer_id.router,
                    origin: eval.origin,
                    local_pref: new_pref,
                });

                self.hysteresis.record_change(
                    eval.peer_id.router,
                    eval.origin,
                    actions.last().unwrap().clone(),
                    new_pref,
                );
            }
        }

        // for healthy peers, set preference based on score
        for eval in evaluations {
            if congested.iter().any(|c| c.origin == eval.origin) {
                continue; // already handled
            }

            let new_pref = score_to_local_pref(eval.score, self.min_pref, self.max_pref);

            if self.hysteresis.should_change_pref(
                eval.peer_id.router,
                eval.origin,
                new_pref,
            ) {
                let current = self.hysteresis.current_pref(eval.peer_id.router, eval.origin);

                debug!(
                    peer = %eval.origin,
                    router = %eval.peer_id.router,
                    score = format!("{:.3}", eval.score),
                    old_pref = current,
                    new_pref = new_pref,
                    "updating preference"
                );

                actions.push(Action::SetPreference {
                    router: eval.peer_id.router,
                    origin: eval.origin,
                    local_pref: new_pref,
                });

                self.hysteresis.record_change(
                    eval.peer_id.router,
                    eval.origin,
                    actions.last().unwrap().clone(),
                    new_pref,
                );
            }
        }

        actions
    }

    fn find_peer_config(&self, origin: PeerOrigin) -> Option<&PeerConfig> {
        // match by origin name
        let origin_name = origin.name().to_lowercase();

        self.peer_configs
            .iter()
            .find(|(name, _)| {
                let config_name = name.to_lowercase().replace("-", "_");
                config_name.contains(&origin_name) || origin_name.contains(&config_name)
            })
            .map(|(_, c)| c)
    }

    /// get current state summary for display
    pub async fn get_summary(&self) -> OptimizationSummary {
        let peer_states = self.session_collector.get_all_states().await;
        let probe_metrics = self.probe_engine.get_all_metrics().await;

        let mut peers = Vec::new();

        for (origin, state) in &peer_states {
            let metrics = probe_metrics.get(origin).copied();
            let current_pref = self.hysteresis.current_pref(state.router, *origin);

            peers.push(PeerSummary {
                origin: *origin,
                router: state.router,
                session_name: state.session.name.clone(),
                established: state.session.is_established(),
                rtt_ms: metrics.map(|m| m.rtt_median.as_secs_f64() * 1000.0),
                loss_pct: metrics.map(|m| m.loss_ratio * 100.0),
                capacity_mbps: state.capacity.capacity_bps / 1_000_000,
                utilization_pct: state.capacity.utilization * 100.0,
                current_pref,
                in_hold: self.hysteresis.is_cooling(state.router, *origin),
            });
        }

        // sort by utilization descending
        peers.sort_by(|a, b| {
            b.utilization_pct.partial_cmp(&a.utilization_pct).unwrap()
        });

        let total_capacity = self.session_collector.total_capacity().await;
        let total_utilization = self.session_collector.total_utilization().await;

        OptimizationSummary {
            peers,
            total_capacity_gbps: total_capacity as f64 / 1_000_000_000.0,
            total_utilization_pct: total_utilization * 100.0,
            peers_in_hold: self.hysteresis.peers_in_hold().len(),
            dry_run: self.dry_run,
        }
    }
}

#[derive(Debug)]
pub struct OptimizationSummary {
    pub peers: Vec<PeerSummary>,
    pub total_capacity_gbps: f64,
    pub total_utilization_pct: f64,
    pub peers_in_hold: usize,
    pub dry_run: bool,
}

#[derive(Debug)]
pub struct PeerSummary {
    pub origin: PeerOrigin,
    pub router: crate::types::RouterId,
    pub session_name: String,
    pub established: bool,
    pub rtt_ms: Option<f64>,
    pub loss_pct: Option<f64>,
    pub capacity_mbps: u64,
    pub utilization_pct: f64,
    pub current_pref: Option<u16>,
    pub in_hold: bool,
}

impl std::fmt::Display for OptimizationSummary {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "\n=== bgpctl optimization summary{} ===",
            if self.dry_run { " (DRY RUN)" } else { "" }
        )?;
        writeln!(
            f,
            "total capacity: {:.2} gbps | utilization: {:.1}% | peers in hold: {}",
            self.total_capacity_gbps, self.total_utilization_pct, self.peers_in_hold
        )?;
        writeln!(f)?;
        writeln!(
            f,
            "{:<12} {:<8} {:<24} {:>6} {:>8} {:>8} {:>10} {:>6} {:>6}",
            "ORIGIN", "ROUTER", "SESSION", "STATE", "RTT", "LOSS", "UTIL", "CAP", "PREF"
        )?;
        writeln!(f, "{}", "-".repeat(100))?;

        for p in &self.peers {
            let state = if p.established { "UP" } else { "DOWN" };
            let rtt = p.rtt_ms.map(|r| format!("{:.1}ms", r)).unwrap_or_else(|| "-".into());
            let loss = p.loss_pct.map(|l| format!("{:.2}%", l)).unwrap_or_else(|| "-".into());
            let pref = p.current_pref.map(|p| p.to_string()).unwrap_or_else(|| "-".into());
            let hold = if p.in_hold { "*" } else { "" };

            writeln!(
                f,
                "{:<12} {:<8} {:<24} {:>6} {:>8} {:>8} {:>9.1}% {:>5}M {:>5}{}",
                p.origin.name(),
                p.router.to_string(),
                truncate(&p.session_name, 24),
                state,
                rtt,
                loss,
                p.utilization_pct,
                p.capacity_mbps,
                pref,
                hold
            )?;
        }

        Ok(())
    }
}

fn truncate(s: &str, max: usize) -> &str {
    if s.len() <= max {
        s
    } else {
        &s[..max]
    }
}
