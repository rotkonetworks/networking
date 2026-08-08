#!/bin/bash
# add bkk06/07/08 to wg_rotko vpn
# run this script from a machine that can ssh to all servers

set -e

# bkk00 wireguard endpoint - use direct LAG link per server
# bkk06 -> 10.155.106.0:51820
# bkk07 -> 10.155.107.0:51820
# bkk08 -> 10.155.108.0:51820
WG_PORT="51820"
BKK00_PUBKEY="gkXioj9pgmNULmvJqN9LtR31XaCfVWF/11QHxJBYhTg="

# ip allocations
# bkk06: 172.31.0.6
# bkk07: 172.31.0.7
# bkk08: 172.31.0.8

echo "=== step 1: generate keys on each server ==="

for server in bkk06 bkk07 bkk08; do
    echo "generating keys on $server..."
    ssh $server "
        if [ ! -f /etc/wireguard/privatekey ]; then
            umask 077
            wg genkey > /etc/wireguard/privatekey
            cat /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
            echo 'keys generated'
        else
            echo 'keys already exist'
        fi
        echo 'public key:'
        cat /etc/wireguard/publickey
    "
done

echo ""
echo "=== step 2: get public keys ==="
echo ""
echo "run these commands to get public keys:"
echo ""
echo "ssh bkk06 'cat /etc/wireguard/publickey'"
echo "ssh bkk07 'cat /etc/wireguard/publickey'"
echo "ssh bkk08 'cat /etc/wireguard/publickey'"
echo ""

echo "=== step 3: add peers to bkk00 (routeros) ==="
echo ""
echo "run on bkk00:"
echo ""
echo '/interface/wireguard/peers/add interface=wg_rotko name=bkk06 allowed-address=172.31.0.6/32 public-key="<BKK06_PUBKEY>"'
echo '/interface/wireguard/peers/add interface=wg_rotko name=bkk07 allowed-address=172.31.0.7/32 public-key="<BKK07_PUBKEY>"'
echo '/interface/wireguard/peers/add interface=wg_rotko name=bkk08 allowed-address=172.31.0.8/32 public-key="<BKK08_PUBKEY>"'
echo ""

echo "=== step 4: configure wireguard on servers ==="
echo ""
echo "create /etc/wireguard/wg0.conf on each server"
