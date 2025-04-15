# ==============================================================================
# Utility Command-Line Tools installed via ZI
# ==============================================================================

# Use zi to install binaries from GitHub releases or other sources

# --- Core Utilities (fzf, fd, bat) ---
# `from"gh-r"`: Install from GitHub releases
# `as"null"`: Don't source any plugin files, just add binary to path via `sbin` ice
# `sbin"..."`: Specify the binary name(s) within the release/repo
zi wait lucid from"gh-r" as"null" for \
  sbin"fzf" junegunn/fzf \
  sbin"**/fd" sharkdp/fd \
  sbin"**/bat" sharkdp/bat \
  sbin"eza" eza-community/eza # Install eza via zi

# --- Zoxide (Smarter cd) ---
# Installs from gh-r and runs init script to set up alias/function (often `x` or `z`)
zi ice as"program" from"gh-r" \
  atpull'./zoxide init --cmd z zsh >| init.zsh' \
  atload'source init.zsh' \
  blockf lucid wait
zi light ajeetdsouza/zoxide

# --- Parallel Shell (pash) ---
# Requires GPG
zi ice lucid wait as'program' has'gpg' blockf
zi light dylanaraps/pash

# --- Prettier Ping ---
# Requires ping
zi ice lucid wait as'program' pick'prettyping' has'ping' blockf
zi light denilsonsa/prettyping

# --- Git Addons ---
# Install various git helper scripts/binaries
zi wait"1" lucid as"null" blockf for \
  sbin Fakerr/git-recall \
  sbin paulirish/git-open \
  sbin paulirish/git-recent \
  sbin davidosomething/git-my \
  sbin arzzen/git-quick-stats \
  make'PREFIX=$ZPFX install' sbin'**/git-extras' tj/git-extras # Compile git-extras

# --- Other Tools ---
# Add more tools here as needed
