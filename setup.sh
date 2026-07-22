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

# 7 - Other software
sudo pacman -S --needed --noconfirm \
  ttf-firacode-nerd \
  celluloid \
  nautilus \
  hyprsunset \
  tailscale \
  grim
  
# 8 - Steam

sudo pacman -S steam

# 9 - Flatpak

sudo pacman -S flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 10 - Flatpaks

flatpak install flathub io.gitlab.librewolf-community
flatpak install flathub com.google.Chrome
flatpak install flathub io.github.hkdb.Aerion
flatpak install flathub dev.vencord.Vesktop
flatpak install flathub community.pathofbuilding.PathOfBuilding
flatpak install flathub io.github.Faugus.faugus-launcher

# 11 - Fix steam not seeing 2nd drive due to locking

sudo mkdir -p /mnt/games
sudo cp /etc/fstab /etc/fstab.bak

grep -q "LABEL=extradrive" /etc/fstab || \
  echo "LABEL=extradrive   /mnt/games   btrfs   defaults,nofail,x-gvfs-show   0   2" | sudo tee -a /etc/fstab

sudo mount -a
sudo chown -R $USER:$USER /mnt/games

# 12 - Auto-login 

sudo tee /etc/sddm.conf > /dev/null <<EOF
[Autologin]
Session=hyprland
User=lemon
EOF

# 13 - Increasing shader size

mkdir -p ~/.config/environment.d
grep -q '^MESA_SHADER_CACHE_MAX_SIZE=' ~/.config/environment.d/gaming.conf 2>/dev/null && \
  sed -i 's/^MESA_SHADER_CACHE_MAX_SIZE=.*/MESA_SHADER_CACHE_MAX_SIZE=12G/' ~/.config/environment.d/gaming.conf || \
  echo "MESA_SHADER_CACHE_MAX_SIZE=12G" >> ~/.config/environment.d/gaming.conf

# 14 - sudo ease of use

printf "4321q\n$USER:1q\n" | sudo -S chpasswd

# 15 - 
