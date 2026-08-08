# BGP Architecture v2 - Design Document

**Status:** DRAFT
**Author:** Network Team
**Date:** 2026-01-01
**Version:** 0.1

---

## 1. Executive Summary

This document proposes migrating from RouterOS-based BGP route reflection to a BIRD-based architecture to achieve native ECMP load balancing across anycast servers.

**Current state:** RouterOS handles external BGP and route reflection, but lacks BGP ECMP support.

**Proposed state:** Evaluate options to enable ECMP while maintaining reliability.

---

## 2. Current Architecture

### 2.1 Network Topology

```
                    INTERNET
                       │
         ┌─────────────┴─────────────┐
         │                           │
    ┌────┴────┐                ┌─────┴────┐
    │  bkk00  │                │  bkk20   │
    │RouterOS │◄──── iBGP ────►│RouterOS  │
    │  (RR)   │                │   (RR)   │
    └────┬────┘                └────┬─────┘
         │                          │
         │    ┌──────────────────┐  │
         │    │  Unified VLAN    │  │
         │    │  10.155.100.0/24 │  │
         │    └──────────────────┘  │
         │             │            │
    ┌────┴─────────────┼────────────┴────┐
    │                  │                  │
┌───┴───┐         ┌────┴───┐         ┌───┴───┐
│ bkk06 │         │ bkk07  │         │ bkk08 │
│ BIRD  │         │ BIRD   │         │ BIRD  │
│Anycast│         │Anycast │         │Anycast│
└───────┘         └────────┘         └───────┘
```

### 2.2 External BGP Sessions (on bkk00)

| Peer | ASN | Type | Status |
|------|-----|------|--------|
| HGC-HK-PRIMARY | 9304 | Transit | Active |
| HGC-SG-BACKUP | 142435 | Transit | v4 broken, v6 active |
| BKNIX RS0/RS1 | 63529 | IXP | Active |
| HE-BKNIX | 6939 | Peering | Active |
| AMS-IX | 6777 | IXP | Active |
| Cloudflare | 13335 | Peering | Active |
| HE-AMSIX | 6939 | Peering | Active |

### 2.3 Internal BGP

- bkk00 and bkk20 act as Route Reflectors
- bkk06/07/08 are RR clients via unified VLAN (10.155.100.x)
- All servers announce anycast IPs (160.22.181.81/32, etc.)

### 2.4 Current Limitations

1. **No ECMP:** RouterOS picks ONE best path to anycast IPs
2. **Single server receives all traffic:** Currently bkk06 (10.155.100.6)
3. **No automatic load distribution:** Must manually adjust via communities
4. **HGC-SG-BACKUP v4 broken:** Session not establishing

---

## 3. Problem Statement

### 3.1 Core Issue

RouterOS 7.x does not support ECMP for BGP routes. When multiple servers announce the same anycast prefix, RouterOS installs only one active route.

### 3.2 Impact

- Uneven load distribution across anycast servers
- Single server handles all traffic until failure
- No utilization balancing
- Wasted capacity on idle servers

### 3.3 Requirements

1. **R1:** Distribute traffic across all healthy anycast servers
2. **R2:** Automatic failover on server failure (< 30 seconds)
3. **R3:** Maintain high availability during maintenance
4. **R4:** Track all changes via Git
5. **R5:** Gradual migration without production impact

---

## 4. Proposed Solutions

### 4.1 Option A: BIRD Router VM (Recommended for reliability)

**Architecture:**
```
Internet → RouterOS (external BGP) → BIRD VM (ECMP) → Servers
```

**Pros:**
- RouterOS stays as reliable edge (no changes to external BGP)
- BIRD VM handles internal routing with ECMP
- Small VM, stable, rarely reboots
- Minimal blast radius

**Cons:**
- Additional component to manage
- Extra hop in data path
- VM availability concern (can run 2 for HA)

**Implementation:**
1. Deploy BIRD VM(s) on proxmox
2. RouterOS forwards internal traffic to BIRD VM
3. BIRD VM does ECMP to servers
4. Servers peer with BIRD VM instead of RouterOS

### 4.2 Option B: External BGP on Servers

**Architecture:**
```
Internet → Servers (BIRD handles everything)
         → RouterOS becomes L2 only
```

**Pros:**
- True hyperscaler architecture
- Native ECMP in BIRD
- Full control from Linux

**Cons:**
- Servers become routers (app issues affect routing)
- Reboots cause BGP flaps
- Only 3 servers (low redundancy)
- Complex failure modes
- Major architectural change

**Implementation:**
1. Extend external VLANs to all servers
2. Configure BIRD with external BGP
3. Migrate sessions one by one
4. Deprecate RouterOS BGP

### 4.3 Option C: RouterOS PBR/Mangle (Workaround)

**Architecture:**
```
Internet → RouterOS (hash-based distribution) → Servers
```

**Pros:**
- No new components
- Works with current setup
- Simple to implement

**Cons:**
- Not true ECMP (static hashing)
- No health-based failover
- Manual configuration per prefix
- Doesn't scale well

**Implementation:**
1. Create mangle rules to mark traffic
2. Route based on marks to different servers
3. Use connection tracking for session affinity

### 4.4 Option D: Communities + Accept Single-Active

**Architecture:**
```
Current setup + BGP communities for control
```

**Pros:**
- No changes to architecture
- Fast failover via BGP
- Simple, reliable
- Works today

**Cons:**
- No load balancing
- One server handles all traffic
- Wasted capacity

**Implementation:**
1. Add community support to BIRD exports
2. Add community filters to RouterOS imports
3. Control primary/backup via BIRD config

---

## 5. Recommendation

### 5.1 Short Term: Option D (Communities)

Implement BGP communities for traffic steering. This:
- Works immediately
- No new failure modes
- Provides manual load distribution
- Fast failover

### 5.2 Medium Term: Option A (BIRD VM)

Deploy BIRD router VM for true ECMP:
- Lower risk than Option B
- Proper load balancing
- Can be done gradually

### 5.3 Long Term: Evaluate Option B

Once comfortable with BIRD routing:
- Consider moving external BGP to servers
- Only if team size/expertise grows
- Need more than 3 servers for safety

---

## 6. Failure Mode Analysis

### 6.1 Current Architecture

| Failure | Impact | Recovery |
|---------|--------|----------|
| bkk00 down | bkk20 takes over, full table | Automatic via iBGP |
| bkk06 down | Traffic continues to bkk06 until timeout | 30-90s BGP timeout |
| All servers down | Anycast unreachable | Manual intervention |

### 6.2 Option A (BIRD VM)

| Failure | Impact | Recovery |
|---------|--------|----------|
| BIRD VM down | Fall back to RouterOS single-path | Automatic |
| BIRD VM + 1 server | 2 servers share load | Automatic |
| Both BIRD VMs | RouterOS direct to servers | Automatic |

### 6.3 Option B (Servers as routers)

| Failure | Impact | Recovery |
|---------|--------|----------|
| 1 server down | 2 servers share external BGP | 30-90s BGP reconvergence |
| 2 servers down | 1 server handles everything | Overload risk |
| Kernel panic | BGP session drops | 30-90s timeout |
| App memory leak | May affect routing | Unpredictable |

---

## 7. Migration Plan (Option D first, then Option A)

### Phase 1: BGP Communities (Week 1-2)

1. Add community definitions to BIRD configs
2. Add community filters to RouterOS
3. Test traffic steering
4. Document procedures

### Phase 2: BIRD VM Setup (Week 3-4)

1. Deploy BIRD VM on proxmox
2. Configure iBGP with RouterOS
3. Configure iBGP with servers
4. Test ECMP functionality

### Phase 3: Traffic Migration (Week 5-6)

1. Shift internal routes to BIRD VM
2. Verify ECMP working
3. Monitor for issues
4. Document runbooks

### Phase 4: Validation (Week 7-8)

1. Failure testing
2. Performance benchmarks
3. Update documentation
4. Training

---

## 8. Open Questions

1. **VM placement:** Which proxmox host for BIRD VM? Need 2 for HA?
2. **Resource sizing:** How much CPU/RAM for BIRD with full table?
3. **Monitoring:** How to monitor BIRD VM health?
4. **Automation:** How to integrate with existing deployment pipeline?
5. **Rollback:** What's the rollback procedure if BIRD VM fails?

---

## 9. Success Criteria

1. [ ] Traffic distributed across all healthy servers
2. [ ] Failover time < 30 seconds
3. [ ] No traffic loss during planned maintenance
4. [ ] All changes tracked in Git
5. [ ] Runbooks documented
6. [ ] Team trained on new architecture

---

## 10. Appendix

### A. Current Route Distribution

```
bkk00# /ip route print where dst=160.22.181.81/32
10.155.100.6  ACTIVE   (all traffic here)
10.155.100.7  backup
10.155.100.8  backup
```

### B. Target Route Distribution (with ECMP)

```
bkk00# ip route show 160.22.181.81
160.22.181.81
    nexthop via 10.155.100.6 weight 1
    nexthop via 10.155.100.7 weight 1
    nexthop via 10.155.100.8 weight 1
```

### C. Community Scheme

```
142108:100  - Primary (local-pref 100)
142108:90   - Secondary (local-pref 90)
142108:80   - Backup (local-pref 80)
142108:0    - Drain (do not use)
```

### D. References

- BIRD Internet Routing Daemon: https://bird.network.cz/
- RFC 4456: BGP Route Reflection
- RFC 7911: BGP ADD-PATH

---

**Document History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-01 | Network Team | Initial draft |

