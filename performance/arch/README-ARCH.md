# Arch Support

## Differences from Debian/Zorin

| Feature | Debian/Zorin | Arch |
|---|---|---|
| zram | `zram-tools` + `/etc/default/zramswap` (ALGO=zstd PERCENT=50) | `systemd-zram-generator` + `/etc/systemd/zram-generator.conf` |
| cpu governor | `cpufrequtils` + `/etc/default/cpufrequtils` GOVERNOR=performance | `cpupower` + `/etc/default/cpupower` governor=performance |
| package install | `apt` | `pacman -S` |
| preload | `preload` (apt) | AUR `preload` or `systemd` readahead |
| journal | `/etc/systemd/journald.conf.d/99-journald.conf` (same) | same |
| pipewire | `~/.config/pipewire/pipewire.conf.d/` (same) | same, Arch uses pipewire 1.2+ |
| modprobe | `/etc/modprobe.d/` (same) | same |

## On Arch, install with:
```bash
~/.config/performance/scripts/install.sh --arch
```
Or auto-detect (checks /etc/os-release ID=arch):
```bash
~/.config/performance/scripts/install.sh
```

## Manual Arch steps if script not used:
```bash
sudo pacman -S systemd-zram-generator cpupower
sudo cp ~/.config/performance/zram/zram-generator.conf /etc/systemd/zram-generator.conf
sudo cp ~/.config/performance/cpu/cpupower-arch /etc/default/cpupower
sudo cp ~/.config/performance/sysctl.d/99-performance.conf /etc/sysctl.d/
sudo cp ~/.config/performance/modprobe.d/99-audio-powersave.conf /etc/modprobe.d/
sudo systemctl daemon-reload && sudo systemctl restart systemd-zram-setup@zram0
sudo systemctl enable --now cpupower
sudo sysctl --system
```
