use crate::error::{Error, Result};
use crate::types::RouterId;
use secrecy::SecretString;
use serde::Deserialize;
use std::collections::HashMap;
use std::net::IpAddr;
use std::path::Path;
use std::time::Duration;

#[derive(Debug, Deserialize)]
pub struct Config {
    pub daemon: DaemonConfig,
    pub routers: HashMap<String, RouterConfig>,
    pub peers: HashMap<String, PeerConfig>,
    pub probes: ProbeConfig,
    pub scoring: ScoringConfig,
    pub hysteresis: HysteresisConfig,
    pub capacity: CapacityConfig,
    pub metrics: MetricsConfig,
}

#[derive(Debug, Deserialize)]
pub struct DaemonConfig {
    /// how often to run the decision loop
    #[serde(with = "humantime_serde")]
    pub decision_interval: Duration,
    /// how often to collect metrics from routers
    #[serde(with = "humantime_serde")]
    pub collect_interval: Duration,
    /// log level
    pub log_level: String,
    /// run in dry-run mode (no changes applied)
    #[serde(default)]
    pub dry_run: bool,
}

#[derive(Debug, Deserialize)]
pub struct RouterConfig {
    pub address: IpAddr,
    #[serde(default = "default_api_port")]
    pub port: u16,
    pub username: String,
    /// password loaded from environment
    #[serde(skip)]
    pub password: Option<SecretString>,
    /// environment variable containing password
    pub password_env: String,
    #[serde(default = "default_true")]
    pub tls: bool,
    /// source ip to use for probes through this router
    pub probe_source_ip: Option<IpAddr>,
}

/// per-peer configuration for capacity and preferences
#[derive(Debug, Clone, Deserialize)]
pub struct PeerConfig {
    /// which router this peer is on
    pub router: String,
    /// nominal capacity in mbps
    pub capacity_mbps: u64,
    /// filter chain name in mikrotik (for import policy)
    pub import_chain: String,
    /// filter chain name for export policy
    pub export_chain: String,
    /// interface name for traffic counters
    pub interface: Option<String>,
    /// minimum acceptable local_pref (don't go below this)
    #[serde(default = "default_min_pref")]
    pub min_local_pref: u16,
    /// whether this is a transit provider (vs peering)
    #[serde(default)]
    pub is_transit: bool,
    /// cost factor (higher = more expensive, deprioritize)
    #[serde(default = "default_cost")]
    pub cost_factor: f64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProbeConfig {
    /// targets to probe through each upstream
    pub targets: Vec<IpAddr>,
    /// probes per target per interval
    pub count: u32,
    /// timeout per probe
    #[serde(with = "humantime_serde")]
    pub timeout: Duration,
    /// interval between probe batches
    #[serde(with = "humantime_serde")]
    pub interval: Duration,
}

#[derive(Debug, Deserialize)]
pub struct ScoringConfig {
    pub weights: ScoringWeightsConfig,
    pub baselines: BaselinesConfig,
}

#[derive(Debug, Deserialize, Clone, Copy)]
pub struct ScoringWeightsConfig {
    /// weight for latency score
    pub latency: f64,
    /// weight for packet loss score
    pub loss: f64,
    /// weight for jitter score
    pub jitter: f64,
    /// weight for session stability score
    pub stability: f64,
    /// weight for capacity/utilization score (key for load balancing)
    pub capacity: f64,
    /// weight for cost factor
    pub cost: f64,
}

impl Default for ScoringWeightsConfig {
    fn default() -> Self {
        Self {
            latency: 0.15,
            loss: 0.20,
            jitter: 0.10,
            stability: 0.10,
            capacity: 0.35, // heavily weight available capacity
            cost: 0.10,
        }
    }
}

#[derive(Debug, Deserialize, Clone, Copy)]
pub struct BaselinesConfig {
    /// rtt above this is scored 0
    #[serde(with = "humantime_serde")]
    pub max_acceptable_rtt: Duration,
    /// loss above this is scored 0
    pub max_acceptable_loss: f64,
    /// jitter above this is scored 0
    #[serde(with = "humantime_serde")]
    pub max_acceptable_jitter: Duration,
    /// session uptime for full stability score
    #[serde(with = "humantime_serde")]
    pub stable_uptime: Duration,
    /// utilization above this triggers load shedding
    pub congestion_threshold: f64,
    /// utilization above this is critical
    pub critical_threshold: f64,
}

impl Default for BaselinesConfig {
    fn default() -> Self {
        Self {
            max_acceptable_rtt: Duration::from_millis(200),
            max_acceptable_loss: 0.02,
            max_acceptable_jitter: Duration::from_millis(20),
            stable_uptime: Duration::from_secs(86400),
            congestion_threshold: 0.75,
            critical_threshold: 0.90,
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct HysteresisConfig {
    /// minimum score difference to trigger change
    pub min_delta: f64,
    /// hold time between changes for same peer
    #[serde(with = "humantime_serde")]
    pub hold_time: Duration,
    /// minimum time a peer must be stable before being preferred
    #[serde(with = "humantime_serde")]
    pub stability_window: Duration,
}

#[derive(Debug, Deserialize)]
pub struct CapacityConfig {
    /// target overall utilization across all peers
    pub target_utilization: f64,
    /// enable ecmp-style load balancing across multiple peers
    #[serde(default = "default_true")]
    pub enable_load_balancing: bool,
    /// maximum number of paths to use for ecmp
    #[serde(default = "default_max_paths")]
    pub max_ecmp_paths: u32,
    /// rebalance threshold - trigger rebalance if deviation > this
    pub rebalance_threshold: f64,
}

#[derive(Debug, Deserialize)]
pub struct MetricsConfig {
    pub listen: String,
    pub path: String,
}

fn default_api_port() -> u16 {
    443
}

fn default_true() -> bool {
    true
}

fn default_min_pref() -> u16 {
    50
}

fn default_cost() -> f64 {
    1.0
}

fn default_max_paths() -> u32 {
    4
}

impl Config {
    pub fn load(path: &Path) -> Result<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| Error::ConfigError(format!("failed to read config: {}", e)))?;

        let mut config: Config = toml::from_str(&content)?;

        // load passwords from environment
        for (name, router) in config.routers.iter_mut() {
            match std::env::var(&router.password_env) {
                Ok(password) => {
                    router.password = Some(SecretString::from(password));
                }
                Err(e) => {
                    return Err(Error::ConfigError(format!(
                        "failed to load password for router {} from {}: {}",
                        name, router.password_env, e
                    )));
                }
            }
        }

        config.validate()?;
        Ok(config)
    }

    /// load config with optional password (for dry-run/testing without real creds)
    pub fn load_dry_run(path: &Path) -> Result<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| Error::ConfigError(format!("failed to read config: {}", e)))?;

        let mut config: Config = toml::from_str(&content)?;

        // try to load passwords, but don't fail if missing
        for (_, router) in config.routers.iter_mut() {
            if let Ok(password) = std::env::var(&router.password_env) {
                router.password = Some(SecretString::from(password));
            }
        }

        config.validate()?;
        Ok(config)
    }

    fn validate(&self) -> Result<()> {
        // validate weights sum to ~1.0
        let weights = &self.scoring.weights;
        let sum = weights.latency
            + weights.loss
            + weights.jitter
            + weights.stability
            + weights.capacity
            + weights.cost;

        if (sum - 1.0).abs() > 0.01 {
            return Err(Error::ConfigError(format!(
                "scoring weights must sum to 1.0, got {}",
                sum
            )));
        }

        // validate thresholds
        if self.scoring.baselines.congestion_threshold >= self.scoring.baselines.critical_threshold
        {
            return Err(Error::ConfigError(
                "congestion_threshold must be less than critical_threshold".into(),
            ));
        }

        // validate peer configs reference valid routers
        for (name, peer) in &self.peers {
            if !self.routers.contains_key(&peer.router) {
                return Err(Error::ConfigError(format!(
                    "peer {} references unknown router {}",
                    name, peer.router
                )));
            }
        }

        Ok(())
    }

    pub fn router_id(&self, name: &str) -> Option<RouterId> {
        name.parse().ok()
    }
}
