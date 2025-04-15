# ==============================================================================
# ZI Plugin Manager Initialization
# ==============================================================================

# --- Define ZI Paths ---
# Base directory for ZI related data
ZI_BASE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zi"
# Directory where the ZI repository is cloned
ZI_INSTALL_DIR="${ZI_BASE_DIR}/bin"
# The actual script file to be sourced
ZI_SCRIPT_TO_SOURCE="${ZI_INSTALL_DIR}/zi.zsh"

# --- Check if ZI script exists, install if not ---
if [[ ! -f "$ZI_SCRIPT_TO_SOURCE" ]]; then
  print -P "%F{33}▓▒░ %F{160}Installing (%F{33}z-shell/zi%F{160})...%f"

  # Ensure git is available
  if ! command -v git >/dev/null 2>&1; then
    print -P "%F{160}▓▒░ Error: 'git' command not found. Cannot install zi.%f%b"
    return 1 # Stop sourcing if git is missing
  fi

  # Create ZI_INSTALL_DIR specifically, ensure parent ZI_BASE_DIR exists too
  command mkdir -p "$ZI_INSTALL_DIR" && command chmod go-rwX "$ZI_BASE_DIR"

  # Clone zi into the install directory
  # Use --branch "main" explicitly
  if command git clone -q --depth=1 --branch "main" https://github.com/z-shell/zi "$ZI_INSTALL_DIR"; then
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b"
  else
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
    command rm -rf "$ZI_INSTALL_DIR"
    return 1
  fi
fi

# --- Source zi ---
if [[ -f "$ZI_SCRIPT_TO_SOURCE" ]]; then
  source "$ZI_SCRIPT_TO_SOURCE"

  if ! command -v zi >/dev/null 2>&1; then
      print -P "%F{160}▓▒░ Error: Sourced '$ZI_SCRIPT_TO_SOURCE' but 'zi' command is still not available.%f%b"
      return 1
  fi

  export PATH="$ZI_INSTALL_DIR:$PATH"

else
  print -P "%F{160}▓▒░ Error: Failed to find zi script to source at '$ZI_SCRIPT_TO_SOURCE'.%f%b"
  return 1
fi

# Cleanup temporary variables if desired
# unset ZI_BASE_DIR ZI_INSTALL_DIR ZI_SCRIPT_TO_SOURCE
