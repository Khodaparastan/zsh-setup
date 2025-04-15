# ==============================================================================
# Core Interactive Experience Plugins
# ==============================================================================

# Load critical plugins that should be available immediately for interaction

# --- Autosuggestions ---
# Provides command suggestions based on history
zi wait lucid blockf \
  atload"!_zsh_autosuggest_start" \
  zsh-users/zsh-autosuggestions

# --- Syntax Highlighting ---
# Highlights commands while typing
zi wait lucid blockf \
  zsh-users/zsh-syntax-highlighting

# --- fzf-tab (Replaces default completion menu with fzf) ---
# Load this early if you want it as the primary completion UI
zi wait lucid blockf for \
  Aloxaf/fzf-tab

# --- zsh-select ---
# For interactive selection menus (used by some other plugins/functions)
zi ice lucid wait blockf
zi snippet PZT::modules/environment/init.zsh # Load any required env setup first
zi load z-shell/zsh-select
