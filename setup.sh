# 1 - Audio stack

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


# 2 - Core graphics and Vulkan

sudo pacman -S --needed --noconfirm \
  mesa \
  lib32-mesa \
  vulkan-radeon \
  lib32-vulkan-radeon \
  vulkan-icd-loader \
  lib32-vulkan-icd-loader

# 3 - Hardware video acceleration

sudo pacman -S --needed --noconfirm \
  libva \
  lib32-libva \
  libva-mesa-driver \
  lib32-libva-mesa-driver

# 4 - CPU performance optimiser

sudo pacman -S --needed --noconfirm \
  gamemode \
  lib32-gamemode

# 5 - Launcher UI, WebViews & Fonts

sudo pacman -S --needed --noconfirm \
  lib32-gtk3 \
  libxslt \
  libjpeg-turbo \
  lib32-libjpeg-turbo \
  giflib \
  lib32-giflib \
  ttf-liberation
