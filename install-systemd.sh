#!/bin/bash

# Get the absolute path of the directory where this install script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_SCRIPT="$SCRIPT_DIR/src/sense-hat-ip-display.py"
NINJA_SCRIPT="$SCRIPT_DIR/src/run-ninja-code.sh"

# Check if src/sense-hat-ip-display.py exists relative to this script
if [ ! -f "$TARGET_SCRIPT" ]; then
  echo "Error: Could not find '$TARGET_SCRIPT'"
  echo "Make sure install.sh is run from the directory containing the 'src' folder."
  exit 1
fi

# Check if src/run-ninja-code.sh exists relative to this script
if [ ! -f "$NINJA_SCRIPT" ]; then
  echo "Error: Could not find '$NINJA_SCRIPT'"
  echo "Make sure install.sh is run from the directory containing the 'src' folder."
  exit 1
fi

# Make sure the ninja script is executable
chmod +x "$NINJA_SCRIPT"

# Determine the actual user (even if run with sudo)
CURRENT_USER="${SUDO_USER:-$USER}"
echo "Configuring services for user: $CURRENT_USER"
echo "Target script path: $TARGET_SCRIPT"
echo "Ninja script path: $NINJA_SCRIPT"

# Detect if a virtual environment exists in the script directory
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
if [ -f "$VENV_PYTHON" ]; then
  PYTHON_EXEC="$VENV_PYTHON"
  echo "Using virtual environment Python: $PYTHON_EXEC"
else
  PYTHON_EXEC="/usr/bin/python3"
  echo "No local venv found. Defaulting to system Python: $PYTHON_EXEC"
fi

# install_service <service-name> <unit-file-contents>
# Writes the unit file, reloads systemd, enables the service, and (re)starts
# it if it was already running so re-runs pick up unit changes. Safe to run
# repeatedly.
install_service() {
  local service_name="$1"
  local unit_contents="$2"
  local service_file="/etc/systemd/system/$service_name"

  echo "Creating systemd service file at $service_file..."

  # Write the systemd unit file (prompts for sudo password here)
  echo "$unit_contents" | sudo tee "$service_file" > /dev/null

  # Set systemd permissions
  sudo chmod 644 "$service_file"

  echo "Reloading systemd daemon..."
  sudo systemctl daemon-reload

  echo "Enabling $service_name..."
  sudo systemctl enable "$service_name"

  # Restart if already running so re-running this script applies changes.
  if sudo systemctl is-active --quiet "$service_name"; then
    echo "$service_name is already running, restarting to apply changes..."
    sudo systemctl restart "$service_name"
  fi
}

install_service "sense-hat-ip.service" "[Unit]
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
WantedBy=multi-user.target"

install_service "run-ninja-code.service" "[Unit]
Description=Run Ninja Code Watcher Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
SupplementaryGroups=input video i2c

WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash $NINJA_SCRIPT

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target"

echo "Done."
