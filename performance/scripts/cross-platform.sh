#!/bin/bash
# cross-platform.sh - Cross-platform dev dependencies installer
# Supports: Arch, Debian/Ubuntu/Zorin, Fedora, openSUSE, macOS
# Workflow: PHASE 1 = INSTALL programs/dependencies  ->  PHASE 2 = TWEAKS/CONFIG/PATH (.zshrc/.bashrc)
# Usage: bash ~/.config/performance/scripts/cross-platform.sh [--dry-run] [--yes] [--only a,b] [--skip a,b] [--list] [--interactive] [--minimal|--full|--dev|--android] [--arch|--debian|--fedora|--macos]

set -e
# ── UI palette ──────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; DIM='\033[2m'
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
  NC='\033[0m'
else
  BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''; NC=''
fi
log()  { echo -e "${GREEN}✔${NC} $*"; }
warn() { echo -e "${YELLOW}▲${NC} $*"; }
err()  { echo -e "${RED}✘${NC} $*" >&2; }
info() { echo -e "${BLUE}●${NC} $*"; }
dry()  { echo -e "${CYAN}[DRY]${NC} $*"; }

START_TS=$(date +%s)
STEP=0
TOTAL=38
PASSED=()
FAILED=()
SKIPPED=()

banner() {
  echo -e "${BOLD}${CYAN}"
  cat <<'BANNER'
   ____                 __                          ___  __
  / ___|_ __ ___  ___  / _|_ __   | | __ _| |_ / _| ___  _ __ _ __ ___
 | |   | '__/ _ \/ __|| |_| '_ \  | |/ _` | __| |_ / _ \| '__| '_ ` _ \
 | |___| | |  __/\__ \|  _| |_) | | | (_| | |_|  _| (_) | |  | | | | | |
  \____|_|  \___||___/|_| | .__/  |_|\__,_|\__|_|  \___/|_|  |_| |_| |_|
                          |_|
BANNER
  echo -e "${NC}${DIM}  Cross-platform dev setup  •  PHASE 1 INSTALL → PHASE 2 TWEAKS/PATH${NC}"
  echo ""
}

phase_hdr() { echo -e "\n${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${BOLD}$1${NC}\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

section() { # section "cat" "Human title"
  STEP=$((STEP+1))
  printf "${BOLD}${BLUE}[%02d/%02d]${NC} ${BOLD}%s${NC} ${DIM} (%s)${NC}\n" "$STEP" "$TOTAL" "$2" "$1"
}

ok()   { PASSED+=("$1"); log "$1 done"; }
fail() { FAILED+=("$1"); err "$1 failed (continuing)"; }
skip() { SKIPPED+=("$1"); echo -e "${DIM}  ↷ skipped $1${NC}"; }

# ── args ────────────────────────────────────────────────────
DRY_RUN=false; AUTO_YES=false; ONLY=""; SKIP=""; FORCE_OS=""; INTERACTIVE=false; LIST_ONLY=false; PROFILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --yes|-y) AUTO_YES=true; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    --only=*) ONLY="${1#--only=}"; shift ;;
    --skip) SKIP="$2"; shift 2 ;;
    --skip=*) SKIP="${1#--skip=}"; shift ;;
    --interactive|-i) INTERACTIVE=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
    --minimal) PROFILE="minimal"; shift ;;
    --full) PROFILE="full"; shift ;;
    --dev) PROFILE="dev"; shift ;;
    --android) PROFILE="android"; shift ;;
    --arch) FORCE_OS="arch"; shift ;;
    --debian) FORCE_OS="debian"; shift ;;
    --fedora) FORCE_OS="fedora"; shift ;;
    --suse) FORCE_OS="suse"; shift ;;
    --macos) FORCE_OS="macos"; shift ;;
    --help|-h)
      cat <<EOF
${BOLD}cross-platform.sh${NC} — install deps (PHASE 1) then tweaks/PATH (PHASE 2)

Usage: $0 [options]
  --dry-run            preview only
  --yes, -y            no prompt
  --only a,b,c         only these categories
  --skip a,b,c         skip these categories
  --interactive, -i    ask per category
  --list               list categories and exit
  --minimal            base+git+curl+utils only
  --dev                minimal + languages + containers + editors
  --android            dev + android-rom + android-kernel + sdk
  --full               everything
  --arch/--debian/--fedora/--suse/--macos  force OS
  --help               this help

Categories:
  base shell editors git scrcpy cmake dart node python java java-tools
  curl 7zip unzip pkg clang ninja glu stdc go rust js-tools python-tools
  ruby php lua zig kotlin github-cli db containers k8s media net-tools
  docs fonts sysutils security ssh android-rom android-kernel sdk
  adb fastboot android-udev usb-tools virt extra-media extra-dev fwupd
  kitty librewolf starship fastfetch
EOF
      exit 0 ;;
    *) shift ;;
  esac
done

CATEGORIES="base shell editors git scrcpy cmake dart node python java java-tools curl 7zip unzip pkg clang ninja glu stdc go rust js-tools python-tools ruby php lua zig kotlin github-cli db containers k8s media net-tools docs fonts sysutils security ssh android-rom android-kernel sdk adb fastboot android-udev usb-tools virt extra-media extra-dev fwupd kitty librewolf starship fastfetch"
if $LIST_ONLY; then echo "Categories:"; for c in $CATEGORIES; do echo "  - $c"; done; echo ""; echo "Profiles: minimal dev android full"; exit 0; fi

# profiles expand to ONLY/SKIP
case "$PROFILE" in
  minimal) ONLY="base,git,curl,unzip,7zip,sysutils,ssh,adb,usb-tools,fastfetch,starship,kitty" ;;
  dev) ONLY="base,shell,editors,git,github-cli,cmake,ninja,pkg,clang,stdc,python,python-tools,node,js-tools,go,rust,java,java-tools,containers,db,media,net-tools,docs,sysutils,security,ssh,adb,usb-tools,extra-dev,fwupd,fastfetch,starship,kitty" ;;
  android) ONLY="base,git,java,python,cmake,ninja,clang,stdc,sdk,android-rom,android-kernel,scrcpy,sysutils,adb,fastboot,android-udev,usb-tools,fastfetch" ;;
  full) ONLY="" ;;
esac

# ── OS detect ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/detect-os.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/detect-os.sh"; detect_os
else
  if [ -f /etc/os-release ]; then . /etc/os-release; OS_ID=${ID,,}; OS_ID_LIKE=${ID_LIKE,,}; else OS_ID="unknown"; fi
  if [[ "$OSTYPE" == darwin* ]]; then OS="macos"; else case "$OS_ID" in arch*) OS="arch";; debian|ubuntu|zorin*) OS="debian";; fedora*) OS="fedora";; *) OS="$OS_ID";; esac; fi
fi
[ -n "$FORCE_OS" ] && OS="$FORCE_OS"
case "$OS" in
  arch|manjaro|endeavouros|garuda|cachyos) PKG="pacman" ;;
  debian|ubuntu|zorin|pop|linuxmint) PKG="apt" ;;
  fedora|rhel|centos|rocky|almalinux) PKG="dnf" ;;
  suse|opensuse*) PKG="zypper" ;;
  macos|darwin) PKG="brew" ;;
  *) PKG="unknown" ;;
esac

should_run() {
  local cat="$1"
  if [ -n "$SKIP" ]; then IFS=',' read -ra S <<< "$SKIP"; for s in "${S[@]}"; do [ "$s" = "$cat" ] && return 1; done; fi
  if [ -z "$ONLY" ]; then return 0; fi
  IFS=',' read -ra O <<< "$ONLY"; for o in "${O[@]}"; do [ "$o" = "$cat" ] && return 0; done
  return 1
}
ask() { # ask "cat" "prompt" -> 0 run, 1 skip
  $INTERACTIVE || return 0
  echo -e "${YELLOW}?${NC} Install $1? [Y/n] "; read -r a; [[ "$a" == n* || "$a" == N* ]] && return 1 || return 0
}
run() { if $DRY_RUN; then dry "$*"; else eval "$@"; fi; }

# detect if a system package is already installed (no re-download)
have_pkg() { # have_pkg <name> -> 0 if installed
  local p="$1"
  case "$PKG" in
    apt) dpkg -s "$p" >/dev/null 2>&1 ;;
    pacman) pacman -Qi "$p" >/dev/null 2>&1 ;;
    dnf) rpm -q "$p" >/dev/null 2>&1 ;;
    zypper) rpm -q "$p" >/dev/null 2>&1 ;;
    brew) brew list "$p" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}
# detect if a binary exists in PATH (curl installs / manual builds)
have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_pkg() {
  local pkgs=("$@"); [ ${#pkgs[@]} -eq 0 ] && return 0
  local missing=() skipped=() p
  for p in "${pkgs[@]}"; do
    if $DRY_RUN; then missing+=("$p")
    elif have_pkg "$p"; then skipped+=("$p")
    else missing+=("$p"); fi
  done
  if [ ${#skipped[@]} -gt 0 ]; then info "already installed, skip: ${skipped[*]}"; fi
  [ ${#missing[@]} -eq 0 ] && return 0
  case "$PKG" in
    apt) if $DRY_RUN; then dry "sudo apt install -y ${missing[*]}"; else sudo apt update -qq 2>&1 | tail -3; sudo apt install -y "${missing[@]}" 2>&1 | tail -8; fi ;;
    pacman) if $DRY_RUN; then dry "sudo pacman -S --noconfirm ${missing[*]}"; else sudo pacman -S --noconfirm "${missing[@]}" 2>&1 | tail -8; fi ;;
    dnf) if $DRY_RUN; then dry "sudo dnf install -y ${missing[*]}"; else sudo dnf install -y "${missing[@]}" 2>&1 | tail -8; fi ;;
    zypper) if $DRY_RUN; then dry "sudo zypper install -y ${missing[*]}"; else sudo zypper install -y "${missing[@]}" 2>&1 | tail -8; fi ;;
    brew) if $DRY_RUN; then dry "brew install ${missing[*]}"; else brew install "${missing[@]}" 2>&1 | tail -8; fi ;;
    *) err "Unknown PKG $PKG skip ${missing[*]}"; return 1 ;;
  esac
}

banner
info "OS: ${BOLD}$OS${NC}  PKG: ${BOLD}$PKG${NC}  DRY: $DRY_RUN  ONLY: ${ONLY:-all}  SKIP: ${SKIP:-none}  PROFILE: ${PROFILE:-custom}"
[ "$OS" = "unknown" ] && warn "Unknown OS — trying best effort"
if ! $AUTO_YES && ! $DRY_RUN && ! $INTERACTIVE; then
  echo -e "${YELLOW}Install → then Tweaks/PATH. Continue? [Y/n]${NC}"; read -r ans; [[ "$ans" == n* || "$ans" == N* ]] && exit 1
fi
# adjust TOTAL to active count for nicer progress
ACTIVE=0; for c in $CATEGORIES; do should_run "$c" && ACTIVE=$((ACTIVE+1)); done
TOTAL=$((ACTIVE*2)); [ "$TOTAL" -lt 1 ] && TOTAL=1
STEP=0

##############################################################################
phase_hdr "PHASE 1 — INSTALL PROGRAMS / DEPENDENCIES (no config here)"
##############################################################################

# base
if should_run base && ask base "base tools"; then section base "Base essentials"
  case "$PKG" in
    apt) install_pkg git curl wget ca-certificates gnupg lsb-release software-properties-common apt-transport-https build-essential || fail base ;;
    pacman) install_pkg git curl wget ca-certificates gnupg base-devel || fail base ;;
    dnf) install_pkg git curl wget ca-certificates gnupg2 gcc gcc-c++ make || fail base ;;
    brew) install_pkg git curl wget ca-certificates gnupg make || fail base ;;
  esac; ok base; else skip base; fi

# curl/unzip/7zip
if should_run curl && ask curl "curl"; then section curl "curl"; case "$PKG" in apt|pacman|dnf) install_pkg curl || fail curl;; brew) install_pkg curl || fail curl;; esac; ok curl; else skip curl; fi
if should_run unzip && ask unzip "unzip"; then section unzip "unzip/zip"; case "$PKG" in apt|pacman|dnf) install_pkg unzip zip || fail unzip;; brew) install_pkg unzip || fail unzip;; esac; ok unzip; else skip unzip; fi
if should_run 7zip && ask 7zip "7zip"; then section 7zip "7-Zip"
  case "$PKG" in apt) install_pkg p7zip-full p7zip || fail 7zip;; pacman) install_pkg p7zip || fail 7zip;; dnf) install_pkg p7zip p7zip-plugins || fail 7zip;; brew) install_pkg p7zip || fail 7zip;; esac; ok 7zip; else skip 7zip; fi

# shell
if should_run shell && ask shell "shell (zsh/fish/starship/tmux)"; then section shell "Shell power tools"
  case "$PKG" in
    apt) install_pkg zsh fish starship tmux fzf fd-find bat eza zoxide direnv || install_pkg zsh fish tmux fzf || fail shell ;;
    pacman) install_pkg zsh fish starship tmux fzf fd bat eza zoxide direnv || fail shell ;;
    dnf) install_pkg zsh fish tmux fzf fd-find bat eza zoxide direnv || fail shell ;;
    brew) install_pkg zsh fish starship tmux fzf fd bat eza zoxide direnv || fail shell ;;
  esac; ok shell; else skip shell; fi

# editors
if should_run editors && ask editors "editors"; then section editors "Editors (nvim/helix/emacs)"
  case "$PKG" in
    apt) install_pkg neovim helix emacs vim nano || install_pkg neovim vim || fail editors ;;
    pacman) install_pkg neovim helix emacs vim || fail editors ;;
    dnf) install_pkg neovim helix emacs vim || fail editors ;;
    brew) install_pkg neovim helix emacs vim || fail editors ;;
  esac; ok editors; else skip editors; fi

# pkg/clang/ninja/cmake/glu/stdc
if should_run pkg && ask pkg "pkg-config"; then section pkg "pkg-config"; case "$PKG" in apt) install_pkg pkg-config;; pacman) install_pkg pkgconf;; dnf) install_pkg pkgconf-pkg-config;; brew) install_pkg pkg-config;; esac; ok pkg; else skip pkg; fi
if should_run clang && ask clang "clang"; then section clang "Clang/LLVM"
  case "$PKG" in apt) install_pkg clang lld lldb clang-format clang-tidy llvm || fail clang;; pacman) install_pkg clang lld llvm || fail clang;; dnf) install_pkg clang lld llvm || fail clang;; brew) install_pkg llvm || fail clang;; esac; ok clang; else skip clang; fi
if should_run ninja && ask ninja "ninja"; then section ninja "Ninja"; case "$PKG" in apt) install_pkg ninja-build;; pacman) install_pkg ninja;; dnf) install_pkg ninja-build;; brew) install_pkg ninja;; esac; ok ninja; else skip ninja; fi
if should_run cmake && ask cmake "cmake"; then section cmake "CMake"; case "$PKG" in apt) install_pkg cmake cmake-extras extra-cmake-modules;; pacman) install_pkg cmake;; dnf) install_pkg cmake;; brew) install_pkg cmake;; esac; ok cmake; else skip cmake; fi
if should_run glu && ask glu "glu/mesa"; then section glu "OpenGL/Mesa"
  case "$PKG" in apt) install_pkg libglu1-mesa-dev libgl1-mesa-dev mesa-common-dev libglx-dev freeglut3-dev || fail glu;; pacman) install_pkg glu mesa libglvnd freeglut || fail glu;; dnf) install_pkg mesa-libGLU mesa-libGL-devel freeglut-devel || fail glu;; brew) install_pkg mesa glu freeglut || true;; esac; ok glu; else skip glu; fi
if should_run stdc && ask stdc "stdc++"; then section stdc "libstdc++/toolchain"
  case "$PKG" in apt) install_pkg libstdc++6 g++ gcc-multilib || fail stdc;; pacman) install_pkg gcc-libs lib32-gcc-libs || fail stdc;; dnf) install_pkg libstdc++ libstdc++-devel gcc-c++ || fail stdc;; brew) install_pkg gcc || fail stdc;; esac; ok stdc; else skip stdc; fi

# python + tools
if should_run python && ask python "python3.11"; then section python "Python 3.11"
  case "$PKG" in
    apt) install_pkg python3.11 python3.11-dev python3.11-venv python3-pip python-is-python3 || install_pkg python3 python3-dev python3-venv python3-pip || fail python ;;
    pacman) install_pkg python python-pip python-virtualenv || fail python ;;
    dnf) install_pkg python3.11 python3-pip python3-devel || fail python ;;
    brew) install_pkg python@3.11 || fail python ;;
  esac; ok python; else skip python; fi
if should_run python-tools && ask python-tools "python-tools"; then section python-tools "Python tools (pipx/uv/ruff/poetry)"
  case "$PKG" in apt) install_pkg pipx ruff || true;; pacman) install_pkg python-pipx uv ruff || true;; dnf) install_pkg pipx || true;; brew) install_pkg pipx uv ruff poetry || true;; esac
  if $DRY_RUN; then dry "pip install --user uv poetry ruff"; else python3 -m pip install --user --upgrade uv poetry ruff 2>&1 | tail -3 || true; fi; ok python-tools; else skip python-tools; fi

# node + js-tools
if should_run node && ask node "node/nvm"; then section node "Node via nvm (+fallback)"
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then if $DRY_RUN; then dry "curl nvm install"; else curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>&1 | tail -3; fi; else info "nvm exists"; fi
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then case "$PKG" in apt) install_pkg nodejs npm;; pacman) install_pkg nodejs npm;; dnf) install_pkg nodejs npm;; brew) install_pkg node@24;; esac; fi
  ok node; else skip node; fi
if should_run js-tools && ask js-tools "js-tools"; then section js-tools "JS tools (yarn/pnpm/bun/deno)"
  case "$PKG" in apt) install_pkg yarn || true;; pacman) install_pkg yarn pnpm bun deno || true;; dnf) install_pkg yarn || true;; brew) install_pkg yarn pnpm bun deno || true;; esac
  if $DRY_RUN; then dry "npm i -g yarn pnpm (skip if have_cmd yarn/pnpm)"; else have_cmd yarn || npm i -g yarn 2>&1 | tail -2 || true; have_cmd pnpm || npm i -g pnpm 2>&1 | tail -2 || true; fi; ok js-tools; else skip js-tools; fi

# java + java-tools + kotlin
if should_run java && ask java "java 17-26"; then section java "Java 17–26 (SDKMAN + native)"
  if [ ! -d "$HOME/.sdkman" ]; then if $DRY_RUN; then dry "curl get.sdkman.io | bash"; else curl -s https://get.sdkman.io | bash 2>&1 | tail -3; fi; fi
  [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh" || true
  for V in 17 18 19 20 21 22 23 24 25 26; do TEM_ID="${V}-tem"
    if command -v sdk >/dev/null 2>&1; then if $DRY_RUN; then dry "sdk install java $TEM_ID"; else sdk install java "$TEM_ID" 2>&1 | tail -3 || true; fi; fi
    case "$PKG" in apt) [[ "$V" == 17 || "$V" == 21 ]] && { if $DRY_RUN; then dry "sudo apt install openjdk-$V-jdk"; else sudo apt install -y openjdk-${V}-jdk 2>&1 | tail -3 || true; fi; } ;;
      pacman) case "$V" in 17) install_pkg jdk17-openjdk || true;; 21) install_pkg jdk21-openjdk || true;; 25|26) install_pkg jdk-openjdk || true;; esac ;;
      dnf) install_pkg java-${V}-openjdk-devel 2>&1 | tail -2 || true ;;
      brew) if $DRY_RUN; then dry "brew install openjdk@$V"; else brew install openjdk@${V} 2>&1 | tail -3 || true; fi ;; esac
  done; ok java; else skip java; fi
if should_run java-tools && ask java-tools "maven/gradle"; then section java-tools "Maven/Gradle"
  case "$PKG" in apt) install_pkg maven gradle || true;; pacman) install_pkg maven gradle || true;; dnf) install_pkg maven gradle || true;; brew) install_pkg maven gradle || true;; esac
  if command -v sdk >/dev/null 2>&1; then if $DRY_RUN; then dry "sdk install maven + gradle"; else sdk install maven 2>&1 | tail -2 || true; sdk install gradle 2>&1 | tail -2 || true; fi; fi; ok java-tools; else skip java-tools; fi
if should_run kotlin && ask kotlin "kotlin"; then section kotlin "Kotlin"
  case "$PKG" in apt) install_pkg kotlin || true;; pacman) install_pkg kotlin || true;; dnf) install_pkg kotlin || true;; brew) install_pkg kotlin || true;; esac
  if command -v sdk >/dev/null 2>&1; then if $DRY_RUN; then dry "sdk install kotlin"; else sdk install kotlin 2>&1 | tail -2 || true; fi; fi; ok kotlin; else skip kotlin; fi

# go/rust/ruby/php/lua/zig/dart
if should_run go && ask go "go"; then section go "Go"; case "$PKG" in apt) install_pkg golang-go || install_pkg golang || true;; pacman) install_pkg go || true;; dnf) install_pkg golang || true;; brew) install_pkg go || true;; esac; ok go; else skip go; fi
if should_run rust && ask rust "rust"; then section rust "Rust (rustup)"
  if have_cmd rustc && have_cmd cargo; then info "already installed, skip rustup: $(rustc --version 2>&1 | head -1)"
  elif $DRY_RUN; then dry "curl --proto https://sh.rustup.rs -sSf | sh -s -- -y + rustup component add rust-analyzer clippy rustfmt"
  else curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tail -3 || true; source "$HOME/.cargo/env" 2>/dev/null || true; rustup component add rust-analyzer clippy rustfmt 2>&1 | tail -2 || true; fi
  case "$PKG" in pacman) have_cmd rustup || install_pkg rustup || true;; *) true;; esac; ok rust; else skip rust; fi
if should_run ruby && ask ruby "ruby/php/lua"; then section ruby "Ruby/PHP/Lua"
  case "$PKG" in apt) install_pkg ruby ruby-dev php php-cli lua5.4 || true;; pacman) install_pkg ruby php lua || true;; dnf) install_pkg ruby php lua || true;; brew) install_pkg ruby php lua || true;; esac; ok ruby; else skip ruby; fi
if should_run php && ask php "php extra"; then section php "PHP composer"; if $DRY_RUN; then dry "php composer install"; else php --version 2>&1 | head -2 || true; fi; ok php; else skip php; fi
if should_run lua && ask lua "lua extra"; then section lua "LuaRocks"; case "$PKG" in apt) install_pkg luarocks;; pacman) install_pkg luarocks;; dnf) install_pkg luarocks;; brew) install_pkg luarocks;; esac; ok lua; else skip lua; fi
if should_run zig && ask zig "zig"; then section zig "Zig"; case "$PKG" in apt) install_pkg zig || true;; pacman) install_pkg zig || true;; dnf) install_pkg zig || true;; brew) install_pkg zig || true;; esac; ok zig; else skip zig; fi
if should_run dart && ask dart "flutter"; then section dart "Flutter/Dart"
  if [ ! -d "$HOME/flutter" ] && [ ! -d "$HOME/.flutter" ]; then if $DRY_RUN; then dry "git clone flutter stable ~/flutter"; else git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter" 2>&1 | tail -3; fi; else info "flutter exists"; fi
  case "$PKG" in apt|pacman|brew) install_pkg dart 2>&1 | tail -2 || true;; esac; ok dart; else skip dart; fi

# git + github-cli
if should_run git && ask git "git"; then section git "Git + LFS"
  case "$PKG" in apt) install_pkg git git-lfs;; pacman) install_pkg git git-lfs;; dnf) install_pkg git git-lfs;; brew) install_pkg git git-lfs;; esac; ok git; else skip git; fi
if should_run github-cli && ask github-cli "gh/lazygit"; then section github-cli "GitHub CLI + lazygit/delta"
  case "$PKG" in apt) install_pkg gh lazygit git-delta || install_pkg gh || true;; pacman) install_pkg github-cli lazygit git-delta || true;; dnf) install_pkg gh lazygit git-delta || true;; brew) install_pkg gh lazygit git-delta || true;; esac; ok github-cli; else skip github-cli; fi

# scrcpy
if should_run scrcpy && ask scrcpy "scrcpy"; then section scrcpy "scrcpy + adb"
  case "$PKG" in apt) install_pkg scrcpy adb || true;; pacman) install_pkg scrcpy android-tools;; dnf) install_pkg scrcpy android-tools;; brew) install_pkg scrcpy android-platform-tools;; esac; ok scrcpy; else skip scrcpy; fi

# adb + fastboot drivers (PHASE 1 install only, udev/PATH in PHASE 2)
if should_run adb && ask adb "adb platform-tools"; then section adb "ADB (platform-tools)"
  case "$PKG" in
    apt) install_pkg adb android-tools-adb android-sdk-platform-tools-common || install_pkg adb || true ;;
    pacman) install_pkg android-tools || true ;;
    dnf) install_pkg android-tools || true ;;
    brew) install_pkg android-platform-tools || true ;;
  esac; ok adb; else skip adb; fi
if should_run fastboot && ask fastboot "fastboot"; then section fastboot "Fastboot drivers"
  case "$PKG" in
    apt) install_pkg fastboot android-tools-fastboot android-sdk-platform-tools-common || install_pkg fastboot || true ;;
    pacman) install_pkg android-tools || true ;;
    dnf) install_pkg android-tools || true ;;
    brew) install_pkg android-platform-tools || true ;;
  esac; ok fastboot; else skip fastboot; fi
if should_run android-udev && ask android-udev "android udev rules"; then section android-udev "Android udev rules (51-android)"
  case "$PKG" in
    apt) install_pkg android-sdk-platform-tools-common android-tools-udev || true ;;
    pacman) install_pkg android-udev || true ;;
    dnf) install_pkg android-tools-udev || true ;;
    brew) true ;;
  esac; ok android-udev; else skip android-udev; fi
if should_run usb-tools && ask usb-tools "usb/mtp tools"; then section usb-tools "USB/MTP tools (lsusb/mtp)"
  case "$PKG" in
    apt) install_pkg usbutils mtp-tools libmtp-common libmtp-runtime gvfs-backends jmtpfs exfatprogs || install_pkg usbutils mtp-tools || true ;;
    pacman) install_pkg usbutils mtp-tools libmtp gvfs-mtp jmtpfs exfatprogs || true ;;
    dnf) install_pkg usbutils mtp-tools libmtp gvfs-mtp jmtpfs exfatprogs || true ;;
    brew) install_pkg usbutils mtp-tools libmtp || true ;;
  esac; ok usb-tools; else skip usb-tools; fi
if should_run virt && ask virt "virtualization"; then section virt "Virtualization (qemu/virt-manager)"
  case "$PKG" in
    apt) install_pkg qemu-kvm qemu-utils virt-manager libvirt-daemon-system bridge-utils ovmf || install_pkg qemu virt-manager || true ;;
    pacman) install_pkg qemu-full virt-manager libvirt edk2-ovmf bridge-utils || install_pkg qemu virt-manager || true ;;
    dnf) install_pkg qemu-kvm qemu-img virt-manager libvirt edk2-ovmf || true ;;
    brew) install_pkg qemu || true ;;
  esac; ok virt; else skip virt; fi
if should_run extra-media && ask extra-media "extra media apps"; then section extra-media "Extra media (obs/vlc/gimp/ink)"
  case "$PKG" in
    apt) install_pkg obs-studio vlc gimp inkscape kdenlive audacity || true ;;
    pacman) install_pkg obs-studio vlc gimp inkscape kdenlive audacity || true ;;
    dnf) install_pkg obs-studio vlc gimp inkscape kdenlive audacity || true ;;
    brew) install_pkg --cask obs vlc gimp inkscape 2>/dev/null || brew install ffmpeg vlc || true ;;
  esac; ok extra-media; else skip extra-media; fi
if should_run extra-dev && ask extra-dev "extra dev tools"; then section extra-dev "Extra dev (yq/httpie/lazydocker/act)"
  case "$PKG" in
    apt) install_pkg yq httpie shellcheck shfmt direnv tokei hyperfine || true ;;
    pacman) install_pkg yq httpie shellcheck shfmt direnv tokei hyperfine lazydocker act || true ;;
    dnf) install_pkg yq httpie shellcheck direnv tokei hyperfine || true ;;
    brew) install_pkg yq httpie shellcheck shfmt direnv tokei hyperfine lazydocker act || true ;;
  esac
  if $DRY_RUN; then dry "npm i -g @githubnext/github-copilot-cli vercel wrangler firebase-tools"; else npm i -g vercel wrangler firebase-tools 2>&1 | tail -2 || true; fi
  ok extra-dev; else skip extra-dev; fi
if should_run fwupd && ask fwupd "firmware updater"; then section fwupd "Firmware (fwupd)"
  case "$PKG" in
    apt) install_pkg fwupd fwupd-signed || install_pkg fwupd || true ;;
    pacman) install_pkg fwupd || true ;;
    dnf) install_pkg fwupd || true ;;
    brew) true ;;
  esac; ok fwupd; else skip fwupd; fi

# containers/k8s/db/media/net/docs/fonts/sysutils/security/ssh
if should_run containers && ask containers "docker"; then section containers "Containers (docker/podman/buildx)"
  case "$PKG" in apt) install_pkg docker.io docker-buildx podman podman-compose containerd || true;; pacman) install_pkg docker docker-buildx podman podman-compose || true;; dnf) install_pkg docker podman podman-compose || true;; brew) install_pkg docker podman || true;; esac; ok containers; else skip containers; fi
if should_run k8s && ask k8s "k8s"; then section k8s "K8s (kubectl/helm/kind)"
  case "$PKG" in apt) install_pkg kubectl helm kind minikube || true;; pacman) install_pkg kubectl helm kind minikube || true;; dnf) install_pkg kubectl helm || true;; brew) install_pkg kubectl helm kind minikube || true;; esac; ok k8s; else skip k8s; fi
if should_run db && ask db "db clients"; then section db "DB clients (sqlite/pg/redis)"
  case "$PKG" in apt) install_pkg sqlite3 postgresql-client redis-tools mysql-client || true;; pacman) install_pkg sqlite postgresql redis mysql-clients || true;; dnf) install_pkg sqlite postgresql redis mysql || true;; brew) install_pkg sqlite postgresql redis mysql-client || true;; esac; ok db; else skip db; fi
if should_run media && ask media "ffmpeg"; then section media "Media (ffmpeg/magick)"
  case "$PKG" in apt) install_pkg ffmpeg imagemagick mpv yt-dlp || true;; pacman) install_pkg ffmpeg imagemagick mpv yt-dlp || true;; dnf) install_pkg ffmpeg ImageMagick mpv yt-dlp || true;; brew) install_pkg ffmpeg imagemagick mpv yt-dlp || true;; esac; ok media; else skip media; fi
if should_run net-tools && ask net-tools "net-tools"; then section net-tools "Net tools"
  case "$PKG" in apt) install_pkg openssh-client net-tools dnsutils nmap socat aria2 httpie || true;; pacman) install_pkg openssh net-tools bind nmap socat aria2 httpie || true;; dnf) install_pkg openssh net-tools bind-utils nmap socat aria2 httpie || true;; brew) install_pkg openssh nmap socat aria2 httpie || true;; esac; ok net-tools; else skip net-tools; fi
if should_run docs && ask docs "docs"; then section docs "Docs (pandoc/graphviz)"
  case "$PKG" in apt) install_pkg pandoc graphviz texlive-latex-base || true;; pacman) install_pkg pandoc graphviz || true;; dnf) install_pkg pandoc graphviz || true;; brew) install_pkg pandoc graphviz || true;; esac; ok docs; else skip docs; fi
if should_run fonts && ask fonts "fonts"; then section fonts "Nerd fonts"
  case "$PKG" in apt) install_pkg fonts-jetbrains-mono fonts-firacode || true;; pacman) install_pkg ttf-jetbrains-mono-nerd ttf-firacode-nerd || true;; dnf) install_pkg jetbrains-mono-fonts || true;; brew) true;; esac; ok fonts; else skip fonts; fi
if should_run sysutils && ask sysutils "sysutils"; then section sysutils "Sysutils (htop/jq/rg/fd/bat)"
  case "$PKG" in apt) install_pkg htop tree jq ripgrep fd-find bat fzf tmux vim ncdu duf btop || true;; pacman) install_pkg htop tree jq ripgrep fd bat fzf tmux vim ncdu duf btop || true;; dnf) install_pkg htop tree jq ripgrep fd-find bat fzf tmux vim ncdu || true;; brew) install_pkg htop tree jq ripgrep fd bat fzf tmux vim ncdu duf btop || true;; esac; ok sysutils; else skip sysutils; fi
if should_run security && ask security "security"; then section security "Security (gpg/age/sops)"
  case "$PKG" in apt) install_pkg gnupg age sops pass || true;; pacman) install_pkg gnupg age sops pass || true;; dnf) install_pkg gnupg age sops pass || true;; brew) install_pkg gnupg age sops pass || true;; esac; ok security; else skip security; fi
if should_run ssh && ask ssh "ssh server"; then section ssh "SSH"
  case "$PKG" in apt) install_pkg openssh-client openssh-server mosh || true;; pacman) install_pkg openssh mosh || true;; dnf) install_pkg openssh mosh || true;; brew) install_pkg openssh mosh || true;; esac; ok ssh; else skip ssh; fi

# terminal / prompt / fetch / browser — PHASE 1 size-ordered: smallest → largest
# OS is detected first (detect_os → $OS/$PKG); each block uses native mgr:
# arch → pacman, debian/ubuntu/zorin → apt, fedora → dnf, suse → zypper, macos → brew
# Order: fastfetch (~2MB) → starship (~8MB) → kitty (~35MB) → librewolf (~120MB)
if should_run fastfetch && ask fastfetch "fastfetch"; then section fastfetch "Fastfetch (sysinfo, ~2MB)"
  case "$PKG" in
    apt) install_pkg fastfetch || true ;;
    pacman) install_pkg fastfetch || true ;;
    dnf) install_pkg fastfetch || true ;;
    brew) install_pkg fastfetch || true ;;
  esac; ok fastfetch; else skip fastfetch; fi
if should_run starship && ask starship "starship prompt"; then section starship "Starship prompt (~8MB, starship.rs)"
  case "$PKG" in
    apt) install_pkg starship || true ;;
    pacman) install_pkg starship || true ;;
    dnf) install_pkg starship || true ;;
    brew) install_pkg starship || true ;;
  esac
  if ! command -v starship >/dev/null 2>&1; then
    if $DRY_RUN; then dry "curl -sS https://starship.rs/install.sh | sh -s -- -y"; else curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | tail -5 || true; fi
  fi; ok starship; else skip starship; fi
if should_run kitty && ask kitty "kitty terminal"; then section kitty "Kitty terminal (~35MB)"
  case "$PKG" in
    apt) install_pkg kitty kitty-terminfo || install_pkg kitty || true ;;
    pacman) install_pkg kitty || true ;;
    dnf) install_pkg kitty || true ;;
    brew) install_pkg --cask kitty 2>/dev/null || brew install kitty || true ;;
  esac; ok kitty; else skip kitty; fi
if should_run librewolf && ask librewolf "librewolf browser"; then section librewolf "LibreWolf browser (~120MB, largest of set)"
  case "$PKG" in
    apt) if $DRY_RUN; then dry "add librewolf repo (apt) + sudo apt install librewolf"; else
           if [ ! -f /etc/apt/sources.list.d/librewolf.sources ]; then
             sudo apt update && sudo apt install -y extrepo 2>&1 | tail -2 || true
             sudo extrepo enable librewolf 2>&1 | tail -2 || true
           fi
           sudo apt update 2>&1 | tail -2 || true; install_pkg librewolf || true; fi ;;
    pacman) install_pkg librewolf librewolf-bin 2>/dev/null || install_pkg librewolf || true ;;
    dnf) if $DRY_RUN; then dry "sudo dnf copr enable bgstack15/librewolf + install"; else sudo dnf copr enable -y bgstack15/librewolf 2>&1 | tail -2 || true; install_pkg librewolf || true; fi ;;
    brew) install_pkg --cask librewolf 2>/dev/null || brew install librewolf || true ;;
  esac; ok librewolf; else skip librewolf; fi

# android rom/kernel/sdk
if should_run android-rom && ask android-rom "android-rom"; then section android-rom "Android ROM deps"
  case "$PKG" in
    apt) install_pkg git-core gnupg flex bison build-essential zip curl zlib1g-dev libc6-dev-i386 libncurses5-dev x11proto-core-dev libx11-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig squashfs-tools libssl-dev ccache python3 rsync schedtool bc cpio liblz4-tool lzop pngcrush gperf libelf-dev m4 repo 2>&1 | tail -5 || true
      if ! command -v repo >/dev/null 2>&1; then if $DRY_RUN; then dry "curl repo -> ~/bin/repo"; else mkdir -p ~/bin; curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo; chmod a+x ~/bin/repo; fi; fi ;;
    pacman) install_pkg base-devel git gnupg flex bison zip curl zlib ncurses libx11 glu mesa libxml2 xsltproc unzip squashfs-tools openssl ccache python rsync bc cpio lz4 sdl elfutils 2>&1 | tail -5 || true; command -v repo >/dev/null 2>&1 || warn "yay -S repo" ;;
    dnf) install_pkg git-core gnupg flex bison gcc gcc-c++ make zip curl zlib-devel ncurses-devel libX11-devel libxml2-utils xsltproc unzip squashfs-tools openssl ccache python3 rsync bc cpio lz4 2>&1 | tail -5 || true ;;
    brew) install_pkg git gnupg flex bison zip curl zlib ncurses libx11 2>&1 | tail -3 || true ;;
  esac; ok android-rom; else skip android-rom; fi
if should_run android-kernel && ask android-kernel "android-kernel"; then section android-kernel "Android kernel deps"
  case "$PKG" in
    apt) install_pkg build-essential bc bison flex libssl-dev libelf-dev dwarves libncurses-dev gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf clang lld llvm ccache python3 cpio rsync kmod 2>&1 | tail -5 || true ;;
    pacman) install_pkg base-devel bc bison flex openssl libelf dwarves ncurses aarch64-linux-gnu-gcc arm-none-eabi-gcc clang lld llvm ccache python cpio rsync 2>&1 | tail -5 || true ;;
    dnf) install_pkg bc bison flex openssl-devel elfutils-libelf-devel dwarves ncurses-devel gcc-aarch64-linux-gnu clang lld llvm ccache python3 cpio 2>&1 | tail -5 || true ;;
    brew) install_pkg bc bison flex openssl libelf dwarves ncurses clang llvm ccache python cpio 2>&1 | tail -3 || true ;;
  esac; ok android-kernel; else skip android-kernel; fi
if should_run sdk && ask sdk "android-sdk"; then section sdk "Android SDK cmdline-tools"
  CANDS=("$HOME/Android/Sdk" "$HOME/Android/sdk" "$HOME/Library/Android/sdk" "/opt/android-sdk" "/usr/local/android-sdk"); SDK_TMP=""
  for c in "${CANDS[@]}"; do [ -d "$c" ] && SDK_TMP="$c" && break; done
  [ -z "$SDK_TMP" ] && SDK_TMP="$HOME/Android/Sdk"
  if ! $DRY_RUN; then mkdir -p "$SDK_TMP"; fi
  if [ ! -d "$SDK_TMP/cmdline-tools" ]; then URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"; [[ "$OS" == macos ]] && URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
    if $DRY_RUN; then dry "curl $URL → $SDK_TMP"; else mkdir -p /tmp/android-sdk; curl -fsSL "$URL" -o /tmp/cmdline-tools.zip 2>&1 | tail -2; unzip -q /tmp/cmdline-tools.zip -d /tmp/android-sdk; mkdir -p "$SDK_TMP/cmdline-tools"; mv /tmp/android-sdk/cmdline-tools "$SDK_TMP/cmdline-tools/latest" 2>&1 | tail -2 || true; fi; fi
  ok sdk; else skip sdk; fi

##############################################################################
phase_hdr "PHASE 2 — TWEAKS, CONFIG & PATH (.zshrc/.bashrc)"
##############################################################################
add_rc() { # add_rc "MATCH" "LINE-or-BLOCK" file...
  local match="$1"; shift; local content="$1"; shift
  for RC in "$@"; do [ -f "$RC" ] || continue
    if ! grep -qF "$match" "$RC" 2>/dev/null; then if $DRY_RUN; then dry "Add [$match] → $RC"; else printf "\n%s\n" "$content" >> "$RC"; log "PATH/tweak [$match] → $RC"; fi; else info "exists [$match] in $RC"; fi
  done
}

# git main
if should_run git || should_run base; then echo -e "${BOLD}• git defaultBranch${NC}"; if $DRY_RUN; then dry "git config --global init.defaultBranch main"; else git config --global init.defaultBranch main || true; log "init.defaultBranch=$(git config --global init.defaultBranch)"; fi; fi
# python
if should_run python; then echo -e "${BOLD}• python pip${NC}"; if $DRY_RUN; then dry "pip upgrade + python3.11 --version"; else python3 -m pip install --user --upgrade pip 2>&1 | tail -2 || true; python3.11 --version 2>&1 | head -1 || python3 --version; fi; fi
# node nvm
if should_run node; then echo -e "${BOLD}• node 24.16${NC}"; export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then source "$NVM_DIR/nvm.sh"; if $DRY_RUN; then dry "nvm install 24.16.0 && alias default (skip if node v24.16.x present)"; elif node --version 2>/dev/null | grep -q "v24\.16"; then info "already installed, skip node: $(node --version)"; else nvm install 24.16.0 2>&1 | tail -3; nvm alias default 24.16.0 2>&1 | tail -1; node --version; fi
    add_rc "NVM_DIR" '# NVM (PHASE 2)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "$HOME/.bashrc" "$HOME/.zshrc"; fi; fi
# java sdkman
if should_run java; then echo -e "${BOLD}• java verify${NC}"; if $DRY_RUN; then dry "java -version && sdk current java"; else java -version 2>&1 | head -2 || true; command -v sdk >/dev/null 2>&1 && sdk current java 2>&1 | head -3 || true; fi
  [ -d "$HOME/.sdkman" ] && add_rc "sdkman-init.sh" '# SDKMAN (PHASE 2)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' "$HOME/.bashrc" "$HOME/.zshrc"; fi
# rust cargo
if should_run rust; then echo -e "${BOLD}• rust cargo PATH${NC}"; add_rc ".cargo/env" '# Rust (PHASE 2)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"' "$HOME/.bashrc" "$HOME/.zshrc"; fi
# go path
if should_run go; then echo -e "${BOLD}• go PATH${NC}"; add_rc "go/bin" 'export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH" # Go (PHASE 2)' "$HOME/.bashrc" "$HOME/.zshrc"; fi
# flutter
if should_run dart; then echo -e "${BOLD}• flutter PATH${NC}"; add_rc "flutter/bin" 'export PATH="$HOME/flutter/bin:$PATH" # Flutter (PHASE 2)' "$HOME/.bashrc" "$HOME/.zshrc"
  if $DRY_RUN; then dry "flutter --version"; else export PATH="$HOME/flutter/bin:$PATH"; flutter --version 2>&1 | head -3 || true; fi; fi
# scrcpy
if should_run scrcpy; then echo -e "${BOLD}• scrcpy-fixed + pipewire${NC}"
  if [ ! -f "$HOME/.local/bin/scrcpy-fixed" ]; then if $DRY_RUN; then dry "create ~/.local/bin/scrcpy-fixed"; else mkdir -p "$HOME/.local/bin"; printf '#!/bin/bash\nexec scrcpy --audio-codec=aac --audio-bit-rate=128K --audio-buffer=150 --video-buffer=50 "$@"\n' > "$HOME/.local/bin/scrcpy-fixed"; chmod +x "$HOME/.local/bin/scrcpy-fixed"; fi; fi
  mkdir -p "$HOME/.config/pipewire/pipewire.conf.d" "$HOME/.config/wireplumber/wireplumber.conf.d"
  [ -f "$HOME/.config/pipewire/pipewire.conf.d/99-low-latency.conf" ] || { if $DRY_RUN; then dry "pipewire quantum 1024"; else printf 'context.properties = {\n    default.clock.quantum = 1024\n    default.clock.min-quantum = 256\n    default.clock.max-quantum = 2048\n    default.clock.rate = 48000\n}\n' > "$HOME/.config/pipewire/pipewire.conf.d/99-low-latency.conf"; fi; }
  [ -f "$HOME/.config/wireplumber/wireplumber.conf.d/99-no-suspend.conf" ] || { if $DRY_RUN; then dry "wireplumber no-suspend"; else printf 'monitor.alsa.rules = [ { matches = [{ node.name = "~alsa_.*"}] actions = { update-props = { session.suspend-timeout-seconds = 0 } } } ]\n' > "$HOME/.config/wireplumber/wireplumber.conf.d/99-no-suspend.conf"; fi; }
  add_rc ".local/bin" 'export PATH="$HOME/.local/bin:$PATH" # local bin (PHASE 2)' "$HOME/.bashrc" "$HOME/.zshrc"
  if ! $DRY_RUN; then systemctl --user restart pipewire pipewire-pulse wireplumber 2>&1 | tail -2 || true; fi; fi
# android sdk PATH
if should_run sdk; then echo -e "${BOLD}• android SDK PATH${NC}"; AH=""; for c in "$HOME/Android/Sdk" "$HOME/Android/sdk" "$HOME/Library/Android/sdk" "/opt/android-sdk"; do [ -d "$c" ] && AH="$c" && break; done; [ -z "$AH" ] && AH="$HOME/Android/Sdk"
  log "ANDROID_HOME=$AH"
  for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do [ -f "$RC" ] || continue
    if ! grep -q "ANDROID_HOME" "$RC" 2>/dev/null; then if $DRY_RUN; then dry "Add ANDROID_HOME → $RC"; else printf '\n# Android SDK (PHASE 2)\nexport ANDROID_HOME="%s"\nexport ANDROID_SDK_ROOT="$ANDROID_HOME"\nexport PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"\n' "$AH" >> "$RC"; fi; else info "ANDROID_HOME exists in $RC"; fi; done
  export ANDROID_HOME="$AH" ANDROID_SDK_ROOT="$AH"; export PATH="$AH/cmdline-tools/latest/bin:$AH/platform-tools:$AH/emulator:$PATH"
  if $DRY_RUN; then dry "adb --version"; else adb --version 2>&1 | head -2 || warn "run sdkmanager --install platform-tools"; fi; fi
# kernel ccache + ~/bin
if should_run android-kernel; then echo -e "${BOLD}• ccache + ~/bin${NC}"; if $DRY_RUN; then dry "ccache --max-size=50G"; else mkdir -p ~/.ccache; ccache --max-size=50G 2>&1 | tail -1 || true; fi
  add_rc "USE_CCACHE" 'export USE_CCACHE=1 # ccache (PHASE 2)' "$HOME/.bashrc" "$HOME/.zshrc"
  add_rc '$HOME/bin' 'export PATH="$HOME/bin:$PATH" # ~/bin (PHASE 2)' "$HOME/.bashrc" "$HOME/.zshrc"; fi
# fastfetch / starship / kitty / librewolf tweaks (PHASE 2: config + shell init — no installs)
if should_run fastfetch; then echo -e "${BOLD}• fastfetch config${NC}"
  if $DRY_RUN; then dry "mkdir ~/.config/fastfetch + fastfetch --gen-config + verify"; else
    mkdir -p "$HOME/.config/fastfetch" || true
    fastfetch --gen-config 2>&1 | tail -2 || true
    fastfetch --version 2>&1 | head -2 || true
  fi; fi
if should_run starship; then echo -e "${BOLD}• starship.toml + shell init${NC}"
  if $DRY_RUN; then dry "create ~/.config/starship.toml + init starship in .bashrc/.zshrc"; else
    mkdir -p "$HOME/.config" || true
    if [ ! -f "$HOME/.config/starship.toml" ]; then
      cat > "$HOME/.config/starship.toml" <<'TOML'
# starship.toml — auto-generated by cross-platform.sh (PHASE 2)
format = "$all"
add_newline = true
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"
[directory]
truncation_length = 3
truncate_to_repo = true
[git_branch]
symbol = "🌱 "
[git_status]
ahead = "⇡"
behind = "⇣"
diverged = "⇕"
[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow) "
[time]
disabled = false
format = "🕙[$time]($style) "
TOML
      log "created ~/.config/starship.toml"
    else info "starship.toml exists"; fi
    command -v starship >/dev/null 2>&1 && starship --version 2>&1 | head -1 || true
  fi
  add_rc 'starship init' '# Starship (PHASE 2)
eval "$(starship init bash)"' "$HOME/.bashrc"
  add_rc 'starship init zsh' '# Starship (PHASE 2)
eval "$(starship init zsh)"' "$HOME/.zshrc"; fi
if should_run kitty; then echo -e "${BOLD}• kitty config${NC}"
  if $DRY_RUN; then dry "mkdir ~/.config/kitty + kitty.conf defaults + verify"; else
    mkdir -p "$HOME/.config/kitty" || true
    if [ ! -f "$HOME/.config/kitty/kitty.conf" ]; then
      cat > "$HOME/.config/kitty/kitty.conf" <<'KITTY'
# kitty.conf — auto-generated by cross-platform.sh (PHASE 2)
font_family JetBrains Mono
font_size 12.0
background_opacity 0.95
confirm_os_window_close 0
enable_audio_bell no
KITTY
      log "created ~/.config/kitty/kitty.conf"
    else info "kitty.conf exists"; fi
    kitty --version 2>&1 | head -1 || true
  fi; fi
if should_run librewolf; then echo -e "${BOLD}• librewolf verify${NC}"
  if $DRY_RUN; then dry "librewolf --version + policies.json hardening note"; else
    librewolf --version 2>&1 | head -2 || true
    mkdir -p "$HOME/.librewolf" || true
  fi; fi
# fd/bat symlinks
if should_run sysutils; then if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then if $DRY_RUN; then dry "ln fdfind→fd"; else sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true; fi; fi
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then if $DRY_RUN; then dry "ln batcat→bat"; else sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat || true; fi; fi; fi
# adb/fastboot + udev tweaks (PHASE 2: group, rules reload, verify — no installs)
if should_run adb || should_run fastboot || should_run android-udev; then echo -e "${BOLD}• adb/fastboot drivers tweak${NC}"
  if $DRY_RUN; then dry "sudo usermod -aG plugdev \$USER + udevadm reload + adb start-server + fastboot --version"
  else
    sudo groupadd -f plugdev 2>&1 | tail -1 || true
    sudo usermod -aG plugdev "$USER" 2>&1 | tail -1 || true
    if [ ! -f /etc/udev/rules.d/51-android.rules ]; then sudo sh -c 'curl -fsSL https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules -o /etc/udev/rules.d/51-android.rules 2>&1 | tail -2 || echo "# fallback android udev" > /etc/udev/rules.d/51-android.rules'; log "installed 51-android.rules"; else info "51-android.rules exists"; fi
    sudo chmod 644 /etc/udev/rules.d/51-android.rules 2>&1 | tail -1 || true
    sudo udevadm control --reload-rules 2>&1 | tail -1 || true; sudo udevadm trigger 2>&1 | tail -1 || true
    adb start-server 2>&1 | tail -2 || true; adb --version 2>&1 | head -2 || true; fastboot --version 2>&1 | head -2 || fastboot --help 2>&1 | head -2 || true
    log "plugdev groups: $(groups 2>&1 | tr '\n' ' ') — relogin needed for plugdev to apply"
  fi; fi
# usb-tools tweak: verify mtp/adb see devices
if should_run usb-tools; then echo -e "${BOLD}• usb/mtp verify${NC}"; if $DRY_RUN; then dry "lsusb + mtp-detect --list-devices + adb devices"; else lsusb 2>&1 | head -10 || true; mtp-detect 2>&1 | head -5 || true; adb devices 2>&1 | head -10 || true; fi; fi
# virt tweak: libvirt group + service
if should_run virt; then echo -e "${BOLD}• virt tweak (libvirtd)${NC}"
  if $DRY_RUN; then dry "sudo usermod -aG libvirt,kvm + systemctl enable libvirtd"
  else sudo groupadd -f libvirt 2>&1 | tail -1 || true; sudo groupadd -f kvm 2>&1 | tail -1 || true; sudo usermod -aG libvirt,kvm "$USER" 2>&1 | tail -1 || true; sudo systemctl enable --now libvirtd 2>&1 | tail -2 || true; fi; fi

# ── summary ─────────────────────────────────────────────────
END_TS=$(date +%s); ELAPSED=$((END_TS-START_TS))
phase_hdr "DONE — PHASE 1 + PHASE 2 COMPLETE (${ELAPSED}s)"
echo -e "${BOLD}OS:${NC} $OS ($PKG)   ${BOLD}Profile:${NC} ${PROFILE:-custom}   ${BOLD}ONLY:${NC} ${ONLY:-all}   ${BOLD}SKIP:${NC} ${SKIP:-none}"
echo -e "${GREEN}✔ passed (${#PASSED[@]}):${NC} ${PASSED[*]:-none}"
[ ${#FAILED[@]} -gt 0 ] && echo -e "${RED}✘ failed (${#FAILED[@]}):${NC} ${FAILED[*]}"
echo -e "${DIM}↷ skipped (${#SKIPPED[@]}):${NC} ${SKIPPED[*]:-none}"
echo ""
echo -e "${BOLD}Verify:${NC}"
echo "  java -version; nvim --version; scrcpy --version; git config --global init.defaultBranch"
echo "  node --version; python3.11 --version; go version; rustc --version; flutter --version"
echo "  echo \$ANDROID_HOME; adb --version; adb devices; fastboot --version; lsusb | head"
$DRY_RUN && warn "DRY RUN — no changes made"
log "Reload shell: source ~/.bashrc  •  source ~/.zshrc"
