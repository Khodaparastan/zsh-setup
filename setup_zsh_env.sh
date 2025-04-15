#!/usr/bin/env bash

# ==============================================================================
# Zsh Environment Setup Script (YAML Based)
#
# Sets up a clean macOS, Ubuntu, or RHEL-based system for the modular
# Zsh configuration using the 'zi' plugin manager.
# Reads package definitions from 'packages.yaml'.
#
# Usage: Run from the root of the cloned dotfiles repository
#        (e.g., inside ~/.config/zsh)
#        ./setup_zsh_env.sh
# ==============================================================================

# --- Configuration ---
set -e # Exit on error
# set -u # Treat unset vars as error (optional)
set -o pipefail # Fail pipelines on first error

# --- Script Information ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
YAML_FILE="${SCRIPT_DIR}/packages.yaml"

# --- Colors for Output ---
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_BOLD='\033[1m'

# --- Helper Functions ---
msg() {
  echo -e "${COLOR_BLUE}${COLOR_BOLD}==>${COLOR_RESET}${COLOR_BOLD} $1${COLOR_RESET}"
}

success() {
  echo -e "${COLOR_GREEN}${COLOR_BOLD}==>${COLOR_RESET} $1${COLOR_RESET}"
}

warn() {
  echo -e "${COLOR_YELLOW}${COLOR_BOLD}==> WARNING:${COLOR_RESET} $1${COLOR_RESET}"
}

error() {
  echo -e "${COLOR_RED}${COLOR_BOLD}==> ERROR:${COLOR_RESET} $1${COLOR_RESET}" >&2
  exit 1
}

cmd_exists() {
  command -v "$1" &>/dev/null
}

# --- Global Variables ---
OS=""
DISTRO=""
DISTRO_KEY="" # Key used in YAML (macos, ubuntu, rhel)
PKG_MANAGER=""
SUDO_CMD="sudo"

# --- Detect Operating System ---
detect_os() {
  msg "Detecting operating system..."
  OS="$(uname -s)"

  case "$OS" in
  Linux)
    if [[ -f /etc/os-release ]]; then
      # shellcheck source=/dev/null
      source /etc/os-release
      DISTRO=$ID
      case "$DISTRO" in
      ubuntu | debian | pop)
        DISTRO_KEY="ubuntu"
        PKG_MANAGER="apt"
        ;;
      fedora | rocky | alma)
        DISTRO_KEY="rhel"
        PKG_MANAGER="dnf"
        ;;
      rhel | centos) # Older or base RHEL/CentOS
        DISTRO_KEY="rhel"
        # Check dnf first, fallback to yum
        if cmd_exists dnf; then PKG_MANAGER="dnf"; else PKG_MANAGER="yum"; fi
        ;;
      *)
        if [[ -n "$ID_LIKE" ]]; then # Check ID_LIKE for RHEL/Debian heritage
          if [[ "$ID_LIKE" == *"fedora"* || "$ID_LIKE" == *"rhel"* ]]; then
            DISTRO_KEY="rhel"
            if cmd_exists dnf; then PKG_MANAGER="dnf"; else PKG_MANAGER="yum"; fi
          elif [[ "$ID_LIKE" == *"debian"* ]]; then
            DISTRO_KEY="ubuntu" # Treat debian-like as ubuntu for packages
            PKG_MANAGER="apt"
          else
            error "Unsupported Linux distribution (based on ID_LIKE): $ID_LIKE"
          fi
        else
          error "Unsupported Linux distribution: $ID"
        fi
        ;;
      esac
    else
      error "Cannot detect Linux distribution (missing /etc/os-release)."
    fi
    ;;
  Darwin)
    DISTRO="macos"
    DISTRO_KEY="macos"
    PKG_MANAGER="brew"
    ;;
  *)
    error "Unsupported operating system: $OS"
    ;;
  esac
  msg "Detected OS: $OS, Distro: $DISTRO ($DISTRO_KEY), Package Manager: $PKG_MANAGER"

  if ! cmd_exists $SUDO_CMD; then
    warn "'sudo' command not found. Installation of system packages will likely fail."
    SUDO_CMD=""
  fi
}

# --- Check/Install yq (YAML Parser) ---
check_install_yq() {
  msg "Checking for yq (YAML parser)..."
  if cmd_exists yq; then
    success "yq found: $(command -v yq)"
    return 0
  fi

  warn "yq not found. Attempting to install..."
  local install_cmd=""
  case "$PKG_MANAGER" in
  apt) install_cmd="$SUDO_CMD apt-get update -qq && $SUDO_CMD apt-get install -y -qq yq" ;;
  dnf) install_cmd="$SUDO_CMD dnf install -y yq" ;;
  yum) install_cmd="$SUDO_CMD yum install -y yq" ;; # Might need EPEL repo
  brew) install_cmd="brew install yq" ;;
  *) warn "Cannot automatically install yq for package manager $PKG_MANAGER." ;;
  esac

  if [[ -n "$install_cmd" ]]; then
    if $install_cmd; then
      success "yq installed successfully."
      return 0
    else
      warn "Failed to install yq via package manager."
    fi
  fi

  # Fallback: Try downloading binary (adjust version/arch as needed)
  warn "Attempting to download yq binary..."
  local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" # Adjust for OS/Arch
  local yq_bin="/usr/local/bin/yq"                                                       # Install location
  if [[ "$OS" == "Darwin" ]]; then
    yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_amd64"
    if [[ "$(uname -m)" == "arm64" ]]; then
      yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_arm64"
    fi
  fi

  if cmd_exists curl; then
    if curl -sL "$yq_url" -o /tmp/yq && chmod +x /tmp/yq; then
      msg "Moving yq binary to $yq_bin (requires sudo)..."
      if $SUDO_CMD mv /tmp/yq "$yq_bin"; then
        success "yq binary installed to $yq_bin."
        return 0
      else
        warn "Failed to move yq binary to $yq_bin."
      fi
    else
      warn "Failed to download or make yq binary executable."
    fi
  else
    warn "Cannot download yq binary: curl not found."
  fi

  error "Failed to find or install yq. Cannot proceed without YAML parser."
}

# --- Read Packages from YAML ---
# Usage: read_yaml_packages ".path.to.list"
# Outputs package names one per line
read_yaml_packages() {
  local yaml_path="$1"
  # Use 'eval' to handle potential errors if path doesn't exist, default to empty node '[]'
  # Use '-o=j -I=0' for compact JSON array output, then 'jq -r .[]' to list items
  if cmd_exists jq; then
    yq eval "${yaml_path} // [] | select(length > 0)" -o=j -I=0 "$YAML_FILE" | jq -r '.[]' || true # Continue if empty/error
  else
    # Fallback without jq - less robust for complex items, relies on yq list format
    yq eval "${yaml_path} // [] | .[]" -I=0 "$YAML_FILE" || true
  fi
}

# Usage: read_yaml_objects ".path.to.list"
# Outputs objects (like tools with methods/scripts) one JSON object per line
read_yaml_objects() {
  local yaml_path="$1"
  if cmd_exists jq; then
    yq eval "${yaml_path} // [] | select(length > 0)" -o=j -I=0 "$YAML_FILE" | jq -c '.[]' || true
  else
    warn "jq command not found, cannot reliably process complex package objects from YAML."
    # Attempt basic yq output, might break on complex structures
    yq eval "${yaml_path} // [] | .[]" -I=0 "$YAML_FILE" || true
  fi
}

# --- Install Homebrew (macOS / Linux) ---
install_homebrew() {
  if ! cmd_exists brew; then
    msg "Homebrew not found. Installing Homebrew..."
    if cmd_exists curl; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [[ "$OS" == "Darwin" ]]; then
        if [[ "$(uname -m)" == "arm64" ]]; then # Apple Silicon
          eval "$(/opt/homebrew/bin/brew shellenv)"
        else # Intel
          eval "$(/usr/local/bin/brew shellenv)"
        fi
      elif [[ "$OS" == "Linux" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi
      success "Homebrew installed."
    else
      error "Cannot install Homebrew: 'curl' command not found."
    fi
  else
    msg "Homebrew already installed. Updating..."
    brew update || warn "Brew update failed, continuing..."
  fi
}

# --- Install Packages via Package Manager ---
install_pkgs_via_manager() {
  local pkgs_to_install=("$@")
  if [[ ${#pkgs_to_install[@]} -eq 0 ]]; then
    msg "No packages specified for system package manager installation."
    return
  fi

  msg "Installing via $PKG_MANAGER: ${pkgs_to_install[*]}"
  local install_failed=0

  case "$PKG_MANAGER" in
  apt)
    $SUDO_CMD apt-get update -qq || warn "apt update failed"
    $SUDO_CMD apt-get install -y -qq "${pkgs_to_install[@]}" || install_failed=1
    ;;
  dnf)
    local dnf_pkgs=()
    local dnf_groups=()
    for pkg in "${pkgs_to_install[@]}"; do
      if [[ "$pkg" == @* ]]; then dnf_groups+=("$pkg"); else dnf_pkgs+=("$pkg"); fi
    done
    if [[ ${#dnf_pkgs[@]} -gt 0 ]]; then
      $SUDO_CMD dnf install -y "${dnf_pkgs[@]}" || install_failed=1
    fi
    if [[ ${#dnf_groups[@]} -gt 0 ]]; then
      # DNF group install syntax uses '@' directly
      $SUDO_CMD dnf group install -y "${dnf_groups[@]}" || install_failed=1
    fi
    ;;
  yum)
    local yum_pkgs=()
    local yum_groups=()
    for pkg in "${pkgs_to_install[@]}"; do
      if [[ "$pkg" == @* ]]; then yum_groups+=("${pkg#@}"); else yum_pkgs+=("$pkg"); fi
    done
    if [[ ${#yum_pkgs[@]} -gt 0 ]]; then
      $SUDO_CMD yum install -y "${yum_pkgs[@]}" || install_failed=1
    fi
    if [[ ${#yum_groups[@]} -gt 0 ]]; then
      # Yum groupinstall syntax often needs quotes around group name
      for group in "${yum_groups[@]}"; do
        $SUDO_CMD yum groupinstall -y "$group" || install_failed=1
      done
    fi
    ;;
  brew)
    install_homebrew # Ensure brew is ready
    local needed_brew_pkgs=()
    for pkg in "${pkgs_to_install[@]}"; do
      if ! brew list --formula | grep -q "^${pkg}\$"; then
        needed_brew_pkgs+=("$pkg")
      else
        msg "Brew package '$pkg' already installed."
      fi
    done
    if [[ ${#needed_brew_pkgs[@]} -gt 0 ]]; then
      msg "Installing via Homebrew: ${needed_brew_pkgs[*]}"
      brew install "${needed_brew_pkgs[@]}" || install_failed=1
    else
      msg "All specified Homebrew packages are already installed."
    fi
    ;;
  *)
    error "install_pkgs_via_manager: Unknown package manager '$PKG_MANAGER'"
    ;;
  esac

  if [[ $install_failed -eq 1 ]]; then
    warn "Some packages may not have installed correctly. Please check the output above."
  else
    success "Package installation via $PKG_MANAGER completed."
  fi
}

# --- Install Tool via External Script ---
install_via_script() {
  local tool_name="$1"
  local install_script="$2"
  msg "Installing $tool_name using external script..."
  warn "Executing script directly from the internet: $install_script"
  read -rp "Do you want to proceed? (y/N): " confirm_script
  if [[ "$confirm_script" =~ ^[Yy]$ ]]; then
    if eval "$install_script"; then
      success "$tool_name installed successfully via script."
    else
      error "Failed to install $tool_name using script."
    fi
  else
    warn "Skipping installation of $tool_name."
  fi
}

# --- Install Pyenv (Official Installer) ---
install_pyenv_official() {
  if cmd_exists pyenv; then
    msg "Pyenv already installed."
    return 0
  fi

  msg "Installing Pyenv dependencies..."
  local pyenv_deps=()
  # Read deps using yq - assumes simple list
  while IFS= read -r line; do pyenv_deps+=("$line"); done < <(read_yaml_packages ".${DISTRO_KEY}.pyenv_deps")
  install_pkgs_via_manager "${pyenv_deps[@]}"

  msg "Installing Pyenv using the official installer..."
  if cmd_exists curl; then
    warn "The official pyenv installer pipes a script from the internet to bash."
    read -rp "Do you want to proceed? (y/N): " confirm_pyenv
    if [[ "$confirm_pyenv" =~ ^[Yy]$ ]]; then
      if curl -sL https://pyenv.run | bash; then
        success "Pyenv installed via official installer."
        msg "Pyenv configuration will be handled by the Zsh config."
        # Add pyenv to PATH for *this script session* if needed for subsequent steps
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init --path)"
      else
        error "Pyenv installation script failed."
      fi
    else
      warn "Skipping pyenv installation."
    fi
  else
    error "Cannot install pyenv via official installer: 'curl' not found."
  fi
}

# --- Set Zsh as Default Shell ---
set_default_shell() {
  if ! cmd_exists zsh; then
    warn "zsh command not found. Attempting to install..."
    install_pkgs_via_manager "zsh"
    if ! cmd_exists zsh; then
      error "Failed to install zsh."
    fi
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -z "$zsh_path" ]]; then
    error "Could not find zsh path even after installation attempt."
  fi

  local current_shell_path
  current_shell_path=$(getent passwd "$USER" | cut -d: -f7)

  if [[ "$current_shell_path" != "$zsh_path" ]]; then
    msg "Changing default shell to Zsh ($zsh_path)..."
    if ! grep -Fxq "$zsh_path" /etc/shells; then
      msg "Adding $zsh_path to /etc/shells (requires sudo)..."
      echo "$zsh_path" | $SUDO_CMD tee -a /etc/shells >/dev/null || { warn "Failed to add zsh to /etc/shells. chsh might fail."; }
    fi

    if cmd_exists chsh; then
      msg "Attempting to change shell using 'chsh'..."
      if chsh -s "$zsh_path" "$USER"; then
        success "Default shell changed to Zsh. Change takes effect on next login."
      elif [[ -n "$SUDO_CMD" ]]; then
        if $SUDO_CMD chsh -s "$zsh_path" "$USER"; then
          success "Default shell changed to Zsh using sudo. Change takes effect on next login."
        else
          error "Failed to change default shell using chsh (even with sudo)."
        fi
      else
        error "Failed to change default shell using chsh (sudo not available)."
      fi
    else
      warn "'chsh' command not found. Please change the default shell manually."
    fi
  else
    msg "Zsh is already the default shell."
  fi
}

# --- Main Execution ---
main() {
  detect_os
  check_install_yq

  if [[ ! -f "$YAML_FILE" ]]; then
    error "Package definition file not found: $YAML_FILE"
  fi

  # --- Install Core System Dependencies ---
  msg "Processing core system dependencies..."
  local core_pkgs=()
  while IFS= read -r line; do core_pkgs+=("$line"); done < <(read_yaml_objects ".${DISTRO_KEY}.core")
  # Extract names for package manager, handle groups
  local core_pkg_names=()
  for item_json in "${core_pkgs[@]}"; do
    # Assuming simple names or objects with 'name' field
    local name
    # Use jq if available for safer parsing
    if cmd_exists jq; then
      name=$(jq -r '.name // .' <<<"$item_json") # Get .name or the string itself
    else
      # Basic parsing if no jq - might fail on complex items
      name=$(echo "$item_json" | sed -n 's/.*name: \([^ ]*\).*/\1/p') # Try to extract name
      if [[ -z "$name" ]]; then name="$item_json"; fi                 # Fallback to full item
    fi
    core_pkg_names+=("$name")
  done
  install_pkgs_via_manager "${core_pkg_names[@]}"

  # --- Install Common & OS Specific Tools ---
  msg "Processing tool dependencies..."
  local tools_to_install_pkg=()
  local tools_to_install_script=() # Store as "name|script"
  local common_tools=()
  local os_tools=()

  while IFS= read -r line; do common_tools+=("$line"); done < <(read_yaml_objects ".common_tools")
  while IFS= read -r line; do os_tools+=("$line"); done < <(read_yaml_objects ".${DISTRO_KEY}.tools")

  local all_tools=("${common_tools[@]}" "${os_tools[@]}")

  for item_json in "${all_tools[@]}"; do
    if ! cmd_exists jq; then
      error "jq is required to parse tool definitions. Please install jq."
    fi
    local name command method install_script
    name=$(jq -r '.name' <<<"$item_json")
    command=$(jq -r '.command // empty' <<<"$item_json") # Optional command name
    method=$(jq -r '.method // "pkg"' <<<"$item_json")   # Default to pkg
    install_script=$(jq -r '.install_script // empty' <<<"$item_json")

    if [[ -z "$name" ]]; then
      warn "Skipping invalid tool definition: $item_json"
      continue
    fi

    # Check if command already exists (use specified command or name)
    local check_cmd="${command:-$name}"
    # Special case: map gnupg to gpg command if needed
    if [[ "$name" == "gnupg" && "$DISTRO_KEY" != "macos" ]]; then check_cmd="gpg"; fi
    if [[ "$name" == "ripgrep" ]]; then check_cmd="rg"; fi

    if cmd_exists "$check_cmd"; then
      msg "Tool '$check_cmd' (from $name) already seems to be installed."
      continue
    fi

    # Add to appropriate install list
    if [[ "$method" == "pkg" ]]; then
      tools_to_install_pkg+=("$name")
    elif [[ "$method" == "script" ]]; then
      if [[ -n "$install_script" ]]; then
        tools_to_install_script+=("${name}|${install_script}")
      else
        warn "Tool '$name' specified method 'script' but no 'install_script' found in YAML."
      fi
    else
      warn "Unknown installation method '$method' for tool '$name'."
    fi
  done

  # Install packages via package manager
  install_pkgs_via_manager "${tools_to_install_pkg[@]}"

  # Install tools via external scripts
  for item in "${tools_to_install_script[@]}"; do
    local tool_name="${item%|*}"
    local script_cmd="${item#*|}"
    # Double check command existence *after* package installs, before running script
    local check_cmd
    for item_json in "${all_tools[@]}"; do
      local name command
      name=$(jq -r '.name' <<<"$item_json")
      if [[ "$name" == "$tool_name" ]]; then
        command=$(jq -r '.command // empty' <<<"$item_json")
        check_cmd="${command:-$name}"
        if [[ "$name" == "gnupg" && "$DISTRO_KEY" != "macos" ]]; then check_cmd="gpg"; fi
        if [[ "$name" == "ripgrep" ]]; then check_cmd="rg"; fi
        break
      fi
    done

    if cmd_exists "$check_cmd"; then
      msg "Tool '$check_cmd' (from $tool_name) seems installed now, skipping script install."
      continue
    fi
    install_via_script "$tool_name" "$script_cmd"
  done

  # Handle specific symlinks (e.g., batcat -> bat)
  if [[ "$DISTRO_KEY" == "ubuntu" ]]; then
    if cmd_exists batcat && ! cmd_exists bat; then
      msg "Creating 'bat' symlink for 'batcat'..."
      $SUDO_CMD ln -sf "$(command -v batcat)" /usr/local/bin/bat || warn "Failed to create bat symlink"
    fi
    # fd symlink usually handled by fd-find package itself now
  fi

  # --- Install Pyenv ---
  install_pyenv_official

  # --- Set Zsh as Default Shell ---
  set_default_shell

  # --- Create XDG Dirs (Idempotent) ---
  msg "Ensuring XDG/Zsh directories exist..."
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zi"   # For zi installation
  mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" # For history file

  # --- Final Instructions ---
  success "========================================="
  success " Zsh Environment Setup Complete!"
  success "========================================="
  echo ""
  msg "What's next?"
  echo " 1. ${COLOR_YELLOW}Log out and log back in${COLOR_RESET}, or start a new Zsh session (${COLOR_BOLD}zsh${COLOR_RESET})."
  echo " 2. On the first Zsh launch, 'zi' will install configured plugins/tools."
  echo " 3. Review script output for any warnings or errors."
  echo " 4. Install Python versions: ${COLOR_BOLD}pyenv install <version>${COLOR_RESET}."
  echo " 5. Configure tools like Starship, Atuin if needed."
  echo ""
  msg "Enjoy your new Zsh environment!"
}

# --- Run Main Function ---
main

exit 0
