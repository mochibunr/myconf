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

## Cross-platform dev dependencies
```bash
~/.config/performance/scripts/detect-os.sh              # detect OS only
~/.config/performance/scripts/cross-platform.sh --help  # full installer
~/.config/performance/scripts/cross-platform.sh --dry-run --yes          # preview all
~/.config/performance/scripts/cross-platform.sh --dry-run --yes --only java,node,python  # subset
~/.config/performance/scripts/cross-platform.sh --yes    # install everything
~/.config/performance/scripts/cross-platform.sh --yes --arch --only android-rom  # force Arch, only Android ROM deps

# Categories: java,neovim,scrcpy,git,cmake,dart,node,python,curl,7zip,unzip,clang,pkg,ninja,glu,stdc,android-rom,android-kernel,sdk,base
```
- Installs Java 17-26 (SDKMAN + apt/pacman), neovim, scrcpy + pipewire fix, git, cmake, dart/flutter, node 24.16 (nvm), python 3.11, curl, 7zip, unzip, clang, pkg-config, ninja, libGLU/mesa, libstdc, Android ROM/Kernel toolchains, Android SDK + PATH
