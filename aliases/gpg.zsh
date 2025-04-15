# ============================================
# GPG Aliases
# --------------------------------------------
# Key Listing & Fingerprints
# --------------------------------------------
# List public keys (short ID format) - Existing
alias gpg.list='gpg --list-keys --keyid-format SHORT'
# List public keys (long ID format)
alias gpg.list.long='gpg --list-keys --keyid-format LONG'
# List public keys with full fingerprints
alias gpg.list.fp='gpg --fingerprint'
# List secret keys (short ID format)
alias gpg.list.sec='gpg --list-secret-keys --keyid-format SHORT'
# List secret keys with full fingerprints
alias gpg.list.sec.fp='gpg --list-secret-keys --fingerprint'

# --------------------------------------------
# Key Management (Import, Export, Edit, Revoke)
# --------------------------------------------
# Import keys from a file (append FILENAME)
alias gpg.import='gpg --import'
# Export a public key (ASCII armored) (append KEYID)
alias gpg.export='gpg --armor --export'
# Export a public key (binary) (append KEYID)
alias gpg.export.bin='gpg --export'
# Edit a key (trust, add UID, expire, etc.) (append KEYID)
alias gpg.edit='gpg --edit-key'
# Generate a revocation certificate for a key (append KEYID)
# (Outputs to revocation_cert.asc by default)
alias gpg.gen.revoke='gpg --output revocation_cert.asc --gen-revoke'
# Export *secret* keys (ASCII armored) - !! Use with extreme caution !! (append KEYID)
# alias gpg.export.secret='gpg --armor --export-secret-keys'

# --------------------------------------------
# Keyserver Interaction
# --------------------------------------------
# Receive keys from a keyserver (append KEYIDs)
alias gpg.recv='gpg --recv-keys'
# Refresh keys from a keyserver (updates local keys from server)
alias gpg.refresh='gpg --refresh-keys'
# Send keys to a keyserver (append KEYIDs)
alias gpg.send='gpg --send-keys'
# Search for keys on a keyserver (append SEARCH TERM)
alias gpg.search='gpg --search-keys'

# --------------------------------------------
# Encryption
# --------------------------------------------
# Encrypt a file for recipient(s) (ASCII armored)
# (Append -r RECIPIENT [ -r NEXT_RECIPIENT... ] FILENAME)
alias gpg.encrypt='gpg --armor --encrypt'
# Encrypt and sign a file for recipient(s) (ASCII armored, uses default key for signing)
# (Append -r RECIPIENT [ -r NEXT_RECIPIENT... ] FILENAME)
alias gpg.encrypt.sign='gpg --armor --sign --encrypt'
# Encrypt file symmetrically (password-based) (ASCII armored)
# (Shorthand for --symmetric --armor) (append FILENAME)
alias gpg.encrypt.sym='gpg -ca'

# --------------------------------------------
# Decryption
# --------------------------------------------
# Decrypt a file or message (auto-detects format)
# (Append FILENAME. Add '-o OUTFILE' to direct output)
alias gpg.decrypt='gpg --decrypt'

# --------------------------------------------
# Signing (Uses default key)
# --------------------------------------------
# Create a detached signature (ASCII armored)
# (Append FILENAME. Creates FILENAME.asc)
alias gpg.sign='gpg --armor --detach-sign'
# Create a clear-signed message (human-readable + signature)
# (Append FILENAME. Creates FILENAME.asc)
alias gpg.sign.clear='gpg --clear-sign'
# Sign file with default key (non-detached, ASCII armored)
# (Append FILENAME. Creates FILENAME.asc containing signed data)
# alias gpg.sign.inline='gpg --armor --sign' # Less common for files, often clear-sign is preferred

# --------------------------------------------
# Verification
# --------------------------------------------
# Verify a signature
# (Append SIGNATURE_FILE [ORIGINAL_FILE if detached])
alias gpg.verify='gpg --verify'