# ============================================
# OpenSSL Aliases (ossl.*)
# --------------------------------------------
# Hashing / Message Digests
# --------------------------------------------
# Calculate MD5 hash of a file (Use SHA instead where possible)
# (Append FILENAME)
alias ossl.hash.md5='openssl dgst -md5'
# Calculate SHA1 hash of a file (Use SHA256+ where possible)
# (Append FILENAME)
alias ossl.hash.sha1='openssl dgst -sha1'
# Calculate SHA256 hash of a file
# (Append FILENAME)
alias ossl.hash.sha256='openssl dgst -sha256'
# Calculate SHA512 hash of a file
# (Append FILENAME)
alias ossl.hash.sha512='openssl dgst -sha512'

# --------------------------------------------
# Encoding / Decoding
# --------------------------------------------
# Base64 encode stdin or file (Append -in INFILE -out OUTFILE if not using stdin/stdout)
alias ossl.b64.enc='openssl base64 -e'
# Base64 decode stdin or file (Append -in INFILE -out OUTFILE if not using stdin/stdout)
alias ossl.b64.dec='openssl base64 -d'

# --------------------------------------------
# Random Data Generation
# --------------------------------------------
# Generate random bytes (Append BYTE_COUNT, e.g., 32)
alias ossl.rand.bytes='openssl rand'
# Generate random hex string (Append BYTE_COUNT, e.g., 32)
alias ossl.rand.hex='openssl rand -hex'
# Generate random base64 string (Append BYTE_COUNT, e.g., 32)
alias ossl.rand.b64='openssl rand -base64'

# --------------------------------------------
# Key Generation & Management
# --------------------------------------------
# Generate RSA private key (encrypts with AES256, prompts for passphrase)
# (Append -out private.key 4096) - 4096 bits recommended
alias ossl.gen.rsa='openssl genrsa -aes256'
# Generate unencrypted RSA private key (Less secure storage, useful for automation)
# (Append -out private.key 4096)
alias ossl.gen.rsa.nodes='openssl genrsa'
# Generate EC private key (using specified curve, e.g., prime256v1 or secp384r1)
# (Append -name prime256v1 -genkey -noout -out ec_private.key)
alias ossl.gen.ec='openssl ecparam'
# List available EC curves supported by openssl
alias ossl.list.eccurves='openssl ecparam -list_curves'
# Extract public key from a private key (RSA or EC)
# (Append -in private.key -pubout -out public.key)
alias ossl.get.pubkey='openssl pkey -pubout'
# Check private key consistency and print details
# (Append -in private.key -check -text -noout)
alias ossl.check.key='openssl pkey -check -text -noout'
# Remove passphrase from a private key (Requires original passphrase)
# (Append -in encrypted.key -out decrypted.key)
alias ossl.key.rmpass='openssl pkey' # Works for RSA & EC; use `openssl rsa` for older OpenSSL versions

# --------------------------------------------
# Certificate Signing Request (CSR) Generation
# --------------------------------------------
# Generate CSR from an existing private key (Interactive for subject details)
# (Append -key private.key -out request.csr)
alias ossl.gen.csr='openssl req -new -sha256'
# Generate NEW private key (RSA 2048, unencrypted) AND CSR in one go (Interactive)
# (Append -keyout domain.key -out domain.csr -subj "/C=CA/ST=BC/L=Vancouver/O=My Org/CN=mydomain.com")
alias ossl.gen.keycsr='openssl req -new -newkey rsa:2048 -nodes -sha256' # Add -subj '...' for non-interactive

# --------------------------------------------
# Self-Signed Certificate Generation
# --------------------------------------------
# Generate NEW key (RSA 4096, unencrypted) and Self-Signed Cert (365 days)
# (Interactive for subject. Append -keyout key.pem -out cert.pem)
# (Add -subj '/C=CA/ST=BC/O=Test/CN=localhost' for non-interactive)
alias ossl.gen.selfcert='openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 365'

# --------------------------------------------
# Viewing Certificates, Keys, CSRs, PKCS12
# --------------------------------------------
# View details of a Certificate (PEM format)
# (Append -in certificate.crt)
alias ossl.view.cert='openssl x509 -noout -text'
# View validity dates of a Certificate
# (Append -in certificate.crt)
alias ossl.view.cert.dates='openssl x509 -noout -startdate -enddate'
# View subject of a Certificate
# (Append -in certificate.crt)
alias ossl.view.cert.subject='openssl x509 -noout -subject'
# View issuer of a Certificate
# (Append -in certificate.crt)
alias ossl.view.cert.issuer='openssl x509 -noout -issuer'
# View serial number of a Certificate
# (Append -in certificate.crt)
alias ossl.view.cert.serial='openssl x509 -noout -serial'
# View fingerprint (SHA256) of a Certificate
# (Append -in certificate.crt)
alias ossl.view.cert.fp256='openssl x509 -noout -fingerprint -sha256'
# View details of a CSR (and verify its signature)
# (Append -in request.csr)
alias ossl.view.csr='openssl req -noout -text -verify'
# View details of a private key
# (Append -in private.key)
alias ossl.view.key='openssl pkey -noout -text'
# View details of a PKCS#12 file (.pfx, .p12) - Prompts for import password
# (Append -in keystore.p12)
alias ossl.view.p12='openssl pkcs12 -info' # Removed -noout to see components

# --------------------------------------------
# Verification & Matching (Using helper functions for logic)
# --------------------------------------------
# Verify certificate chain against CA file/path
# (Append -CAfile /path/to/ca-bundle.pem /path/to/certificate.pem)
# (Or use -CApath /path/to/ca_dir/)
alias ossl.verify.cert='openssl verify'

# Helper function to compare moduli MD5 hashes
_ossl_compare_md5() {
  local type1_label="$1"
  local type1_cmd="$2"
  local file1="$3"
  local type2_label="$4"
  local type2_cmd="$5"
  local file2="$6"

  if [ ! -f "$file1" ]; then echo "ERROR: File not found: $file1"; return 2; fi
  if [ ! -f "$file2" ]; then echo "ERROR: File not found: $file2"; return 2; fi

  local mod1=$(openssl $type1_cmd -noout -modulus -in "$file1" 2>/dev/null | openssl md5)
  local mod2=$(openssl $type2_cmd -noout -modulus -in "$file2" 2>/dev/null | openssl md5)

  if [ -z "$mod1" ] || [ -z "$mod2" ]; then
      echo "ERROR: Could not compute modulus for one or both files ($file1, $file2)."
      echo "       Ensure files are valid and passwords (if any) are handled correctly."
      return 3
  fi

  echo "$type1_label Modulus MD5 ($file1): $mod1"
  echo "$type2_label Modulus MD5 ($file2): $mod2"

  if [ "$mod1" = "$mod2" ]; then
    echo "OK: Moduli match."
    return 0
  else
    echo "ERROR: Moduli do NOT match."
    return 1
  fi
}

# Check if Private Key matches Certificate public key
# (Usage: ossl.check.match cert.pem key.pem)
alias ossl.check.match='_ossl_compare_md5 Certificate x509 "$1" "Private Key" pkey "$2"'

# Check if Private Key matches CSR public key
# (Usage: ossl.check.match.csr csr.pem key.pem)
alias ossl.check.match.csr='_ossl_compare_md5 CSR req "$1" "Private Key" pkey "$2"'


# --------------------------------------------
# Format Conversion
# --------------------------------------------
# Convert Certificate: PEM -> DER
# (Append -in certificate.pem -out certificate.der)
alias ossl.conv.pem2der='openssl x509 -outform der'
# Convert Certificate: DER -> PEM
# (Append -inform der -in certificate.der -out certificate.pem)
alias ossl.conv.der2pem='openssl x509 -inform der -outform pem'
# Convert Private Key: PEM -> DER
# (Append -in key.pem -out key.der)
alias ossl.conv.pemkey2der='openssl pkey -outform der'
# Convert Private Key: DER -> PEM
# (Append -inform der -in key.der -out key.pem)
alias ossl.conv.derkey2pem='openssl pkey -inform der -outform pem'
# Convert PKCS#7 (often .p7b) -> PEM (usually contains cert chain)
# (Append -in certs.p7b -print_certs -out certs.pem)
alias ossl.conv.p7btopem='openssl pkcs7 -print_certs'
# Convert PEM -> PKCS#7 (.p7b) (useful for bundling certs)
# (Append -certfile cert1.pem [-certfile cert2.pem...] -out bundle.p7b -nocrl)
alias ossl.conv.pemtop7b='openssl crl2pkcs7 -nocrl'
# Convert PKCS#12 (.pfx/.p12) -> PEM (extracts certs AND unencrypted key) - Prompts for import pass
# (Append -in keystore.p12 -out output.pem)
alias ossl.conv.p12topem='openssl pkcs12 -nodes'
# Convert PKCS#12 -> PEM (certs only) - Prompts for import pass
# (Append -in keystore.p12 -nokeys -out certs_only.pem)
alias ossl.conv.p12topem.certs='openssl pkcs12 -nokeys'
# Convert PKCS#12 -> PEM (key only, unencrypted) - Prompts for import pass AND new PEM pass
# (Append -in keystore.p12 -nocerts -nodes -out key_only.pem)
alias ossl.conv.p12topem.key='openssl pkcs12 -nocerts -nodes'
# Convert PEM Key + Cert(s) -> PKCS#12 (.pfx/.p12) (prompts for export password)
# (Append -inkey private.key -in certificate.crt [-certfile chain.pem] -export -out keystore.p12 -name "Friendly Name")
alias ossl.conv.pemtop12='openssl pkcs12 -export'

# --------------------------------------------
# SSL/TLS Client/Server Testing
# --------------------------------------------
# Connect to TLS server (interactive)
# (Append -connect host:port [-servername name_for_sni])
alias ossl.test.client='openssl s_client'
# Connect and show server certificate chain
# (Append -connect host:port [-servername name_for_sni])
alias ossl.test.client.showcerts='openssl s_client -showcerts'
# Connect non-interactively (closes after handshake, good for scripting checks)
# Use: echo | ossl.test.client.noninteractive -connect host:port [-servername name]
alias ossl.test.client.noninteractive='openssl s_client' # Needs input like `echo |` or `< /dev/null` or `printf "Q" |`
# Run simple TLS test server (requires cert & key, listens on 4433 by default)
# (Append -cert certificate.pem -key private.key [-accept port] [-WWW replies with simple HTML])
alias ossl.test.server='openssl s_server'

# --------------------------------------------
# Cipher Information
# --------------------------------------------
# List available TLS ciphers (verbose format)
alias ossl.ciphers.list='openssl ciphers -v'
# Test specific cipher(s) against a server (e.g., -cipher AES256-GCM-SHA384)
# (Append -cipher CipherSuiteString -connect host:port [-servername name])
alias ossl.ciphers.test='openssl s_client'