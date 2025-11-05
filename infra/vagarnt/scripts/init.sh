#!/usr/bin/env bash
set -e

echo "[INIT] Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[INIT] Basic utilities install..."
sudo apt-get install -y curl wget git vim net-tools

echo "[INIT] VM setup complete."