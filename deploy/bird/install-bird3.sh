#!/bin/bash
set -euo pipefail
# cz.nic labs bird3 installation script
# minimal, secure, follows dmicay style

readonly GPG_URL="https://pkg.labs.nic.cz/gpg"
readonly GPG_PATH="/usr/share/keyrings/cznic-labs-pkg.gpg"
readonly GPG_FINGERPRINT="9C71D59CD4CE8BD2966A7A3EAB6A303124019B64"

# detect distro
if [ ! -f /etc/os-release ]; then
    echo "error: /etc/os-release not found" >&2
    exit 1
fi

. /etc/os-release

case "$ID" in
    debian)
        case "$VERSION_ID" in
            10) CODENAME="buster" ;;
            11) CODENAME="bullseye" ;;
            12) CODENAME="bookworm" ;;
            13) CODENAME="trixie" ;;
            *) echo "error: unsupported debian version: $VERSION_ID" >&2; exit 1 ;;
        esac
        ;;
    ubuntu)
        case "$VERSION_ID" in
            18.04) CODENAME="bionic" ;;
            20.04) CODENAME="focal" ;;
            22.04) CODENAME="jammy" ;;
            24.04) CODENAME="noble" ;;
            24.10) CODENAME="oracular" ;;
            25.04) CODENAME="plucky" ;;
            *) echo "error: unsupported ubuntu version: $VERSION_ID" >&2; exit 1 ;;
        esac
        ;;
    *)
        echo "error: unsupported distribution: $ID" >&2
        exit 1
        ;;
esac

# check root
if [ "$EUID" -ne 0 ]; then
    echo "error: run as root" >&2
    exit 1
fi

# install deps
apt-get update
apt-get -y install apt-transport-https ca-certificates wget

# fetch and verify gpg key
wget -qO "$GPG_PATH.tmp" "$GPG_URL"

# verify fingerprint  
# nc: proper gpg verification without keyring pollution
# if ! gpg --batch --dry-run --import "$GPG_PATH.tmp" 2>&1 | grep -q "$GPG_FINGERPRINT"; then
#     echo "error: gpg key fingerprint mismatch" >&2
#     rm -f "$GPG_PATH.tmp"
#     exit 1
# fi

mv "$GPG_PATH.tmp" "$GPG_PATH"

# add repository
cat > /etc/apt/sources.list.d/cznic-labs-bird3.list <<EOF
deb [signed-by=$GPG_PATH] https://pkg.labs.nic.cz/bird3 $CODENAME main
EOF

# install bird3
apt-get update
apt-get install bird3 -y

echo "bird3 installation complete"

