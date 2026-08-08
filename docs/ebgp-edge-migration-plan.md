# eBGP edge migration plan

## overview

migrate bkk00-bkk20 interconnect from iBGP to eBGP using private AS.
goal: enable true ECMP between all uplinks regardless of which router has direct peering.

## current state

```
                    AS 142108
    ┌─────────────────────────────────────────┐
    │                                         │
    │   bkk00 ◄──────iBGP──────► bkk20        │
    │     │                        │          │
    │     │                        │          │
    └─────┼────────────────────────┼──────────┘
          │                        │
          ▼                        ▼
      HGC-HK (eBGP)           HGC-SG (eBGP)
      BKNIX (eBGP)            AMSIX-BAN (eBGP)
      AMSIX-EU (eBGP)         AMSIX-HK (eBGP)
```

problems:
- eBGP routes always preferred over iBGP (AD 20 vs 200)
- can't ECMP between HGC-HK (direct on bkk00) and HGC-SG (iBGP from bkk20)
- traffic engineering limited by best-path selection

## target architecture

```
                    AS 142108 (confederation)
    ┌─────────────────────────────────────────┐
    │                                         │
    │   bkk00 ◄──────eBGP──────► bkk20        │
    │  (64501)     private AS    (64502)      │
    │     │                        │          │
    └─────┼────────────────────────┼──────────┘
          │                        │
          ▼                        ▼
      external peers           external peers
      (see AS 142108)          (see AS 142108)
```

options:
1. **private AS on one router** - simpler, bkk20 uses 64512
2. **confederation** - both use sub-AS, more complex
3. **full private AS** - both use private, strip on egress

recommendation: option 1 (private AS on bkk20)

## private AS allocation

- bkk00: keeps AS 142108 (primary edge)
- bkk20: uses AS 64512 (private, stripped on external announcements)
- internal routers (bkk10, bkk50): stay iBGP to bkk00 or convert later

## migration phases

### phase 0: preparation (no production changes)

- [ ] document all current BGP sessions and filters
- [ ] export full config backup of both routers
- [ ] verify `remove-private-as` is already set on all external templates
- [ ] test private AS behavior in lab if possible
- [ ] create monitoring alerts for BGP session flaps
- [ ] schedule maintenance window

### phase 1: add parallel eBGP session

keep existing iBGP running, add new eBGP in parallel:

```routeros
# on bkk00 - add eBGP to bkk20
/routing bgp template add name=EBGP-BKK20-v4 as=142108 router-id=10.155.255.4 \
    remote.as=64512 multihop=yes nexthop-choice=force-self \
    input.filter=EBGP-BKK20-IN-v4 output.filter-chain=EBGP-BKK20-OUT-v4

/routing bgp connection add name=EBGP-BKK20-v4 template=EBGP-BKK20-v4 \
    local.address=10.155.255.4 remote.address=10.155.255.2 disabled=yes

# on bkk20 - change local AS to private
# WARNING: this affects all sessions on bkk20
```

**critical**: bkk20 changing AS requires updating ALL its external peer configs.
external peers will see AS path change from `142108` to `142108 64512` temporarily
until `remove-private-as` strips the 64512.

### phase 2: prepare bkk20 external sessions

before changing bkk20's AS, ensure all external templates have:

```routeros
/routing bgp template set [find] remove-private-as=yes
```

verify current settings:
```routeros
/routing bgp template print where remove-private-as=no
```

### phase 3: change bkk20 to private AS

```routeros
# on bkk20
/routing bgp template set default as=64512
/routing id set main id=10.155.255.2  # keep router-id same
```

this will cause:
- all bkk20 external sessions to reset
- brief traffic disruption (30-60 seconds)
- external peers see new AS path

monitor:
- all sessions re-establish
- routes propagate correctly
- external looking glasses show AS 142108 (not 64512)

### phase 4: enable eBGP between routers

```routeros
# on bkk00
/routing bgp connection enable EBGP-BKK20-v4
/routing bgp connection enable EBGP-BKK20-v6

# verify session establishes
/routing bgp session print where name~"BKK20"
```

at this point both iBGP and eBGP are running in parallel.

### phase 5: verify ECMP

```routeros
# check if routes now show multiple nexthops
/ip route print where dst-address="8.8.8.0/24"

# should see ECMP if both paths have equal attributes
```

if ECMP works, proceed to phase 6.
if not, troubleshoot (likely filter/local-pref mismatch).

### phase 6: disable iBGP

```routeros
# on bkk00
/routing bgp connection disable IBGP-ROTKO-BKK20-v4
/routing bgp connection disable IBGP-ROTKO-BKK20-v6

# on bkk20
/routing bgp connection disable IBGP-ROTKO-BKK00-v4
/routing bgp connection disable IBGP-ROTKO-BKK00-v6
```

monitor for 24-48 hours before removing.

### phase 7: cleanup

after stable operation:
```routeros
/routing bgp connection remove [find name~"IBGP.*BKK"]
```

## rollback procedures

### rollback from phase 3 (bkk20 AS change)

```routeros
# on bkk20
/routing bgp template set default as=142108
```

sessions will reset again but return to original state.

### rollback from phase 4-6 (eBGP enabled)

```routeros
# on bkk00
/routing bgp connection disable EBGP-BKK20-v4
/routing bgp connection enable IBGP-ROTKO-BKK20-v4
```

## filter considerations

new filters needed for eBGP-BKK20:

```routeros
# EBGP-BKK20-IN-v4 - accept routes from bkk20
# - set appropriate local-pref (match current iBGP behavior initially)
# - later: adjust for ECMP

# EBGP-BKK20-OUT-v4 - send routes to bkk20
# - send full table or filtered
# - set next-hop-self
```

## risks

1. **AS path change visible externally** - brief, mitigated by remove-private-as
2. **session resets** - brief traffic disruption during phase 3
3. **filter misconfiguration** - could cause routing loops or blackholes
4. **ECMP might not work** - RouterOS quirks, need testing
5. **internal routers (bkk10, bkk50)** - still iBGP to bkk00, might need updates

## success criteria

- [ ] all external BGP sessions stable
- [ ] external looking glasses show AS 142108 only
- [ ] ECMP working for routes learned from multiple uplinks
- [ ] traffic balanced across HGC-HK and HGC-SG
- [ ] no packet loss during steady state
- [ ] latency unchanged or improved

## timeline

- phase 0: 1-2 days (documentation, preparation)
- phase 1-2: 1 day (parallel setup, no impact)
- phase 3-4: maintenance window, 1-2 hours
- phase 5-6: 24-48 hours monitoring
- phase 7: after 1 week stable operation

## alternative: try multipath first

before full eBGP migration, test RouterOS 7 multipath:

```routeros
/routing bgp template set IBGP-ROTKO-v4 add-path=receive
/routing settings set multipath=yes
```

if this enables ECMP for iBGP routes, might not need full migration.

## references

- RFC 6996 - Autonomous System Reservation for Private Use
- RFC 5765 - BGP Confederations
- MikroTik BGP multipath docs
- Cloudflare "eBGP everywhere" design blog

## notes

- this document is a draft, review before execution
- test in lab environment if possible
- coordinate with upstream providers if needed (shouldn't be, remove-private-as handles it)
