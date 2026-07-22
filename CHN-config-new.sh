#!/usr/bin/env bash
#
# CachyOS post-install setup script
# Target: cachyos-hypr-noctalia (Hyprland 0.55 / Noctalia v5)
# HW: Ryzen 7 7800X3D + Radeon RX 9060 XT 16GB
#
# Usage: ./setup.sh
#
set -euo pipefail

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
# 0 - Preflight checks
# ---------------------------------------------------------------------------

sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
sudo pacman -Sy

# ---------------------------------------------------------------------------
# 1 - Update system
# ---------------------------------------------------------------------------
log "Updating system"
sudo pacman -Syu --noconfirm

# ---------------------------------------------------------------------------
# 2 - Remove unwanted defaults
# ---------------------------------------------------------------------------
log "Removing default packages"
sudo pacman -Rns --noconfirm kitty dolphin firefox cachyos-firefox-settings || \
  warn "One or more packages were not installed, skipping removal errors"

# ---------------------------------------------------------------------------
# 3 - Audio stack
# ---------------------------------------------------------------------------
log "Installing audio stack (PipeWire)"
sudo pacman -S --needed --noconfirm \
  pipewire \
  pipewire-pulse \
  pipewire-alsa \
  pipewire-jack \
  wireplumber \
  alsa-utils \
  alsa-plugins \
  lib32-pipewire \
  lib32-pipewire-jack \
  lib32-alsa-plugins \
  lib32-mpg123 \
  openal \
  lib32-openal \
  mpg123

# ---------------------------------------------------------------------------
# 4 - Core graphics and Vulkan (RDNA4 / RX 9060 XT)
# ---------------------------------------------------------------------------
log "Installing graphics and Vulkan stack"
sudo pacman -S --needed --noconfirm \
  mesa \
  lib32-mesa \
  vulkan-radeon \
  lib32-vulkan-radeon \
  vulkan-icd-loader \
  lib32-vulkan-icd-loader

# ---------------------------------------------------------------------------
# 5 - Hardware video acceleration
# ---------------------------------------------------------------------------
log "Installing VA-API stack"
sudo pacman -S --needed --noconfirm \
  libva \
  lib32-libva \
  libva-mesa-driver \
  lib32-libva-mesa-driver

# ---------------------------------------------------------------------------
# 6 - CPU performance optimiser
# ---------------------------------------------------------------------------
log "Installing GameMode"
sudo pacman -S --needed --noconfirm \
  gamemode \
  lib32-gamemode

# ---------------------------------------------------------------------------
# 7 - Launcher UI, WebViews & Fonts
# ---------------------------------------------------------------------------
log "Installing launcher UI/WebView/font dependencies"
sudo pacman -S --needed --noconfirm \
  lib32-gtk3 \
  libxslt \
  libjpeg-turbo \
  lib32-libjpeg-turbo \
  giflib \
  lib32-giflib \
  ttf-liberation

# ---------------------------------------------------------------------------
# 8 - Other software
# ---------------------------------------------------------------------------
log "Installing miscellaneous applications"
sudo pacman -S --needed --noconfirm \
  ttf-firacode-nerd \
  celluloid \
  nautilus \
  hyprsunset \
  tailscale \
  grim

# ---------------------------------------------------------------------------
# 9 - Steam
# ---------------------------------------------------------------------------
log "Installing Steam"
sudo pacman -S --needed --noconfirm steam

# ---------------------------------------------------------------------------
# 10 - Flatpak
# ---------------------------------------------------------------------------
log "Installing Flatpak and adding Flathub remote"
sudo pacman -S --needed --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ---------------------------------------------------------------------------
# 11 - Flatpaks
# ---------------------------------------------------------------------------
log "Installing Flatpak applications"
flatpak install -y --noninteractive flathub io.gitlab.librewolf-community
flatpak install -y --noninteractive flathub com.google.Chrome
flatpak install -y --noninteractive flathub io.github.hkdb.Aerion
flatpak install -y --noninteractive flathub dev.vencord.Vesktop
flatpak install -y --noninteractive flathub community.pathofbuilding.PathOfBuilding
flatpak install -y --noninteractive flathub io.github.Faugus.faugus-launcher
flatpak install -y --noninteractive flathub org.gimp.GIMP

# ---------------------------------------------------------------------------
# 12 - Fix Steam not seeing 2nd drive (mount + permissions)
# ---------------------------------------------------------------------------
log "Configuring second drive mount (/mnt/games)"
sudo mkdir -p /mnt/games

grep -q "LABEL=extradrive" /etc/fstab || \
  echo "LABEL=extradrive   /mnt/games   btrfs   defaults,nofail,x-gvfs-show   0   2" | sudo tee -a /etc/fstab

if mountpoint -q /mnt/games; then
  log "/mnt/games already mounted, skipping"
else
  sudo mount -a
fi
sudo chown -R "$USER:$USER" /mnt/games

# ---------------------------------------------------------------------------
# 13 - Auto-login
# ---------------------------------------------------------------------------
# sddm.conf.d drop-ins load BEFORE /etc/sddm.conf, and /etc/sddm.conf wins
# for any key it already defines - so if the base file already has a
# (blank) User= line, a drop-in alone would be silently ignored. Editing
# the existing file in place is what actually works. This only touches
# the two lines it needs to; everything else in the file is left alone.
log "Configuring SDDM autologin for user: $USER"
SDDM_CONF=/etc/sddm.conf
sudo touch "$SDDM_CONF"

if grep -q '^\[Autologin\]' "$SDDM_CONF"; then
  if grep -q '^User=' "$SDDM_CONF"; then
    sudo sed -i "s/^User=.*/User=$USER/" "$SDDM_CONF"
  else
    sudo sed -i "/^\[Autologin\]/a User=$USER" "$SDDM_CONF"
  fi
  if grep -q '^Session=' "$SDDM_CONF"; then
    sudo sed -i "s/^Session=.*/Session=hyprland/" "$SDDM_CONF"
  else
    sudo sed -i "/^\[Autologin\]/a Session=hyprland" "$SDDM_CONF"
  fi
else
  printf '\n[Autologin]\nSession=hyprland\nUser=%s\n' "$USER" | sudo tee -a "$SDDM_CONF" > /dev/null
fi

# ---------------------------------------------------------------------------
# 14 - Increase shader cache size
# ---------------------------------------------------------------------------
log "Setting MESA shader cache size"
mkdir -p ~/.config/environment.d
if grep -q '^MESA_SHADER_CACHE_MAX_SIZE=' ~/.config/environment.d/gaming.conf 2>/dev/null; then
  sed -i 's/^MESA_SHADER_CACHE_MAX_SIZE=.*/MESA_SHADER_CACHE_MAX_SIZE=12G/' ~/.config/environment.d/gaming.conf
else
  echo "MESA_SHADER_CACHE_MAX_SIZE=12G" >> ~/.config/environment.d/gaming.conf
fi

# ---------------------------------------------------------------------------
# 15 - Kernel optimizations
# ---------------------------------------------------------------------------
log "Applying sysctl kernel tweaks"
if ! sudo grep -q "^vm.swappiness=" /etc/sysctl.conf; then
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
else
    sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=10/' /etc/sysctl.conf
fi

if ! sudo grep -q "^kernel.sysrq=" /etc/sysctl.conf; then
    echo 'kernel.sysrq=1' | sudo tee -a /etc/sysctl.conf
else
    sudo sed -i 's/^kernel.sysrq=.*/kernel.sysrq=1/' /etc/sysctl.conf
fi

sudo sysctl -p

# ---------------------------------------------------------------------------
# 16 - Disable auto-mute so speakers work
# ---------------------------------------------------------------------------
# Instead of a hardcoded card name (which can shift between installs),
# loop over every ALSA card actually present and try the control on each.
# Cards that don't have this mixer control just fail silently.
log "Disabling Auto-Mute Mode on all detected ALSA cards"
mapfile -t CARDS < <(aplay -l 2>/dev/null | awk -F'[ :]' '/^card/ {print $2}')
if [ "${#CARDS[@]}" -eq 0 ]; then
  warn "No ALSA cards detected, skipping Auto-Mute step."
else
  for card in "${CARDS[@]}"; do
    if amixer -c "$card" sset "Auto-Mute Mode" Disabled >/dev/null 2>&1; then
      log "Disabled Auto-Mute Mode on card $card"
    fi
  done
fi

sudo alsactl store

# ---------------------------------------------------------------------------
# 17 - Final sync: catch anything mid-script left half-updated
# ---------------------------------------------------------------------------
log "Running final pacman + flatpak update pass"
sudo pacman -Syu --noconfirm
flatpak update -y --noninteractive

# ---------------------------------------------------------------------------
# 18 - Set sudo/user password (interactive, run last on purpose)
# ---------------------------------------------------------------------------
# Run last so it doesn't block the rest of setup if you want to walk away.
# chpasswd (used here) does not go through the CachyOS installer's password
# strength wizard, so a short password like "1q" will go through fine -
# just be aware it's genuinely weak from a security standpoint.
# Reads from /dev/tty explicitly rather than stdin. If this script is ever
# run via `curl ... | bash`, stdin is the pipe, not your keyboard - a plain
# `read` would get EOF immediately and NEWPASS would end up empty, which
# chpasswd would happily accept, leaving the account with NO password.
log "Setting user password for $USER"
while true; do
  read -r -s -p "Enter new password for $USER: " NEWPASS < /dev/tty; echo
  if [ -z "$NEWPASS" ]; then
    warn "Password cannot be empty."
    continue
  fi
  read -r -s -p "Confirm password: " NEWPASS_CONFIRM < /dev/tty; echo
  if [ "$NEWPASS" != "$NEWPASS_CONFIRM" ]; then
    warn "Passwords did not match, try again."
    continue
  fi
  break
done
printf "%s:%s\n" "$USER" "$NEWPASS" | sudo chpasswd
unset NEWPASS NEWPASS_CONFIRM

log "Setup complete."
