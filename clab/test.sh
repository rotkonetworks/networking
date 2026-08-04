#!/usr/bin/env bash
# Full convergence test. Needs containerlab + a CHR image ($ROS_IMAGE). Run on a lab host / CI runner.
set -uo pipefail
cd "$(dirname "$0")"
command -v containerlab >/dev/null || { echo "SKIP: containerlab not installed"; exit 0; }
[ -n "${ROS_IMAGE:-}" ] || { echo "SKIP: set ROS_IMAGE (CHR image) for full-fidelity test"; exit 0; }
sudo containerlab deploy -t rotko.clab.yml || exit 1
sleep 30
rc=0
echo "== assert BGP sessions established =="
sudo containerlab exec -t rotko.clab.yml --label clab-node-name=edge1 --cmd '/routing/bgp/session/print' | grep -q established || { echo "FAIL: edge1 no established session"; rc=1; }
echo "== assert host prefix present on edge =="
# add real prefix assertions here as the fabric grows
sudo containerlab destroy -t rotko.clab.yml
exit $rc
