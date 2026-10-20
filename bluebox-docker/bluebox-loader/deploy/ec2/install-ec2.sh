#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/bluebox-loader"
SERVICE_FILE="/etc/systemd/system/bluebox-loader.service"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Expected project directory at $APP_DIR"
  exit 1
fi

cd "$APP_DIR"
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

sudo cp deploy/ec2/bluebox-loader.service "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable bluebox-loader
sudo systemctl restart bluebox-loader

echo "Installed and started bluebox-loader service"
