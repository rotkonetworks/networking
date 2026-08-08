use crate::config::{Config, PeerConfig};
use crate::error::Result;
use crate::types::{PeerCapacity, PeerOrigin, RouterId, SessionState};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;
use tracing::{debug, info, warn};

use super::MikrotikClient;

/// collected state for all peers
#[derive(Debug, Clone)]
pub struct PeerState {
    pub origin: PeerOrigin,
    pub router: RouterId,
    pub session: SessionState,
    pub capacity: PeerCapacity,
    pub updated_at: Instant,
}

/// session collector - periodically fetches state from all routers
pub struct SessionCollector {
    clients: HashMap<RouterId, MikrotikClient>,
    peer_configs: HashMap<String, PeerConfig>,
    /// cached state per peer origin
    state: Arc<RwLock<HashMap<PeerOrigin, PeerState>>>,
}

impl SessionCollector {
    pub fn new(
        clients: HashMap<RouterId, MikrotikClient>,
        peer_configs: HashMap<String, PeerConfig>,
    ) -> Self {
        Self {
            clients,
            peer_configs,
            state: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// run a single collection cycle
    pub async fn collect(&self) -> Result<()> {
        let mut all_states: HashMap<PeerOrigin, PeerState> = HashMap::new();

        for (router_id, client) in &self.clients {
            match client.get_bgp_sessions().await {
                Ok(sessions) => {
                    for session in sessions {
                        if let Some(origin) = session.origin {
                            // get capacity using session's traffic data
                            let capacity = self.get_peer_capacity_from_session(&origin, &session);

                            all_states.insert(
                                origin,
                                PeerState {
                                    origin,
                                    router: *router_id,
                                    session,
                                    capacity,
                                    updated_at: Instant::now(),
                                },
                            );
                        }
                    }
                }
                Err(e) => {
                    warn!(router = %router_id, error = %e, "failed to collect sessions");
                }
            }
        }

        // update cache
        let mut cache = self.state.write().await;
        *cache = all_states;

        debug!(
            peers = cache.len(),
            "collection cycle complete"
        );

        Ok(())
    }

    fn get_peer_capacity_from_session(&self, origin: &PeerOrigin, session: &SessionState) -> PeerCapacity {
        // find peer config by origin name - match config key against origin name
        let origin_name = origin.name().to_lowercase();
        let peer_config = self
            .peer_configs
            .iter()
            .find(|(name, _)| {
                let config_name = name.to_lowercase().replace("-", "_");
                config_name == origin_name || origin_name.contains(&config_name) || config_name.contains(&origin_name)
            });

        match peer_config {
            Some((_, config)) => {
                let capacity_bps = config.capacity_mbps * 1_000_000;
                // use traffic from session (populated by mikrotik client with sim state)
                let current_bps = session.traffic.rx_bps.max(session.traffic.tx_bps);
                PeerCapacity::new(capacity_bps, current_bps)
            }
            None => {
                // default 1gbps capacity, use session traffic
                let current_bps = session.traffic.rx_bps.max(session.traffic.tx_bps);
                PeerCapacity::new(1_000_000_000, current_bps)
            }
        }
    }

    /// get current state for a peer
    pub async fn get_state(&self, origin: PeerOrigin) -> Option<PeerState> {
        let cache = self.state.read().await;
        cache.get(&origin).cloned()
    }

    /// get all current states
    pub async fn get_all_states(&self) -> HashMap<PeerOrigin, PeerState> {
        let cache = self.state.read().await;
        cache.clone()
    }

    /// get total egress capacity across all peers
    pub async fn total_capacity(&self) -> u64 {
        let cache = self.state.read().await;
        cache.values().map(|s| s.capacity.capacity_bps).sum()
    }

    /// get total current utilization
    pub async fn total_utilization(&self) -> f64 {
        let cache = self.state.read().await;
        let total_capacity: u64 = cache.values().map(|s| s.capacity.capacity_bps).sum();
        let total_used: u64 = cache
            .values()
            .map(|s| (s.capacity.utilization * s.capacity.capacity_bps as f64) as u64)
            .sum();

        if total_capacity > 0 {
            total_used as f64 / total_capacity as f64
        } else {
            0.0
        }
    }

    /// background task that runs collection periodically
    pub async fn run_background(
        self: Arc<Self>,
        interval: Duration,
        mut shutdown: tokio::sync::watch::Receiver<bool>,
    ) {
        info!(?interval, "starting session collector");

        let mut ticker = tokio::time::interval(interval);
        ticker.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

        loop {
            tokio::select! {
                _ = ticker.tick() => {
                    if let Err(e) = self.collect().await {
                        warn!(error = %e, "collection cycle failed");
                    }
                }
                _ = shutdown.changed() => {
                    if *shutdown.borrow() {
                        info!("session collector shutting down");
                        break;
                    }
                }
            }
        }
    }
}
