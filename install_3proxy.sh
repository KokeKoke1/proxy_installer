#!/bin/bash

# === Konfiguracja użytkownika ===
USERNAME="proxy"
PASSWORD="1xD4CboitCayXXH51NlwiQCTI"
HTTP_PORT="3128"
SOCKS_PORT="1080"

echo "👉 Instalacja 3proxy z HTTP (port $HTTP_PORT) i SOCKS5 (port $SOCKS_PORT)"
echo "🧑 Użytkownik: $USERNAME | 🔒 Hasło: $PASSWORD"

# === Instalacja wymaganych pakietów ===
apt update && apt install -y git build-essential wget nano ufw curl

# === Pobranie i kompilacja 3proxy ===
cd /opt || exit
git clone https://github.com/z3APA3A/3proxy.git
cd 3proxy || exit
make -f Makefile.Linux

# === Instalacja binarki ===
cp bin/3proxy /usr/bin/
chmod +x /usr/bin/3proxy
mkdir -p /etc/3proxy/logs

# === Tworzenie pliku konfiguracyjnego ===
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

# === Tworzenie pliku systemd ===
cat <<EOF > /etc/systemd/system/3proxy.service
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

# === Ustawienie autostartu i uruchomienie ===
systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy

# === Otwórz porty w firewallu ===
ufw allow $HTTP_PORT/tcp
ufw allow $SOCKS_PORT/tcp

# === Informacje końcowe ===
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)

echo ""
echo "✅ INSTALACJA ZAKOŃCZONA!"
echo "🌐 HTTP proxy:  http://$PUBLIC_IP:$HTTP_PORT:$USERNAME:$PASSWORD"
echo "🧦 SOCKS5 proxy: socks5://$PUBLIC_IP:$SOCKS_PORT:$USERNAME:$PASSWORD"
