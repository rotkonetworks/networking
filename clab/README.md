# clab — network config test stage

Lab-before-a-real-port, wired into CI. Two tiers:

## 1. `lint.sh` — fast gate (every PR, no CHR needed)
Runs in seconds on a plain docker runner:
- **BIRD** host configs → `bird -p` parse (set `BIRD_IMG` to a BIRD3 image; else grep-sanity fallback)
- **generator** scripts → `bash -n`
- **RouterOS** `.rsc` → brace balance + CRLF notice
- **clab** topologies → YAML well-formed

`./clab/lint.sh` locally, or automatically via `.github/workflows/clab-test.yml` on any
change under `generated/ backup/mikrotik/ deploy/ clab/`. Blocks the merge on failure.

## 2. `rotko.clab.yml` + `test.sh` — full convergence (on demand / self-hosted)
Boots the real fabric — RouterOS edges (unnumbered, v7.21+) + BIRD hosts — from the actual
repo configs, waits, and asserts BGP sessions/prefixes, then tears down.
Needs `containerlab` + a CHR image: `ROS_IMAGE=<vrnetlab chr> ./clab/test.sh`.
Trigger in CI via the `full_convergence` workflow_dispatch input (self-hosted `kvm` runner).

## To make the BIRD parse real
Build/publish a BIRD3 image (same version the deploy job installs) and set repo var `BIRD_IMG`.
Until then lint falls back to a structural sanity check on the bird configs.

## New-DC design lives in ../newdc/ (validated FRR reference) and ../docs/dc-migration-*.md
