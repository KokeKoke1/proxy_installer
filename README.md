# proxy_installer 🚀

**Note:** This project is intended for legal and ethical use only. Do not attempt to abuse services or circumvent payment systems.  

## Introduction 🌐
A SOCKS5 or HTTPS proxy can be extremely useful for cybersecurity, penetration testing, web scraping, or safely routing network traffic through your own infrastructure. By using your own proxy server, you can:
- Test applications in controlled network environments 🛠️  
- Mask your outgoing IP for security research 🕵️‍♂️  
- Analyze network behavior and threats safely 🔍  
- Learn networking and proxy server management hands-on 📚  

## Description 📝

This script automates the installation and basic configuration of 3proxy, allowing you to quickly set up a simple HTTP/SOCKS proxy server on your own machine or cloud instance.

The repository includes `install_3proxy.sh`, which:

* Installs required packages,
* Builds/installs 3proxy,
* Creates a sample configuration,
* Starts the service and optionally adds it to autostart.

---

## Table of Contents 📚

* [Requirements](#requirements)
* [Quick Installation (Debian/Ubuntu)](#quick-installation-debianubuntu)
* [Example Deployment on Google Cloud](#example-deployment-on-google-cloud)
* [3proxy Configuration — Basics](#3proxy-configuration--basics)
* [Security & Compliance](#security--compliance)
* [FAQ / Troubleshooting](#faq--troubleshooting)
* [License & Contributions](#license--contributions)

---

## Requirements ⚙️

* System: Debian / Ubuntu (tested on Ubuntu 22.04)
* Permissions: root / sudo
* Internet access to download the script and packages
* (Optional) Cloud account with permissions to create instances if deploying on cloud

---

## Quick Installation (Debian / Ubuntu) 💻

Run as root or with `sudo`:

```bash
apt update
apt install -y dos2unix curl wget
wget https://raw.githubusercontent.com/KokeKoke1/proxy_installer/refs/heads/main/install_3proxy.sh -O install_3proxy.sh
dos2unix install_3proxy.sh
chmod +x install_3proxy.sh
bash install_3proxy.sh
```

Check service status:

```bash
systemctl status 3proxy
```

**Note:** Always review `install_3proxy.sh` before running. Auditing scripts from the internet is recommended.

---

## Example Deployment on Google Cloud ☁️

Create an `instance-template` with a startup script:

```bash
gcloud beta compute instance-templates create instance-template-20250712-210239 \
  --machine-type=custom-1-1024 \
  --network-interface=network=default,network-tier=PREMIUM,stack-type=IPV4_ONLY \
  --instance-template-region=europe-central2 \
  --metadata=startup-script=\#\!/bin/bash$'\n'$'\n'apt\ update$'\n'apt\ install\ -y\ dos2unix\ curl\ wget$'\n'$'\n'wget\ https://pastebin.com/raw/HVzz99pd\ -O\ install_3proxy.sh$'\n'dos2unix\ install_3proxy.sh$'\n'chmod\ \+x\ install_3proxy.sh$'\n'bash\ install_3proxy.sh$'\n' \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=YOUR_SERVICE_ACCOUNT@developer.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=instance-template-20250712-210239,image=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250710,mode=rw,size=10,type=pd-balanced \
  --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
```

### Example Firewall Rule 🔒

> ⚠️ This example is very open — modify to limit ports and source ranges.

```bash
gcloud compute firewall-rules create proxy \
  --network=default \
  --direction=INGRESS \
  --priority=1080 \
  --action=ALLOW \
  --rules=all \
  --source-ranges=0.0.0.0/0 \
  --description="Allow inbound traffic for proxy"
```

**Safer approach:**

* Open only specific ports (e.g., `--rules=tcp:3128,tcp:1080`)
* Limit `--source-ranges` to trusted IPs
* Use additional security features (VPC firewall, identity-aware proxy)

---

## 3proxy Configuration — Basics ⚡

Default config file: `/etc/3proxy/3proxy.cfg`

Example snippet:

```
nserver 8.8.8.8
nscache 65536
timeouts 1 5 30 60 180 1800 15 60

# HTTP proxy on port 3128
proxy -p3128

# SOCKS proxy on port 1080
socks -p1080
```

Restart service after editing:

```bash
systemctl restart 3proxy
journalctl -u 3proxy -f
```

**Authentication & rules:**

* Add users with `users username:CL:password`
* Use `allow` / `deny` to control access
* Enable logging and log rotation

---

## Security & Compliance 🔐

* Always require authentication or restrict by IP
* Avoid opening all ports to the world
* Monitor usage and logs
* Follow cloud provider rules — do not bypass limits or use unauthorized resources
* Keep your system updated with security patches

---

## FAQ / Troubleshooting ❓

**Script fails with error:**

* Check permissions (`chmod +x install_3proxy.sh`)
* Convert to Unix format (`dos2unix`)
* Review logs and script output

**Cannot connect to proxy in cloud deployment:**

* Check firewall rules (GCP VPC + local firewall)
* Verify 3proxy is listening on the expected port (`ss -tulpen | grep 3proxy`)

**How to add authentication?**

* Edit the 3proxy config and add `users` section + rules requiring auth

---

## License & Contributions 📄

* Add a `LICENSE` file if missing (e.g., MIT)
* Optional: `CONTRIBUTING.md` for PRs / issues
* Report issues or send pull requests in the repository

