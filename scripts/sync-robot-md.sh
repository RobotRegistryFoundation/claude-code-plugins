#!/usr/bin/env bash
# Refresh the copied components of plugins/robot-md from their canonical sources.
#   scripts/sync-robot-md.sh          copy canonical files into plugins/robot-md
#   scripts/sync-robot-md.sh --check  exit 1 if any copy differs (used by CI)
set -euo pipefail
cd "$(dirname "$0")/.."

MCP_REPO="${ROBOT_MD_MCP_REPO:-https://github.com/RobotRegistryFoundation/robot-md-mcp.git}"
DEST=plugins/robot-md
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git clone --quiet --depth 1 "$MCP_REPO" "$work/robot-md-mcp"

# canonical source -> copy in this plugin
pairs=(
  "$work/robot-md-mcp/skills/using-robot-md|$DEST/skills/using-robot-md"
  "$work/robot-md-mcp/commands/enable-dispatch.md|$DEST/commands/enable-dispatch.md"
  "$work/robot-md-mcp/.mcp.json|$DEST/.mcp.json"
  "plugins/bounded-embodiment/skills/bounded-embodiment|$DEST/skills/bounded-embodiment"
)

drift=0
for pair in "${pairs[@]}"; do
  src="${pair%%|*}"; dst="${pair##*|}"
  if [[ "${1:-}" == "--check" ]]; then
    if ! diff -r "$src" "$dst" >/dev/null 2>&1; then
      echo "drift: $dst differs from its canonical source"
      diff -ru "$src" "$dst" | head -40 || true
      drift=1
    fi
  else
    rm -rf "$dst"
    cp -r "$src" "$dst"
    echo "synced $dst"
  fi
done

if [[ "${1:-}" == "--check" && $drift -ne 0 ]]; then
  echo "Run scripts/sync-robot-md.sh and commit the result."
  exit 1
fi
