# ROLLBACK for 2026-08-05_svc-fib-watchdog — removes the watchdog entirely.
# ssh pjbkk00 / pjbkk20, paste.
/system scheduler remove [find name="svc-fib-watchdog"]
/system script remove [find name="svc-fib-watchdog"]
