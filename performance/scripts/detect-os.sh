#!/bin/bash
# detect-os.sh - Cross-platform OS detection (Debian/Ubuntu/Zorin, Arch, Fedora, openSUSE, macOS)
# Source this file: source ~/.config/performance/scripts/detect-os.sh && echo $OS
set -e
detect_os() {
  OS="unknown"
  OS_VERSION="unknown"
  OS_CODENAME=""
  PKG_MANAGER="unknown"
  IS_ARCH=false
  IS_DEBIAN=false
  IS_FEDORA=false
  IS_SUSE=false
  IS_MACOS=false
  IS_WSL=false

  if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=true; fi

  if [[ "$OSTYPE" == darwin* ]]; then
    OS="macos"
    OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    PKG_MANAGER="brew"
    IS_MACOS=true
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID,,}"
    OS_ID_LIKE="${ID_LIKE,,}"
    OS_VERSION="${VERSION_ID:-unknown}"
    OS_CODENAME="${VERSION_CODENAME:-$UBUNTU_CODENAME}"
    case "$OS_ID" in
      arch|manjaro|endeavouros|garuda|cachyos) OS="arch"; PKG_MANAGER="pacman"; IS_ARCH=true ;;
      debian) OS="debian"; PKG_MANAGER="apt"; IS_DEBIAN=true ;;
      ubuntu|zorin|pop|linuxmint|elementary|kali) OS="debian"; PKG_MANAGER="apt"; IS_DEBIAN=true ;;
      fedora|rhel|centos|rocky|almalinux) OS="fedora"; PKG_MANAGER="dnf"; IS_FEDORA=true ;;
      opensuse*|suse) OS="suse"; PKG_MANAGER="zypper"; IS_SUSE=true ;;
      *) 
        if [[ "$OS_ID_LIKE" == *"arch"* ]]; then OS="arch"; PKG_MANAGER="pacman"; IS_ARCH=true
        elif [[ "$OS_ID_LIKE" == *"debian"* ]] || [[ "$OS_ID_LIKE" == *"ubuntu"* ]]; then OS="debian"; PKG_MANAGER="apt"; IS_DEBIAN=true
        elif [[ "$OS_ID_LIKE" == *"fedora"* ]] || [[ "$OS_ID_LIKE" == *"rhel"* ]]; then OS="fedora"; PKG_MANAGER="dnf"; IS_FEDORA=true
        else OS="$OS_ID"; PKG_MANAGER="unknown"; fi
        ;;
    esac
  elif [ -f /etc/arch-release ]; then OS="arch"; PKG_MANAGER="pacman"; IS_ARCH=true
  elif [ -f /etc/debian_version ]; then OS="debian"; PKG_MANAGER="apt"; IS_DEBIAN=true
  fi

  export OS OS_VERSION OS_CODENAME PKG_MANAGER IS_ARCH IS_DEBIAN IS_FEDORA IS_SUSE IS_MACOS IS_WSL
}

# If run directly, print info
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  detect_os
  cat <<EOF
OS=$OS
OS_VERSION=$OS_VERSION
OS_CODENAME=$OS_CODENAME
PKG_MANAGER=$PKG_MANAGER
IS_ARCH=$IS_ARCH
IS_DEBIAN=$IS_DEBIAN
IS_FEDORA=$IS_FEDORA
IS_SUSE=$IS_SUSE
IS_MACOS=$IS_MACOS
IS_WSL=$IS_WSL
EOF
fi
