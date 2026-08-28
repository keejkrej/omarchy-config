#!/bin/bash
# Install machine-independent Omarchy user config into the current session.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

backup() {
  local path="$1"
  [[ -e $path || -L $path ]] || return 0
  [[ -L $path ]] && return 0
  cp -a "$path" "$path.bak.$(date +%s)"
}

mkdir -p "$HYPR_DIR"

backup "$HYPR_DIR/bindings.lua"
backup "$HYPR_DIR/monitors.lua"

ln -sfn "$REPO/config/hypr/bindings.lua" "$HYPR_DIR/bindings.lua"
ln -sfn "$REPO/config/hypr/monitors.lua" "$HYPR_DIR/monitors.lua"

if command -v hyprctl >/dev/null && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null
  hyprctl configerrors
fi

echo "Installed Omarchy user config from $REPO"
echo "Hardware overlays: omarchy-zenbookduo, omarchy-razerblade"
