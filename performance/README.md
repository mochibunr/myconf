# Performance Config — Debian/Zorin + Arch portable
# Location: ~/.config/performance/ (dotfiles friendly)
# Installer auto-detects distro

## Contents
- `sysctl.d/99-performance.conf` → /etc/sysctl.d/99-performance.conf
- `modprobe.d/99-audio-powersave.conf` → /etc/modprobe.d/99-audio-powersave.conf
- `zram/zramswap-debian.conf` → /etc/default/zramswap (zram-tools, Debian/Ubuntu/Zorin)
- `zram/zram-generator.conf` → /etc/systemd/zram-generator.conf (Arch, systemd-zram-generator)
- `cpu/cpufrequtils-debian` → /etc/default/cpufrequtils (Debian)
- `cpu/cpupower-arch` → /etc/default/cpupower (Arch)
- `systemd/99-journald.conf` → /etc/systemd/journald.conf.d/99-journald.conf
- `pipewire` / `wireplumber` already in ~/.config/pipewire & ~/.config/wireplumber (no sudo needed)

## Install
```bash
~/.config/performance/scripts/install.sh        # auto-detect
~/.config/performance/scripts/install.sh --arch   # force Arch
~/.config/performance/scripts/install.sh --debian # force Debian
```
## Apply without reboot
```bash
~/.config/performance/scripts/apply.sh
```
