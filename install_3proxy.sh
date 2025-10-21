#!/bin/bash
set -euo pipefail

# Defaults
USERNAME="proxy"
PASSWORD="1xD4CboitCayXXH51NlwiQCTI"
HTTP_PORT="3128"
SOCKS_PORT="1080"

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -u USERNAME      Proxy username (default: $USERNAME)
  -p PASSWORD      Proxy password (default: $PASSWORD)
  -P HTTP_PORT     HTTP proxy port (default: $HTTP_PORT)
  -S SOCKS_PORT    SOCKS5 proxy port (default: $SOCKS_PORT)
  -h               Show this help and exit

Example:
  sudo bash $0 -u myuser -p S3cr3tPass -P 3128 -S 1080
EOF
  exit 1
}

# parse args
while getopts ":u:p:P:S:h" opt; do
  case ${opt} in
    u ) USERNAME="$OPTARG" ;;
    p ) PASSWORD="$OPTARG" ;;
    P ) HTTP_PORT="$OPTARG" ;;
    S ) SOCKS_PORT="$OPTARG" ;;
    h ) usage ;;
    \? ) echo "Invalid Option: -$OPTARG" >&2; usage ;;
    : ) echo "Invalid Option: -$OPTARG requires an argument" >&2; usage ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try: sudo $0" >&2
   exit 1
fi

echo "👉 Installing 3proxy (HTTP port: $HTTP_PORT, SOCKS5 port: $SOCKS_PORT)"
echo "🧑 User: $USERNAME | 🔒 Password: $PASSWORD"

# === Update and install packages ===
apt update
apt install -y dos2unix curl wget git build-essential nano ufw

# create build dir
cd /opt || exit 1

# If repo already exists, try update, else clone
if [ -d /opt/3proxy ]; then
  echo "3proxy source exists in /opt/3proxy — updating (git pull)..."
  cd /opt/3proxy || exit 1
  git pull || true
else
  git clone https://github.com/z3APA3A/3proxy.git
  cd 3proxy || exit 1
fi

# build
make -f Makefile.Linux

# install binary
install -Dm755 bin/3proxy /usr/bin/3proxy

# create directories
mkdir -p /etc/3proxy /etc/3proxy/logs

# === Create config file ===
cat <<EOF > /etc/3proxy/3proxy.cfg
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
users $USERNAME:CL:$PASSWORD
auth strong
allow $USERNAME
proxy -p$HTTP_PORT
socks -p$SOCKS_PORT
flush
EOF

# === Create systemd service ===
cat <<'EOF' > /etc/systemd/system/3proxy.service
[Unit]
Description=3proxy Proxy Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy

# === Firewall ===
# Allow only specified ports (tcp)
ufw --force enable
ufw allow "${HTTP_PORT}/tcp"
ufw allow "${SOCKS_PORT}/tcp"

# === Get public IP ===
PUBLIC_IP=""
if command -v curl >/dev/null 2>&1; then
  PUBLIC_IP=$(curl -s https://ipinfo.io/ip || true)
fi
if [ -z "$PUBLIC_IP" ]; then
  if command -v wget >/dev/null 2>&1; then
    PUBLIC_IP=$(wget -qO- https://ipinfo.io/ip || true)
  fi
fi
# fallback to local ip if no public ip found
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP=$(hostname -I | awk '{print $1}')
fi

echo ""
echo "> Success!"
echo "> HTTP proxy:  http://$USERNAME:$PASSWORD@$PUBLIC_IP:$HTTP_PORT"
echo "> SOCKS5 proxy: socks5://$USERNAME:$PASSWORD@$PUBLIC_IP:$SOCKS_PORT"
echo ""
echo "Notes:"
echo "- Review /etc/3proxy/3proxy.cfg to adjust rules, logging and timeouts."
echo "- Check service status: systemctl status 3proxy"
echo "- View logs: journalctl -u 3proxy -f"
