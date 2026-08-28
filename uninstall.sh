#!/bin/bash
# Remove machine-independent Omarchy user config and restore stock templates.

set -euo pipefail

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
TEMPLATE="${OMARCHY_PATH:-/usr/share/omarchy}/config/hypr"

restore() {
  local name="$1"
  [[ -L $HYPR_DIR/$name ]] || return 0
  rm -f "$HYPR_DIR/$name"
  if [[ -f $TEMPLATE/$name ]]; then
    cp "$TEMPLATE/$name" "$HYPR_DIR/$name"
  fi
}

restore bindings.lua
restore monitors.lua

if command -v hyprctl >/dev/null && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null || true
fi

echo "Removed Omarchy user config overlay."
