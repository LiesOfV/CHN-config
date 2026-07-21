#!/usr/bin/env bash
# ^ "shebang" line. Tells the system to run this file using bash specifically,
#   found via the $PATH (env), rather than assuming a fixed location like
#   /bin/bash. Every executable script starts with a line like this.

# sync-chn-config.sh
# Pulls dotfiles from LiesOfV/CHN-config and drops them into place.
# Edit the FILES list below whenever you add/remove files from the repo.

set -euo pipefail
# ^ Three safety switches bundled together, each one a flag:
#   -e : if ANY command fails (non-zero exit code), stop the whole script
#        immediately instead of barrelling on with a half-done job.
#   -u : if the script references a variable that was never set (typo'd
#        name, etc.), error out instead of silently treating it as "".
#   -o pipefail : normally in bash only the LAST command in a pipe (cmd1 |
#        cmd2) decides success/failure. This makes a failure ANYWHERE in
#        the pipe count as a failure. We don't use pipes here, but it's
#        good habit to always include it.

BASE="https://raw.githubusercontent.com/LiesOfV/CHN-config/refs/heads/main"
# ^ A regular variable. No spaces around "=" in bash - that's mandatory
#   syntax, not style. BASE="x" works, BASE = "x" is a syntax error.

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
  "~/.config/hypr/config/autostart.lua|$HOME/.config/hypr/config/autostart.lua"
  "~/.config/hypr/config/binds.lua|$HOME/.config/hypr/config/binds.lua"
  "~/.config/hypr/config/misc.lua|$HOME/.config/hypr/config/misc.lua"
  "~/.config/hypr/config/monitors.lua|$HOME/.config/hypr/config/monitors.lua"
  "~/.config/hypr/config/variables.lua|$HOME/.config/hypr/config/variables.lua"
)
# ^ FILES=( ... ) declares an ARRAY - a list of items, here one string per
#   line. Each string packs two pieces of info into one line using "|" as
#   a separator, so we don't need two parallel arrays that could drift out
#   of sync. We split each entry back apart down in the loop below.

# --- running totals, updated as the loop below goes ---
ok=0            # how many files downloaded successfully
fail=0          # how many files failed
failed_names=() # empty array - we'll push failed filenames onto this as we go
tmp=""          # tracks whatever temp file is currently in flight, for the trap below

# if the script is interrupted (Ctrl+C, killed, terminal closed) mid-download,
# delete whatever temp file was in progress instead of leaving it orphaned
cleanup() {
  if [[ -n "$tmp" && -f "$tmp" ]]; then
    # -n "$tmp"   -> true if $tmp is a non-empty string (i.e. we were mid-download)
    # -f "$tmp"   -> true if that path actually exists as a file on disk
    rm -f "$tmp"
  fi
  return 0
  # ^ explicitly return success (0) no matter what happened above.
  #   Without this, if the "if" was false, the function's own exit status
  #   would be non-zero, and because of "set -e" that would get mistaken
  #   for the WHOLE SCRIPT failing, even on a totally successful run.
}
trap cleanup EXIT INT TERM
# ^ "trap" registers cleanup() to auto-run when any of these happen:
#   EXIT = the script is ending, for ANY reason (normal finish or error)
#   INT  = you pressed Ctrl+C
#   TERM = something sent the process a "please stop" signal (e.g. closing
#          the terminal window, or another program asking it to quit)

for entry in "${FILES[@]}"; do
  # ^ "${FILES[@]}" expands to every item in the array, each kept as one
  #   whole word even if it contained spaces (the quotes matter for that).
  #   This loop runs once per line in FILES, top to bottom.

  src="${entry%%|*}"
  # ^ "%%|*" strips the LONGEST match of "|" onwards from the END,
  #   leaving everything BEFORE the first "|". This is how we pull the
  #   repo-path half back out of "repo-path|destination-path".

  dest="${entry##*|}"
  # ^ "##*|" strips the LONGEST match of "everything up to |" from the
  #   FRONT, leaving whatever comes AFTER the last "|" - the destination half.

  label="${dest#"$HOME"/}"
  # ^ "#" strips a SHORT prefix match from the front (unlike "##" above).
  #   This just removes "$HOME/" from the start of the path, purely so the
  #   printed output reads ".config/fish/config.fish" instead of the full
  #   "/home/you/.config/fish/config.fish" - cosmetic only.

  dest_dir="$(dirname "$dest")"
  # ^ dirname strips the filename off a path, leaving just the folder.
  #   e.g. dirname "/home/you/.config/fish/config.fish" -> "/home/you/.config/fish"
  #   $(...) runs a command and captures its output into the variable.

  mkdir -p "$dest_dir"
  # ^ create that folder if it doesn't exist yet. -p also creates any
  #   missing PARENT folders along the way, and does nothing (no error)
  #   if the folder is already there - important for a fresh install
  #   where none of ~/.config/hypr/config/ etc. exist yet.

  # download to a temp file in the SAME directory as dest, so the final
  # mv is an atomic rename on the same filesystem, not a copy+delete
  tmp="$(mktemp "$dest_dir/.sync-tmp.XXXXXX")"
  # ^ mktemp creates a new, guaranteed-unique, empty file right now and
  #   gives us its name. The XXXXXX gets replaced with random characters
  #   so two files never collide, even if the script somehow ran twice
  #   at once. The leading "." makes it a hidden file.

  if curl -fsSL --retry 2 --retry-delay 1 -o "$tmp" "$BASE/$src"; then
    # curl flags used here:
    #   -f  fail silently on HTTP errors (404 etc.) instead of saving an
    #       error page as if it were the real file
    #   -s  silent mode - don't print curl's normal progress bar/stats
    #   -S  but DO still show the error message if something goes wrong
    #       (this pairs with -s: quiet on success, loud on failure)
    #   -L  follow redirects, in case the URL ever gets redirected
    #   --retry 2 --retry-delay 1  -> if the download fails, wait 1 second
    #       and try again, up to 2 extra attempts, before giving up
    #   -o "$tmp"  write the output to our temp file, not straight to $dest
    #
    # This whole line is a condition for the "if": curl's own exit code
    # (0 = success, anything else = failure) decides which branch runs.

    mv "$tmp" "$dest"
    # ^ only reached if curl succeeded. Renames the temp file to the real
    #   destination name. On the same filesystem this is instant and
    #   atomic - there's no moment where $dest is half-written.

    echo "OK   $label"
    ok=$((ok + 1))
    # ^ $(( )) is arithmetic in bash. This just adds 1 to the ok counter.

  else
    echo "FAIL $label (download error, left untouched)" >&2
    # ^ >&2 sends this line to "stderr" (the error stream) instead of
    #   normal output (stdout). That's the convention for error messages -
    #   it means someone could redirect normal output to a log file while
    #   still seeing errors on screen, for example.

    rm -f "$tmp"
    # ^ curl failed, so throw away whatever partial/empty file it left in tmp.

    fail=$((fail + 1))
    failed_names+=("$label")
    # ^ += appends onto the end of an array instead of replacing it.
  fi
done

echo ""
echo "Synced $ok/${#FILES[@]} files."
# ^ ${#FILES[@]} is special syntax meaning "how many items are in the
#   FILES array" - here that's 8. Not the same as ${FILES[@]}, which
#   would expand to the actual items.

if [[ $fail -gt 0 ]]; then
  echo "Failed:"
  printf '  - %s\n' "${failed_names[@]}"
  # ^ printf repeats its format string once per argument given to it.
  #   So this prints one "  - filename" line for every entry in
  #   failed_names, without needing a manual loop.

  exit 1
  # ^ exit with a non-zero code so anything checking "$?" afterwards
  #   (or you, glancing at the terminal) knows something went wrong.
fi
