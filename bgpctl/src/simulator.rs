//! traffic simulation for testing load balancing behavior
//!
//! generates realistic traffic patterns to demonstrate how the optimizer
//! responds to congestion and rebalances traffic across peers

use crate::types::{PeerOrigin, RouterId, TrafficCounters};
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

/// global simulation state
pub struct SimulationState {
    /// simulated traffic rate per peer (bps)
    traffic: HashMap<PeerOrigin, AtomicU64>,
    /// capacity per peer (bps)
    capacity: HashMap<PeerOrigin, u64>,
    /// latency per peer (ms)
    latency: HashMap<PeerOrigin, AtomicU64>,
    /// packet loss per peer (basis points, 100 = 1%)
    loss: HashMap<PeerOrigin, AtomicU64>,
    /// scenario start time
    start: Instant,
    /// current scenario
    scenario: SimulationScenario,
}

#[derive(Debug, Clone, Copy)]
pub enum SimulationScenario {
    /// all peers healthy, moderate load
    Normal,
    /// hgc-hk congested, need to shift traffic
    HgcHkCongested,
    /// bknix has packet loss issues
    BknixLossy,
    /// gradual traffic increase over time
    TrafficRamp,
    /// one peer down
    PeerDown(PeerOrigin),
    /// flash crowd - sudden traffic spike
    FlashCrowd,
}

impl SimulationState {
    pub fn new(scenario: SimulationScenario) -> Self {
        let mut capacity = HashMap::new();
        let mut traffic = HashMap::new();
        let mut latency = HashMap::new();
        let mut loss = HashMap::new();

        // realistic capacities matching actual port sizes
        for origin in PeerOrigin::all() {
            let cap = match origin {
                PeerOrigin::Bknix => 10_000_000_000,      // 10G v4
                PeerOrigin::BknixV6 => 10_000_000_000,    // 10G v6 (same port)
                PeerOrigin::HgcHk => 800_000_000,         // 800M
                PeerOrigin::HgcSg => 800_000_000,         // 800M
                PeerOrigin::AmsixEu => 100_000_000,       // 100M
                PeerOrigin::AmsixBkk => 1_000_000_000,    // 1G
                PeerOrigin::AmsixHk => 200_000_000,       // 200M
                PeerOrigin::HeV6 => 10_000_000_000,       // v6 transit via BKNIX 10G
                PeerOrigin::Cloudflare => 10_000_000_000, // via BKNIX 10G
                PeerOrigin::IptxBackup => 100_000_000,    // 100M backup
            };
            capacity.insert(*origin, cap);
            traffic.insert(*origin, AtomicU64::new(0));
            latency.insert(*origin, AtomicU64::new(20)); // 20ms default
            loss.insert(*origin, AtomicU64::new(0)); // 0% loss
        }

        // set up initial state based on scenario
        let state = Self {
            traffic,
            capacity,
            latency,
            loss,
            start: Instant::now(),
            scenario,
        };

        state.apply_scenario();
        state
    }

    fn apply_scenario(&self) {
        match self.scenario {
            SimulationScenario::Normal => {
                // moderate balanced load - realistic for your capacities
                // total ~2.5G spread across links
                self.set_traffic(PeerOrigin::HgcHk, 500_000_000);   // 500M on 800M (62%)
                self.set_traffic(PeerOrigin::HgcSg, 400_000_000);   // 400M on 800M (50%)
                self.set_traffic(PeerOrigin::Bknix, 800_000_000);   // 800M on 10G (8%)
                self.set_traffic(PeerOrigin::AmsixBkk, 600_000_000); // 600M on 1G (60%)
                self.set_traffic(PeerOrigin::AmsixHk, 120_000_000); // 120M on 200M (60%)
                self.set_traffic(PeerOrigin::AmsixEu, 50_000_000);  // 50M on 100M (50%)
                self.set_traffic(PeerOrigin::HeV6, 200_000_000);      // 200M via BKNIX (v6 transit)
                self.set_traffic(PeerOrigin::Cloudflare, 150_000_000); // 150M via BKNIX

                // set realistic latencies
                self.set_latency(PeerOrigin::Bknix, 5); // local IX
                self.set_latency(PeerOrigin::AmsixBkk, 8);
                self.set_latency(PeerOrigin::HgcHk, 35);
                self.set_latency(PeerOrigin::HgcSg, 25);
                self.set_latency(PeerOrigin::AmsixHk, 40);
                self.set_latency(PeerOrigin::AmsixEu, 180);
                self.set_latency(PeerOrigin::HeV6, 45);
                self.set_latency(PeerOrigin::Cloudflare, 10);
            }

            SimulationScenario::HgcHkCongested => {
                // HGC HK at 95% of 800M - should trigger load shedding
                self.set_traffic(PeerOrigin::HgcHk, 760_000_000);  // 760M on 800M (95%)
                self.set_traffic(PeerOrigin::HgcSg, 600_000_000);  // 600M on 800M (75%)
                self.set_traffic(PeerOrigin::Bknix, 500_000_000);
                self.set_traffic(PeerOrigin::AmsixBkk, 400_000_000);

                self.set_latency(PeerOrigin::HgcHk, 85); // congestion latency
                self.set_latency(PeerOrigin::Bknix, 5);
                self.set_latency(PeerOrigin::HgcSg, 40); // elevated due to load

                self.set_loss(PeerOrigin::HgcHk, 50); // 0.5% loss from congestion
            }

            SimulationScenario::BknixLossy => {
                // BKNIX having issues - maybe fiber cut or IX problems
                self.set_traffic(PeerOrigin::Bknix, 600_000_000);
                self.set_traffic(PeerOrigin::HgcHk, 700_000_000);  // 87% - picking up slack
                self.set_traffic(PeerOrigin::HgcSg, 650_000_000);  // 81%

                self.set_latency(PeerOrigin::Bknix, 15); // slightly elevated
                self.set_loss(PeerOrigin::Bknix, 300); // 3% loss - bad!
            }

            SimulationScenario::TrafficRamp => {
                // starts low, increases over time
                // handled in get_current_traffic()
                self.set_latency(PeerOrigin::Bknix, 5);
                self.set_latency(PeerOrigin::HgcHk, 35);
                self.set_latency(PeerOrigin::HgcSg, 25);
            }

            SimulationScenario::PeerDown(origin) => {
                // one peer completely down
                self.set_traffic(origin, 0);
                self.set_loss(origin, 10000); // 100% loss = down

                // redistribute to others - traffic shifts to remaining links
                self.set_traffic(PeerOrigin::HgcHk, 750_000_000);  // 94% - near cap!
                self.set_traffic(PeerOrigin::HgcSg, 700_000_000);  // 87%
                self.set_traffic(PeerOrigin::Bknix, 1_500_000_000); // absorbs most
                self.set_traffic(PeerOrigin::AmsixBkk, 900_000_000); // 90%
            }

            SimulationScenario::FlashCrowd => {
                // sudden spike - small links saturate first
                self.set_traffic(PeerOrigin::HgcHk, 800_000_000);   // 100% - maxed!
                self.set_traffic(PeerOrigin::HgcSg, 800_000_000);   // 100% - maxed!
                self.set_traffic(PeerOrigin::Bknix, 3_000_000_000); // 30% of 10G
                self.set_traffic(PeerOrigin::AmsixBkk, 1_000_000_000); // 100% - maxed!
                self.set_traffic(PeerOrigin::AmsixHk, 200_000_000); // 100% - maxed!
                self.set_traffic(PeerOrigin::AmsixEu, 100_000_000); // 100% - maxed!
                self.set_traffic(PeerOrigin::HeV6, 1_000_000_000);
                self.set_traffic(PeerOrigin::Cloudflare, 500_000_000);

                // latencies spike on saturated links
                self.set_latency(PeerOrigin::HgcHk, 120);  // bad
                self.set_latency(PeerOrigin::HgcSg, 100);  // bad
                self.set_latency(PeerOrigin::Bknix, 8);    // still ok
                self.set_latency(PeerOrigin::AmsixBkk, 50); // elevated
                self.set_latency(PeerOrigin::AmsixHk, 80);
                self.set_latency(PeerOrigin::AmsixEu, 250);

                // packet loss on saturated links
                self.set_loss(PeerOrigin::HgcHk, 200);   // 2%
                self.set_loss(PeerOrigin::HgcSg, 150);   // 1.5%
                self.set_loss(PeerOrigin::AmsixBkk, 100); // 1%
            }
        }
    }

    fn set_traffic(&self, origin: PeerOrigin, bps: u64) {
        if let Some(t) = self.traffic.get(&origin) {
            t.store(bps, Ordering::Relaxed);
        }
    }

    fn set_latency(&self, origin: PeerOrigin, ms: u64) {
        if let Some(l) = self.latency.get(&origin) {
            l.store(ms, Ordering::Relaxed);
        }
    }

    fn set_loss(&self, origin: PeerOrigin, basis_points: u64) {
        if let Some(l) = self.loss.get(&origin) {
            l.store(basis_points, Ordering::Relaxed);
        }
    }

    /// get current traffic for a peer (may vary over time for some scenarios)
    pub fn get_traffic(&self, origin: PeerOrigin) -> u64 {
        let base = self.traffic.get(&origin)
            .map(|t| t.load(Ordering::Relaxed))
            .unwrap_or(0);

        match self.scenario {
            SimulationScenario::TrafficRamp => {
                // ramp up over 10 minutes
                let elapsed = self.start.elapsed().as_secs_f64();
                let ramp_duration = 600.0; // 10 min
                let ramp_factor = (elapsed / ramp_duration).min(1.0);

                // start at 20%, ramp to 90%
                let min_util = 0.2;
                let max_util = 0.9;
                let util = min_util + (max_util - min_util) * ramp_factor;

                let capacity = self.capacity.get(&origin).copied().unwrap_or(10_000_000_000);
                (capacity as f64 * util) as u64
            }
            _ => base,
        }
    }

    pub fn get_capacity(&self, origin: PeerOrigin) -> u64 {
        self.capacity.get(&origin).copied().unwrap_or(10_000_000_000)
    }

    pub fn get_latency_ms(&self, origin: PeerOrigin) -> u64 {
        self.latency.get(&origin)
            .map(|l| l.load(Ordering::Relaxed))
            .unwrap_or(50)
    }

    pub fn get_loss_ratio(&self, origin: PeerOrigin) -> f64 {
        self.loss.get(&origin)
            .map(|l| l.load(Ordering::Relaxed) as f64 / 10000.0)
            .unwrap_or(0.0)
    }

    pub fn get_utilization(&self, origin: PeerOrigin) -> f64 {
        let traffic = self.get_traffic(origin) as f64;
        let capacity = self.get_capacity(origin) as f64;
        if capacity > 0.0 {
            traffic / capacity
        } else {
            1.0
        }
    }

    pub fn get_counters(&self, origin: PeerOrigin) -> TrafficCounters {
        let bps = self.get_traffic(origin);
        TrafficCounters {
            rx_bytes: bps / 8 * 60,
            tx_bytes: bps / 8 * 60 / 3, // asymmetric
            rx_bps: bps,
            tx_bps: bps / 3,
            interval: Duration::from_secs(60),
        }
    }

    /// get summary of current state
    pub fn summary(&self) -> String {
        let mut lines = vec![format!("scenario: {:?}", self.scenario)];
        lines.push(format!("elapsed: {:.1}s", self.start.elapsed().as_secs_f64()));
        lines.push(String::new());
        lines.push(format!(
            "{:<12} {:>10} {:>10} {:>8} {:>8}",
            "PEER", "TRAFFIC", "CAPACITY", "UTIL", "RTT"
        ));
        lines.push("-".repeat(52));

        for origin in PeerOrigin::all() {
            let traffic = self.get_traffic(*origin);
            let capacity = self.get_capacity(*origin);
            let util = self.get_utilization(*origin);
            let rtt = self.get_latency_ms(*origin);
            let loss = self.get_loss_ratio(*origin);

            lines.push(format!(
                "{:<12} {:>9.1}G {:>9.1}G {:>7.1}% {:>6}ms{}",
                origin.name(),
                traffic as f64 / 1_000_000_000.0,
                capacity as f64 / 1_000_000_000.0,
                util * 100.0,
                rtt,
                if loss > 0.0 { format!(" (loss: {:.1}%)", loss * 100.0) } else { String::new() }
            ));
        }

        lines.join("\n")
    }
}

impl Default for SimulationState {
    fn default() -> Self {
        Self::new(SimulationScenario::Normal)
    }
}

/// parse scenario from string
pub fn parse_scenario(s: &str) -> Option<SimulationScenario> {
    match s.to_lowercase().as_str() {
        "normal" => Some(SimulationScenario::Normal),
        "congested" | "hgc-congested" => Some(SimulationScenario::HgcHkCongested),
        "lossy" | "bknix-lossy" => Some(SimulationScenario::BknixLossy),
        "ramp" | "traffic-ramp" => Some(SimulationScenario::TrafficRamp),
        "flash" | "flash-crowd" => Some(SimulationScenario::FlashCrowd),
        "down-hgc" => Some(SimulationScenario::PeerDown(PeerOrigin::HgcHk)),
        "down-bknix" => Some(SimulationScenario::PeerDown(PeerOrigin::Bknix)),
        _ => None,
    }
}
