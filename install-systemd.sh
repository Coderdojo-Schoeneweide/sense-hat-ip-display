#!/bin/bash

# Get the absolute path of the directory where this install script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_SCRIPT="$SCRIPT_DIR/src/sense-hat-ip-display.py"

# Check if src/sense-hat-ip-display.py exists relative to this script
if [ ! -f "$TARGET_SCRIPT" ]; then
  echo "Error: Could not find '$TARGET_SCRIPT'"
  echo "Make sure install.sh is run from the directory containing the 'src' folder."
  exit 1
fi

# Determine the actual user (even if run with sudo)
CURRENT_USER="${SUDO_USER:-$USER}"
echo "Configuring service for user: $CURRENT_USER"
echo "Target script path: $TARGET_SCRIPT"

# Detect if a virtual environment exists in the script directory
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then
  PYTHON_EXEC="$VENV_PYTHON"
  echo "Using virtual environment Python: $PYTHON_EXEC"
else
  PYTHON_EXEC="/usr/bin/python3"
  echo "No local venv found. Defaulting to system Python: $PYTHON_EXEC"
fi

SERVICE_FILE="/etc/systemd/system/sense-hat-ip.service"

echo "Creating systemd service file at $SERVICE_FILE..."

# Write the systemd unit file (prompts for sudo password here)
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Sense HAT IP Display Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
SupplementaryGroups=input video i2c

WorkingDirectory=$SCRIPT_DIR
ExecStart=$PYTHON_EXEC $TARGET_SCRIPT

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Set systemd permissions and reload
sudo chmod 644 "$SERVICE_FILE"

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable and start the service
echo "Enabling sense-hat-ip.service..."
sudo systemctl enable sense-hat-ip.service
