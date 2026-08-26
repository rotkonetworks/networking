# bkk10 post-reset recovery — identity + management path + ansible user.
#
# Paste line-by-line into the SERIAL CONSOLE (bkk03 /dev/ttyUSB1, 115200)
# or MAC-telnet.  No line continuations: safe to paste into `screen`.
#
# Why BKK60-LAG for mgmt: it is independent of OSPF and loopbacks, so it
# survives the edge-config rebuild that follows.  The reset destroyed the
# bond, which is why bkk60's LACP has no partner and 192.168.88.10 is dead.

/system/identity/set name=bkk10

# Factory defconf bridges every port together. Remove it first, otherwise
# sfp+2 / sfp+4 remain bridge members and the bonding add will fail.
/interface/bridge/remove [find name="bridge"]

/interface/bonding/add name=BKK60-LAG slaves=sfp-sfpplus2,sfp-sfpplus4 mode=802.3ad lacp-rate=1sec transmit-hash-policy=layer-2-and-3 comment="mgmt uplink to bkk60 - LACP must match bkk60 side"

/ip/address/add address=192.168.88.10/24 interface=BKK60-LAG comment="mgmt"
/ip/route/add dst-address=0.0.0.0/0 gateway=192.168.88.1 comment="mgmt default via bkk60"

/ip/service/enable ssh
/ip/service/set ssh port=22

# ansible user. MAC-telnet and serial are password-only (no key auth), so set
# a password here; the SSH key is imported afterwards over the network.
# Replace CHANGEME before pasting.
/user/add name=ansible group=full password=CHANGEME comment="automation"

# --- then, from the workstation, once 192.168.88.10 answers -------------
#   scp -J bkk08 ~/.ssh/unlabored/ansible_mikrotik.pub ansible@192.168.88.10:
#   ssh -J bkk08 ansible@192.168.88.10 \
#     '/user/ssh-keys/import public-key-file=ansible_mikrotik.pub user=ansible'
# After that, key auth works and the password can be retired.
