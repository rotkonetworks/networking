# ECMP Fix for Anycast Routes - WIP

## Problem
- bkk06/07/08 all advertise anycast 160.22.180.180/32 via unified VLAN 400.100
- RouterOS 7 BGP selects only ONE best path (bkk06 wins via router-id tie-breaker)
- No ECMP load balancing across RPC endpoint hosts

## What we tried

### 1. Filter rule for bgp-weight (DONE on bkk00)
Added `set bgp-weight 1` BEFORE accept rule in RR-CLIENT-IN-v4:
```
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="set bgp-weight 1" place-before=125 comment="ECMP weight for anycast"
```

Current filter order:
- 124: reject blocked gateways
- 142: set bgp-weight 1 (ECMP) <-- NEW
- 125: accept our prefixes
- 126: reject everything else

Removed orphaned rule 131 that was after accept.

### 2. BIRD reload on bkk08
Tested `sudo birdc configure` on bkk08 - routes re-advertised but still no ECMP flag.

## Why it doesn't work
RouterOS 7 BGP doesn't have "multipath ibgp N" like Cisco/BIRD. The bgp-weight filter sets an attribute but doesn't enable multipath installation. BGP best-path algorithm still selects one winner.

## Potential solutions

### Option A: Static ECMP routes (quick fix)
```
/ip route add dst-address=160.22.180.180/32 gateway=10.155.100.6,10.155.100.7,10.155.100.8 comment="anycast ECMP"
```
- Overrides BGP with static ECMP
- Need to add for each anycast IP
- Manual maintenance if hosts change

### Option B: Use both RRs (bkk00 + bkk20)
- Traffic from different upstreams may prefer different validators
- Partial load distribution
- Already configured but limited by BGP best-path

### Option C: Move edge routing to BIRD
- Replace RouterOS BGP with BIRD on edge routers
- Full multipath ibgp support
- Major change

### Option D: Policy-based load balancing
- Use firewall mangle to distribute traffic
- Mark connections and route via different gateways
- Complex to maintain

## Current state
- Unified VLAN 400.100 working (all RR sessions established)
- Filter rule in place on bkk00 (needs to be applied to bkk20)
- Old QnQ VLANs (106/107/108/116/117/118) still exist but 0 routes using them
- Only bkk06 receiving anycast traffic

## Next steps
1. Apply same filter fix to bkk20
2. Test static ECMP route for one anycast IP
3. If works, add static routes for all anycast IPs
4. Clean up old QnQ VLANs

## Topology reminder
- bkk06/07/08: RPC endpoint hosts (10 containers each)
- Other bkkXX nodes: validators
- bkk00/bkk20: edge routers (route reflectors)
- bkk50: internal router (NAT for management)
- bkk60: CRS354 switch connecting all servers
