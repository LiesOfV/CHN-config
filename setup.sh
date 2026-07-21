# 1 - Update

sudo pacman -Syu

# 2 - Uninstall

sudo pacman -Rns kitty dolphin firefox cachyos-firefox-settings

# 2 - Audio stack

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


# 3 - Core graphics and Vulkan

sudo pacman -S --needed --noconfirm \
  mesa \
  lib32-mesa \
  vulkan-radeon \
  lib32-vulkan-radeon \
  vulkan-icd-loader \
  lib32-vulkan-icd-loader

# 4 - Hardware video acceleration

sudo pacman -S --needed --noconfirm \
  libva \
  lib32-libva \
  libva-mesa-driver \
  lib32-libva-mesa-driver

# 5 - CPU performance optimiser

sudo pacman -S --needed --noconfirm \
  gamemode \
  lib32-gamemode

# 6 - Launcher UI, WebViews & Fonts

sudo pacman -S --needed --noconfirm \
  lib32-gtk3 \
  libxslt \
  libjpeg-turbo \
  lib32-libjpeg-turbo \
  giflib \
  lib32-giflib \
  ttf-liberation

# 7 - Steam

sudo pacman -S steam

# 8 - Flatpak

sudo pacman -S flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 9 - Flatpaks

flatpak install flathub io.gitlab.librewolf-community
flatpak install flathub com.google.Chrome
flatpak install flathub io.github.hkdb.Aerion
flatpak install flathub dev.vencord.Vesktop
flatpak install flathub community.pathofbuilding.PathOfBuilding
flatpak install flathub io.github.Faugus.faugus-launcher

# 10 - Fix steam not seeing 2nd drive due to it locking

sudo mkdir -p /mnt/games
sudo cp /etc/fstab /etc/fstab.bak

grep -q "LABEL=extradrive" /etc/fstab || \
  echo "LABEL=extradrive  /mnt/games  btrfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab

sudo mount -a
ls /mnt/games

# 11 - Auto-login 

sudo tee /etc/sddm.conf > /dev/null <<EOF
[Autologin]
Session=hyprland
User=lemon
EOF

# 12 - 

