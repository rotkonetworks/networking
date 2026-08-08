use crate::config::{BaselinesConfig, PeerConfig, ScoringWeightsConfig};
use crate::types::{PathMetrics, PeerCapacity, ScoreBreakdown, SessionState};
use std::time::Duration;

/// path scoring engine
/// computes a score [0.0, 1.0] for each path based on multiple factors
/// higher score = better path
pub struct Scorer {
    weights: ScoringWeightsConfig,
    baselines: BaselinesConfig,
}

impl Scorer {
    pub fn new(weights: ScoringWeightsConfig, baselines: BaselinesConfig) -> Self {
        Self { weights, baselines }
    }

    /// score a path based on all available metrics
    /// returns (final_score, breakdown)
    pub fn score(
        &self,
        metrics: &PathMetrics,
        session: &SessionState,
        capacity: &PeerCapacity,
        peer_config: Option<&PeerConfig>,
    ) -> (f64, ScoreBreakdown) {
        let latency_score = self.score_latency(metrics.rtt_median);
        let loss_score = self.score_loss(metrics.loss_ratio);
        let jitter_score = self.score_jitter(metrics.rtt_jitter);
        let stability_score = self.score_stability(session);
        let capacity_score = self.score_capacity(capacity);
        let cost_score = self.score_cost(peer_config);

        let breakdown = ScoreBreakdown {
            latency_score,
            loss_score,
            jitter_score,
            stability_score,
            capacity_score,
        };

        let final_score = self.weights.latency * latency_score
            + self.weights.loss * loss_score
            + self.weights.jitter * jitter_score
            + self.weights.stability * stability_score
            + self.weights.capacity * capacity_score
            + self.weights.cost * cost_score;

        (final_score.clamp(0.0, 1.0), breakdown)
    }

    /// score latency - lower is better
    fn score_latency(&self, rtt: Duration) -> f64 {
        let max_ms = self.baselines.max_acceptable_rtt.as_secs_f64() * 1000.0;
        let rtt_ms = rtt.as_secs_f64() * 1000.0;

        if rtt_ms <= 0.0 {
            return 1.0;
        }

        // exponential decay - small latencies score much better
        // 10ms = 0.95, 50ms = 0.78, 100ms = 0.61, 200ms = 0.37
        let normalized = rtt_ms / max_ms;
        (-normalized * 2.0).exp().clamp(0.0, 1.0)
    }

    /// score packet loss - lower is better
    fn score_loss(&self, loss: f64) -> f64 {
        if loss <= 0.0 {
            return 1.0;
        }

        let max_loss = self.baselines.max_acceptable_loss;

        // very aggressive penalty for loss
        // 0.5% loss = 0.75, 1% = 0.5, 2% = 0
        let normalized = loss / max_loss;
        (1.0 - normalized.powf(0.5)).clamp(0.0, 1.0)
    }

    /// score jitter - lower is better
    fn score_jitter(&self, jitter: Duration) -> f64 {
        let max_ms = self.baselines.max_acceptable_jitter.as_secs_f64() * 1000.0;
        let jitter_ms = jitter.as_secs_f64() * 1000.0;

        if jitter_ms <= 0.0 {
            return 1.0;
        }

        (1.0 - (jitter_ms / max_ms)).clamp(0.0, 1.0)
    }

    /// score session stability - uptime and flap history
    fn score_stability(&self, session: &SessionState) -> f64 {
        if !session.is_established() {
            return 0.0;
        }

        // penalize recent flaps
        let flap_penalty = session
            .last_flap
            .map(|f| {
                let since_flap = f.elapsed();
                let recovery_time = Duration::from_secs(3600); // 1h to fully recover
                (since_flap.as_secs_f64() / recovery_time.as_secs_f64()).min(1.0)
            })
            .unwrap_or(1.0);

        // uptime score - logarithmic, full score at stable_uptime
        let uptime_secs = session.uptime.as_secs_f64();
        let stable_secs = self.baselines.stable_uptime.as_secs_f64();

        let uptime_score = if uptime_secs >= stable_secs {
            1.0
        } else if uptime_secs <= 0.0 {
            0.0
        } else {
            // log scale - 1 hour = 0.5, 12 hours = 0.75, 24 hours = 1.0
            (uptime_secs.ln() / stable_secs.ln()).clamp(0.0, 1.0)
        };

        flap_penalty * uptime_score
    }

    /// score available capacity - key for load balancing
    /// higher available capacity = higher score
    fn score_capacity(&self, capacity: &PeerCapacity) -> f64 {
        let utilization = capacity.utilization;
        let congestion = self.baselines.congestion_threshold;
        let critical = self.baselines.critical_threshold;

        if utilization >= critical {
            // critical - avoid this path
            0.0
        } else if utilization >= congestion {
            // congested - penalize proportionally
            let range = critical - congestion;
            let excess = utilization - congestion;
            0.3 * (1.0 - excess / range)
        } else {
            // healthy - score based on headroom
            // 0% util = 1.0, 50% = 0.7, 75% = 0.3
            let headroom = 1.0 - (utilization / congestion);
            0.3 + 0.7 * headroom
        }
    }

    /// score cost factor - lower cost = higher score
    fn score_cost(&self, peer_config: Option<&PeerConfig>) -> f64 {
        let cost = peer_config.map(|c| c.cost_factor).unwrap_or(1.0);

        // transit typically costs more than peering
        // cost 1.0 = score 1.0, cost 2.0 = score 0.5, cost 3.0 = score 0.33
        (1.0 / cost).clamp(0.0, 1.0)
    }
}

/// compute target local_pref from score
/// maps score [0.0, 1.0] to local_pref [50, 150]
pub fn score_to_local_pref(score: f64, min_pref: u16, max_pref: u16) -> u16 {
    let range = (max_pref - min_pref) as f64;
    let pref = min_pref as f64 + (score * range);
    pref.round() as u16
}

/// compute ecmp weights from scores
/// returns normalized weights that sum to 1.0
pub fn scores_to_weights(scores: &[(String, f64)]) -> Vec<(String, f64)> {
    let total: f64 = scores.iter().map(|(_, s)| s).sum();

    if total <= 0.0 {
        // equal weights if no valid scores
        let weight = 1.0 / scores.len() as f64;
        return scores.iter().map(|(name, _)| (name.clone(), weight)).collect();
    }

    scores
        .iter()
        .map(|(name, score)| (name.clone(), score / total))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::{BgpState, PeerId, RouterId, TrafficCounters};
    use std::net::IpAddr;

    fn make_scorer() -> Scorer {
        Scorer::new(
            ScoringWeightsConfig::default(),
            BaselinesConfig::default(),
        )
    }

    fn make_session() -> SessionState {
        SessionState {
            peer_id: PeerId {
                router: RouterId::Bkk00,
                remote_as: 6939,
                remote_addr: "203.159.68.135".parse().unwrap(),
            },
            name: "HE-BKNIX-v4".into(),
            origin: None,
            state: BgpState::Established,
            uptime: Duration::from_secs(86400),
            prefixes_received: 200000,
            prefixes_advertised: 5,
            updates_received: 1000,
            withdraws_received: 50,
            last_flap: None,
            traffic: TrafficCounters::default(),
        }
    }

    #[test]
    fn test_latency_scoring() {
        let scorer = make_scorer();

        // 10ms should score very high
        assert!(scorer.score_latency(Duration::from_millis(10)) > 0.9);
        // 50ms should score well
        assert!(scorer.score_latency(Duration::from_millis(50)) > 0.6);
        // 200ms should score low
        assert!(scorer.score_latency(Duration::from_millis(200)) < 0.4);
    }

    #[test]
    fn test_capacity_scoring() {
        let scorer = make_scorer();

        // low utilization = high score
        let low_util = PeerCapacity::new(1_000_000_000, 100_000_000); // 10%
        assert!(scorer.score_capacity(&low_util) > 0.8);

        // high utilization = low score
        let high_util = PeerCapacity::new(1_000_000_000, 850_000_000); // 85%
        assert!(scorer.score_capacity(&high_util) < 0.3);

        // critical = zero
        let critical = PeerCapacity::new(1_000_000_000, 950_000_000); // 95%
        assert_eq!(scorer.score_capacity(&critical), 0.0);
    }

    #[test]
    fn test_score_to_local_pref() {
        assert_eq!(score_to_local_pref(0.0, 50, 150), 50);
        assert_eq!(score_to_local_pref(0.5, 50, 150), 100);
        assert_eq!(score_to_local_pref(1.0, 50, 150), 150);
    }
}
