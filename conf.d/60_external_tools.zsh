# ~/.config/zsh/conf.d/60_external_tools.zsh
# ==============================================================================
# Initialization for Tools Managed Externally (Not via ZI)
# ==============================================================================

# --- Autojump ---
# Check common locations for autojump init script
local autojump_sh
if [[ -f "/opt/homebrew/etc/profile.d/autojump.sh" ]]; then # macOS Homebrew
    autojump_sh="/opt/homebrew/etc/profile.d/autojump.sh"
elif [[ -f "/usr/local/etc/profile.d/autojump.sh" ]]; then # macOS Homebrew (Intel legacy)
    autojump_sh="/usr/local/etc/profile.d/autojump.sh"
elif [[ -f "/home/linuxbrew/.linuxbrew/etc/profile.d/autojump.sh" ]]; then # Linuxbrew
    autojump_sh="/home/linuxbrew/.linuxbrew/etc/profile.d/autojump.sh"
elif [[ -f "/usr/share/autojump/autojump.sh" ]]; then # Common Linux path (check your distro)
    autojump_sh="/usr/share/autojump/autojump.sh"
fi
if [[ -n "$autojump_sh" ]] && [[ -f "$autojump_sh" ]]; then
  source "$autojump_sh"
fi
unset autojump_sh

# --- fzf (Keybindings & Fuzzy Completion) ---
# If fzf was installed via package manager or manually
# The zi installation in 41_plugins_tools.zsh might handle some setup,
# but the standard install often suggests sourcing ~/.fzf.zsh
if [[ -f "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi
# Removed redundant `zi light Aloxaf/fzf-tab` load here

# --- Lua Rocks ---
if command -v luarocks &>/dev/null; then
  # Ensure environment variables from 10_env.zsh are set first
  eval "$(luarocks path --no-bin)" # Add lua paths, assumes LUA_PATH/CPATH are set
fi

# --- Pyenv ---
if command -v pyenv &>/dev/null; then
  # PYENV_ROOT should be set in 10_env.zsh
  eval "$(pyenv init --path)" # Add shims to PATH
  eval "$(pyenv init -)"       # Load pyenv command, completions, etc.
  if command -v pyenv-virtualenv-init &>/dev/null; then
    eval "$(pyenv virtualenv-init -)" # Initialize virtualenv plugin if present
  fi
fi

# --- Direnv (Per-directory Environment Variables) ---
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# --- Starship Prompt ---
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# --- Atuin (Enhanced Shell History) ---
# Check default binary location, adjust if installed elsewhere
local atuin_env="${XDG_CONFIG_HOME:-$HOME/.config}/atuin/env.zsh"
if [[ -f "$atuin_env" ]]; then
  source "$atuin_env"
elif [[ -f "$HOME/.atuin/bin/env" ]]; then # Older location?
  source "$HOME/.atuin/bin/env"
fi
unset atuin_env

# --- Wezterm Shell Integration ---
local wezterm_int="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/shell-integration.zsh"
if [[ -f "$wezterm_int" ]]; then
    source "$wezterm_int"
fi
unset wezterm_int


# --- Google Cloud SDK ---
local gcloud_path_inc="$HOME/google-cloud-sdk/path.zsh.inc" # Common location
local gcloud_path_inc_local="$HOME/.local/google-cloud-sdk/path.zsh.inc" # Your original location

if [[ -f "$gcloud_path_inc" ]]; then
    source "$gcloud_path_inc"
elif [[ -f "$gcloud_path_inc_local" ]]; then
    source "$gcloud_path_inc_local"
fi
unset gcloud_path_inc gcloud_path_inc_local
