# ==============================================================================
# Key Bindings Setup
# ==============================================================================

# --- Define Keybinding Setup Function ---
_setup_keybindings() {
  # --- Zsh Navigation Tools (ZNT) Bindings ---
  # Ensure widgets are available before binding
  if command -v znt-history-widget >/dev/null 2>&1; then
    zle -N znt-history-widget
    bindkey "^R" znt-history-widget # Ctrl+R for ZNT history search
  fi

  if command -v znt-cd-widget >/dev/null 2>&1; then
    zle -N znt-cd-widget
    bindkey "^B" znt-cd-widget # Ctrl+B for ZNT cd widget
  fi

  if command -v znt-kill-widget >/dev/null 2>&1; then
    zle -N znt-kill-widget
    bindkey "^Y" znt-kill-widget # Ctrl+Y for ZNT kill widget
  fi

  # --- fzf Keybindings (if fzf installed externally and configured) ---
  # Sourced via ~/.fzf.zsh in 60_external_tools.zsh usually handles this.
  # Example manual bindings:
  # bindkey '^T' fzf-file-widget # Ctrl+T for fzf file search
  # bindkey '^R' fzf-history-widget # Ctrl+R for fzf history search (conflicts with ZNT default)
  # bindkey '^[c' fzf-cd-widget # Alt+C for fzf directory change

  # --- Other Custom Bindings ---
  # bindkey '...' ...
}

# --- Load Plugins Providing Widgets & Trigger Setup ---
# Load ZNT and trigger the binding function after it's loaded
zi ice wait lucid blockf atload'_setup_keybindings'
zi light z-shell/zsh-navigation-tools

# Note: Ensure there are no conflicting bindings (e.g., Ctrl+R)
