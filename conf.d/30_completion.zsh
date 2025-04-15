# ==============================================================================
# Zsh Completion System Setup & Styling
# ==============================================================================

# --- Initialize Completion System ---
# Load base functionalities (history/syntax/completion related)
# Note: F-Sy-H often bundles syntax highlighting and history multi-word search
zi ice wait'0' lucid blockf
zi load z-shell/F-Sy-H

# Initialize Zsh's completion system via zi & Prezto module
# `zicompinit`: Initializes compinit efficiently
# `zicdreplay`: Replays completion cache if available
zi ice wait'0' lucid blockf atinit'zicompinit; zicdreplay'
zi snippet PZT::modules/completion/init.zsh

# --- Load Essential Completion Plugins ---
zi ice wait lucid blockf # Wait for completion system before loading these
zi light zsh-users/zsh-completions # Collection of completion definitions

# --- Completion Styling Function ---
# This function will be called after F-Sy-H is loaded (see atload below)
_zstyle_config() {
  # General completion configuration
  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*:match:*' original only
  zstyle ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

  # Grouping and formatting
  zstyle ':completion:*:matches' group 'yes'
  zstyle ':completion:*:options' description 'yes'
  zstyle ':completion:*:options' auto-description '%d'
  zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
  zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
  zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
  zstyle ':completion:*:default' list-prompt '%S%M matches%s'
  zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*' verbose yes

  # Matching and behavior
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
  zstyle ':completion:*' use-cache true # Enable completion caching
  zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache" # Use XDG cache dir
  zstyle ':completion:*' rehash true # Rehash cache if completion dirs change
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # Use LS_COLORS for completion highlighting

  # --- Plugin-Specific Styles ---
  # History Search Multi Word (if F-Sy-H provides it)
  zstyle ':plugin:history-search-multi-word' page-size "10"
  zstyle ':plugin:history-search-multi-word' highlight-color "fg=yellow,bold"
  zstyle ':plugin:history-search-multi-word' synhl "yes"
  zstyle ':plugin:history-search-multi-word' active "underline"
  zstyle ':plugin:history-search-multi-word' check-paths "yes"
  zstyle ':plugin:history-search-multi-word' clear-on-cancel "no"

  # Custom highlight styles for HSMW
  typeset -gA HSMW_HIGHLIGHT_STYLES
  HSMW_HIGHLIGHT_STYLES[path]="bg=magenta,fg=white,bold"
  HSMW_HIGHLIGHT_STYLES[single-hyphen-option]="fg=cyan"
  HSMW_HIGHLIGHT_STYLES[double-hyphen-option]="fg=cyan"
  HSMW_HIGHLIGHT_STYLES[commandseparator]="fg=241,bg=17"

  # fzf-tab completion styling (if using fzf-tab)
  # zstyle ':completion:*' fzf-preview 'bat --color=always $realpath' # Example
  # zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always $realpath' # Example
}

# --- Trigger Styling Function ---
# Use atload to ensure F-Sy-H is loaded before applying styles
# This second `zi light` load is primarily to attach the `atload` hook reliably.
zi ice wait lucid blockf atload'_zstyle_config'
zi light z-shell/F-Sy-H
