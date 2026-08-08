use serde::{Deserialize, Serialize};
use std::fmt;
use std::net::IpAddr;
use std::str::FromStr;

/// identifies a router in our network
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum RouterId {
    Bkk00,
    Bkk20,
    Bkk50,
}

impl fmt::Display for RouterId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RouterId::Bkk00 => write!(f, "bkk00"),
            RouterId::Bkk20 => write!(f, "bkk20"),
            RouterId::Bkk50 => write!(f, "bkk50"),
        }
    }
}

impl FromStr for RouterId {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "bkk00" => Ok(RouterId::Bkk00),
            "bkk20" => Ok(RouterId::Bkk20),
            "bkk50" => Ok(RouterId::Bkk50),
            _ => Err(format!("unknown router: {}", s)),
        }
    }
}

/// identifies an upstream peer uniquely
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct PeerId {
    pub router: RouterId,
    pub remote_as: u32,
    pub remote_addr: IpAddr,
}

impl fmt::Display for PeerId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}:AS{}:{}", self.router, self.remote_as, self.remote_addr)
    }
}

/// origin community assigned on import - identifies which peer a route came from
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[repr(u16)]
pub enum PeerOrigin {
    /// bknix route servers ipv4 (as63529)
    Bknix = 1001,
    /// hgc hong kong primary (as9304)
    HgcHk = 1002,
    /// hgc singapore primary (as9304)
    HgcSg = 1003,
    /// ams-ix eu route servers (as6777)
    AmsixEu = 1004,
    /// ams-ix bangkok route servers (as150388)
    AmsixBkk = 1005,
    /// ams-ix hong kong route servers (as58560)
    AmsixHk = 1006,
    /// hurricane electric ipv6 transit at bknix (as6939) - IMPORTANT: v6 only!
    HeV6 = 1007,
    /// cloudflare (as13335)
    Cloudflare = 1008,
    /// iptx/hgc backup links (as142435)
    IptxBackup = 1009,
    /// bknix route servers ipv6 (as63529)
    BknixV6 = 1010,
}

impl PeerOrigin {
    /// our asn and the origin tag
    pub fn community(&self) -> (u32, u16) {
        (142108, *self as u16)
    }

    /// all known origins for iteration
    pub fn all() -> &'static [PeerOrigin] {
        &[
            PeerOrigin::Bknix,
            PeerOrigin::BknixV6,
            PeerOrigin::HgcHk,
            PeerOrigin::HgcSg,
            PeerOrigin::AmsixEu,
            PeerOrigin::AmsixBkk,
            PeerOrigin::AmsixHk,
            PeerOrigin::HeV6,
            PeerOrigin::Cloudflare,
            PeerOrigin::IptxBackup,
        ]
    }

    /// ipv4 origins only
    pub fn all_v4() -> &'static [PeerOrigin] {
        &[
            PeerOrigin::Bknix,
            PeerOrigin::HgcHk,
            PeerOrigin::HgcSg,
            PeerOrigin::AmsixEu,
            PeerOrigin::AmsixBkk,
            PeerOrigin::AmsixHk,
            PeerOrigin::Cloudflare,
            PeerOrigin::IptxBackup,
        ]
    }

    /// ipv6 origins only
    pub fn all_v6() -> &'static [PeerOrigin] {
        &[
            PeerOrigin::BknixV6,
            PeerOrigin::HeV6,
        ]
    }

    /// is this an ipv6 peer?
    pub fn is_v6(&self) -> bool {
        matches!(self, PeerOrigin::BknixV6 | PeerOrigin::HeV6)
    }

    /// peer name for display and metrics
    pub fn name(&self) -> &'static str {
        match self {
            PeerOrigin::Bknix => "bknix",
            PeerOrigin::BknixV6 => "bknix_v6",
            PeerOrigin::HgcHk => "hgc_hk",
            PeerOrigin::HgcSg => "hgc_sg",
            PeerOrigin::AmsixEu => "amsix_eu",
            PeerOrigin::AmsixBkk => "amsix_bkk",
            PeerOrigin::AmsixHk => "amsix_hk",
            PeerOrigin::HeV6 => "he_v6",
            PeerOrigin::Cloudflare => "cloudflare",
            PeerOrigin::IptxBackup => "iptx_backup",
        }
    }
}

impl fmt::Display for PeerOrigin {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.name())
    }
}

/// mapping of session name patterns to peer origins
/// used to identify which origin a bgp session belongs to
pub fn session_to_origin(session_name: &str) -> Option<PeerOrigin> {
    let name = session_name.to_uppercase();
    let is_v6 = name.contains("V6") || name.contains("-6");

    // hurricane electric - ipv6 transit only at bknix
    if name.contains("HE-") || name.contains("HE_") || (name.contains("HURRICANE") || name.contains("AS6939")) {
        return Some(PeerOrigin::HeV6);
    }

    // bknix - separate v4 and v6
    if name.contains("BKNIX") && !name.contains("AMSIX") {
        return Some(if is_v6 { PeerOrigin::BknixV6 } else { PeerOrigin::Bknix });
    }

    if name.contains("HGC") && name.contains("HK") && !name.contains("BACKUP") {
        Some(PeerOrigin::HgcHk)
    } else if name.contains("HGC") && name.contains("SG") && !name.contains("BACKUP") {
        Some(PeerOrigin::HgcSg)
    } else if name.contains("AMSIX") && (name.contains("EU") || name.contains("RS1-V") || name.contains("RS2-V")) && !name.contains("BAN") && !name.contains("HK") && !name.contains("TH") {
        Some(PeerOrigin::AmsixEu)
    } else if name.contains("AMSIX") && (name.contains("BAN") || name.contains("TH")) {
        Some(PeerOrigin::AmsixBkk)
    } else if name.contains("AMSIX") && name.contains("HK") {
        Some(PeerOrigin::AmsixHk)
    } else if name.contains("CLOUDFLARE") {
        Some(PeerOrigin::Cloudflare)
    } else if name.contains("BACKUP") || name.contains("IPTX") {
        Some(PeerOrigin::IptxBackup)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_session_to_origin() {
        // bknix v4 and v6
        assert_eq!(session_to_origin("BKNIX-RS0-v4"), Some(PeerOrigin::Bknix));
        assert_eq!(session_to_origin("BKNIX-RS0-v6"), Some(PeerOrigin::BknixV6));

        // hgc
        assert_eq!(session_to_origin("HGC-HK-PRIMARY-v4"), Some(PeerOrigin::HgcHk));
        assert_eq!(session_to_origin("HGC-SG-PRIMARY-v4"), Some(PeerOrigin::HgcSg));

        // ams-ix
        assert_eq!(session_to_origin("AMSIX-RS1-v4"), Some(PeerOrigin::AmsixEu));
        assert_eq!(session_to_origin("AMSIX-RS1-TH-v4"), Some(PeerOrigin::AmsixBkk));
        assert_eq!(session_to_origin("AMSIX-RS1-HK-v4"), Some(PeerOrigin::AmsixHk));

        // hurricane electric - always v6 transit
        assert_eq!(session_to_origin("HE-BKNIX-v6"), Some(PeerOrigin::HeV6));
        assert_eq!(session_to_origin("HE-BKNIX-v4"), Some(PeerOrigin::HeV6)); // even if says v4, HE is v6 only

        // cloudflare
        assert_eq!(session_to_origin("Cloudflare-AMSIX-v4-1"), Some(PeerOrigin::Cloudflare));

        // backup
        assert_eq!(session_to_origin("HGC-HK-BACKUP-v6"), Some(PeerOrigin::IptxBackup));
    }
}
