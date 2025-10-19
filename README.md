# 🚀 Lesson 3 — Running install_dev_tools.sh on a Fresh EC2 (Ubuntu)

This guide explains how to set up and run the automated installation script for Docker, Docker Compose v2, Python (>= 3.9), and Django on a clean Ubuntu EC2 instance.

---

## Requirements

- AWS account and permission to launch EC2 instances
- Ubuntu 22.04 or newer (recommended: Ubuntu Server 24.04 LTS)
- SSH key (.pem) and network access to the instance
- Internet connectivity from the instance

---

## Quick Start

1. Launch an Ubuntu EC2 instance in the AWS Console (choose Ubuntu 22.04/24.04).
2. Open SSH to your IP and obtain the instance public IP.

Connect via SSH:

```bash
ssh -i your-key.pem ubuntu@<public_ip>
```

Install git and clone the repo:

```bash
sudo apt-get update -y
sudo apt-get install -y git
git clone https://github.com/TatianaSnisarenko/dev-ops-ci-cd.git
cd dev-ops-ci-cd
git checkout lesson-3
```

Run the script:

```bash
./install_dev_tools.sh
```

---

## What the script does

- Installs Docker Engine and enables the service
- Installs Docker Compose v2 plugin (docker compose)
- Installs Python >= 3.9 (tries python3.11 / 3.10) and python3-venv
- Creates a virtual environment at `~/.venvs/devops`
- Installs Django (>= 4.2) inside the virtual environment

---

## Verify installation

Run these commands after the script completes:

```bash
docker --version
docker compose version
python3 --version
source ~/.venvs/devops/bin/activate
django-admin --version
```

If the user was added to the `docker` group, re-login (logout/login) or reboot to apply group changes.

---

## Optional: auto-activate the venv on SSH login

Append this to `~/.bashrc` to auto-activate the venv:

```bash
echo 'if [ -d "$HOME/.venvs/devops" ]; then source "$HOME/.venvs/devops/bin/activate"; fi' >> ~/.bashrc
source ~/.bashrc
```
