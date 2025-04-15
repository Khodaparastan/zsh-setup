# ==============================================================================
# PATH Configuration (Cross-Platform)
# ==============================================================================

# Ensure PATH arrays are unique and synced
typeset -U path PATH

# --- Define Base Paths ---
# Start with standard system paths
path=(
  /usr/local/sbin
  /usr/local/bin
  /usr/sbin
  /usr/bin
  /sbin
  /bin
)

# --- OS-Specific Paths ---
local brew_prefix
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS Homebrew (Apple Silicon or Intel)
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    brew_prefix="/opt/homebrew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    brew_prefix="/usr/local"
  fi
  if [[ -n "$brew_prefix" ]]; then
    path+=(
      "$brew_prefix/sbin"
      "$brew_prefix/bin"
    )
    # Add common opt paths if needed, but prefer relying on symlinks in bin/sbin
    # path+=(
    #   "$brew_prefix/opt/ruby/bin" # Example: If truly needed globally
    # )
  fi
elif [[ "$(uname)" == "Linux" ]]; then
  # Linuxbrew
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      brew_prefix="/home/linuxbrew/.linuxbrew"
      path+=(
        "$brew_prefix/sbin"
        "$brew_prefix/bin"
      )
  fi
  # Add standard Linux user paths if they exist
  [[ -d "$HOME/.local/bin" ]] && path+=("$HOME/.local/bin")

fi

# --- User & Tool Specific Paths (Common across OS) ---
path+=(
  "$HOME/.cargo/bin"                 # Rust Cargo
  "$HOME/.npm-global/bin"            # NPM Global Bin (if configured this way)
  "$HOME/.luarocks/bin"              # Lua Rocks
  "${LUA_DIR}/bin"                  # Custom Lua Bin
  "$PYENV_ROOT/bin"                 # Pyenv Bin
  # Add other consistent cross-platform paths here
)

# --- Add existing system PATH to ensure nothing is missed ---
# Use parameter expansion to split the existing PATH
path+=(${(s/:/)PATH})

# Export the final unique PATH
export PATH

# --- Compiler Flags (Consider moving to direnv/project scope) ---
# Only set these if you *consistently* build against a specific Homebrew package globally
# if [[ -n "$brew_prefix" ]] && [[ -d "$brew_prefix/opt/ruby" ]]; then
#   export LDFLAGS="-L$brew_prefix/opt/ruby/lib ${LDFLAGS}"
#   export CPPFLAGS="-I$brew_prefix/opt/ruby/include ${CPPFLAGS}"
#   export PKG_CONFIG_PATH="$brew_prefix/opt/ruby/lib/pkgconfig:${PKG_CONFIG_PATH}"
# fi

unset brew_prefix
