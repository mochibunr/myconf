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

## Cross-platform dev dependencies (PHASE 1 INSTALL → PHASE 2 TWEAKS/PATH)
```bash
~/.config/performance/scripts/detect-os.sh              # detect OS only
~/.config/performance/scripts/cross-platform.sh --list  # list 42 categories + profiles
~/.config/performance/scripts/cross-platform.sh --help  # full help
~/.config/performance/scripts/cross-platform.sh --dry-run --yes          # preview all
~/.config/performance/scripts/cross-platform.sh --dry-run --yes --only java,node,python  # subset
~/.config/performance/scripts/cross-platform.sh --yes --only shell,editors,go,rust  # new tools
~/.config/performance/scripts/cross-platform.sh --yes -i                 # interactive per-category
~/.config/performance/scripts/cross-platform.sh --yes --minimal          # base+git+utils only
~/.config/performance/scripts/cross-platform.sh --yes --dev              # dev languages + containers
~/.config/performance/scripts/cross-platform.sh --yes --android          # android rom/kernel/sdk
~/.config/performance/scripts/cross-platform.sh --yes --full             # everything
~/.config/performance/scripts/cross-platform.sh --yes --skip fonts,docs  # skip noisy
```

Categories (42): base shell editors git github-cli scrcpy cmake dart node js-tools python python-tools
  java java-tools kotlin go rust ruby php lua zig curl 7zip unzip pkg clang ninja glu stdc
  containers k8s db media net-tools docs fonts sysutils security ssh android-rom android-kernel sdk
- PHASE 1 installs only (apt/pacman/dnf/zypper/brew, rustup, SDKMAN java 17-26, nvm node 24.16, flutter clone, repo, cmdline-tools)
- PHASE 2 tweaks/PATH only (.bashrc/.zshrc): git init.defaultBranch=main, NVM_DIR, SDKMAN_DIR, cargo env, go/bin, flutter/bin, ~/.local/bin + scrcpy-fixed + pipewire quantum 1024, ANDROID_HOME/SDK_ROOT, USE_CCACHE + ~/bin, fd/bat symlinks
