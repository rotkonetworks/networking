# bkk00 (pjbkk00) + bkk20 (pjbkk20) — 2026-08-05
# Service-IP FIB watchdog: self-heal edge blackholes like the 2026-08-05
# penumbra incident (bkk07 rebooted; edge kept a stale HW-offloaded FIB
# entry for 160.22.181.252/32; RIB looked healthy; inbound traffic died
# until the RR-client session was bounced).
#
# Mechanism: every 60s fetch https://160.22.181.252/ from the router. On 3
# consecutive failures, reset the BGP session(s) toward bkk07 (forces full
# route relearn + FIB reprogram) and log loudly.
#
# CAVEAT: router-sourced probes traverse the CPU path; a blackhole confined
# strictly to the HW fastpath may not be visible to this probe. The
# bird-postboot-rebounce timer on bkk06/bkk07 covers the known reboot
# trigger; this watchdog is continuous best-effort insurance on top.
#
# Apply: ssh pjbkk00 / pjbkk20, paste. Rollback: see ROLLBACK file.

/system script add name=svc-fib-watchdog policy=read,write,test,policy source={
    :global svcFibFailCount
    :if ([:typeof $svcFibFailCount] = "nothing") do={ :set svcFibFailCount 0 }
    :do {
        /tool fetch url="https://160.22.181.252/" check-certificate=no keep-result=no
        :set svcFibFailCount 0
    } on-error={
        :set svcFibFailCount ($svcFibFailCount + 1)
        :log warning ("svc-fib-watchdog: probe of 160.22.181.252 failed (" . $svcFibFailCount . "/3)")
        :if ($svcFibFailCount >= 3) do={
            :log error "svc-fib-watchdog: 3 consecutive failures - resetting BGP session(s) to bkk07 to force FIB reprogram"
            /routing/bgp/session/reset [find where name~"bkk07"]
            :set svcFibFailCount 0
        }
    }
}

/system scheduler add name=svc-fib-watchdog interval=1m on-event="/system script run svc-fib-watchdog" comment="self-heal stale service-IP FIB (2026-08-05 penumbra incident)"
