# 2026-08-08 — Stop advertising RPKI-invalid v6 more-specifics to transit (emergency, live-applied)
#
# Root cause: ROA 2401:a860::/32 has maxLength=32 (APNIC portal pinned it). The anycast
# aggregates 2401:a860::/36 (global) and 2401:a860:1081::/48 (site) are RPKI invalid_length,
# so they are dropped/become intermittently unreachable. Interim mitigation:
#
#   [1] Edge transit filters changed to advertise ONLY the valid /32 for v6:
#       (before)  if (dst-len > 48) { reject; }
#       (after)   if (dst-len > 32) { reject; }
#
# Live change applied on BOTH edges, all transit v6 OUT chains:
#   pjbkk00: BKNIX-OUT-v6, AMSIX-OUT-v6, HGC-HK-OUT-v6, HGC-SG-OUT-v6
#   pjbkk20: AMSIX-BAN-OUT-v6, AMSIX-HK-OUT-v6, HGC-HK-OUT-v6, HGC-SG-OUT-v6
#   (IN chains + IBGP/RR-CLIENT internal chains deliberately NOT touched)
#   Command: /routing filter rule set [find chain=<c> and rule~"dst-len > 48"] rule="if (dst-len > 32) { reject; }"
#
#   [2] Cloudflare DNS: deleted ALL 33 AAAA records with content exactly "2401:a860::"
#       (global anycast VIP) on RPC hostnames; they now resolve only to 2401:a860:1081::.
#       Kept dns.rotko.net 2401:a860::80 and all other 2401:a860:* records.
#
# ROLLBACK (before APNIC maxLength is raised):
#   /routing filter rule set [find chain=<c> and rule~"dst-len > 32"] rule="if (dst-len > 48) { reject; }"
#   + re-add the 2401:a860:: AAAA records in Cloudflare.
#
# PENDING REAL FIX: APNIC RPKI ROA maxLength must be raised (>= /48 v6, >= /24 v4) so the
# /36 and /48 anycast aggregates are valid again. Ticket sent to helpdesk@apnic.net
# (member ROTKONETWORKSOU-AP, AS142108, hq@rotko.net).

# --- Follow-up (2026-08-08, same session) ---
# ROA is now 2401:a860::/32 maxLength /40 (APNIC cap = parent + 8). Therefore:
#   - global anycast = /32 (valid)
#   - site anycast   = /40 (2401:a860:1000::/40)  (was /48; /48 cannot be ROA'd under /32-40)
# Edge transit filter relaxed to 'dst-len > 40 reject' (allows /32 and /40, blocks /41+).
# Host bird (bkk06/07/08) now originates: 2401:a860::/32, 2401:a860:1000::/40, site /128 VIP.
