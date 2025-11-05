#!/usr/bin/env bash
set -e

echo "[INIT] Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[INIT] Installing basic utilities..."
sudo apt-get install -y curl wget git vim net-tools software-properties-common

echo "[INIT] Installing Ansible..."
sudo apt-get install -y ansible

echo "[INIT] VM setup complete."
