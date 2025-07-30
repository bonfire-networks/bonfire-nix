#!/usr/bin/env bash
set -euo pipefail

# Usage: ./install-hetzner.sh <SERVER_IP> <ROOT_PASSWORD>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <SERVER_IP> <ROOT_PASSWORD>"
  exit 1
fi

SERVER_IP="$1"
ROOT_PASSWORD="$2"

# 1. Check/install Nix
if ! command -v nix >/dev/null 2>&1; then
  echo "Nix not found. Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# 2. Check/install nixos-anywhere
if ! nix run github:nix-community/nixos-anywhere -- --help >/dev/null 2>&1; then
  echo "nixos-anywhere not found. Installing..."
  nix profile install github:nix-community/nixos-anywhere
fi

# 3. Generate SSH key if missing
if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
  echo "No SSH key found. Generating one..."
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
fi

# 4. Install sshpass if missing (for password auth)
if ! command -v sshpass >/dev/null 2>&1; then
  echo "sshpass not found. Installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install hudochenkov/sshpass/sshpass
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y sshpass
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y sshpass
  else
    echo "Please install sshpass manually."
    exit 1
  fi
fi

# 5. Copy SSH key to server
sshpass -p "$ROOT_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no root@"$SERVER_IP"

# 6. Run nixos-anywhere
nix run github:nix-community/nixos-anywhere -- --flake github:bonfire-networks/bonfire-nix/tree/vm#nixos-vm root@"$SERVER_IP"

echo "\n✅ Done! Your Hetzner server is now running NixOS." 