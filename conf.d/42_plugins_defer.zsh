# ==============================================================================
# Deferred Plugins (Loaded Later for Faster Startup)
# ==============================================================================

# Use `wait"N"` to load these plugins after the prompt is ready

# Wait level 2 (slightly more delay)
zi wait"2" lucid blockf for \
  z-shell/zsh-diff-so-fancy \
  voronkovich/gitignore.plugin.zsh \
  z-shell/H-S-MW # History Search Multi Word (might be part of F-Sy-H already?)

# Use zi's pack system for potentially optimized loading of related items
zi wait"2" lucid pack"default" for \
  ls_colors # Plugin providing LS_COLORS definitions?

# --- Conditional Deferred Loads ---

# Brew completions (only if brew exists)
if command -v brew &>/dev/null; then
  zi wait"2" lucid pack"brew" blockf for brew-completions
fi

# eza integration (if eza installed - e.g., via zi above or system)
# Provides aliases and potentially completions for eza
zi wait"2" lucid as"null" has"eza" blockf for \
  atinit"alias ls='eza --git --color=always' && alias la='ls -a' && alias ll='ls -l'" \
  z-shell/zsh-eza
  # Note: Aliases are also defined in 50_aliases.zsh, ensure no conflicts or choose one method.
