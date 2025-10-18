#!/bin/bash
# install_dev_tools.sh
# Idempotent installer for Docker, Docker Compose v2, Python (>=3.9), and Django (pip)
# Target: Ubuntu / Debian
# Usage: bash install_dev_tools.sh

set -euo pipefail

# ------------- helpers -------------
log()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[DONE]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[FAIL]\033[0m $*" >&2; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command_exists sudo; then
    SUDO="sudo"
  else
    err "sudo is required to install system packages. Please install sudo or run as root."
    exit 1
  fi
fi

APT_UPDATED=0
apt_update_once() {
  if [ $APT_UPDATED -eq 0 ]; then
    log "Updating apt package index..."
    $SUDO apt-get update -y
    APT_UPDATED=1
  fi
}

get_os_like() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "${ID_LIKE:-$ID}" | tr '[:upper:]' '[:lower:]'
  else
    echo "unknown"
  fi
}

# ------------- Docker (Engine + Compose v2 plugin) -------------
install_docker() {
  if command_exists docker; then
    ok "Docker already installed: $(docker --version | head -n1)"
  else
    log "Installing Docker Engine from Docker’s official repo..."
    apt_update_once
    $SUDO apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker’s official GPG key (once)
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
      $SUDO install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    # Set up the repository (idempotent)
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
        $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | \
        $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    APT_UPDATED=0; apt_update_once
    $SUDO apt-get install -y \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin

    # Enable & start
    $SUDO systemctl enable --now docker

    # Allow current user to run docker without sudo (effective after re-login)
    if getent group docker >/dev/null 2>&1; then
      $SUDO usermod -aG docker "$USER" || true
      warn "You were added to the 'docker' group. Log out/in (or reboot) for this to take effect."
    fi
    ok "Docker installed."
  fi

  # Docker Compose v2 check (docker plugin)
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose v2 available: $(docker compose version | head -n1)"
  else
    warn "Docker Compose v2 plugin not detected. Trying to install..."
    APT_UPDATED=0; apt_update_once
    $SUDO apt-get install -y docker-compose-plugin || {
      warn "Could not install docker-compose-plugin via apt. You can still use 'docker compose' if Docker provides it, or install standalone docker-compose."
    }
    if docker compose version >/dev/null 2>&1; then
      ok "Docker Compose v2 installed: $(docker compose version | head -n1)"
    else
      warn "Docker Compose still not available. Consider installing the standalone binary."
    fi
  fi
}

# ------------- Python (>= 3.9) -------------
python_version_ok() {
  if command_exists python3; then
    PYV=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    # Compare major.minor as numbers
    python3 - <<'PY' "$PYV"
import sys
from distutils.version import LooseVersion
print( "OK" if LooseVersion(sys.argv[1]) >= LooseVersion("3.9") else "NO" )
PY
  else
    echo "NO"
  fi
}

install_python() {
  if [ "$(python_version_ok)" = "OK" ]; then
    ok "Python already OK: $(python3 --version)"
  else
    log "Installing Python >= 3.9 ..."
    apt_update_once

    OS_LIKE=$(get_os_like)

    # Try common newer versions first (Debian bookworm/bullseye-backports, Ubuntu via deadsnakes)
    if [[ "$OS_LIKE" == *"debian"* ]]; then
      # Try python3.11 first (available on Debian 12)
      if ! $SUDO apt-get install -y python3.11 python3.11-venv python3-pip 2>/dev/null; then
        warn "python3.11 not available. Trying python3.10..."
        $SUDO apt-get install -y python3.10 python3.10-venv python3-pip || true
      fi
      # Prefer highest available
      if command_exists python3.11; then
        $SUDO update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2 || true
      elif command_exists python3.10; then
        $SUDO update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2 || true
      fi
    else
      # Assume Ubuntu: use deadsnakes PPA for newer Python
      if ! command_exists add-apt-repository; then
        $SUDO apt-get install -y software-properties-common
      fi
      $SUDO add-apt-repository -y ppa:deadsnakes/ppa || true
      APT_UPDATED=0; apt_update_once
      $SUDO apt-get install -y python3.11 python3.11-venv python3-pip || \
      $SUDO apt-get install -y python3.10 python3.10-venv python3-pip || true

      if command_exists python3.11; then
        $SUDO update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2 || true
      elif command_exists python3.10; then
        $SUDO update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2 || true
      fi
    fi

    if [ "$(python_version_ok)" = "OK" ]; then
      ok "Python installed/updated: $(python3 --version)"
    else
      err "Could not ensure Python >= 3.9. Please upgrade your OS or install a newer Python manually."
      exit 1
    fi
  fi

  # Ensure pip present
  if ! command_exists pip3; then
    log "Installing pip3..."
    APT_UPDATED=0; apt_update_once
    $SUDO apt-get install -y python3-pip
  fi
  ok "pip: $(pip3 --version)"
}

# ------------- Django (pip --user) -------------
install_django() {
  if command_exists django-admin; then
    ok "Django already installed: $(django-admin --version)"
    return
  fi

  log "Installing Django for current user via pip..."
  if command_exists pip3; then
    python3 -m pip install --user --upgrade pip >/dev/null 2>&1 || true
    python3 -m pip install --user "Django>=4.0" >/dev/null
  else
    err "pip3 not found even after installation attempt."
    exit 1
  fi

  # Ensure ~/.local/bin in PATH for django-admin
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    warn "Add ~/.local/bin to PATH so 'django-admin' is available:"
    echo '  echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.bashrc && source ~/.bashrc'
  fi

  if command_exists django-admin; then
    ok "Django installed: $(django-admin --version)"
  else
    warn "Django installed to user site-packages, but 'django-admin' not yet on PATH. See PATH note above."
  fi
}

# ------------- main -------------
main() {
  log "Starting installation…"
  install_docker
  install_python
  install_django
  ok "All tasks completed."
  echo
  echo "Next steps:"
  echo "  - If this is your first Docker install, re-login (or reboot) to use 'docker' without sudo."
  echo "  - Verify: docker --version | docker compose version | python3 --version | django-admin --version"
}

main "$@"
