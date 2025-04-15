# ~/.zshrc
# ==============================================================================
# Main Zsh configuration file. Loads modular configuration files.
# ==============================================================================

# Set ZDOTDIR config files in ~/.config/zsh instead of ~/.zsh*
export ZDOTDIR="$HOME/.config/zsh"

# --- Configuration Directory ---
# All modular config files are expected here.
ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/conf.d"

# --- Source Modular Configuration Files ---
if [[ -d "$ZSH_CONFIG_DIR" ]]; then
  # Set ZI_HOME before sourcing the init file
  export ZI_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zi/zi.zsh"

  # Source files in numerical order
  for config_file ("$ZSH_CONFIG_DIR"/[0-9][0-9]_*.zsh); do
    if [[ -f "$config_file" ]]; then
      source "$config_file"
    fi
  done
  unset config_file
else
  print -P "%F{red}Error: Zsh configuration directory not found at '$ZSH_CONFIG_DIR'%f"
fi

unset ZSH_CONFIG_DIR
