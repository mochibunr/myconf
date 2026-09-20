#!/bin/bash
set -e
# Support both direct and sudo invocation: use SUDO_USER's home if sudo
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  USER_HOME="$HOME"
fi
SRC="$USER_HOME/.config/performance"
ID=$(grep -E '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
ID_LIKE=$(grep -E '^ID_LIKE=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
FORCE="$1"

is_arch=false
is_debian=false
if [[ "$FORCE" == "--arch" ]]; then is_arch=true
elif [[ "$FORCE" == "--debian" ]]; then is_debian=true
elif [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == *"arch"* ]]; then is_arch=true
else is_debian=true; fi

echo "Detected: ID=$ID ID_LIKE=$ID_LIKE -> arch=$is_arch debian=$is_debian"
echo "SRC=$SRC"

# sysctl (both)
echo "-> Installing sysctl..."
sudo install -Dm644 "$SRC/sysctl.d/99-performance.conf" /etc/sysctl.d/99-performance.conf
sudo sysctl --system 2>&1 | head -30 || sudo sysctl -p /etc/sysctl.d/99-performance.conf 2>&1 | head -10

# modprobe (both)
echo "-> Installing modprobe..."
sudo install -Dm644 "$SRC/modprobe.d/99-audio-powersave.conf" /etc/modprobe.d/99-audio-powersave.conf

# zram
if $is_arch; then
  echo "-> Arch: installing zram-generator..."
  if ! pacman -Qi systemd-zram-generator >/dev/null 2>&1; then
    echo "   installing systemd-zram-generator via pacman..."
    sudo pacman -S --noconfirm systemd-zram-generator
  fi
  sudo install -Dm644 "$SRC/zram/zram-generator.conf" /etc/systemd/zram-generator.conf
  sudo systemctl daemon-reload
  sudo systemctl disable --now zramswap.service 2>/dev/null || true
  sudo systemctl enable --now systemd-zram-setup@zram0.service 2>&1 | head -5 || true
else
  echo "-> Debian: installing zram-tools..."
  if ! dpkg -l zram-tools >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y zram-tools
  fi
  sudo install -Dm644 "$SRC/zram/zramswap-debian.conf" /etc/default/zramswap
  sudo systemctl enable --now zramswap.service 2>&1 | head -5 || sudo systemctl restart zramswap.service 2>&1 | head -5
fi

# cpu governor
if $is_arch; then
  echo "-> Arch: cpupower..."
  if ! pacman -Qi cpupower >/dev/null 2>&1; then sudo pacman -S --noconfirm cpupower; fi
  sudo install -Dm644 "$SRC/cpu/cpupower-arch" /etc/default/cpupower
  sudo systemctl enable --now cpupower.service 2>&1 | head -5 || true
  sudo cpupower frequency-set -g performance 2>&1 | head -5 || true
else
  echo "-> Debian: cpufrequtils..."
  if ! dpkg -l cpufrequtils >/dev/null 2>&1; then sudo apt install -y cpufrequtils; fi
  sudo install -Dm644 "$SRC/cpu/cpufrequtils-debian" /etc/default/cpufrequtils
  sudo systemctl restart cpufrequtils 2>&1 | head -5 || true
  for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo tee "$f" >/dev/null 2>&1 || true; done
fi

# journald
echo "-> Installing journald override..."
sudo mkdir -p /etc/systemd/journald.conf.d
sudo install -Dm644 "$SRC/systemd/99-journald.conf" /etc/systemd/journald.conf.d/99-journald.conf
sudo systemctl restart systemd-journald 2>&1 | head -5 || true

# fstab noatime (both, idempotent)
if grep -q "errors=remount-ro$" /etc/fstab; then
  echo "-> Patching /etc/fstab noatime..."
  sudo cp /etc/fstab /etc/fstab.bak.$(date +%s)
  sudo sed -i 's/errors=remount-ro/errors=remount-ro,noatime/' /etc/fstab
  sudo mount -o remount / 2>&1 | head -5 || true
else echo "-> fstab already has noatime or custom"; fi

# pipewire/wireplumber (user, no sudo, already in ~/.config)
echo "-> PipeWire/WirePlumber configs already in ~/.config/pipewire & ~/.config/wireplumber"
echo "   (quantum 1024, suspend disabled) — restart with: systemctl --user restart pipewire wireplumber"

echo "Done. Verify: sysctl vm.swappiness; swapon --show; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; journalctl --disk-usage"
