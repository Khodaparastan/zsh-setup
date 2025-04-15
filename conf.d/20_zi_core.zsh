# ==============================================================================
# ZI Core Configuration & Annexes
# ==============================================================================

# --- ZI Annexes ---
# Load core extensions first for enhanced zi functionality
zi light-mode for \
  z-shell/z-a-meta-plugins \
  z-shell/z-a-bin-gem-node \
  z-shell/z-a-patch-dl \
  z-shell/z-a-readurl \
  z-shell/z-a-unscope \
  z-shell/z-a-linkbin \
  z-shell/z-a-eval \
  @annexes

# --- Other Core ZI Settings (if any) ---
# e.g., zstyle ':zi:theme:*' preset 'cybery'
