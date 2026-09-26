#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

APPLY_ONLY=0
if [[ "${1:-}" == "--apply-only" ]]; then
  APPLY_ONLY=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--apply-only]" >&2
  exit 2
fi

TARGET_USER="${SUDO_USER:-$USER}"
# systemd runs this as root with no SUDO_USER. Keep using the venv that belongs
# to whoever owns the script (the normal desktop user).
if [[ "$(id -u)" -eq 0 && -z "${SUDO_USER:-}" ]]; then
  TARGET_USER="$(stat -c '%U' "$0")"
fi
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

echo "Disable Cooler Master RGB lighting via cm-rgb"

CM_RGB_VENV="$TARGET_HOME/.local/share/cm-rgb-venv"
VENV_PIP="$CM_RGB_VENV/bin/pip"
VENV_PYTHON="$CM_RGB_VENV/bin/python"

if [[ "$APPLY_ONLY" -eq 0 ]]; then
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

  run_as_target_user mkdir -p "$(dirname "$CM_RGB_VENV")"

  if [[ ! -d "$CM_RGB_VENV" ]]; then
    echo "Creating venv for cm-rgb at $CM_RGB_VENV"
    run_as_target_user python3 -m venv "$CM_RGB_VENV"
  fi

  run_as_target_user "$VENV_PIP" install --upgrade pip setuptools wheel cm-rgb
elif [[ ! -x "$VENV_PYTHON" ]]; then
  echo "cm-rgb venv is missing at $CM_RGB_VENV. Run $0 once without --apply-only." >&2
  exit 1
fi

apply_lighting() {
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
}

if [[ "$APPLY_ONLY" -eq 1 ]]; then
  echo "Waiting for Cooler Master USB device..."
  apply_err=$(mktemp)
  trap 'rm -f "$apply_err"' EXIT
  for _ in $(seq 1 30); do
    if apply_lighting 2>"$apply_err"; then
      echo "Cooler Master RGB lighting should now be powered down."
      exit 0
    fi
    sleep 2
  done
  cat "$apply_err" >&2
  echo "Failed to power down Cooler Master lighting." >&2
  exit 1
fi

echo "Switching Cooler Master lighting to off..."
apply_lighting
echo "Cooler Master RGB lighting should now be powered down."
