source /usr/share/cachyos-fish-config/cachyos-config.fish

# Custom update alias (overrides CachyOS mirror-ranking version)
alias update='sudo pacman -Syu && flatpak update -y'

# Stop shrinking folder names in the prompt
set -g fish_prompt_pwd_dir_length 0


# overwrite greeting
# potentially disabling fastfetch
function fish_greeting

set -l hypr_ver (hyprctl version 2>/dev/null | head -n 1 | string match -r -o '[0-9]+\.[0-9]+(\.[0-9]+)?')
set -l noctalia_ver (noctalia --version 2>/dev/null)
set -l cachy_kernel (uname -r)

echo "CachyOS:  Kernel $cachy_kernel (x86-64-v4)"
echo "Hyprland: $hypr_ver"
echo "Noctalia: $noctalia_ver"

end

set -gx EZA_COLORS "uu=38;2;87;242;201"

# Override prompt to display user@hostname directory ❯
function fish_prompt
    echo -n (set_color 57F2C9)"$USER"
    echo -n (set_color white)"@"
    echo -n (set_color -o 00C3FF)(prompt_hostname)" "
    echo -n (set_color -o 00C3FF)(prompt_pwd)
    echo -n (set_color -o 57F2C9)" ❯ "(set_color normal)
end

alias s='pactl set-sink-port alsa_output.pci-0000_11_00.6.analog-stereo analog-output-lineout'
alias h='pactl set-sink-port alsa_output.pci-0000_11_00.6.analog-stereo analog-output-headphones'
