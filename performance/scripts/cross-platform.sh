#!/bin/bash
# cross-platform.sh - Cross-platform dev dependencies installer
# Supports: Arch, Debian/Ubuntu/Zorin, Fedora, openSUSE, macOS
# Installs: java 17-26, neovim, scrcpy, git, cmake, dart/flutter, node 24.16, python 3.11, curl, 7zip, unzip, clang, pkg-config, ninja, libGLU, libstdc, Android ROM/Kernel deps, Android SDK PATH
# Usage: bash ~/.config/performance/scripts/cross-platform.sh [--dry-run] [--yes] [--only java,node] [--arch|--debian|--fedora|--macos]
# Location: ~/.config/performance/scripts/cross-platform.sh

set -e
# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }
info() { echo -e "${BLUE}[*]${NC} $*"; }

DRY_RUN=false
AUTO_YES=false
ONLY=""
FORCE_OS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --yes|-y) AUTO_YES=true; shift ;;
    --only)
      ONLY="$2"
      shift 2
      ;;
    --only=*) ONLY="${1#--only=}"; shift ;;
    --arch) FORCE_OS="arch"; shift ;;
    --debian) FORCE_OS="debian"; shift ;;
    --fedora) FORCE_OS="fedora"; shift ;;
    --macos) FORCE_OS="macos"; shift ;;
    --help|-h) cat <<EOF
Usage: $0 [options]
  --dry-run        Show what would be installed
  --yes            Auto yes, no prompt
  --only a,b,c     Only install categories: java,neovim,scrcpy,git,cmake,dart,node,python,curl,7zip,unzip,clang,pkg,ninja,glu,stdc,android-rom,android-kernel,sdk,base
  --arch/--debian/--fedora/--macos  Force OS detection
  --help           Show this help
EOF
    exit 0 ;;
    *) shift ;;
  esac
done

# Source detect-os.sh if exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/detect-os.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/detect-os.sh"
  detect_os
else
  # Inline fallback
  if [ -f /etc/os-release ]; then . /etc/os-release; OS_ID=${ID,,}; OS_ID_LIKE=${ID_LIKE,,}; else OS_ID="unknown"; fi
  if [[ "$OSTYPE" == darwin* ]]; then OS="macos"; else case "$OS_ID" in arch*) OS="arch";; debian|ubuntu|zorin*) OS="debian";; fedora*) OS="fedora";; *) OS="$OS_ID";; esac; fi
fi

# Override if forced
if [ -n "$FORCE_OS" ]; then OS="$FORCE_OS"; fi
# Normalize
case "$OS" in
  arch|manjaro|endeavouros) PKG="pacman" ;;
  debian|ubuntu|zorin) PKG="apt" ;;
  fedora|rhel|centos) PKG="dnf" ;;
  suse|opensuse) PKG="zypper" ;;
  macos|darwin) PKG="brew" ;;
  *) PKG="unknown" ;;
esac

log "Detected OS: $OS (PKG: $PKG) FORCE=$FORCE_OS DRY=$DRY_RUN"
if [ "$OS" = "unknown" ]; then warn "Unknown OS, trying apt/pacman fallback"; fi

# Helper: check if category should run
should_run() {
  local cat="$1"
  if [ -z "$ONLY" ]; then return 0; fi
  IFS=',' read -ra ONLY_ARR <<< "$ONLY"
  for o in "${ONLY_ARR[@]}"; do if [ "$o" = "$cat" ]; then return 0; fi; done
  return 1
}

run() {
  if $DRY_RUN; then echo -e "${CYAN}[DRY]${NC} $*"; else eval "$@"; fi
}

# Wrapper for package install
install_pkg() {
  local pkgs=("$@")
  if [ ${#pkgs[@]} -eq 0 ]; then return 0; fi
  case "$PKG" in
    apt)
      if $DRY_RUN; then echo "[DRY] sudo apt install -y ${pkgs[*]}"; else sudo apt update -qq 2>&1 | tail -5; sudo apt install -y "${pkgs[@]}" 2>&1 | tail -20; fi
      ;;
    pacman)
      if $DRY_RUN; then echo "[DRY] sudo pacman -S --noconfirm ${pkgs[*]}"; else sudo pacman -S --noconfirm "${pkgs[@]}" 2>&1 | tail -20; fi
      ;;
    dnf)
      if $DRY_RUN; then echo "[DRY] sudo dnf install -y ${pkgs[*]}"; else sudo dnf install -y "${pkgs[@]}" 2>&1 | tail -20; fi
      ;;
    zypper)
      if $DRY_RUN; then echo "[DRY] sudo zypper install -y ${pkgs[*]}"; else sudo zypper install -y "${pkgs[@]}" 2>&1 | tail -20; fi
      ;;
    brew)
      if $DRY_RUN; then echo "[DRY] brew install ${pkgs[*]}"; else brew install "${pkgs[@]}" 2>&1 | tail -20; fi
      ;;
    *) err "Unknown package manager $PKG, skipping ${pkgs[*]}"; return 1 ;;
  esac
}

# Confirm
if ! $AUTO_YES && ! $DRY_RUN; then
  echo -e "${YELLOW}This will install many packages for $OS ($PKG). Continue? [Y/n]${NC}"
  read -r ans; if [[ "$ans" == n* || "$ans" == N* ]]; then exit 1; fi
fi

### 1. BASE ###
if should_run base; then
  log "=== BASE: git curl wget ca-certificates ==="
  case "$PKG" in
    apt) install_pkg git curl wget ca-certificates gnupg lsb-release software-properties-common apt-transport-https ;;
    pacman) install_pkg git curl wget ca-certificates gnupg base-devel ;;
    dnf) install_pkg git curl wget ca-certificates gnupg2 ;;
    brew) install_pkg git curl wget ca-certificates gnupg ;;
  esac
fi

### 2. CURL / UNZIP / 7ZIP ###
if should_run curl; then log "=== CURL ==="; case "$PKG" in apt) install_pkg curl ;; pacman) install_pkg curl ;; dnf) install_pkg curl ;; brew) install_pkg curl ;; esac; fi
if should_run unzip; then log "=== UNZIP ==="; case "$PKG" in apt) install_pkg unzip zip ;; pacman) install_pkg unzip zip ;; dnf) install_pkg unzip zip ;; brew) install_pkg unzip ;; esac; fi
if should_run 7zip; then
  log "=== 7ZIP ==="
  case "$PKG" in
    apt) install_pkg p7zip-full p7zip ;;
    pacman) install_pkg p7zip ;;
    dnf) install_pkg p7zip p7zip-plugins ;;
    brew) install_pkg p7zip ;;
  esac
fi

### 3. PKG-CONFIG / CLANG / NINJA / CMAKE / GLU / STDC ###
if should_run pkg; then
  log "=== PKG-CONFIG ==="
  case "$PKG" in apt) install_pkg pkg-config ;; pacman) install_pkg pkgconf ;; dnf) install_pkg pkgconf-pkg-config ;; brew) install_pkg pkg-config ;; esac
fi
if should_run clang; then
  log "=== CLANG / LLVM ==="
  case "$PKG" in
    apt) install_pkg clang lld lldb clang-format clang-tidy llvm ;;
    pacman) install_pkg clang lld llvm ;;
    dnf) install_pkg clang lld llvm ;;
    brew) install_pkg llvm ;;
  esac
fi
if should_run ninja; then
  log "=== NINJA ==="
  case "$PKG" in apt) install_pkg ninja-build ;; pacman) install_pkg ninja ;; dnf) install_pkg ninja-build ;; brew) install_pkg ninja ;; esac
fi
if should_run cmake; then
  log "=== CMAKE ==="
  case "$PKG" in apt) install_pkg cmake cmake-extras extra-cmake-modules ;; pacman) install_pkg cmake ;; dnf) install_pkg cmake ;; brew) install_pkg cmake ;; esac
fi
if should_run glu; then
  log "=== LIBGLU / MESA ==="
  case "$PKG" in
    apt) install_pkg libglu1-mesa-dev libgl1-mesa-dev mesa-common-dev libglx-dev libgl-dev freeglut3-dev ;;
    pacman) install_pkg glu mesa libglvnd freeglut ;;
    dnf) install_pkg mesa-libGLU mesa-libGL-devel freeglut-devel ;;
    brew) install_pkg mesa glu freeglut ;;
  esac
fi
if should_run stdc; then
  log "=== LIBSTDC ==="
  case "$PKG" in
    apt) install_pkg libstdc++6 libstdc++-12-dev build-essential g++ gcc-multilib ;;
    pacman) install_pkg gcc-libs lib32-gcc-libs ;;
    dnf) install_pkg libstdc++ libstdc++-devel gcc-c++ ;;
    brew) install_pkg gcc ;;
  esac
fi

### 4. PYTHON 3.11 ###
if should_run python; then
  log "=== PYTHON 3.11 ==="
  case "$PKG" in
    apt)
      # Ubuntu 24.04 (noble) has python3.11 in deadsnakes or as python3.11
      install_pkg python3.11 python3.11-dev python3.11-venv python3-pip python3-setuptools python-is-python3 || install_pkg python3 python3-dev python3-venv python3-pip
      run "python3.11 --version 2>&1 | head -5 || python3 --version"
      ;;
    pacman) install_pkg python python-pip python-setuptools python-virtualenv ;;
    dnf) install_pkg python3.11 python3-pip python3-devel ;;
    brew) install_pkg python@3.11 ;;
  esac
  # Ensure pipx / poetry optional
  if ! $DRY_RUN; then python3 -m pip install --user --upgrade pip 2>&1 | tail -5 || true; fi
fi

### 5. NODE 24.16 ###
if should_run node; then
  log "=== NODE 24.16 (via nvm) ==="
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    if $DRY_RUN; then echo "[DRY] curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"; else curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>&1 | tail -10; fi
  fi
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
    if $DRY_RUN; then echo "[DRY] nvm install 24.16.0 && nvm alias default 24.16.0"; else nvm install 24.16.0 2>&1 | tail -10; nvm alias default 24.16.0 2>&1 | tail -5; nvm use 24.16.0 2>&1 | tail -5; node --version; npm --version; fi
  else
    warn "nvm not found, trying system node"
    case "$PKG" in apt) install_pkg nodejs npm ;; pacman) install_pkg nodejs npm ;; dnf) install_pkg nodejs npm ;; brew) install_pkg node@24 ;; esac
  fi
fi

### 6. JAVA 17-26 ###
if should_run java; then
  log "=== JAVA 17-26 (Temurin via SDKMAN + apt/pacman fallback) ==="
  # Install SDKMAN if not exists (cross-platform, works on Linux/macOS)
  if [ ! -d "$HOME/.sdkman" ]; then
    if $DRY_RUN; then echo "[DRY] curl -s https://get.sdkman.io | bash"; else curl -s "https://get.sdkman.io" | bash 2>&1 | tail -10; fi
  fi
  # Source SDKMAN
  if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.sdkman/bin/sdkman-init.sh"
  fi
  # Try SDKMAN for all versions, fallback to apt/pacman
  for V in 17 18 19 20 21 22 23 24 25 26; do
    CANDIDATE="java"
    # Map to Temurin identifier; SDKMAN uses e.g., 17.0.9-tem, but '17-tem' works for latest
    TEM_ID="${V}-tem"
    # Check if already installed via sdkman
    if command -v sdk >/dev/null 2>&1; then
      if sdk list java 2>&1 | grep -q "${V}.*tem" || true; then
        if $DRY_RUN; then echo "[DRY] sdk install java $TEM_ID"; else sdk install java "$TEM_ID" 2>&1 | tail -10 || warn "sdk install java $TEM_ID failed"; fi
      else
        warn "Java $V not found in SDKMAN candidate, trying apt/pacman"
      fi
    fi
    # Fallback apt/pacman for available versions (17, 21 are in noble)
    case "$PKG" in
      apt)
        # noble has 17,21; 8,11,17,21 available. Others via SDKMAN only
        if [[ "$V" == "17" || "$V" == "21" ]]; then
          if $DRY_RUN; then echo "[DRY] sudo apt install -y openjdk-${V}-jdk"; else sudo apt install -y "openjdk-${V}-jdk" 2>&1 | tail -10 || true; fi
        fi
        ;;
      pacman)
        # Arch: jdk17-openjdk, jdk21-openjdk, jdk-openjdk (latest)
        case "$V" in 17) install_pkg jdk17-openjdk || true ;; 21) install_pkg jdk21-openjdk || true ;; 8) install_pkg jdk8-openjdk || true ;; *) if [ "$V" == "25" ] || [ "$V" == "26" ]; then warn "Java $V may be JDK-openjdk (latest) on Arch"; install_pkg jdk-openjdk || true; fi ;; esac
        ;;
      dnf) install_pkg "java-${V}-openjdk-devel" 2>&1 | tail -5 || true ;;
      brew) if $DRY_RUN; then echo "[DRY] brew install openjdk@${V}"; else brew install "openjdk@${V}" 2>&1 | tail -10 || true; fi ;;
    esac
  done
  if ! $DRY_RUN; then java -version 2>&1 | head -5 || true; sdk current java 2>&1 | head -10 || true; fi
fi

### 7. NEOVIM ###
if should_run neovim; then
  log "=== NEOVIM ==="
  case "$PKG" in apt) install_pkg neovim ;; pacman) install_pkg neovim ;; dnf) install_pkg neovim ;; brew) install_pkg neovim ;; esac
  if ! $DRY_RUN; then nvim --version 2>&1 | head -5 || true; fi
fi

### 8. GIT (already base, ensure latest) ###
if should_run git; then
  log "=== GIT ==="
  case "$PKG" in apt) install_pkg git git-lfs ;; pacman) install_pkg git git-lfs ;; dnf) install_pkg git git-lfs ;; brew) install_pkg git git-lfs ;; esac
fi

### 9. SCRCPY + CONFIG ###
if should_run scrcpy; then
  log "=== SCRCPY + CONFIG (pipewire low-latency, audio fix) ==="
  case "$PKG" in apt) install_pkg scrcpy adb || true ;; pacman) install_pkg scrcpy android-tools ;; dnf) install_pkg scrcpy android-tools ;; brew) install_pkg scrcpy android-platform-tools ;; esac
  # Ensure manual scrcpy 4.1 if needed (for Zorin)
  if [ ! -f "$HOME/.local/bin/scrcpy-fixed" ]; then
    if [ -f "$HOME/.local/opt/scrcpy-v4.1/scrcpy" ]; then
      log "scrcpy-fixed already exists via previous setup"
    else
      warn "scrcpy-fixed not found, creating wrapper for system scrcpy"
      mkdir -p "$HOME/.local/bin"
      cat > "$HOME/.local/bin/scrcpy-fixed" <<'EOF_INNER'
#!/bin/bash
# Fixed scrcpy for choppy audio (aac + 150ms)
exec scrcpy --audio-codec=aac --audio-bit-rate=128K --audio-buffer=150 --video-buffer=50 "$@"
EOF_INNER
      chmod +x "$HOME/.local/bin/scrcpy-fixed"
    fi
  fi
  # Install pipewire low-latency configs (already in ~/.config)
  mkdir -p "$HOME/.config/pipewire/pipewire.conf.d" "$HOME/.config/wireplumber/wireplumber.conf.d"
  if [ ! -f "$HOME/.config/pipewire/pipewire.conf.d/99-low-latency.conf" ]; then
    cat > "$HOME/.config/pipewire/pipewire.conf.d/99-low-latency.conf" <<'EOF'
context.properties = {
    default.clock.quantum = 1024
    default.clock.min-quantum = 256
    default.clock.max-quantum = 2048
    default.clock.rate = 48000
}
EOF
  fi
  if [ ! -f "$HOME/.config/wireplumber/wireplumber.conf.d/99-no-suspend.conf" ]; then
    cat > "$HOME/.config/wireplumber/wireplumber.conf.d/99-no-suspend.conf" <<'EOF'
monitor.alsa.rules = [
  {
    matches = [{ node.name = "~alsa_.*"}]
    actions = { update-props = { session.suspend-timeout-seconds = 0 } }
  }
]
EOF
  fi
  if ! $DRY_RUN; then systemctl --user restart pipewire pipewire-pulse wireplumber 2>&1 | tail -5 || true; fi
fi

### 10. DART / FLUTTER ###
if should_run dart; then
  log "=== DART / FLUTTER ==="
  if [ ! -d "$HOME/flutter" ] && [ ! -d "$HOME/.flutter" ]; then
    if $DRY_RUN; then echo "[DRY] git clone https://github.com/flutter/flutter.git -b stable ~/flutter"; else git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter" 2>&1 | tail -10; fi
  fi
  # Add to PATH via .zshrc/.bashrc if not present
  for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$RC" ] && ! grep -q "flutter/bin" "$RC"; then
      if $DRY_RUN; then echo "[DRY] echo 'export PATH=\$HOME/flutter/bin:\$PATH' >> $RC"; else echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$RC"; log "Added flutter to $RC"; fi
    fi
  done
  case "$PKG" in apt) install_pkg dart 2>&1 | tail -5 || true ;; pacman) install_pkg dart 2>&1 | tail -5 || true ;; brew) install_pkg dart 2>&1 | tail -5 || true ;; esac
  if ! $DRY_RUN; then export PATH="$HOME/flutter/bin:$PATH"; flutter --version 2>&1 | head -10 || true; dart --version 2>&1 | head -5 || true; fi
fi

### 11. ANDROID ROM DEPS ###
if should_run android-rom; then
  log "=== ANDROID ROM BUILD DEPS ==="
  case "$PKG" in
    apt)
      install_pkg git-core gnupg flex bison build-essential zip curl \
        zlib1g-dev libc6-dev-i386 libncurses5-dev lib32ncurses5-dev \
        x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip \
        libxml2-utils fontconfig squashfs-tools libssl-dev ccache libtinfo5 libncurses5 \
        python3 python3-pip python-is-python3 rsync schedtool bc cpio liblz4-tool \
        lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev \
        libwxgtk3.0-gtk3-dev libxml2 lzop pngcrush schedtool xsltproc zip gperf \
        lib32stdc++6 libelf-dev libssl-dev m4 repo 2>&1 | tail -20 || true
      # repo tool
      if ! command -v repo >/dev/null 2>&1; then
        if $DRY_RUN; then echo "[DRY] curl https://storage.googleapis.com/git-repo-downloads/repo -> ~/bin/repo"; else mkdir -p ~/bin; curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo 2>&1 | tail -5; chmod a+x ~/bin/repo; fi
      fi
      ;;
    pacman)
      install_pkg base-devel git gnupg flex bison zip curl zlib lib32-zlib ncurses lib32-ncurses \
        libx11 lib32-libx11 lib32-zlib glu mesa libxml2 xsltproc unzip squashfs-tools \
        openssl ccache ncurses5-compat-libs python rsync schedtool bc cpio lz4 readline lib32-readline \
        sdl wxgtk3 lib32-gcc-libs elfutils lib32-elfutils 2>&1 | tail -20 || true
      # AUR: repo
      if ! command -v repo >/dev/null 2>&1; then warn "Install repo from AUR: yay -S repo"; fi
      ;;
    dnf)
      install_pkg git-core gnupg flex bison gcc gcc-c++ make zip curl zlib-devel glibc-devel.i686 ncurses-devel \
        libX11-devel glibc-devel libxml2-utils xsltproc unzip squashfs-tools openssl ccache ncurses-compat-libs \
        python3 rsync bc cpio lz4 2>&1 | tail -20 || true
      ;;
    brew)
      install_pkg git gnupg flex bison zip curl zlib ncurses libx11 2>&1 | tail -20 || true
      ;;
  esac
fi

### 12. ANDROID KERNEL DEPS ###
if should_run android-kernel; then
  log "=== ANDROID KERNEL BUILD DEPS ==="
  case "$PKG" in
    apt)
      install_pkg build-essential bc bison flex libssl-dev libelf-dev dwarves \
        libncurses-dev libncurses5-dev libx32ncurses5-dev \
        gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf \
        binutils-aarch64-linux-gnu binutils-arm-linux-gnueabihf \
        clang lld llvm gcc ccache \
        python3 python3-dev libxml2-utils xsltproc cpio rsync kmod 2>&1 | tail -20 || true
      ;;
    pacman)
      install_pkg base-devel bc bison flex openssl libelf dwarves ncurses \
        aarch64-linux-gnu-gcc arm-none-eabi-gcc \
        clang lld llvm ccache python cpio rsync kmod 2>&1 | tail -20 || true
      ;;
    dnf)
      install_pkg bc bison flex openssl-devel elfutils-libelf-devel dwarves ncurses-devel \
        gcc-aarch64-linux-gnu gcc-arm-linux-gnu clang lld llvm ccache python3 cpio rsync 2>&1 | tail -20 || true
      ;;
    brew)
      install_pkg bc bison flex openssl libelf dwarves ncurses clang llvm ccache python cpio rsync 2>&1 | tail -20 || true
      ;;
  esac
  # ccache config for kernel
  if ! $DRY_RUN; then mkdir -p ~/.ccache; ccache --max-size=50G 2>&1 | tail -5 || true; fi
fi

### 13. ANDROID SDK PATH ###
if should_run sdk; then
  log "=== ANDROID SDK PATH ==="
  # Default SDK locations
  ANDROID_SDK_CANDIDATES=(
    "$HOME/Android/Sdk"
    "$HOME/Android/sdk"
    "$HOME/Library/Android/sdk" # macOS
    "/opt/android-sdk"
    "/usr/local/android-sdk"
  )
  ANDROID_HOME=""
  for cand in "${ANDROID_SDK_CANDIDATES[@]}"; do if [ -d "$cand" ]; then ANDROID_HOME="$cand"; break; fi; done
  if [ -z "$ANDROID_HOME" ]; then
    ANDROID_HOME="$HOME/Android/Sdk"
    log "SDK not found, will create $ANDROID_HOME and suggest cmdline-tools install"
    if ! $DRY_RUN; then mkdir -p "$ANDROID_HOME"; fi
    # Download cmdline-tools if no SDK
    if [ ! -d "$ANDROID_HOME/cmdline-tools" ]; then
      CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
      if [[ "$OS" == "macos" ]]; then CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"; fi
      if $DRY_RUN; then echo "[DRY] curl $CMDLINE_URL -> cmdline-tools.zip && unzip to $ANDROID_HOME"; else
        mkdir -p /tmp/android-sdk; curl -fsSL "$CMDLINE_URL" -o /tmp/cmdline-tools.zip 2>&1 | tail -5
        unzip -q /tmp/cmdline-tools.zip -d /tmp/android-sdk 2>&1 | tail -5
        mkdir -p "$ANDROID_HOME/cmdline-tools"
        mv /tmp/android-sdk/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest" 2>&1 | tail -5 || true
      fi
    fi
  fi
  log "ANDROID_HOME=$ANDROID_HOME"
  # Add to shell RCs
  for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.config/fish/config.fish"; do
    if [ -f "$RC" ] || [[ "$RC" == *".bashrc" ]] || [[ "$RC" == *".zshrc" ]]; then
      # Ensure dir exists for fish
      mkdir -p "$(dirname "$RC")" 2>/dev/null || true
      touch "$RC" 2>/dev/null || true
      if ! grep -q "ANDROID_HOME" "$RC" 2>/dev/null; then
        if $DRY_RUN; then echo "[DRY] Add ANDROID vars to $RC"; else
          {
            echo ""
            echo "# Android SDK - added by cross-platform.sh"
            echo "export ANDROID_HOME=\"$ANDROID_HOME\""
            echo "export ANDROID_SDK_ROOT=\"\$ANDROID_HOME\""
            echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"'
          } >> "$RC"
          log "Added Android SDK to $RC"
        fi
      else
        info "Android SDK already in $RC"
      fi
    fi
  done
  # Also export for current session
  export ANDROID_HOME="$ANDROID_HOME"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
  if ! $DRY_RUN; then
    info "PATH includes: $ANDROID_HOME/cmdline-tools/latest/bin"
    adb --version 2>&1 | head -5 || warn "adb not found, run sdkmanager --install platform-tools"
    sdkmanager --version 2>&1 | head -5 || true
  fi
fi

### 14. EXTRA TOOLS ###
if should_run base || [ -z "$ONLY" ]; then
  log "=== EXTRA: htop, tree, jq, ripgrep, fd, bat ==="
  case "$PKG" in
    apt) install_pkg htop tree jq ripgrep fd-find bat fzf tmux vim 2>&1 | tail -10 || true ;;
    pacman) install_pkg htop tree jq ripgrep fd bat fzf tmux vim 2>&1 | tail -10 || true ;;
    dnf) install_pkg htop tree jq ripgrep fd-find bat fzf tmux vim 2>&1 | tail -10 || true ;;
    brew) install_pkg htop tree jq ripgrep fd bat fzf tmux vim 2>&1 | tail -10 || true ;;
  esac
  # fd symlink on Debian (fdfind -> fd)
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then if $DRY_RUN; then echo "[DRY] sudo ln -sf \$(command -v fdfind) /usr/local/bin/fd"; else sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd 2>&1 | tail -5 || true; fi; fi
  # bat symlink
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then if $DRY_RUN; then echo "[DRY] sudo ln -sf \$(command -v batcat) /usr/local/bin/bat"; else sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat 2>&1 | tail -5 || true; fi; fi
fi

# Final
log "=== DONE ==="
info "OS: $OS | PKG: $PKG"
info "Installed categories: ${ONLY:-all}"
info "Verify:"
info "  java -version; sdk current java; nvim --version; scrcpy --version; git --version; cmake --version; dart --version; flutter --version; node --version; python3.11 --version; clang --version; ninja --version; pkg-config --version"
info "  echo \$ANDROID_HOME; adb --version"
info "  sysctl vm.swappiness; swapon --show; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
if $DRY_RUN; then warn "DRY RUN - no changes made"; fi
log "If new PATH needed, run: source ~/.bashrc  or  source ~/.zshrc  or restart shell"
