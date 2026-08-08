use crate::decision::Optimizer;
use prometheus::{
    Encoder, GaugeVec, IntGaugeVec, Opts, Registry, TextEncoder,
};
use std::sync::Arc;
use tokio::sync::RwLock;

/// prometheus metrics exporter
pub struct MetricsExporter {
    registry: Registry,
    // peer metrics
    peer_score: GaugeVec,
    peer_rtt: GaugeVec,
    peer_loss: GaugeVec,
    peer_utilization: GaugeVec,
    peer_capacity: IntGaugeVec,
    peer_local_pref: IntGaugeVec,
    peer_established: IntGaugeVec,
    // aggregate metrics
    total_capacity: prometheus::IntGauge,
    total_utilization: prometheus::Gauge,
    optimization_cycles: prometheus::IntCounter,
    actions_applied: prometheus::IntCounter,
}

impl MetricsExporter {
    pub fn new() -> Self {
        let registry = Registry::new();

        let peer_score = GaugeVec::new(
            Opts::new("bgpctl_peer_score", "computed score for peer path"),
            &["origin", "router"],
        )
        .unwrap();

        let peer_rtt = GaugeVec::new(
            Opts::new("bgpctl_peer_rtt_ms", "round-trip time to peer in milliseconds"),
            &["origin", "router"],
        )
        .unwrap();

        let peer_loss = GaugeVec::new(
            Opts::new("bgpctl_peer_loss_ratio", "packet loss ratio to peer"),
            &["origin", "router"],
        )
        .unwrap();

        let peer_utilization = GaugeVec::new(
            Opts::new("bgpctl_peer_utilization", "link utilization ratio"),
            &["origin", "router"],
        )
        .unwrap();

        let peer_capacity = IntGaugeVec::new(
            Opts::new("bgpctl_peer_capacity_bps", "link capacity in bits per second"),
            &["origin", "router"],
        )
        .unwrap();

        let peer_local_pref = IntGaugeVec::new(
            Opts::new("bgpctl_peer_local_pref", "current local preference"),
            &["origin", "router"],
        )
        .unwrap();

        let peer_established = IntGaugeVec::new(
            Opts::new("bgpctl_peer_established", "1 if peer is established, 0 otherwise"),
            &["origin", "router"],
        )
        .unwrap();

        let total_capacity = prometheus::IntGauge::new(
            "bgpctl_total_capacity_bps",
            "total capacity across all peers in bps",
        )
        .unwrap();

        let total_utilization = prometheus::Gauge::new(
            "bgpctl_total_utilization",
            "overall utilization ratio",
        )
        .unwrap();

        let optimization_cycles = prometheus::IntCounter::new(
            "bgpctl_optimization_cycles_total",
            "number of optimization cycles run",
        )
        .unwrap();

        let actions_applied = prometheus::IntCounter::new(
            "bgpctl_actions_applied_total",
            "number of actions applied",
        )
        .unwrap();

        registry.register(Box::new(peer_score.clone())).unwrap();
        registry.register(Box::new(peer_rtt.clone())).unwrap();
        registry.register(Box::new(peer_loss.clone())).unwrap();
        registry.register(Box::new(peer_utilization.clone())).unwrap();
        registry.register(Box::new(peer_capacity.clone())).unwrap();
        registry.register(Box::new(peer_local_pref.clone())).unwrap();
        registry.register(Box::new(peer_established.clone())).unwrap();
        registry.register(Box::new(total_capacity.clone())).unwrap();
        registry.register(Box::new(total_utilization.clone())).unwrap();
        registry.register(Box::new(optimization_cycles.clone())).unwrap();
        registry.register(Box::new(actions_applied.clone())).unwrap();

        Self {
            registry,
            peer_score,
            peer_rtt,
            peer_loss,
            peer_utilization,
            peer_capacity,
            peer_local_pref,
            peer_established,
            total_capacity,
            total_utilization,
            optimization_cycles,
            actions_applied,
        }
    }

    /// update metrics from optimizer state
    pub async fn update(&self, optimizer: &Optimizer) {
        let summary = optimizer.get_summary().await;

        self.total_capacity.set((summary.total_capacity_gbps * 1_000_000_000.0) as i64);
        self.total_utilization.set(summary.total_utilization_pct / 100.0);

        for peer in &summary.peers {
            let origin = peer.origin.name();
            let router = peer.router.to_string();

            if let Some(rtt) = peer.rtt_ms {
                self.peer_rtt.with_label_values(&[origin, &router]).set(rtt);
            }

            if let Some(loss) = peer.loss_pct {
                self.peer_loss
                    .with_label_values(&[origin, &router])
                    .set(loss / 100.0);
            }

            self.peer_utilization
                .with_label_values(&[origin, &router])
                .set(peer.utilization_pct / 100.0);

            self.peer_capacity
                .with_label_values(&[origin, &router])
                .set((peer.capacity_mbps * 1_000_000) as i64);

            if let Some(pref) = peer.current_pref {
                self.peer_local_pref
                    .with_label_values(&[origin, &router])
                    .set(pref as i64);
            }

            self.peer_established
                .with_label_values(&[origin, &router])
                .set(if peer.established { 1 } else { 0 });
        }
    }

    pub fn record_cycle(&self) {
        self.optimization_cycles.inc();
    }

    pub fn record_actions(&self, count: u64) {
        self.actions_applied.inc_by(count);
    }

    /// encode metrics as prometheus text format
    pub fn encode(&self) -> String {
        let encoder = TextEncoder::new();
        let metric_families = self.registry.gather();
        let mut buffer = Vec::new();
        encoder.encode(&metric_families, &mut buffer).unwrap();
        String::from_utf8(buffer).unwrap()
    }
}
