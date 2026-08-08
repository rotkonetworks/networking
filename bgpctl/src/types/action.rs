use super::peer::{PeerId, PeerOrigin, RouterId};
use std::fmt;

/// action to apply to edge router
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Action {
    /// set local_pref via action community
    SetPreference { router: RouterId, origin: PeerOrigin, local_pref: u16 },

    /// prepend on export to reduce inbound via this peer
    SetPrepend { router: RouterId, origin: PeerOrigin, prepend_count: u8 },

    /// adjust weight for ecmp load balancing
    SetWeight { router: RouterId, origin: PeerOrigin, weight: u16 },

    /// temporarily stop announcing to this peer (drain traffic)
    WithdrawAnnouncement { router: RouterId, origin: PeerOrigin },

    /// re-enable announcement to peer
    RestoreAnnouncement { router: RouterId, origin: PeerOrigin },

    /// no change needed
    Noop,
}

impl fmt::Display for Action {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Action::SetPreference { router, origin, local_pref } => {
                write!(f, "set-pref {}:{} -> {}", router, origin, local_pref)
            }
            Action::SetPrepend { router, origin, prepend_count } => {
                write!(f, "set-prepend {}:{} -> {}x", router, origin, prepend_count)
            }
            Action::SetWeight { router, origin, weight } => {
                write!(f, "set-weight {}:{} -> {}", router, origin, weight)
            }
            Action::WithdrawAnnouncement { router, origin } => {
                write!(f, "withdraw {}:{}", router, origin)
            }
            Action::RestoreAnnouncement { router, origin } => {
                write!(f, "restore {}:{}", router, origin)
            }
            Action::Noop => write!(f, "noop"),
        }
    }
}

/// action communities - applied to trigger local_pref changes
/// format: 142108:9XXX where XXX encodes the action
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ActionCommunity {
    /// our asn
    pub asn: u32,
    /// action code
    pub code: u16,
}

impl ActionCommunity {
    pub const ASN: u32 = 142108;

    /// prefer this path (local_pref 150)
    pub const PREFER: Self = Self { asn: Self::ASN, code: 9150 };
    /// normal preference (local_pref 100)
    pub const NORMAL: Self = Self { asn: Self::ASN, code: 9100 };
    /// deprioritize (local_pref 80)
    pub const DEPREF_LOW: Self = Self { asn: Self::ASN, code: 9080 };
    /// heavily deprioritize (local_pref 50)
    pub const DEPREF: Self = Self { asn: Self::ASN, code: 9050 };
    /// do not use this path (local_pref 10)
    pub const AVOID: Self = Self { asn: Self::ASN, code: 9010 };
    /// blackhole - don't announce to this peer
    pub const BLACKHOLE: Self = Self { asn: Self::ASN, code: 9000 };

    pub fn to_tuple(&self) -> (u32, u16) {
        (self.asn, self.code)
    }

    pub fn to_string_community(&self) -> String {
        format!("{}:{}", self.asn, self.code)
    }

    /// decode local_pref from action community code
    pub fn local_pref_from_code(code: u16) -> Option<u16> {
        if code >= 9000 && code <= 9200 {
            Some(code - 9000)
        } else {
            None
        }
    }

    /// create action community for desired local_pref
    pub fn for_local_pref(local_pref: u16) -> Self {
        Self {
            asn: Self::ASN,
            code: 9000 + local_pref.min(200),
        }
    }
}

/// prepend communities - control as-path prepending on export
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PrependCommunity {
    pub asn: u32,
    pub code: u16,
}

impl PrependCommunity {
    pub const ASN: u32 = 142108;

    /// prepend 1x
    pub const PREPEND_1: Self = Self { asn: Self::ASN, code: 8001 };
    /// prepend 2x
    pub const PREPEND_2: Self = Self { asn: Self::ASN, code: 8002 };
    /// prepend 3x
    pub const PREPEND_3: Self = Self { asn: Self::ASN, code: 8003 };

    pub fn for_count(count: u8) -> Self {
        Self {
            asn: Self::ASN,
            code: 8000 + (count as u16).min(5),
        }
    }
}

/// represents a batch of actions to apply atomically
#[derive(Debug, Clone)]
pub struct ActionBatch {
    pub actions: Vec<Action>,
    pub dry_run: bool,
}

impl ActionBatch {
    pub fn new(dry_run: bool) -> Self {
        Self {
            actions: Vec::new(),
            dry_run,
        }
    }

    pub fn push(&mut self, action: Action) {
        if action != Action::Noop {
            self.actions.push(action);
        }
    }

    pub fn is_empty(&self) -> bool {
        self.actions.is_empty()
    }

    pub fn len(&self) -> usize {
        self.actions.len()
    }
}
