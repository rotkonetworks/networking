use std::time::{Duration, Instant};

use super::peer::{PeerId, PeerOrigin};

/// measured quality metrics for a path
#[derive(Debug, Clone, Copy)]
pub struct PathMetrics {
    /// round-trip time (median of last n probes)
    pub rtt_median: Duration,
    /// rtt jitter (stddev)
    pub rtt_jitter: Duration,
    /// packet loss ratio [0.0, 1.0]
    pub loss_ratio: f64,
    /// timestamp of measurement
    pub measured_at: Instant,
}

impl Default for PathMetrics {
    fn default() -> Self {
        Self {
            rtt_median: Duration::from_millis(100),
            rtt_jitter: Duration::from_millis(5),
            loss_ratio: 0.0,
            measured_at: Instant::now(),
        }
    }
}

/// interface traffic counters
#[derive(Debug, Clone, Copy, Default)]
pub struct TrafficCounters {
    /// bytes received since last poll
    pub rx_bytes: u64,
    /// bytes transmitted since last poll
    pub tx_bytes: u64,
    /// receive rate in bits per second
    pub rx_bps: u64,
    /// transmit rate in bits per second
    pub tx_bps: u64,
    /// measurement interval
    pub interval: Duration,
}

/// capacity info for a peer link
#[derive(Debug, Clone, Copy)]
pub struct PeerCapacity {
    /// nominal link capacity in bits per second
    pub capacity_bps: u64,
    /// current utilization ratio [0.0, 1.0]
    pub utilization: f64,
    /// available headroom in bps
    pub available_bps: u64,
}

impl PeerCapacity {
    pub fn new(capacity_bps: u64, current_bps: u64) -> Self {
        let utilization = if capacity_bps > 0 {
            (current_bps as f64) / (capacity_bps as f64)
        } else {
            1.0
        };
        let available_bps = capacity_bps.saturating_sub(current_bps);

        Self {
            capacity_bps,
            utilization,
            available_bps,
        }
    }

    /// check if link is congested (>80% util)
    pub fn is_congested(&self) -> bool {
        self.utilization > 0.80
    }

    /// check if link is critical (>95% util)
    pub fn is_critical(&self) -> bool {
        self.utilization > 0.95
    }
}

/// bgp session state from collector
#[derive(Debug, Clone)]
pub struct SessionState {
    pub peer_id: PeerId,
    pub name: String,
    pub origin: Option<PeerOrigin>,
    pub state: BgpState,
    pub uptime: Duration,
    pub prefixes_received: u32,
    pub prefixes_advertised: u32,
    pub updates_received: u64,
    pub withdraws_received: u64,
    pub last_flap: Option<Instant>,
    /// traffic counters for this peer's interface
    pub traffic: TrafficCounters,
}

impl SessionState {
    pub fn is_established(&self) -> bool {
        self.state == BgpState::Established
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BgpState {
    Established,
    OpenSent,
    OpenConfirm,
    Active,
    Connect,
    Idle,
}

impl BgpState {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "established" => BgpState::Established,
            "opensent" => BgpState::OpenSent,
            "openconfirm" => BgpState::OpenConfirm,
            "active" => BgpState::Active,
            "connect" => BgpState::Connect,
            _ => BgpState::Idle,
        }
    }
}

/// combined path evaluation with all metrics
#[derive(Debug, Clone)]
pub struct PathEvaluation {
    pub peer_id: PeerId,
    pub origin: PeerOrigin,
    pub session_name: String,
    pub metrics: PathMetrics,
    pub session: SessionState,
    pub capacity: PeerCapacity,
    /// final computed score [0.0, 1.0]
    pub score: f64,
    /// breakdown of score components for debugging
    pub score_breakdown: ScoreBreakdown,
}

/// individual score components for observability
#[derive(Debug, Clone, Copy, Default)]
pub struct ScoreBreakdown {
    pub latency_score: f64,
    pub loss_score: f64,
    pub jitter_score: f64,
    pub stability_score: f64,
    pub capacity_score: f64,
}

/// represents a routing decision for a destination prefix
#[derive(Debug, Clone)]
pub struct RoutingDecision {
    /// destination prefix (or "default" for 0.0.0.0/0)
    pub prefix: String,
    /// ordered list of paths by preference
    pub paths: Vec<PathEvaluation>,
    /// recommended actions to take
    pub actions: Vec<super::action::Action>,
    /// timestamp of decision
    pub decided_at: Instant,
}
