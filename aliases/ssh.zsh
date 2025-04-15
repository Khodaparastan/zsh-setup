# ============================================
# SSH Related Aliases
# --------------------------------------------
# Connection Options & Verbosity
# --------------------------------------------
# Connect disabling password authentication (force key-based)
# (Append user@host)
alias sshnp='ssh -o PasswordAuthentication=no'
# Connect with SSH Agent Forwarding (Use cautiously!)
# (Append user@host)
alias ssha='ssh -A'
# Connect with X11 Forwarding (If needed for GUI apps)
# (Append user@host)
alias sshx='ssh -X'
# Connect with verbose output (Level 1)
# (Append user@host)
alias sshv='ssh -v'
# Connect with very verbose output (Level 2)
# (Append user@host)
alias sshvv='ssh -vv'
# Connect with debug level verbose output (Level 3)
# (Append user@host)
alias sshvvv='ssh -vvv'
# Connect forcing pseudo-terminal allocation (for running remote interactive commands)
# (Append user@host command)
alias ssht='ssh -t'

# --------------------------------------------
# Port Forwarding Shortcuts
# --------------------------------------------
# Setup Local Port Forwarding (-L)
# (Append local_port:target_host:target_port user@gateway_host)
alias sshfl='ssh -N -L' # -N: Do not execute a remote command, just forward
# Setup Remote Port Forwarding (-R)
# (Append remote_port:local_target_host:local_target_port user@gateway_host)
alias sshfr='ssh -N -R' # -N: Do not execute a remote command, just forward
# Setup Dynamic Port Forwarding / SOCKS Proxy (-D)
# (Append local_socks_port user@gateway_host)
alias sshdyn='ssh -N -D' # -N: Do not execute a remote command, just forward

# --------------------------------------------
# SSH Key Generation & Management
# --------------------------------------------
# Generate a new Ed25519 SSH key pair (recommended type)
# (Prompts for file and passphrase)
alias sshkey='ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)-$(date -I)"'
# Generate a new RSA 4096 SSH key pair
# (Prompts for file and passphrase)
alias sshkeyrsa='ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)-$(date -I)"'
# Copy your public SSH key to a remote host for passwordless login
# (Append user@host)
alias sshcopy='ssh-copy-id'
# Show the fingerprint of a specific public key file
# (Append path/to/your/key.pub)
alias sshfingerprint='ssh-keygen -lf'
# Show the fingerprint of a specific private key file
# (Append path/to/your/private_key)
alias sshfingerprintprv='ssh-keygen -yf'


# --------------------------------------------
# SSH Agent Management
# --------------------------------------------
# Add an SSH key to the agent (prompts for passphrase if needed)
# (Append path/to/private_key, e.g., ~/.ssh/id_ed25519)
alias sshadd='ssh-add'
# List keys currently loaded in the SSH agent
alias sshaddls='ssh-add -l'
# List keys with full public key fingerprint
alias sshaddfls='ssh-add -L'
# Delete a specific key from the SSH agent
# (Append path/to/private_key)
alias sshadddelkey='ssh-add -d'
# Delete ALL keys from the SSH agent
alias sshadddelall='ssh-add -D'
# Add key with a specific lifetime (e.g., 1h, 30m, 3600)
# (Append -t lifetime path/to/private_key)
alias sshaddt='ssh-add -t'

# --------------------------------------------
# SSH Connection Multiplexing (ControlMaster)
# Requires setup in ~/.ssh/config for ControlPath
# --------------------------------------------
# Check the status of a ControlMaster connection
# (Append host defined in ~/.ssh/config using ControlMaster)
alias sshchk='ssh -O check'
# Request exit (termination) of a ControlMaster connection
# (Append host defined in ~/.ssh/config using ControlMaster)
alias sshexit='ssh -O exit'