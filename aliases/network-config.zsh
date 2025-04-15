# ============================================
# Cross-Platform Network Configuration Aliases
# ============================================


# ============================================
# Helper Funcs
# ============================================
# --- Function to get OS type (same as before) ---
_net_get_os() {
  case "$(uname)" in
    Linux*)   echo "Linux";;
    Darwin*)  echo "macOS";;
    *)        echo "Unknown";;
  esac
}

# --- Function to guide network configuration editing ---
_net_conf_edit_guide() {
  local os=$(_net_get_os)
  echo "--- Network Configuration Guidance ---"
  if [[ "$os" == "macOS" ]]; then
    echo "On macOS, use 'System Settings' -> 'Network' (GUI)."
    echo "For command line, use 'networksetup'. Examples:"
    echo "  networksetup -listallnetworkservices"
    echo "  networksetup -getinfo <networkservice>"
    echo "  networksetup -setmanual <networkservice> <ip> <subnet> <router>"
    echo "  networksetup -setdhcp <networkservice>"
    echo "Run 'man networksetup' or 'networksetup -help' for details."
  elif [[ "$os" == "Linux" ]]; then
    if command -v netplan >/dev/null; then
      echo "On Ubuntu (likely), use Netplan."
      echo "Edit YAML files in '/etc/netplan/' (e.g., sudo nano /etc/netplan/00-installer-config.yaml)."
      echo "Use 'man netplan' or check Netplan online documentation for syntax."
      echo "After editing, run 'sudo netplan apply' or 'sudo netplan try'."
      echo "You can change directory there using 'net.conf.cd.netplan'."
    elif command -v nmcli >/dev/null; then
      echo "On RHEL/CentOS or Ubuntu with NetworkManager, use 'nmcli' or 'nmtui'."
      echo "  nmcli connection show         # List connections"
      echo "  nmcli connection edit <name>  # Interactive editor"
      echo "  nmcli connection modify <name> setting.property value"
      echo "  sudo nmtui                    # Text User Interface"
      echo "Config files are usually in '/etc/NetworkManager/system-connections/' (keyfile format)."
      echo "Run 'man nmcli' or 'man nm-settings' for details."
      echo "You can change directory there using 'net.conf.cd.nm'."
    elif command -v systemd-networkd >/dev/null; then
       echo "Systemd-networkd detected (possibly configured by Netplan or directly)."
       echo "Primary config is likely Netplan (see above)."
       echo "Direct *.network files are in '/etc/systemd/network/'."
       echo "Use 'man systemd.network' for syntax."
    else
       echo "Could not detect primary Linux network config method (Netplan, NetworkManager, networkd)."
    fi
  else
    echo "Unsupported OS for network configuration guidance."
  fi
  echo "--------------------------------------"
}

# --- Function to guide DNS configuration ---
_net_conf_dns_guide() {
    local os=$(_net_get_os)
    echo "--- DNS Configuration Guidance ---"
    if [[ "$os" == "macOS" ]]; then
        echo "On macOS, use 'System Settings' -> 'Network' -> Select Service -> 'Details...' -> 'DNS'."
        echo "For command line, use 'networksetup -setdnsservers <networkservice> <server1> [server2] ...'"
        echo "Example: networksetup -setdnsservers Wi-Fi 8.8.8.8 1.1.1.1"
        echo "Use 'networksetup -setdnsservers <networkservice> empty' to clear."
    elif [[ "$os" == "Linux" ]]; then
        if command -v netplan > /dev/null; then
            echo "On Ubuntu (likely), edit the 'nameservers:' section in your /etc/netplan/*.yaml file."
            echo "Example within a device definition:"
            echo "  nameservers:"
            echo "    addresses: [8.8.8.8, 1.1.1.1]"
            echo "    search: [mydomain.local]"
            echo "Then run 'sudo netplan apply'."
        elif command -v nmcli > /dev/null; then
            echo "On RHEL/CentOS or Ubuntu with NetworkManager:"
            echo "Use 'nmcli connection modify <con-name> ipv4.dns \"<ip1> <ip2>\" ipv4.ignore-auto-dns yes'"
            echo "And potentially 'nmcli connection modify <con-name> ipv6.dns \"<ip6_1> <ip6_2>\" ipv6.ignore-auto-dns yes'"
            echo "Then bring the connection up: 'nmcli connection up <con-name>'"
            echo "Alternatively, use 'sudo nmtui' (Text UI)."
        elif [ -d /etc/systemd/resolved.conf.d ]; then
             echo "Systemd-resolved detected. You can create a file in /etc/systemd/resolved.conf.d/ with DNS settings,"
             echo "or modify /etc/systemd/resolved.conf directly (less recommended)."
             echo "See 'man resolved.conf'."
        else
            echo "Could not detect standard Linux DNS config method. Might need manual /etc/resolv.conf editing (often overwritten)."
        fi
    else
        echo "Unsupported OS for DNS configuration guidance."
    fi
    echo "--------------------------------"
}


# --- Function to apply network configuration changes ---
_net_conf_apply_guide() {
    local os=$(_net_get_os)
    echo "--- Applying Network Changes Guidance ---"
    if [[ "$os" == "macOS" ]]; then
        echo "On macOS, changes made via 'networksetup' often apply immediately."
        echo "For some changes (e.g., related to DHCP leases or hardware), toggling the network service off/on might help:"
        echo "  networksetup -setnetworkserviceenabled <service> off"
        echo "  networksetup -setnetworkserviceenabled <service> on"
        echo "Or toggle Wi-Fi/Ethernet via the GUI."
    elif [[ "$os" == "Linux" ]]; then
        if command -v netplan > /dev/null; then
            echo "For Netplan (Ubuntu likely): Run 'sudo netplan apply' or 'sudo netplan try'."
        elif command -v nmcli > /dev/null; then
            echo "For NetworkManager (RHEL likely, some Ubuntu):"
            echo "If config files were edited manually: 'sudo nmcli connection reload'"
            echo "To apply changes to an active connection: 'sudo nmcli connection up <con-name_or_uuid>'"
            echo "Or sometimes: 'sudo nmcli device reapply <device_name>'"
            echo "Restarting may also work: 'sudo systemctl restart NetworkManager'"
        elif command -v systemd-networkd >/dev/null; then
            echo "For systemd-networkd (if not using Netplan/NM): 'sudo systemctl restart systemd-networkd'"
        else
            echo "Could not detect standard Linux network apply method."
        fi
    else
        echo "Unsupported OS for applying network changes."
    fi
    echo "---------------------------------------"
}

# --- Function to set hostname ---
_net_conf_set_hostname() {
    local os=$(_net_get_os)
    local new_hostname="$1"

    if [ -z "$new_hostname" ]; then
        echo "Usage: net.hostname.set <new_hostname>"
        return 1
    fi

    echo "Attempting to set hostname to '$new_hostname'..."
    if [[ "$os" == "macOS" ]]; then
        echo "Setting macOS HostName, LocalHostName, and ComputerName (requires sudo)..."
        # Use base name for LocalHostName and ComputerName if FQDN is given for HostName
        local base_name=$(echo "$new_hostname" | cut -d. -f1)
        sudo scutil --set HostName "$new_hostname" && \
        sudo scutil --set LocalHostName "$base_name" && \
        sudo scutil --set ComputerName "$base_name" && \
        echo "macOS hostname components set. A restart might be needed for all services to reflect the change." || \
        echo "Error setting macOS hostname." >&2
    elif [[ "$os" == "Linux" ]]; then
        if command -v hostnamectl >/dev/null; then
            echo "Setting Linux hostname via hostnamectl (requires sudo)..."
            sudo hostnamectl set-hostname "$new_hostname" && \
            echo "Linux hostname set." || \
            echo "Error setting Linux hostname via hostnamectl." >&2
        elif command -v hostname >/dev/null; then
             echo "Attempting to set Linux hostname via hostname command (temporary) and /etc/hostname (persistent)..."
             sudo hostname "$new_hostname" && \
             echo "$new_hostname" | sudo tee /etc/hostname > /dev/null && \
             echo "Linux hostname potentially set. Check /etc/hosts file too. A restart might be needed." || \
             echo "Error setting Linux hostname via hostname command." >&2
        else
             echo "Error: Could not find hostnamectl or hostname command on Linux." >&2
             return 1
        fi
    else
        echo "Error: Unsupported OS for setting hostname." >&2
        return 1
    fi
}


# ============================================
# Aliases
# ============================================

# --- Config Editing Guidance ---
# Provides guidance on HOW/WHERE to edit network configurations per OS
alias net.conf.edit='_net_conf_edit_guide'
# Provides guidance on HOW/WHERE to edit DNS configurations per OS
alias net.conf.dns.edit='_net_conf_dns_guide'

# --- Config Directory Access (Linux Specific) ---
# Change directory to Netplan config folder (Ubuntu)
alias net.conf.cd.netplan='cd /etc/netplan/ 2>/dev/null || echo "Directory /etc/netplan/ not found."'
# Change directory to NetworkManager keyfile folder (RHEL/Linux)
alias net.conf.cd.nm='cd /etc/NetworkManager/system-connections/ 2>/dev/null || echo "Directory /etc/NetworkManager/system-connections/ not found."'

# --- Applying Config Changes ---
# Provides guidance and attempts common commands to apply network changes
alias net.conf.apply='_net_conf_apply_guide'

# --- Hostname Configuration ---
# Set the system hostname (requires sudo and new hostname argument)
alias net.hostname.set='_net_conf_set_hostname'
# Show current hostname details (uses previous alias/function if defined, or basic hostname)
alias net.hostname.show='if type net.info.hostname &>/dev/null; then net.info.hostname; else hostname; fi'>
