# ==============================================================================
# Dynamic and Tool-Specific Completions
# ==============================================================================
local completions_dir="${ZDOTDIR:-$HOME/.config/zsh}/completions"

# --- Docker ---
# Uncomment if Docker is used and completions are desired
# Check common completion locations or use Docker's own command if available
# if command -v docker >/dev/null && [[ -d "$HOME/.docker/completions/zsh" ]]; then
#   fpath=($HOME/.docker/completions/zsh $fpath)
# elif command -v docker >/dev/null; then
#   # Potentially generate dynamically? Requires checking Docker's current methods
#   # zi ice id-as"docker_completion" has"docker" eval"docker completion zsh" run-atpull blockf
#   # zi light z-shell/null
# fi

# --- Kubernetes (kubectl) ---
# Uses zi to dynamically generate completions via `kubectl completion zsh`
# zi ice id-as"kubectl_completion" has"kubectl" \
#   eval"kubectl completion zsh" run-atpull blockf lucid wait"3" # Defer slightly more
# zi light z-shell/null

# --- ngrok ---
# Uses zi to dynamically generate completions via `ngrok completion`
# zi ice id-as"ngrok_completion" has"ngrok" \
#   eval'ngrok completion' run-atpull blockf lucid wait"3"
# zi light z-shell/null

# --- Google Cloud SDK ---
# Load completions provided by the SDK itself
# local gcloud_comp_inc="$HOME/google-cloud-sdk/completion.zsh.inc"
# local gcloud_comp_inc_local="$HOME/.local/google-cloud-sdk/completion.zsh.inc" # Your original location
# if [[ -f "$gcloud_comp_inc" ]]; then
#   zi ice lucid wait as'completion' blockf has'gcloud' id-as'gcloud_completion'
#   zi snippet "$gcloud_comp_inc"
# elif [[ -f "$gcloud_comp_inc_local" ]]; then
#    zi ice lucid wait as'completion' blockf has'gcloud' id-as'gcloud_completion'
#    zi snippet "$gcloud_comp_inc_local"
# fi
# unset gcloud_comp_inc gcloud_comp_inc_local


# --- Wayland Clipboard (wl-copy/wl-paste) - Linux Only ---
if [[ "$(uname)" == "Linux" ]]; then
  zi ice lucid wait as'completion' blockf has'wl-copy' id-as'wl-copy_completion' \
    src"$completions_dir/_wl-copy" # Load from local vendored file
  zi light z-shell/null

  zi ice lucid wait as'completion' blockf has'wl-paste' id-as'wl-paste_completion' \
    src"$completions_dir/_wl-paste" # Load from local vendored file
  zi light z-shell/null
fi

# --- Ripgrep (rg) ---
zi ice lucid wait as'completion' blockf has'rg' id-as'rg_completion' \
  src"$completions_dir/_rg"
zi light z-shell/null

# --- Tealdeer (tldr) ---
# zi ice lucid wait as'completion' blockf has'tldr' id-as'tldr_completion' \
#   src"$completions_dir/_tldr"
# zi light z-shell/null

# --- Buku Bookmarks ---
# zi ice lucid wait as'completion' blockf has'buku' id-as'buku_completion' \
#   src"$completions_dir/_buku"
# zi light z-shell/null

# --- Pandoc ---
# Uses a dedicated completion plugin
# zi ice lucid wait as'completion' blockf has'pandoc' id-as'pandoc_completion'
# zi light srijanshetty/zsh-pandoc-completion

unset completions_dir
