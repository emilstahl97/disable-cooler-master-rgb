#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

TARGET_USER="${SUDO_USER:-$USER}"
if ! TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6); then
  TARGET_HOME="$HOME"
fi
USER_BIN="$TARGET_HOME/.local/bin"

run_as_target_user() {
  local -a cmd=("$@")
  local combined_path="$USER_BIN:$PATH"
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    sudo -u "$TARGET_USER" -H env "PATH=$combined_path" "${cmd[@]}"
  else
    env "PATH=$combined_path" "${cmd[@]}"
  fi
}

export PATH="$USER_BIN:$PATH"

echo "Disable Cooler Master RGB lighting via cm-rgb (installs deps if needed)"

REQUIRED_PKGS=(
  pkg-config
  libcairo2-dev
  libgirepository1.0-dev
  libgirepository-2.0-dev
  python3-dev
  python3-venv
  build-essential
)

echo "Updating apt repositories..."
if ! sudo apt-get update; then
  echo "Warning: apt update reported issues (e.g., missing Release file); continuing with install." >&2
fi

echo "Installing required packages..."
sudo apt-get install -y "${REQUIRED_PKGS[@]}"

CM_RGB_VENV="$TARGET_HOME/.local/share/cm-rgb-venv"
run_as_target_user mkdir -p "$(dirname "$CM_RGB_VENV")"

if [[ ! -d "$CM_RGB_VENV" ]]; then
  echo "Creating venv for cm-rgb at $CM_RGB_VENV"
  run_as_target_user python3 -m venv "$CM_RGB_VENV"
fi

VENV_PIP="$CM_RGB_VENV/bin/pip"
VENV_PYTHON="$CM_RGB_VENV/bin/python"

run_as_target_user "$VENV_PIP" install --upgrade pip setuptools wheel cm-rgb

echo "Switching Cooler Master lighting to off..."
run_as_target_user "$VENV_PYTHON" - <<'PY'
from cm_rgb.ctrl import CMRGBController, LedChannel

ctrl = CMRGBController()
ctrl.enableMirage(0, 0, 0)
ctrl.assign_leds_to_channels(
    LedChannel.OFF,
    LedChannel.OFF,
    *([LedChannel.OFF] * 15),
)
ctrl.apply()
PY

echo "Cooler Master RGB lighting should now be powered down."
