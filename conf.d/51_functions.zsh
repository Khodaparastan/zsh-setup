# ~/.config/zsh/conf.d/51_functions.zsh
# ==============================================================================
# Custom Shell Functions
# ==============================================================================

# --- Define Custom Functions ---
_define_functions() {

  # -- Yazi File Manager Integration --
  # Changes directory in the shell after Yazi exits
  function y() {
    # Prevent nested invocations
    if [ -n "$YAZI_LEVEL" ]; then
      print -P "%F{red}Already inside Yazi.%f"
      return 1
    fi

    # Ensure yazi command exists
    if ! command -v yazi >/dev/null 2>&1; then
      print -P "%F{red}yazi command not found.%f"
      return 1
    fi

    # Create a temporary file securely for CWD passing
    local tmp
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1 # Exit if mktemp fails
    chmod 600 "$tmp" # Restrict permissions

    # Launch yazi, instructing it to write CWD to the temp file on exit
    # Add YAZI_LOG=debug for debugging yazi itself
    YAZI_LOG=error yazi "$@" --cwd-file="$tmp"

    local yazi_exit_code=$? # Capture yazi's exit code

    # Check if the temp file exists and contains a path
    if [[ -f "$tmp" ]]; then
      local cwd
      cwd="$(<"$tmp")" # Read the CWD from the file
      rm -f -- "$tmp" # Clean up the temp file immediately

      # If CWD is valid and different from current PWD, change directory
      if [[ -n "$cwd" ]] && [[ -d "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
        print -P "%F{cyan}Changing directory to: %F{green}$cwd%f"
        cd -- "$cwd"
      fi
    fi
    return $yazi_exit_code # Return yazi's exit code
  }

  # -- Other Functions --
  # function my_func() { ... }

}

# --- Load the Functions ---
zi ice lucid wait blockf id-as"custom_functions" \
  atload'_define_functions'
zi light z-shell/null
