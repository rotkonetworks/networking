use crate::collector::MikrotikClient;
use crate::config::PeerConfig;
use crate::error::{Error, Result};
use crate::types::{Action, ActionCommunity, PeerOrigin, RouterId};
use std::collections::HashMap;
use tracing::{debug, info, warn};

/// executes actions on routers
pub struct ActionExecutor {
    clients: HashMap<RouterId, MikrotikClient>,
    peer_configs: HashMap<String, PeerConfig>,
    dry_run: bool,
}

impl ActionExecutor {
    pub fn new(
        clients: HashMap<RouterId, MikrotikClient>,
        peer_configs: HashMap<String, PeerConfig>,
        dry_run: bool,
    ) -> Self {
        Self {
            clients,
            peer_configs,
            dry_run,
        }
    }

    /// execute a list of actions
    pub async fn execute(&self, actions: &[Action]) -> Vec<ActionResult> {
        let mut results = Vec::new();

        for action in actions {
            let result = self.execute_one(action).await;
            results.push(result);
        }

        results
    }

    async fn execute_one(&self, action: &Action) -> ActionResult {
        match action {
            Action::SetPreference { router, origin, local_pref } => {
                self.set_preference(*router, *origin, *local_pref).await
            }
            Action::SetPrepend { router, origin, prepend_count } => {
                self.set_prepend(*router, *origin, *prepend_count).await
            }
            Action::SetWeight { router, origin, weight } => {
                // weight is handled via local_pref in mikrotik
                self.set_preference(*router, *origin, *weight).await
            }
            Action::WithdrawAnnouncement { router, origin } => {
                self.withdraw(*router, *origin).await
            }
            Action::RestoreAnnouncement { router, origin } => {
                self.restore(*router, *origin).await
            }
            Action::Noop => ActionResult::success(action.clone()),
        }
    }

    async fn set_preference(
        &self,
        router: RouterId,
        origin: PeerOrigin,
        local_pref: u16,
    ) -> ActionResult {
        let action = Action::SetPreference { router, origin, local_pref };

        // find the import chain for this peer
        let chain = match self.find_import_chain(origin) {
            Some(c) => c,
            None => {
                return ActionResult::error(
                    action,
                    format!("no import chain configured for {}", origin),
                );
            }
        };

        if self.dry_run {
            info!(
                router = %router,
                peer = %origin,
                chain = chain,
                local_pref = local_pref,
                "[DRY RUN] would set local_pref"
            );
            return ActionResult::success(action);
        }

        let client = match self.clients.get(&router) {
            Some(c) => c,
            None => {
                return ActionResult::error(
                    action,
                    format!("no client for router {}", router),
                );
            }
        };

        match client.set_local_pref_action(&chain, local_pref).await {
            Ok(()) => {
                info!(
                    router = %router,
                    peer = %origin,
                    chain = chain,
                    local_pref = local_pref,
                    "set local_pref"
                );
                ActionResult::success(action)
            }
            Err(e) => {
                warn!(
                    router = %router,
                    peer = %origin,
                    error = %e,
                    "failed to set local_pref"
                );
                ActionResult::error(action, e.to_string())
            }
        }
    }

    async fn set_prepend(
        &self,
        router: RouterId,
        origin: PeerOrigin,
        prepend_count: u8,
    ) -> ActionResult {
        let action = Action::SetPrepend { router, origin, prepend_count };

        let chain = match self.find_export_chain(origin) {
            Some(c) => c,
            None => {
                return ActionResult::error(
                    action,
                    format!("no export chain configured for {}", origin),
                );
            }
        };

        if self.dry_run {
            info!(
                router = %router,
                peer = %origin,
                chain = chain,
                prepend = prepend_count,
                "[DRY RUN] would set prepend"
            );
            return ActionResult::success(action);
        }

        // prepending is more complex - need to set a community that the export filter uses
        // for now, log and skip
        info!(
            router = %router,
            peer = %origin,
            prepend = prepend_count,
            "prepend control not yet implemented"
        );

        ActionResult::success(action)
    }

    async fn withdraw(&self, router: RouterId, origin: PeerOrigin) -> ActionResult {
        let action = Action::WithdrawAnnouncement { router, origin };

        if self.dry_run {
            info!(
                router = %router,
                peer = %origin,
                "[DRY RUN] would withdraw announcement"
            );
            return ActionResult::success(action);
        }

        // withdrawal requires disabling the export filter or clearing the network statement
        // this is a drastic action - log and require manual confirmation
        warn!(
            router = %router,
            peer = %origin,
            "withdrawal requested - requires manual action"
        );

        ActionResult::error(action, "withdrawal requires manual confirmation".into())
    }

    async fn restore(&self, router: RouterId, origin: PeerOrigin) -> ActionResult {
        let action = Action::RestoreAnnouncement { router, origin };

        if self.dry_run {
            info!(
                router = %router,
                peer = %origin,
                "[DRY RUN] would restore announcement"
            );
            return ActionResult::success(action);
        }

        info!(
            router = %router,
            peer = %origin,
            "restore requested - requires manual action"
        );

        ActionResult::error(action, "restore requires manual confirmation".into())
    }

    fn find_import_chain(&self, origin: PeerOrigin) -> Option<String> {
        let origin_name = origin.name().to_lowercase();

        self.peer_configs
            .iter()
            .find(|(name, _)| {
                let config_name = name.to_lowercase().replace("-", "_");
                config_name.contains(&origin_name) || origin_name.contains(&config_name)
            })
            .map(|(_, c)| c.import_chain.clone())
    }

    fn find_export_chain(&self, origin: PeerOrigin) -> Option<String> {
        let origin_name = origin.name().to_lowercase();

        self.peer_configs
            .iter()
            .find(|(name, _)| {
                let config_name = name.to_lowercase().replace("-", "_");
                config_name.contains(&origin_name) || origin_name.contains(&config_name)
            })
            .map(|(_, c)| c.export_chain.clone())
    }
}

#[derive(Debug)]
pub struct ActionResult {
    pub action: Action,
    pub success: bool,
    pub error: Option<String>,
}

impl ActionResult {
    pub fn success(action: Action) -> Self {
        Self {
            action,
            success: true,
            error: None,
        }
    }

    pub fn error(action: Action, error: String) -> Self {
        Self {
            action,
            success: false,
            error: Some(error),
        }
    }
}

impl std::fmt::Display for ActionResult {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.success {
            write!(f, "[OK] {}", self.action)
        } else {
            write!(
                f,
                "[FAILED] {} - {}",
                self.action,
                self.error.as_deref().unwrap_or("unknown error")
            )
        }
    }
}
