# ~/.config/zsh/conf.d/50_aliases.zsh
# ==============================================================================
# Shell Aliases
# ==============================================================================

# --- Load Aliases from Local Snippets (Vendored from Gists) ---
# Assumes files exist in ~/.config/zsh/aliases/
local alias_dir="${ZDOTDIR:-$HOME/.config/zsh}/aliases"
zi snippet "$alias_dir/remote.zsh"
zi snippet "$alias_dir/network-info.zsh"
zi snippet "$alias_dir/gpg.zsh"
zi snippet "$alias_dir/ssh.zsh"
zi snippet "$alias_dir/openssl.zsh"
zi snippet "$alias_dir/nmap.zsh"
unset alias_dir

# --- Define Core Aliases Function ---
_define_aliases() {
  # -- Navigation --
  # Assuming zoxide is installed via zi and initialized to `z` in 41_plugins_tools.zsh
  # alias z='z' # Explicitly map z to zoxide if needed, often done by init
  # alias j='autojump' # If using autojump (sourced in 60_external...)

  # -- Editors --
  alias v='nvim'
  alias vi='nvim'
  alias vim='nvim'
  alias e='$EDITOR'

  # -- File Management --
  # Use eza if available (could be installed by zi in 41_plugins_tools or system)
  # These override the basic ones potentially set by zsh-eza plugin in 42_plugins_defer.zsh
  if command -v eza &>/dev/null; then
    alias ls='eza --git --color=always --icons' # Add --icons if font supports it
    alias l='ls -1' # List one file per line
    alias ll='ls -l --header --time-style=long-iso' # Long format
    alias la='ll -a --git-ignore' # Long format, all files, gitignored
    alias lt='ls --tree --level=3' # Tree view
    alias tree='lt'
    alias llm='ll --sort=modified' # Sort by modified date
    alias la='eza -lbhHigUmuSa' # Original complex alias
    alias lx='eza -lbhHigUmuSa@' # Original complex alias
  else
    # Fallback to GNU ls options if eza not found
    if ls --color=auto > /dev/null 2>&1; then # Check if ls supports --color
      alias ls='ls --color=auto -F'
      alias ll='ls -lh'
      alias la='ls -lha'
    else # Basic fallback (e.g., some macOS default ls)
      alias ls='ls -F'
      alias ll='ls -lh' # -h might not be available everywhere
      alias la='ls -la'
    fi
    alias lt='find . -maxdepth 3 -print | sed -e "s;[^/]*/;|____;g;s;____|; |;g"' # Basic tree simulation
    alias tree='lt'
  fi

  # -- System Info & Management --
  alias df='df -kh'
  alias du='du -kh'
  alias psg='ps aux | grep' # Grep processes

  # -- Networking --
  alias ping='ping -c 5' # Limit ping count
  alias hosts='sudo $EDITOR /etc/hosts'

  # -- Application Specific (Example) --
  # Check for macOS Surge CLI tool
  if [[ "$(uname)" == "Darwin" ]] && [[ -f '/Applications/Surge.app/Contents/Applications/surge-cli' ]]; then
    alias st='/Applications/Surge.app/Contents/Applications/surge-cli'
  fi

  # -- Safety --
  alias cp='cp -i' # Confirm before overwriting
  alias mv='mv -i'
  alias rm='rm -i' # Use with caution, many prefer not aliasing rm

  # -- Convenience --
  alias ..='cd ..'
  alias ...='cd ../..'
  alias c='clear'
  alias h='history'
  alias mkdir='mkdir -pv' # Create parent dirs, verbose
}

# --- Load the Aliases ---
# Use `zi ice` to ensure the function is defined and then call it.
# `id-as` prevents reloading if sourced multiple times.
# `atload` executes the function *after* the (null) plugin is notionally "loaded".
zi ice lucid wait blockf id-as"custom_aliases" \
  atload'_define_aliases'
zi light z-shell/null # Use a dummy plugin to hang the atload hook on
