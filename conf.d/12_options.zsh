# ==============================================================================
# Zsh Shell Options
# ==============================================================================

# Load prezto modules via zi for base options
# History settings
zi ice lucid wait'0' blockf # blockf: only for interactive shells
zi snippet PZT::modules/history/init.zsh

# Utility settings
zi ice lucid wait'0' blockf
zi snippet PZT::modules/utility/init.zsh

# --- Additional Core Zsh Options ---
setopt auto_cd              # Change directory without cd
setopt auto_list            # Automatically list choices on ambiguous completion
setopt auto_menu            # Show completion menu on successive tabs
setopt auto_param_slash     # If completing a directory, add a trailing slash
setopt auto_pushd           # Make cd push the old directory onto the stack
setopt extended_glob        # Use extended globbing features
setopt glob_dots            # Include dotfiles in globbing results
setopt interactive_comments # Allow comments in interactive shell
setopt long_list_jobs       # List jobs in long format by default
setopt mark_dirs            # Append slash to completed directory names
setopt multios              # Allow multiple redirections (e.g., tee > >(cmd))
setopt no_beep              # No audible bell on errors
setopt pushd_ignore_dups    # Don't push duplicate directories onto the stack
setopt pushd_silent         # Do not print the directory stack after pushd or popd
setopt prompt_subst         # Allow parameter expansion, command substitution in prompts

# --- History Options (Complementing Prezto Module) ---
setopt append_history       # Append to history file, don't overwrite
setopt hist_expire_dups_first # Expire duplicate entries first when trimming history
setopt hist_ignore_dups     # Don't record immediately preceding duplicate commands
setopt hist_ignore_space    # Don't record commands starting with whitespace
setopt hist_find_no_dups    # When searching history, show newest entry first
setopt hist_reduce_blanks   # Remove superfluous blanks from history items
setopt hist_verify          # Show command from history before executing upon expansion
setopt inc_append_history   # Write history incrementally, not just on shell exit
setopt share_history        # Share history between all sessions

# Variables for history file location (use XDG spec)
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
export HISTSIZE=10000        # Lines of history kept in memory
export SAVEHIST=10000        # Lines of history saved to HISTFILE
mkdir -p "$(dirname "$HISTFILE")" # Ensure directory exists
