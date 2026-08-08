# AS142108 BGP Architecture Decision Analysis

**Status:** FINAL RECOMMENDATION
**Date:** 2026-01-01
**Approach:** First-principles network engineering analysis

---

## Executive Decision

**Recommendation: Option B - BIRD on all 3 servers as edge routers**

This is not the conservative choice. It is the correct choice for your stated goals:
- Maximum bandwidth utilization
- Redundancy (2 of 3 can fail)
- Hyperscaler-style architecture
- Full traffic control

The analysis below explains why.

---

## 1. Understanding the Real Problem

### 1.1 Current Bandwidth Bottleneck

Your infrastructure:
```
BKNIX (10Gbps) ──┐
HGC-HK (800M)  ──┼── bkk00 ── single path ── bkk06 (gets ALL traffic)
AMS-IX (100M)  ──┘                           bkk07 (idle)
                                             bkk08 (idle)
```

**Total available bandwidth:** ~11 Gbps
**Actually usable:** Limited by single server capacity

RouterOS cannot do BGP ECMP. Period. This is a fundamental limitation that no amount of workarounds fixes properly.

### 1.2 Why Option A (BIRD VM) Does Not Solve Your Problem

Option A architecture:
```
Internet → RouterOS (external BGP) → BIRD VM (ECMP) → Servers
```

Critical flaw: **The bottleneck remains at RouterOS.**

RouterOS still handles ALL external traffic on its physical interfaces. Whether you add ECMP after it or not:
- All BKNIX traffic still goes through bkk00's sfp28-4
- All HGC traffic still goes through bkk00's sfp28-2
- You're still limited by single router's forwarding capacity

The BIRD VM only helps distribute traffic to servers AFTER it already hit RouterOS. It does not help you utilize multiple uplinks simultaneously for the same destination.

### 1.3 What You Actually Need

For a hyperscaler architecture, you need:
```
                    INTERNET
                       │
         ┌─────────────┼─────────────┐
         │             │             │
    ┌────┴────┐   ┌────┴────┐   ┌────┴────┐
    │  bkk06  │   │  bkk07  │   │  bkk08  │
    │  BIRD   │   │  BIRD   │   │  BIRD   │
    │ +eBGP   │   │ +eBGP   │   │ +eBGP   │
    └─────────┘   └─────────┘   └─────────┘
```

Each server:
- Receives its share of external traffic directly
- Makes its own routing decisions
- Has full bandwidth to the internet
- Fails independently

---

## 2. Failure Mode Analysis (The Real Concern)

Your question: "Can we have 2 machines down and internet still works?"

### 2.1 Option B Failure Scenarios

| Scenario | Impact | Recovery Time |
|----------|--------|---------------|
| 1 server down | 2 servers share load | 30-90s (BGP hold timer) |
| 2 servers down | 1 server handles all | Immediate (BGP converges) |
| Kernel panic | That server's sessions drop | 30-90s |
| Memory leak | Graceful restart handles it | < 5s with GR |
| Planned reboot | Graceful restart, no traffic loss | 0s |

**Key insight:** BGP Graceful Restart (RFC 4724) allows a server to reboot without dropping routes. Upstreams hold routes for 120s default. BIRD supports this natively.

### 2.2 Current Architecture Failure Comparison

| Scenario | Current | Option B |
|----------|---------|----------|
| bkk00 down | bkk20 takes over | N/A (no single edge) |
| All servers down | Anycast gone | Same |
| One server overloaded | All traffic lost | 2 servers continue |

Option B is **more resilient** for server failures because traffic is already distributed.

### 2.3 What Hyperscalers Do

Meta/Google/Cloudflare architecture:
1. Every server is a BGP speaker
2. Anycast handles routing
3. No single point of failure at edge
4. Servers fail gracefully via BGP withdrawal

You have the same setup potential with 3 servers.

---

## 3. VLAN Extension Requirements

### 3.1 Current Physical Connectivity

From bkk00.rsc analysis:
```
BKNIX-LAG (sfp28-4)  → VLAN native → BKNIX peering
AMSIX-LAG (sfp28-2)  → VLAN 2519  → HGC-HK
                     → VLAN 2518  → HGC-SG-BACKUP
                     → VLAN 3995  → EU-AMS-IX
```

### 3.2 Required Changes for Option B

**Physical path already exists:**
```
bkk00 ── BKK30-LAG (qsfp28-2-1) ── bridge_vlan ── VLAN 400 ── bkk06/07/08
```

The Q-in-Q infrastructure is already set up (qnq-400-106/107/108). You need to:

1. **Extend BKNIX VLAN to servers** (requires BKNIX coordination)
   - Request 3 IPs on BKNIX peering LAN
   - Current: 203.159.68.168/23
   - Need: 203.159.68.x/23 for bkk06, bkk07, bkk08

2. **Extend HGC VLANs to servers**
   - Tag VLAN 2519 through to servers
   - Tag VLAN 2518 through to servers

3. **Configure BIRD with external BGP templates**

### 3.3 IP Allocation Plan

| Server | BKNIX IPv4 | BKNIX IPv6 | HGC-HK IPv4 |
|--------|------------|------------|-------------|
| bkk06 | 203.159.68.169/23 | 2001:df5:b881::169 | 118.143.211.187/29 |
| bkk07 | 203.159.68.170/23 | 2001:df5:b881::170 | 118.143.211.188/29 |
| bkk08 | 203.159.68.171/23 | 2001:df5:b881::171 | 118.143.211.189/29 |

**Note:** HGC /29 gives you 6 usable IPs. You currently use 1. Plenty of room.

---

## 4. iBGP Mesh Between Servers

### 4.1 Why You Still Need iBGP

Even with external BGP on all servers, you need internal route sharing:
- Server A learns route to X via BKNIX
- Server B learns route to X via HGC
- They need to share this for optimal routing

### 4.2 Architecture

```
       ┌─────────┐
       │  bkk06  │
       │  eBGP   │
       └────┬────┘
            │ iBGP
      ┌─────┼─────┐
      │     │     │
┌─────┴─────┐     │
│  bkk07    │     │
│  eBGP     ├─────┤ iBGP (full mesh)
└─────┬─────┘     │
      │     ┌─────┴─────┐
      │     │  bkk08    │
      └─────┤  eBGP     │
            └───────────┘
```

With 3 nodes, full iBGP mesh = 3 sessions. Trivial.

### 4.3 BIRD Configuration Pattern

```
# iBGP template for peer servers
template bgp IBGP_MESH {
    local as 142108;
    rr client;  # all can be RR clients to each other
    direct;
    next hop self;
    graceful restart on;

    ipv4 {
        import all;
        export where source = RTS_BGP;
        add paths tx;  # RFC 7911 - send multiple paths
    };
}

protocol bgp iBGP_BKK07 from IBGP_MESH {
    neighbor 10.155.100.7 as 142108;
}

protocol bgp iBGP_BKK08 from IBGP_MESH {
    neighbor 10.155.100.8 as 142108;
}
```

The `add paths` directive is critical - it allows servers to share ALL paths they learn, not just the best one. This enables optimal routing decisions.

---

## 5. Traffic Engineering with BIRD

### 5.1 Ingress Traffic (to your servers)

Controlled by what you announce:
- Announce 160.22.180.0/23 to all upstreams
- Prepend on backup paths
- Use communities to influence upstream routing

All 3 servers announce same prefixes. Internet routers see multiple paths, pick closest.

### 5.2 Egress Traffic (from your servers)

BIRD handles this with `merge paths`:
```
protocol kernel {
    ipv4 {
        export all;
        import none;
        merge paths on;  # ECMP to kernel
    };
}
```

When BIRD learns same prefix via multiple upstreams with equal preference:
```
# BIRD RIB:
8.8.8.0/24
    via 203.159.68.1 (BKNIX)  local-pref 100
    via 118.143.211.185 (HGC) local-pref 100

# Kernel routing table (with merge paths):
8.8.8.0/24
    nexthop via 203.159.68.1 weight 1
    nexthop via 118.143.211.185 weight 1
```

Linux kernel does flow-based ECMP hashing. Each flow gets one path, sticky.

### 5.3 bgpctl Integration

You already have the bgpctl daemon built:
- Monitors path quality (RTT, loss, jitter)
- Adjusts local-pref dynamically
- Uses communities for traffic steering

This works perfectly with Option B - just point it at all 3 servers instead of RouterOS.

---

## 6. Migration Strategy

### 6.1 Phase 0: Fix HGC-SG-BACKUP (Lowest Risk Start)

This session is already broken. Perfect test case.

1. Extend VLAN 2518 to bkk06
2. Configure BIRD with HGC-SG external BGP
3. Establish session from bkk06
4. Validate routes appear
5. Monitor for 1 week

If anything goes wrong: session was broken anyway, no impact.

### 6.2 Phase 1: Add BKNIX to One Server

1. Request additional IP from BKNIX
2. Extend BKNIX VLAN to bkk07
3. Configure BIRD on bkk07 with BKNIX template
4. Establish session alongside bkk00
5. Both routers receive full table
6. Validate routing decisions

**Rollback:** Disable BIRD protocol, remove route announcements.

### 6.3 Phase 2: Shift Traffic Gradually

Use AS-path prepending to shift traffic:

```
# On bkk00 (RouterOS), start prepending:
/routing filter rule add chain="BKNIX-OUT-v4" \
    rule="set bgp-path-prepend 1; accept"
```

Traffic naturally shifts to shorter path via bkk07.

### 6.4 Phase 3: Complete Migration

1. Extend all VLANs to all servers
2. Configure all external BGP on all servers
3. Remove RouterOS external BGP
4. RouterOS becomes pure L2 switch

### 6.5 Final State

```
                    INTERNET
                       │
    ┌──────────────────┼──────────────────┐
    │                  │                  │
    ├── BKNIX ─────────┼── BKNIX ─────────┼── BKNIX
    ├── HGC-HK ────────┼── HGC-HK ────────┼── HGC-HK
    └── AMS-IX ────────┴── AMS-IX ────────┴── AMS-IX
           │                  │                  │
      ┌────┴────┐        ┌────┴────┐        ┌────┴────┐
      │  bkk06  │◄─iBGP─►│  bkk07  │◄─iBGP─►│  bkk08  │
      │  BIRD   │        │  BIRD   │        │  BIRD   │
      └─────────┘        └─────────┘        └─────────┘
             │                                    │
             └─────────── iBGP ───────────────────┘
```

---

## 7. Risk Assessment

### 7.1 Risks of NOT Doing Option B

| Risk | Probability | Impact |
|------|-------------|--------|
| Bandwidth cap during traffic spike | HIGH | Service degradation |
| Single server overload | HIGH | Outage |
| RouterOS bug affects all traffic | MEDIUM | Complete outage |
| Unable to scale beyond current | CERTAIN | Business limitation |

### 7.2 Risks of Option B

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Server reboot affects BGP | LOW | 30s reconvergence | Graceful restart |
| App issue affects routing | LOW | One server affected | Separate BIRD from apps |
| Configuration error | MEDIUM | Outage | Git-based config, dry-run |
| VLAN extension fails | LOW | Rollback to current | Test in phases |

### 7.3 Risk Comparison

**Current state:** Guaranteed to hit bandwidth limits, certain single point of failure.

**Option B:** Potential for brief reconvergence during failures, but distributed and resilient.

The safer long-term choice is Option B.

---

## 8. Resource Requirements

### 8.1 BIRD Resource Usage

Full BGP table (1M+ routes):
- Memory: ~800MB - 1.2GB
- CPU: Minimal (convergence bursts)
- Disk: Negligible

Your servers (bkk06/07/08) easily handle this.

### 8.2 Additional IPs Needed

| Exchange | Current IPs | Additional Needed |
|----------|-------------|-------------------|
| BKNIX | 1 | 2 (can request) |
| HGC-HK | 1 | 2 (within /29) |
| HGC-SG | 1 | 2 (within /30 - may need request) |
| AMS-IX | 1 | 0-2 (optional, remote IX) |

### 8.3 Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| HGC-SG-BACKUP fix | 1 day | None (already broken) |
| BKNIX extension | 3-5 days | BKNIX IP allocation |
| Full migration | 2-3 days | Testing complete |
| Validation | 1 week | Monitoring |

Total: 2-3 weeks for complete migration.

---

## 9. Decision Matrix

| Criterion | Weight | Option A (BIRD VM) | Option B (Servers) | Option D (Communities) |
|-----------|--------|--------------------|--------------------|------------------------|
| Bandwidth utilization | 35% | 20 (no improvement) | 100 (full ECMP) | 10 (single path) |
| Redundancy (2 fail OK) | 25% | 60 (VM single point) | 95 (distributed) | 50 (single path) |
| Operational simplicity | 15% | 70 (extra VM) | 80 (consistent) | 90 (no change) |
| Scalability | 15% | 40 (VM bottleneck) | 100 (linear) | 20 (doesn't scale) |
| Migration risk | 10% | 70 (safe) | 60 (more change) | 95 (minimal) |
| **Weighted Score** | | **46** | **89** | **42** |

**Option B wins decisively** for your stated requirements.

---

## 10. Conclusion

Based on first-principles analysis:

1. **Your core problem is bandwidth utilization** - Option B is the only solution that addresses this.

2. **3 servers is sufficient** - With graceful restart and iBGP mesh, you have N+2 redundancy for any single failure.

3. **The migration is safe** - Start with broken HGC-SG session, graduate to BKNIX, complete methodically.

4. **This is the hyperscaler pattern** - Meta, Google, Cloudflare all run BGP on servers. It works.

5. **RouterOS becomes simpler** - Pure L2 switching, no complex BGP config, fewer failure modes.

**Proceed with Option B.**

---

## Appendix A: BIRD External BGP Template

```
# /etc/bird/peers/bknix.conf

template bgp BKNIX_TEMPLATE {
    local as 142108;
    source address BKNIX_LOCAL_IP;
    strict bind;
    graceful restart on;

    ipv4 {
        import filter {
            # reject bogons
            if net ~ [ 0.0.0.0/8+, 10.0.0.0/8+, 172.16.0.0/12+,
                       192.168.0.0/16+, 224.0.0.0/4+ ] then reject;
            # reject our own prefix
            if net ~ [ 160.22.180.0/23+ ] then reject;
            # accept rest
            accept;
        };
        export filter {
            if net = 160.22.180.0/23 then accept;
            reject;
        };
    };
}

protocol bgp BKNIX_RS0 from BKNIX_TEMPLATE {
    neighbor 203.159.68.253 as 63529;  # RS0
}

protocol bgp BKNIX_RS1 from BKNIX_TEMPLATE {
    neighbor 203.159.68.254 as 63529;  # RS1
}

protocol bgp BKNIX_HE from BKNIX_TEMPLATE {
    neighbor 203.159.69.33 as 6939;    # Hurricane Electric
}
```

---

## Appendix B: RouterOS L2-Only Configuration

After migration, bkk00/bkk20 become simple switches:

```routeros
# Disable all BGP
/routing bgp connection disable [find]
/routing bgp template disable [find]

# Keep VLANs tagged through
/interface bridge vlan
add bridge=bridge_vlan tagged=BKNIX-LAG,BKK30-LAG vlan-ids=native
add bridge=bridge_vlan tagged=AMSIX-LAG,BKK30-LAG vlan-ids=2518,2519,3995
```

RouterOS becomes a reliable, stable L2 device. Fewer moving parts = fewer failures.

---

**Document History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-01 | Network Team | Final recommendation |
