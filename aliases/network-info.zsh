
# ============================================
# Cross-Platform Network Info Aliases (net.*)
# ============================================


# ============================================
# Helper Functions
# ============================================

# --- Function to get OS type ---
_net_get_os() {
  case "$(uname)" in
    Linux*)   echo "Linux";;
    Darwin*)  echo "macOS";;
    *)        echo "Unknown";;
  esac
}

# --- Function to show IP addresses ---
_net_show_ip() {
  local os=$(_net_get_os)
  if [[ "$os" == "macOS" ]]; then
    ifconfig | grep -E "inet |inet6 |status:" | grep -v "127.0.0.1" | grep -v "::1"
  elif [[ "$os" == "Linux" ]]; then
    if command -v ip >/dev/null; then
      ip -c address show
    elif command -v ifconfig >/dev/null; then
      ifconfig
    else
      echo "Error: No suitable command found (ip or ifconfig)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# --- Function to show interface link status ---
_net_show_links() {
  local os=$(_net_get_os)
  if [[ "$os" == "macOS" ]]; then
    ifconfig -a | grep -E '^[a-z0-9]+:|status:' | sed 's/^[ \t]*//'
    # Alternatively, richer info: networksetup -listallhardwareports
  elif [[ "$os" == "Linux" ]]; then
    if command -v ip >/dev/null; then
      ip -c link show
    elif command -v ifconfig >/dev/null; then
      ifconfig -a # Less detailed than ip link
    else
      echo "Error: No suitable command found (ip or ifconfig)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# --- Function to show routing table ---
_net_show_routes() {
  local os=$(_net_get_os)
  if [[ "$os" == "macOS" ]]; then
    netstat -nr # Shows IPv4 and IPv6
  elif [[ "$os" == "Linux" ]]; then
    if command -v ip >/dev/null; then
      ip -c route show
    elif command -v route >/dev/null; then
      route -n # Legacy, often IPv4 only
    else
      echo "Error: No suitable command found (ip or route)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# --- Function to show default gateway ---
_net_show_gw() {
  local os=$(_net_get_os)
  if [[ "$os" == "macOS" ]]; then
    netstat -nr | grep '^default'
  elif [[ "$os" == "Linux" ]]; then
    if command -v ip >/dev/null; then
      ip route show default
    elif command -v route >/dev/null; then
      route -n | grep '^0\.0\.0\.0' # Legacy IPv4
    else
      echo "Error: No suitable command found (ip or route)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# --- Function to show DNS servers ---
_net_show_dns() {
  local os=$(_net_get_os)
  if [[ "$os" == "macOS" ]]; then
    echo "DNS Servers (via scutil):"
    scutil --dns | grep 'nameserver\[' | awk '{print $3}'
    echo "-----"
    echo "DNS Servers (via networksetup - may vary per service):"
    networksetup -listallnetworkservices | while read -r service; do
      if [[ "$service" == "*" ]]; then continue; fi
      printf "\nService: %s\n" "$service"
      networksetup -getdnsservers "$service"
    done
  elif [[ "$os" == "Linux" ]]; then
    if command -v resolvectl >/dev/null; then
      resolvectl dns
    elif [ -f /etc/resolv.conf ]; then
      echo "DNS Servers (from /etc/resolv.conf):"
      grep '^nameserver' /etc/resolv.conf
    else
      echo "Error: No suitable method found (resolvectl or /etc/resolv.conf)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# --- Function to flush DNS cache ---
_net_flush_dns() {
  local os=$(_net_get_os)
  echo "Attempting to flush DNS cache..."
  if [[ "$os" == "macOS" ]]; then
    sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder && echo "macOS DNS cache flushed."
  elif [[ "$os" == "Linux" ]]; then
    if command -v resolvectl >/dev/null; then
      sudo resolvectl flush-caches && echo "systemd-resolved cache flushed."
    elif command -v systemd-resolve >/dev/null; then # Older systemd might have this binary
       sudo systemd-resolve --flush-caches && echo "systemd-resolve cache flushed."
    elif command -v nscd >/dev/null; then
      sudo systemctl restart nscd && echo "Restarted nscd (may flush cache)."
    else
      echo "Warning: Could not determine standard Linux DNS flushing method (systemd-resolved, nscd)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# --- Function to show listening ports ---
_net_show_listeners() {
  local os=$(_net_get_os)
  echo "Listening ports (TCP/UDP):"
  if [[ "$os" == "macOS" ]]; then
    # lsof is powerful but can be slow and requires sudo for all processes
    sudo lsof -i -P -n | grep LISTEN # Shows process info
    # netstat is faster for just ports
    # netstat -anp tcp | grep LISTEN
    # netstat -anp udp # UDP doesn't really "listen" in the same way
  elif [[ "$os" == "Linux" ]]; then
    if command -v ss >/dev/null; then
      sudo ss -tulnp # Modern, fast, shows process info
    elif command -v netstat >/dev/null; then
      sudo netstat -tulnp # Legacy, might need net-tools package
    else
      echo "Error: No suitable command found (ss or netstat)." >&2
      return 1
    fi
  else
    echo "Error: Unsupported OS." >&2
    return 1
  fi
}

# ============================================
# Aliases
# ============================================

# --- Interface & IP Info ---
alias net.ip='_net_show_ip'      # Show assigned IP addresses (IPv4 & IPv6)
alias net.links='_net_show_links' # Show network interfaces and link status

# --- Routing Info ---
alias net.routes='_net_show_routes' # Show routing table
alias net.gw='_net_show_gw'         # Show default gateway

# --- DNS Info & Management ---
alias net.dns='_net_show_dns'       # Show configured DNS servers
alias net.dns.flush='_net_flush_dns' # Attempt to flush DNS cache (needs sudo)

# --- Socket / Port Info ---
alias net.ports='_net_show_listeners' # Show listening TCP/UDP ports (needs sudo)

# --- Network Service Status (Best Effort - assumes common names) ---
# Status of NetworkManager (Linux - RHEL/Ubuntu Desktop likely)
alias net.svc.nm.status='systemctl status NetworkManager 2>/dev/null || echo "NetworkManager status not available (or not installed/running)." '
# Status of systemd-networkd (Linux - Ubuntu Server likely)
alias net.svc.networkd.status='systemctl status systemd-networkd 2>/dev/null || echo "systemd-networkd status not available (or not installed/running)." '
# Status of systemd-resolved (Linux - DNS Resolver)
alias net.svc.resolved.status='systemctl status systemd-resolved 2>/dev/null || echo "systemd-resolved status not available (or not installed/running)." '

# --- Firewall Status (Very Basic - shows if service is active) ---
# Status for UFW (Ubuntu)
alias net.fw.ufw.status='if command -v ufw >/dev/null; then sudo ufw status; else echo "ufw not found."; fi'
# Status for firewalld (RHEL)
alias net.fw.firewalld.status='if command -v firewall-cmd >/dev/null; then sudo firewall-cmd --state && sudo firewall-cmd --list-all; else echo "firewalld not found."; fi'
# Status for pf (macOS)
alias net.fw.pf.status='if [[ "$(uname)" == "Darwin" ]]; then sudo pfctl -s info; else echo "pfctl only on macOS."; fi'

# --- Diagnostics (Generally cross-platform, install if missing) ---
# Ping host (4 packets) - Adjust count/flags if needed
alias net.diag.ping='ping -c 4'
# Traceroute to host
alias net.diag.trace='traceroute' # macOS uses traceroute, Linux often uses `tracepath` or `traceroute`
# DNS lookup (short form)
alias net.diag.dig='dig +short'   # Needs dnsutils/bind-utils
# DNS lookup (standard host command)
alias net.diag.host='host'        # Needs dnsutils/bind-utils
# Whois lookup
alias net.diag.whois='whois'      # Needs whois package
# Get public IP address
alias net.diag.myip='curl -s -4 ifconfig.me || curl -s -4 api.ipify.org || echo "Could not fetch public IP."' # Try IPv4 first

# --- Legacy Info Commands (For quick viewing, prefer modern tools above) ---
alias net.ifconfig='ifconfig'     # Show interface config (Legacy on Linux)
alias net.netstat.routes='netstat -nr' # Show routes (Legacy on Linux)
alias net.netstat.ports='netstat -tulnp' # Show listening ports (Legacy on Linux, requires net-tools)
alias net.arp='arp -an'           # Show ARP cache (Legacy on Linux)