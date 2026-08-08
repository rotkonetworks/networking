use crate::error::{Error, Result};
use socket2::{Domain, Protocol, Socket, Type};
use std::mem::MaybeUninit;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr, SocketAddrV4, SocketAddrV6};
use std::time::{Duration, Instant};

const ICMP_ECHO_REQUEST: u8 = 8;
const ICMP_ECHO_REPLY: u8 = 0;
const ICMPV6_ECHO_REQUEST: u8 = 128;
const ICMPV6_ECHO_REPLY: u8 = 129;

/// raw icmp prober for measuring path latency
pub struct IcmpProber {
    socket_v4: Option<Socket>,
    socket_v6: Option<Socket>,
    identifier: u16,
    sequence: u16,
}

#[derive(Debug, Clone)]
pub struct ProbeResult {
    pub target: IpAddr,
    pub source: Option<IpAddr>,
    pub rtt: Option<Duration>,
    pub sequence: u16,
    pub error: Option<String>,
}

impl IcmpProber {
    pub fn new() -> Result<Self> {
        // try to create sockets, but don't fail if we lack permissions
        // (allows dry-run mode without cap_net_raw)
        let socket_v4 = Socket::new(Domain::IPV4, Type::RAW, Some(Protocol::ICMPV4)).ok();
        let socket_v6 = Socket::new(Domain::IPV6, Type::RAW, Some(Protocol::ICMPV6)).ok();

        if let Some(ref s) = socket_v4 {
            let _ = s.set_read_timeout(Some(Duration::from_secs(2)));
        }
        if let Some(ref s) = socket_v6 {
            let _ = s.set_read_timeout(Some(Duration::from_secs(2)));
        }

        let identifier = (std::process::id() & 0xFFFF) as u16;

        Ok(Self {
            socket_v4,
            socket_v6,
            identifier,
            sequence: 0,
        })
    }

    /// check if prober has necessary permissions
    pub fn is_available(&self) -> bool {
        self.socket_v4.is_some() || self.socket_v6.is_some()
    }

    /// probe a target, optionally binding to source ip for policy routing
    pub fn probe(
        &mut self,
        target: IpAddr,
        source: Option<IpAddr>,
        timeout: Duration,
    ) -> ProbeResult {
        self.sequence = self.sequence.wrapping_add(1);

        let result = match target {
            IpAddr::V4(addr) => self.probe_v4(addr, source.and_then(|s| match s {
                IpAddr::V4(v4) => Some(v4),
                _ => None,
            }), timeout),
            IpAddr::V6(addr) => self.probe_v6(addr, source.and_then(|s| match s {
                IpAddr::V6(v6) => Some(v6),
                _ => None,
            }), timeout),
        };

        match result {
            Ok(rtt) => ProbeResult {
                target,
                source,
                rtt: Some(rtt),
                sequence: self.sequence,
                error: None,
            },
            Err(e) => ProbeResult {
                target,
                source,
                rtt: None,
                sequence: self.sequence,
                error: Some(e.to_string()),
            },
        }
    }

    fn probe_v4(
        &self,
        target: Ipv4Addr,
        source: Option<Ipv4Addr>,
        timeout: Duration,
    ) -> Result<Duration> {
        let socket = self
            .socket_v4
            .as_ref()
            .ok_or_else(|| Error::SocketError("no ipv4 socket available".into()))?;

        // bind to source if specified (for source-based routing)
        if let Some(src) = source {
            let src_addr = SocketAddrV4::new(src, 0);
            socket.bind(&src_addr.into()).map_err(|e| {
                Error::SocketError(format!("failed to bind to {}: {}", src, e))
            })?;
        }

        let packet = self.build_icmp_packet(ICMP_ECHO_REQUEST);
        let dest = SocketAddr::V4(SocketAddrV4::new(target, 0));

        socket.set_read_timeout(Some(timeout))?;

        let start = Instant::now();
        socket.send_to(&packet, &dest.into())?;

        let mut buf = [MaybeUninit::uninit(); 1024];
        loop {
            let (len, _) = socket.recv_from(&mut buf)?;
            let buf = unsafe { std::slice::from_raw_parts(buf.as_ptr() as *const u8, len) };

            // skip ip header (20 bytes typically, but can vary with options)
            let ip_header_len = ((buf[0] & 0x0F) as usize) * 4;
            if len < ip_header_len + 8 {
                continue;
            }

            let icmp = &buf[ip_header_len..];
            if icmp[0] == ICMP_ECHO_REPLY
                && u16::from_be_bytes([icmp[4], icmp[5]]) == self.identifier
                && u16::from_be_bytes([icmp[6], icmp[7]]) == self.sequence
            {
                return Ok(start.elapsed());
            }

            // check if we've exceeded timeout
            if start.elapsed() > timeout {
                return Err(Error::ProbeTimeout { target: target.into() });
            }
        }
    }

    fn probe_v6(
        &self,
        target: Ipv6Addr,
        source: Option<Ipv6Addr>,
        timeout: Duration,
    ) -> Result<Duration> {
        let socket = self
            .socket_v6
            .as_ref()
            .ok_or_else(|| Error::SocketError("no ipv6 socket available".into()))?;

        if let Some(src) = source {
            let src_addr = SocketAddrV6::new(src, 0, 0, 0);
            socket.bind(&src_addr.into()).map_err(|e| {
                Error::SocketError(format!("failed to bind to {}: {}", src, e))
            })?;
        }

        let packet = self.build_icmpv6_packet();
        let dest = SocketAddr::V6(SocketAddrV6::new(target, 0, 0, 0));

        socket.set_read_timeout(Some(timeout))?;

        let start = Instant::now();
        socket.send_to(&packet, &dest.into())?;

        let mut buf = [MaybeUninit::uninit(); 1024];
        loop {
            let (len, _) = socket.recv_from(&mut buf)?;
            let buf = unsafe { std::slice::from_raw_parts(buf.as_ptr() as *const u8, len) };

            if len < 8 {
                continue;
            }

            // icmpv6 has no ip header in raw socket
            if buf[0] == ICMPV6_ECHO_REPLY
                && u16::from_be_bytes([buf[4], buf[5]]) == self.identifier
                && u16::from_be_bytes([buf[6], buf[7]]) == self.sequence
            {
                return Ok(start.elapsed());
            }

            if start.elapsed() > timeout {
                return Err(Error::ProbeTimeout { target: target.into() });
            }
        }
    }

    fn build_icmp_packet(&self, icmp_type: u8) -> Vec<u8> {
        let mut packet = vec![0u8; 64]; // include some payload for better timing
        packet[0] = icmp_type;
        packet[1] = 0; // code
        // checksum at [2..4]
        packet[4..6].copy_from_slice(&self.identifier.to_be_bytes());
        packet[6..8].copy_from_slice(&self.sequence.to_be_bytes());

        // add timestamp in payload
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64;
        packet[8..16].copy_from_slice(&now.to_be_bytes());

        let checksum = self.compute_checksum(&packet);
        packet[2..4].copy_from_slice(&checksum.to_be_bytes());

        packet
    }

    fn build_icmpv6_packet(&self) -> Vec<u8> {
        let mut packet = vec![0u8; 64];
        packet[0] = ICMPV6_ECHO_REQUEST;
        packet[1] = 0;
        // checksum handled by kernel for icmpv6
        packet[4..6].copy_from_slice(&self.identifier.to_be_bytes());
        packet[6..8].copy_from_slice(&self.sequence.to_be_bytes());

        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64;
        packet[8..16].copy_from_slice(&now.to_be_bytes());

        packet
    }

    fn compute_checksum(&self, data: &[u8]) -> u16 {
        let mut sum = 0u32;
        let mut i = 0;

        while i < data.len() {
            let word = if i + 1 < data.len() {
                u16::from_be_bytes([data[i], data[i + 1]])
            } else {
                u16::from_be_bytes([data[i], 0])
            };
            sum = sum.wrapping_add(word as u32);
            i += 2;
        }

        while sum >> 16 != 0 {
            sum = (sum & 0xFFFF) + (sum >> 16);
        }

        !(sum as u16)
    }
}

/// simulated prober for dry-run mode
pub struct SimulatedProber {
    sequence: u16,
}

impl SimulatedProber {
    pub fn new() -> Self {
        Self { sequence: 0 }
    }

    pub fn probe(&mut self, target: IpAddr, source: Option<IpAddr>) -> ProbeResult {
        self.sequence = self.sequence.wrapping_add(1);

        // simulate realistic latencies based on target
        let rtt = match target {
            IpAddr::V4(addr) => {
                let octets = addr.octets();
                // google dns ~10-30ms, cloudflare ~5-20ms, others ~20-100ms
                let base_ms = if octets[0] == 8 && octets[1] == 8 {
                    15.0
                } else if octets[0] == 1 && octets[1] == 1 {
                    10.0
                } else {
                    50.0
                };
                // add some jitter
                let jitter = (self.sequence % 10) as f64 * 2.0;
                Duration::from_secs_f64((base_ms + jitter) / 1000.0)
            }
            IpAddr::V6(_) => {
                Duration::from_millis(20 + (self.sequence % 15) as u64)
            }
        };

        // simulate occasional packet loss (5%)
        let lost = self.sequence % 20 == 0;

        ProbeResult {
            target,
            source,
            rtt: if lost { None } else { Some(rtt) },
            sequence: self.sequence,
            error: if lost {
                Some("simulated packet loss".into())
            } else {
                None
            },
        }
    }
}
