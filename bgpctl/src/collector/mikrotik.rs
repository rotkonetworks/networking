use crate::config::RouterConfig;
use crate::error::{Error, Result};
use crate::simulator::{SimulationScenario, SimulationState};
use crate::types::{BgpState, PeerId, PeerOrigin, RouterId, SessionState, TrafficCounters, session_to_origin};
use reqwest::Client;
use secrecy::ExposeSecret;
use serde::Deserialize;
use std::net::IpAddr;
use std::sync::Arc;
use std::time::Duration;
use tracing::debug;

/// a bgp route from the routing table
#[derive(Debug, Clone)]
pub struct BgpRoute {
    pub prefix: String,
    pub gateway: IpAddr,
    pub peer_name: String,
    pub origin: Option<PeerOrigin>,
    pub local_pref: u32,
    pub as_path: Vec<u32>,
    pub communities: Vec<String>,
    pub active: bool,
}

/// mikrotik routeros rest api client
#[derive(Clone)]
pub struct MikrotikClient {
    router_id: RouterId,
    base_url: String,
    client: Client,
    username: String,
    password: String,
    /// simulated mode for dry-run
    simulated: bool,
    /// simulation state (shared across clients)
    sim_state: Option<Arc<SimulationState>>,
}

#[derive(Debug, Deserialize)]
struct BgpSessionResponse {
    #[serde(rename = ".id")]
    id: String,
    name: String,
    #[serde(rename = "remote.address", default)]
    remote_address: Option<String>,
    #[serde(rename = "remote.as", default)]
    remote_as: Option<u32>,
    #[serde(default)]
    state: Option<String>,
    #[serde(default)]
    uptime: Option<String>,
    #[serde(rename = "prefix-count", default)]
    prefix_count: Option<u32>,
    #[serde(rename = "updates-received", default)]
    updates_received: Option<u64>,
    #[serde(rename = "withdraws-received", default)]
    withdraws_received: Option<u64>,
}

#[derive(Debug, Deserialize)]
struct InterfaceStatsResponse {
    name: String,
    #[serde(rename = "rx-byte", default)]
    rx_bytes: Option<u64>,
    #[serde(rename = "tx-byte", default)]
    tx_bytes: Option<u64>,
    #[serde(rename = "rx-bits-per-second", default)]
    rx_bps: Option<u64>,
    #[serde(rename = "tx-bits-per-second", default)]
    tx_bps: Option<u64>,
}

#[derive(Debug, Deserialize)]
struct FilterRuleResponse {
    #[serde(rename = ".id")]
    id: String,
    chain: String,
    rule: String,
    #[serde(default)]
    disabled: Option<bool>,
}

#[derive(Debug, Deserialize)]
struct BgpRouteResponse {
    #[serde(rename = "dst-address")]
    dst_address: String,
    gateway: Option<String>,
    #[serde(rename = "bgp.peer", default)]
    bgp_peer: Option<String>,
    #[serde(rename = "bgp.local-pref", default)]
    local_pref: Option<u32>,
    #[serde(rename = "bgp.as-path", default)]
    as_path: Option<String>,
    #[serde(rename = "bgp.communities", default)]
    communities: Option<String>,
    #[serde(default)]
    active: Option<bool>,
}

impl MikrotikClient {
    pub fn new(router_id: RouterId, config: &RouterConfig, simulated: bool) -> Result<Self> {
        let client = Client::builder()
            .danger_accept_invalid_certs(true) // routeros uses self-signed certs
            .timeout(Duration::from_secs(30))
            .connect_timeout(Duration::from_secs(10))
            .build()?;

        let scheme = if config.tls { "https" } else { "http" };
        let base_url = format!("{}://{}:{}/rest", scheme, config.address, config.port);

        let password = config
            .password
            .as_ref()
            .map(|p| p.expose_secret().to_string())
            .unwrap_or_default();

        Ok(Self {
            router_id,
            base_url,
            client,
            username: config.username.clone(),
            password,
            simulated,
            sim_state: None,
        })
    }

    /// create simulated client for dry-run
    pub fn simulated(router_id: RouterId) -> Self {
        Self {
            router_id,
            base_url: String::new(),
            client: Client::new(),
            username: String::new(),
            password: String::new(),
            simulated: true,
            sim_state: None,
        }
    }

    /// create simulated client with shared simulation state
    pub fn with_simulation(router_id: RouterId, state: Arc<SimulationState>) -> Self {
        Self {
            router_id,
            base_url: String::new(),
            client: Client::new(),
            username: String::new(),
            password: String::new(),
            simulated: true,
            sim_state: Some(state),
        }
    }

    pub fn router_id(&self) -> RouterId {
        self.router_id
    }

    /// get all bgp sessions
    pub async fn get_bgp_sessions(&self) -> Result<Vec<SessionState>> {
        if self.simulated {
            return Ok(self.simulated_sessions());
        }

        let url = format!("{}/routing/bgp/session", self.base_url);

        let resp = self
            .client
            .get(&url)
            .basic_auth(&self.username, Some(&self.password))
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status().as_u16();
            let message = resp.text().await.unwrap_or_default();
            return Err(Error::ApiError { status, message });
        }

        let sessions: Vec<BgpSessionResponse> = resp.json().await?;

        sessions
            .into_iter()
            .map(|s| self.parse_session(s))
            .collect()
    }

    /// get interface traffic stats
    pub async fn get_interface_stats(&self, interface: &str) -> Result<TrafficCounters> {
        if self.simulated {
            return Ok(self.simulated_traffic());
        }

        let url = format!("{}/interface", self.base_url);

        let resp = self
            .client
            .get(&url)
            .basic_auth(&self.username, Some(&self.password))
            .query(&[("name", interface)])
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status().as_u16();
            let message = resp.text().await.unwrap_or_default();
            return Err(Error::ApiError { status, message });
        }

        let interfaces: Vec<InterfaceStatsResponse> = resp.json().await?;

        interfaces
            .into_iter()
            .find(|i| i.name == interface)
            .map(|i| TrafficCounters {
                rx_bytes: i.rx_bytes.unwrap_or(0),
                tx_bytes: i.tx_bytes.unwrap_or(0),
                rx_bps: i.rx_bps.unwrap_or(0),
                tx_bps: i.tx_bps.unwrap_or(0),
                interval: Duration::from_secs(1),
            })
            .ok_or_else(|| Error::ParseError(format!("interface {} not found", interface)))
    }

    /// get bgp routes from routing table
    /// can filter by prefix (e.g., "0.0.0.0/0" for default, or specific prefix)
    pub async fn get_bgp_routes(&self, prefix_filter: Option<&str>) -> Result<Vec<BgpRoute>> {
        if self.simulated {
            return Ok(self.simulated_routes(prefix_filter));
        }

        // mikrotik ros7 uses /routing/route for the unified routing table
        let url = format!("{}/routing/route", self.base_url);

        let mut query: Vec<(&str, &str)> = vec![("where", "bgp")];
        if let Some(prefix) = prefix_filter {
            query.push(("dst-address", prefix));
        }

        let resp = self
            .client
            .get(&url)
            .basic_auth(&self.username, Some(&self.password))
            .query(&query)
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status().as_u16();
            let message = resp.text().await.unwrap_or_default();
            return Err(Error::ApiError { status, message });
        }

        let routes: Vec<BgpRouteResponse> = resp.json().await?;

        Ok(routes
            .into_iter()
            .filter_map(|r| self.parse_route(r))
            .collect())
    }

    fn parse_route(&self, resp: BgpRouteResponse) -> Option<BgpRoute> {
        let gateway: IpAddr = resp.gateway.as_ref()?.parse().ok()?;
        let peer_name = resp.bgp_peer.unwrap_or_default();
        let origin = session_to_origin(&peer_name);

        let as_path: Vec<u32> = resp
            .as_path
            .map(|p| {
                p.split_whitespace()
                    .filter_map(|s| s.parse().ok())
                    .collect()
            })
            .unwrap_or_default();

        let communities: Vec<String> = resp
            .communities
            .map(|c| c.split(',').map(|s| s.trim().to_string()).collect())
            .unwrap_or_default();

        Some(BgpRoute {
            prefix: resp.dst_address,
            gateway,
            peer_name,
            origin,
            local_pref: resp.local_pref.unwrap_or(100),
            as_path,
            communities,
            active: resp.active.unwrap_or(false),
        })
    }

    fn simulated_routes(&self, _prefix_filter: Option<&str>) -> Vec<BgpRoute> {
        // generate some simulated routes for testing
        let peers = match self.router_id {
            RouterId::Bkk00 => vec![
                ("BKNIX-RS0-v4", PeerOrigin::Bknix, "203.159.68.68"),
                ("HGC-HK-PRIMARY-v4", PeerOrigin::HgcHk, "118.143.211.185"),
                ("HE-BKNIX-v6", PeerOrigin::HeV6, "2001:7fa:11:4::68"),
            ],
            RouterId::Bkk20 => vec![
                ("HGC-SG-PRIMARY-v4", PeerOrigin::HgcSg, "118.143.234.73"),
                ("AMSIX-RS1-TH-v4", PeerOrigin::AmsixBkk, "103.100.140.251"),
            ],
            RouterId::Bkk50 => vec![],
        };

        let mut routes = Vec::new();
        for (peer, origin, gw) in peers {
            // default route
            routes.push(BgpRoute {
                prefix: if origin.is_v6() { "::/0".to_string() } else { "0.0.0.0/0".to_string() },
                gateway: gw.parse().unwrap(),
                peer_name: peer.to_string(),
                origin: Some(origin),
                local_pref: 100,
                as_path: vec![63529, 6939],
                communities: vec![format!("142108:{}", origin as u16)],
                active: true,
            });
        }
        routes
    }

    /// set a community on import filter chain
    pub async fn set_import_community(
        &self,
        chain: &str,
        community: (u32, u16),
    ) -> Result<()> {
        if self.simulated {
            debug!(
                router = %self.router_id,
                chain = chain,
                community = %format!("{}:{}", community.0, community.1),
                "would set import community (dry-run)"
            );
            return Ok(());
        }

        // first, find existing rule for this chain that sets communities
        let url = format!("{}/routing/filter/rule", self.base_url);

        let resp = self
            .client
            .get(&url)
            .basic_auth(&self.username, Some(&self.password))
            .query(&[("chain", chain)])
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status().as_u16();
            let message = resp.text().await.unwrap_or_default();
            return Err(Error::ApiError { status, message });
        }

        let rules: Vec<FilterRuleResponse> = resp.json().await?;

        // find rule that sets bgp-communities
        let community_rule = rules
            .iter()
            .find(|r| r.rule.contains("set bgp-communities"));

        let community_str = format!("{}:{}", community.0, community.1);
        let new_rule = format!("set bgp-communities {}", community_str);

        if let Some(existing) = community_rule {
            // update existing rule
            let update_url = format!("{}/routing/filter/rule/{}", self.base_url, existing.id);

            let resp = self
                .client
                .patch(&update_url)
                .basic_auth(&self.username, Some(&self.password))
                .json(&serde_json::json!({
                    "rule": new_rule
                }))
                .send()
                .await?;

            if !resp.status().is_success() {
                let status = resp.status().as_u16();
                let message = resp.text().await.unwrap_or_default();
                return Err(Error::ApiError { status, message });
            }
        } else {
            // create new rule
            let resp = self
                .client
                .put(&url)
                .basic_auth(&self.username, Some(&self.password))
                .json(&serde_json::json!({
                    "chain": chain,
                    "rule": new_rule
                }))
                .send()
                .await?;

            if !resp.status().is_success() {
                let status = resp.status().as_u16();
                let message = resp.text().await.unwrap_or_default();
                return Err(Error::ApiError { status, message });
            }
        }

        Ok(())
    }

    /// set local_pref action community
    pub async fn set_local_pref_action(
        &self,
        chain: &str,
        local_pref: u16,
    ) -> Result<()> {
        // action community format: 142108:9XXX where XXX is local_pref
        let action_community = (142108u32, 9000 + local_pref);
        self.set_import_community(chain, action_community).await
    }

    fn parse_session(&self, resp: BgpSessionResponse) -> Result<SessionState> {
        let remote_addr: IpAddr = resp
            .remote_address
            .as_ref()
            .and_then(|s| s.parse().ok())
            .unwrap_or_else(|| "0.0.0.0".parse().unwrap());

        let remote_as = resp.remote_as.unwrap_or(0);

        let state = resp
            .state
            .as_ref()
            .map(|s| BgpState::from_str(s))
            .unwrap_or(BgpState::Idle);

        let uptime = resp
            .uptime
            .as_ref()
            .map(|u| parse_routeros_duration(u))
            .unwrap_or(Duration::ZERO);

        let origin = session_to_origin(&resp.name);

        Ok(SessionState {
            peer_id: PeerId {
                router: self.router_id,
                remote_as,
                remote_addr,
            },
            name: resp.name,
            origin,
            state,
            uptime,
            prefixes_received: resp.prefix_count.unwrap_or(0),
            prefixes_advertised: 0,
            updates_received: resp.updates_received.unwrap_or(0),
            withdraws_received: resp.withdraws_received.unwrap_or(0),
            last_flap: None,
            traffic: TrafficCounters::default(),
        })
    }

    /// generate simulated sessions for dry-run
    fn simulated_sessions(&self) -> Vec<SessionState> {
        let sessions = match self.router_id {
            RouterId::Bkk00 => vec![
                // ipv4
                ("BKNIX-RS0-v4", 63529, "203.159.68.68", PeerOrigin::Bknix),
                ("BKNIX-RS1-v4", 63529, "203.159.68.69", PeerOrigin::Bknix),
                ("HGC-HK-PRIMARY-v4", 9304, "118.143.211.185", PeerOrigin::HgcHk),
                ("AMSIX-RS1-v4", 6777, "80.249.208.255", PeerOrigin::AmsixEu),
                ("AMSIX-RS2-v4", 6777, "80.249.209.0", PeerOrigin::AmsixEu),
                ("Cloudflare-AMSIX-v4-1", 13335, "80.249.211.140", PeerOrigin::Cloudflare),
                // ipv6 - HE is our v6 transit!
                ("HE-BKNIX-v6", 6939, "2001:7fa:11:4::68", PeerOrigin::HeV6),
                ("BKNIX-RS0-v6", 63529, "2001:7fa:11::45", PeerOrigin::BknixV6),
            ],
            RouterId::Bkk20 => vec![
                ("HGC-SG-PRIMARY-v4", 9304, "118.143.234.73", PeerOrigin::HgcSg),
                ("AMSIX-RS1-TH-v4", 150388, "103.100.140.251", PeerOrigin::AmsixBkk),
                ("AMSIX-RS2-TH-v4", 150388, "103.100.140.252", PeerOrigin::AmsixBkk),
                ("AMSIX-RS1-HK-v4", 58560, "103.247.139.125", PeerOrigin::AmsixHk),
                ("AMSIX-RS2-HK-v4", 58560, "103.247.139.126", PeerOrigin::AmsixHk),
                ("AMSIX-CLOUDFLARE-HK-v4", 13335, "103.247.139.50", PeerOrigin::Cloudflare),
                ("HGC-HK-BACKUP-v4", 142435, "103.168.174.177", PeerOrigin::IptxBackup),
            ],
            RouterId::Bkk50 => vec![],
        };

        sessions
            .into_iter()
            .map(|(name, asn, addr, origin)| {
                // get traffic from simulation state if available
                let traffic = self.simulated_traffic_for_origin(origin);

                SessionState {
                    peer_id: PeerId {
                        router: self.router_id,
                        remote_as: asn,
                        remote_addr: addr.parse().unwrap(),
                    },
                    name: name.to_string(),
                    origin: Some(origin),
                    state: BgpState::Established,
                    uptime: Duration::from_secs(86400 * 7), // 7 days
                    prefixes_received: match origin {
                        PeerOrigin::HgcHk | PeerOrigin::HgcSg => 900000,
                        PeerOrigin::AmsixEu => 800000,
                        PeerOrigin::Bknix | PeerOrigin::BknixV6 => 200000,
                        PeerOrigin::HeV6 => 230000, // full v6 table
                        _ => 100000,
                    },
                    prefixes_advertised: 5,
                    updates_received: 1000,
                    withdraws_received: 50,
                    last_flap: None,
                    traffic,
                }
            })
            .collect()
    }

    fn simulated_traffic_for_origin(&self, origin: PeerOrigin) -> TrafficCounters {
        if let Some(ref state) = self.sim_state {
            state.get_counters(origin)
        } else {
            // fallback to basic simulation
            let base_bps = match self.router_id {
                RouterId::Bkk00 => 800_000_000,
                RouterId::Bkk20 => 600_000_000,
                RouterId::Bkk50 => 200_000_000,
            };

            TrafficCounters {
                rx_bytes: base_bps / 8 * 60,
                tx_bytes: base_bps / 8 * 60 / 2,
                rx_bps: base_bps,
                tx_bps: base_bps / 2,
                interval: Duration::from_secs(60),
            }
        }
    }

    fn simulated_traffic(&self) -> TrafficCounters {
        // aggregate traffic - not origin-specific
        let base_bps = match self.router_id {
            RouterId::Bkk00 => 800_000_000,
            RouterId::Bkk20 => 600_000_000,
            RouterId::Bkk50 => 200_000_000,
        };

        TrafficCounters {
            rx_bytes: base_bps / 8 * 60,
            tx_bytes: base_bps / 8 * 60 / 2,
            rx_bps: base_bps,
            tx_bps: base_bps / 2,
            interval: Duration::from_secs(60),
        }
    }
}

/// parse routeros duration format (e.g., "1w2d3h4m5s")
fn parse_routeros_duration(s: &str) -> Duration {
    let mut secs = 0u64;
    let mut num = String::new();

    for c in s.chars() {
        if c.is_ascii_digit() {
            num.push(c);
        } else {
            let n: u64 = num.parse().unwrap_or(0);
            num.clear();
            match c {
                'w' => secs += n * 604800,
                'd' => secs += n * 86400,
                'h' => secs += n * 3600,
                'm' => secs += n * 60,
                's' => secs += n,
                _ => {}
            }
        }
    }

    Duration::from_secs(secs)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_duration() {
        assert_eq!(parse_routeros_duration("1h30m"), Duration::from_secs(5400));
        assert_eq!(parse_routeros_duration("1d"), Duration::from_secs(86400));
        assert_eq!(
            parse_routeros_duration("1w2d3h"),
            Duration::from_secs(604800 + 2 * 86400 + 3 * 3600)
        );
    }
}
