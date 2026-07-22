#!/usr/bin/env bash
set -euo pipefail

BASE="https://raw.githubusercontent.com/LiesOfV/CHN-config/refs/heads/main"

# format: "repo-path|destination-path"
# NOTE: the "~" on the left side of each "|" is a LITERAL folder name in the
# repo (LiesOfV/CHN-config actually has a directory named "~"), not a home-dir
# shortcut -- it is intentionally left unexpanded. Only the right side (after
# "|") uses $HOME, which is correct. See: https://www.shellcheck.net/wiki/SC2088

# shellcheck disable=SC2088
FILES=(
  "~/.config/fish/config.fish|$HOME/.config/fish/config.fish"
  "~/.config/alacritty/alacritty.toml|$HOME/.config/alacritty/alacritty.toml"
  "~/.config/noctalia/config.toml|$HOME/.config/noctalia/config.toml"
  "~/.config/hypr/config/animations.lua|$HOME/.config/hypr/config/animations.lua"
  "~/.config/hypr/config/autostart.lua|$HOME/.config/hypr/config/autostart.lua"
  "~/.config/hypr/config/binds.lua|$HOME/.config/hypr/config/binds.lua"
  "~/.config/hypr/config/misc.lua|$HOME/.config/hypr/config/misc.lua"
  "~/.config/hypr/config/monitors.lua|$HOME/.config/hypr/config/monitors.lua"
  "~/.config/hypr/config/variables.lua|$HOME/.config/hypr/config/variables.lua"
  "~/.config/hypr/config/windowrules.lua|$HOME/.config/hypr/config/windowrules.lua"
)

ok=0
fail=0
failed_names=()
tmp=""

cleanup() {
  if [[ -n "$tmp" && -f "$tmp" ]]; then
    rm -f "$tmp"
  fi
  return 0
}
trap cleanup EXIT INT TERM

for entry in "${FILES[@]}"; do
  src="${entry%%|*}"
  dest="${entry##*|}"
  label="${dest#"$HOME"/}"

  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"

  tmp="$(mktemp "$dest_dir/.sync-tmp.XXXXXX")"

  if curl -fsSL --retry 2 --retry-delay 1 -o "$tmp" "$BASE/$src"; then
    mv "$tmp" "$dest"
    echo "OK   $label"
    ok=$((ok + 1))
  else
    echo "FAIL $label (download error, left untouched)" >&2
    rm -f "$tmp"
    fail=$((fail + 1))
    failed_names+=("$label")
  fi
done

echo ""
echo "Synced $ok/${#FILES[@]} files."
if [[ $fail -gt 0 ]]; then
  echo "Failed:"
  printf '  - %s\n' "${failed_names[@]}"
  exit 1
fi
