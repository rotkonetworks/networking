# IPv6 Addressing Scheme Documentation

## Overview

This document describes the IPv6 addressing scheme for the ROTKO network infrastructure. The design follows ISP best practices with stateless core routers and edge routers providing customer services.

## Network Architecture

### Router Functions
- **BKK00, BKK20**: Core transit routers (stateless, BGP, upstream connectivity)
- **BKK10, BKK50**: Edge routers (customer services, NAT, DHCP, firewalls)

### Physical Topology
```
BKK00 ──────── BKK20  (Core transit link - needs global)
  │              │  
  │              │    (Edge access links - ULA only)
BKK10 ──────── BKK50
```

## Design Principles

1. **Core Efficiency**: Global addresses only where required for BGP/transit
2. **ULA for Internal**: All internal links use ULA for OSPF adjacencies  
3. **Stateless Core**: Core routers forward packets, edge routers provide services
4. **Scalable Pattern**: Consistent XXYY numbering scheme

## Address Allocation

### ULA Address Space: `fd00:dead:beef::/48`

#### Loopback Addresses: `fd00:dead:beef::/64`
- **bkk00**: `fd00:dead:beef::0/128`
- **bkk10**: `fd00:dead:beef::10/128`
- **bkk20**: `fd00:dead:beef::20/128`
- **bkk50**: `fd00:dead:beef::50/128`

#### P2P Links: `fd00:dead:beef:XXYY::/127`
All inter-router links use ULA for OSPF adjacencies:

- **BKK00 ↔ BKK10**: `fd00:dead:beef:0010::/127`
  - BKK00: `fd00:dead:beef:0010::0/127`
  - BKK10: `fd00:dead:beef:0010::1/127`

- **BKK00 ↔ BKK20**: `fd00:dead:beef:0020::/127`
  - BKK00: `fd00:dead:beef:0020::0/127`
  - BKK20: `fd00:dead:beef:0020::1/127`

- **BKK10 ↔ BKK50**: `fd00:dead:beef:1050::/127`
  - BKK10: `fd00:dead:beef:1050::0/127`
  - BKK50: `fd00:dead:beef:1050::1/127`

- **BKK20 ↔ BKK50**: `fd00:dead:beef:2050::/127`
  - BKK20: `fd00:dead:beef:2050::0/127`
  - BKK50: `fd00:dead:beef:2050::1/127`

### Global Address Space: `2401:a860:1181::/48`

#### Loopback Addresses (Management/BGP Router-ID)
- **bkk00**: `2401:a860:1181::0/128`
- **bkk10**: `2401:a860:1181::10/128`
- **bkk20**: `2401:a860:1181::20/128`
- **bkk50**: `2401:a860:1181::50/128`

#### Core Transit Link (BGP/External Routing)
**BKK00 ↔ BKK20**: `2401:a860:1181:0020::/127`
- BKK00: `2401:a860:1181:0020::0/127`
- BKK20: `2401:a860:1181:0020::1/127`

*Note: Edge access links (BKK00↔BKK10, BKK10↔BKK50, BKK20↔BKK50) use ULA only*

### Customer/Service Networks
- **BKK10**: `2401:a860:181::/48` (customer allocations)
- **BKK50**: `2401:a860:169::/48` (SAX network)

## Routing Design

### OSPF (Internal Routing)
- **Area backbone**: IPv4 networks
- **Area backbone-v6**: IPv6 ULA networks
- All inter-router links participate in OSPF via ULA addresses
- Loopback addresses advertised as passive

### Default Routing (Edge Routers)
Edge routers (BKK10, BKK50) use default routes to core router loopbacks:
```bash
# On BKK10
/ipv6 route add dst-address=::/0 gateway=2401:a860:1181::0
/ipv6 route add dst-address=::/0 gateway=2401:a860:1181::20

# On BKK50  
/ipv6 route add dst-address=::/0 gateway=2401:a860:1181::0
/ipv6 route add dst-address=::/0 gateway=2401:a860:1181::20
```

### BGP (External Routing)
- Core routers (BKK00, BKK20) run eBGP with upstream providers
- Use global loopback addresses as BGP router-IDs
- Advertise customer prefixes received from edge routers via OSPF

## Implementation Benefits

1. **Efficient Core**: Minimal global addressing on transit infrastructure
2. **Scalable**: Easy to add new edge routers without global address changes
3. **Troubleshooting**: ULA patterns match physical topology
4. **Standards Compliance**: Follows RFC 6164 (/127 P2P links)
5. **ISP Best Practice**: Stateless core, stateful edge design

## OSPF Configuration Example

### Core Router (BKK00)
```bash
# ULA Loopback
/routing ospf interface-template add area=backbone-v6 networks=fd00:dead:beef::0/128 passive

# ULA P2P Links  
/routing ospf interface-template add area=backbone-v6 networks=fd00:dead:beef:0010::0/127
/routing ospf interface-template add area=backbone-v6 networks=fd00:dead:beef:0020::0/127

# Global Loopback (passive)
/routing ospf interface-template add area=backbone-v6 networks=2401:a860:1181::0/128 passive
```

### Edge Router (BKK50)
```bash
# ULA Loopback
/routing ospf interface-template add area=backbone-v6 networks=fd00:dead:beef::50/128 passive

# ULA P2P Links
/routing ospf interface-template add area=backbone-v6 networks=fd00:dead:beef:1050::1/127  
/routing ospf interface-template add area=backbone-v6 networks=fd00:dead:beef:2050::1/127

# Customer Networks (passive)
/routing ospf interface-template add area=backbone-v6 networks=2401:a860:169::/48 passive
```

## Verification Commands

### Connectivity Testing
```bash
# Test ULA P2P connectivity
/ping fd00:dead:beef:0010::1 src-address=fd00:dead:beef:0010::0  # BKK00→BKK10
/ping fd00:dead:beef:0020::1 src-address=fd00:dead:beef:0020::0  # BKK00→BKK20
/ping fd00:dead:beef:1050::1 src-address=fd00:dead:beef:1050::0  # BKK10→BKK50
/ping fd00:dead:beef:2050::1 src-address=fd00:dead:beef:2050::0  # BKK20→BKK50

# Test global loopback reachability
/ping 2401:a860:1181::0   # To BKK00
/ping 2401:a860:1181::20  # To BKK20

# Test external connectivity from edge routers
/ping 2620:fe::fe         # From BKK10/BKK50
```

### OSPF Status
```bash
# Check all OSPFv3 neighbors are Full
/routing ospf neighbor print where instance=ospf-instance-v3

# Verify route propagation
/ipv6 route print where ospf and dst-address~"::/0"
```

## Troubleshooting

### Common Issues
1. **TwoWay OSPF state**: Check ULA address conflicts
2. **No IPv6 connectivity from edge**: Verify default routes to core loopbacks
3. **External routing issues**: Check BGP on core routers

### Debug Commands
```bash
# Check for duplicate addresses
/ipv6 address print where invalid

# OSPF debugging
/routing ospf interface print
/routing ospf lsa print

# Route table analysis
/ipv6 route print detail
```

## Adding New Routers

### New Edge Router (e.g., BKK30)
1. **ULA Loopback**: `fd00:dead:beef::30/128`
2. **Global Loopback**: `2401:a860:1181::30/128`  
3. **ULA P2P links**: Follow XXYY pattern to existing routers
4. **Default routes**: Point to core router loopbacks
5. **Customer networks**: Assign new global prefix

### New Core Router (e.g., BKK40)
1. Add global P2P link to existing core routers
2. Configure BGP peering
3. Add ULA links to edge routers as needed

