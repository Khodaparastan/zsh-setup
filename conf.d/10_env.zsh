# ==============================================================================
# Core Environment Variables
# ==============================================================================

# --- Terminal & Editor ---
export TERM="xterm-256color"
export EDITOR="nvim"
export VISUAL="$EDITOR"

# --- GPG ---
export GPG_TTY=$(tty)
export GNUPGHOME="${XDG_CONFIG_HOME:-$HOME/.config}/gnupg"
# Ensure the directory exists with correct permissions
mkdir -p "$GNUPGHOME" && chmod 700 "$GNUPGHOME"

# --- Python Environment (Pyenv) ---
# Pyenv initialization happens later in 60_external_tools.zsh
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}" # Allow override

# --- Lua Configuration ---
# Consider if these are needed globally or can be project-specific (e.g., direnv)
# If kept global, use XDG paths if possible
# export LUA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/lua" # Example XDG path
export LUA_DIR="$HOME/.local/lua" # Original path
export LUA_CPATH="${LUA_DIR}/lib/lua/5.1/?.so;;" # Check Lua version if not 5.1
export LUA_PATH="${LUA_DIR}/share/lua/5.1/?.lua;;" # Check Lua version if not 5.1
export MANPATH="${LUA_DIR}/share/man:${MANPATH}"

# --- Zsh Select (Loaded via zi later) ---
export ZSHSELECT_BOLD="1"
export ZSHSELECT_COLOR_PAIR="white/black"
export ZSHSELECT_BORDER="0"
export ZSHSELECT_ACTIVE_TEXT="reverse"
export ZSHSELECT_START_IN_SEARCH_MODE="1"
