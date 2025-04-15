# ============================================
# Linux Server Management Helper Functions & Aliases
# Designed for execution FROM local machine TARGETING remote server(s).
# ============================================
# Assumes passwordless SSH key authentication is set up for target hosts.

# --- Core Remote Execution Function ---
# Usage: _srv_remote_exec <user@host> <command_string...>
_srv_remote_exec() {
    local target="$1"
    shift # Remove target from arguments
    local cmd_string="$*" # Remaining args form the command string

    if [ -z "$target" ] || [ -z "$cmd_string" ]; then
        echo "Usage Error: _srv_remote_exec <user@host> <command_string>" >&2
        echo "Example: _srv_remote_exec admin@server1 'uptime'" >&2
        return 1
    fi

    # Use -- to prevent ssh interpreting command args as its own options
    ssh -o ServerAliveInterval=60 -o ConnectTimeout=10 -T "$target" -- "$cmd_string"
    # -T disables pseudo-tty allocation (usually good for non-interactive)
    # Exit status of ssh reflects the remote command's exit status
    return $?
}

# --- Interactive Remote Execution Function ---
# Usage: _srv_remote_exec_interactive <user@host> <command_string...>
_srv_remote_exec_interactive() {
    local target="$1"
    shift
    local cmd_string="$*"

    if [ -z "$target" ] || [ -z "$cmd_string" ]; then
        echo "Usage Error: _srv_remote_exec_interactive <user@host> <command_string>" >&2
        echo "Example: _srv_remote_exec_interactive admin@server1 'htop'" >&2
        return 1
    fi

    # Use -t to force pseudo-tty allocation for interactive commands
    ssh -o ServerAliveInterval=60 -o ConnectTimeout=10 -t "$target" -- "$cmd_string"
    return $?
}


# --- Function to GENERATE package manager commands ---
# This function *prints* the command to be run remotely.
_srv_pkg_manager_cmd() {
    local target_host_for_detection=$1 # Requires connecting to detect! Or user knowledge.
                                       # Simpler: Assume user calls the right alias for the target.
                                       # Let's modify to just generate commands based on user choice later.
                                       # For now, the *alias* calls the correct command generator.

    local pkg_manager_type=$1 # 'apt' or 'dnf'
    local action=$2
    shift 2 # Remove type and action
    local pkgs=("$@") # Remaining args are packages/terms

    local cmd=""

    case "$pkg_manager_type" in
        apt)
            case "$action" in
                update)  cmd="sudo apt update" ;;
                upgrade) cmd="sudo apt upgrade -y" ;;
                install) cmd="sudo apt install -y \"${pkgs[@]}\"" ;;
                remove)  cmd="sudo apt remove -y \"${pkgs[@]}\"" ;;
                purge)   cmd="sudo apt purge -y \"${pkgs[@]}\"" ;;
                search)  cmd="apt search \"${pkgs[@]}\"" ;; # No sudo needed
                info)    cmd="apt show \"${pkgs[@]}\"" ;;   # No sudo needed
                list)    cmd="apt list --installed" ;;      # No sudo needed
                clean)   cmd="sudo apt clean && sudo apt autoremove -y" ;;
                *)       echo "APT action '$action' not supported." >&2; return 1 ;;
            esac
            ;;
        dnf)
            case "$action" in
                update)  cmd="sudo dnf check-update" ;; # Just check
                upgrade) cmd="sudo dnf upgrade -y" ;;
                install) cmd="sudo dnf install -y \"${pkgs[@]}\"" ;;
                remove)  cmd="sudo dnf remove -y \"${pkgs[@]}\"" ;;
                purge)   echo "DNF does not have a direct 'purge'. Use 'remove'." >&2; return 1 ;;
                search)  cmd="dnf search \"${pkgs[@]}\"" ;; # No sudo
                info)    cmd="dnf info \"${pkgs[@]}\"" ;;   # No sudo
                list)    cmd="dnf list installed" ;;       # No sudo
                clean)   cmd="sudo dnf clean all" ;;
                *)       echo "DNF action '$action' not supported." >&2; return 1 ;;
            esac
            ;;
        *)
            echo "Error: Unsupported package manager type '$pkg_manager_type'." >&2
            return 1 ;;
    esac

    echo "$cmd" # Output the command string
    return 0
}

# --- Function to GENERATE user add command ---
# Prefers 'adduser' if likely available (Debian/Ubuntu assumption), falls back to 'useradd'.
# This is a heuristic - might need adjustment based on target knowledge.
_srv_user_add_cmd() {
    local username="$1"
    local prefer_interactive=${2:-true} # Default to interactive adduser if possible

    if [ -z "$username" ]; then
        echo "Internal Usage Error: _srv_user_add_cmd <username> [prefer_interactive_bool]" >&2
        return 1
    fi

    # Heuristic: Assume Debian/Ubuntu might have 'adduser'
    # A more robust way would involve detecting on the remote host first,
    # but that adds complexity/latency. This provides a reasonable default.
    if [ "$prefer_interactive" = true ]; then
        # Assume adduser exists for interactive mode. Needs -t ssh flag.
         echo "sudo adduser \"$username\""
    else
        # Use standard useradd, less interactive. Create home dir, needs separate passwd.
        echo "sudo useradd -m \"$username\" && echo 'User $username created. Set password with: sudo passwd $username'"
    fi
    return 0
}

# ============================================
# Comprehensive Server Management Aliases (srv.*)
# ============================================
# Usage: alias <user@host> [arguments...]

# --------------------------------------------
# Base Connection & Remote Execution
# --------------------------------------------
# Base SSH command with keepalive (use directly for interactive sessions)
alias srv.ssh='ssh -o ServerAliveInterval=60'
# Run an arbitrary command non-interactively on remote host
# Usage: srv.run <user@host> "command string"
alias srv.run='_srv_remote_exec'
# Run an arbitrary command interactively on remote host
# Usage: srv.run.interactive <user@host> "command string"
alias srv.run.interactive='_srv_remote_exec_interactive'

# --------------------------------------------
# File Transfer (Remain as before - they inherently need target)
# --------------------------------------------
# Secure copy LOCAL -> REMOTE
# Usage: srv.scp.to local/path user@host:/remote/path
alias srv.scp.to='scp -p -o ServerAliveInterval=60'
# Secure copy REMOTE -> LOCAL
# Usage: srv.scp.from user@host:/remote/path /local/path
alias srv.scp.from='scp -p -o ServerAliveInterval=60'
# Rsync LOCAL -> REMOTE (archive, verbose, progress, compress, partial)
# Usage: srv.rsync.to local/path/ user@host:/remote/path/ # Note trailing slashes
alias srv.rsync.to='rsync -avzP --rsh="ssh -o ServerAliveInterval=60"'
# Rsync REMOTE -> LOCAL (archive, verbose, progress, compress, partial)
# Usage: srv.rsync.from user@host:/remote/path/ local/path/ # Note trailing slashes
alias srv.rsync.from='rsync -avzP --rsh="ssh -o ServerAliveInterval=60"'

# --------------------------------------------
# System Information
# --------------------------------------------
# OS/Kernel/Release Info
# Usage: srv.info.os <user@host>
alias srv.info.os='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "uname -a && (lsb_release -a 2>/dev/null || cat /etc/*release 2>/dev/null)"; }; _srv_remote_exec_wrapper'
# Hostname Info
# Usage: srv.info.host <user@host>
alias srv.info.host='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "hostnamectl"; }; _srv_remote_exec_wrapper'
# System Uptime and Load Average
# Usage: srv.info.uptime <user@host>
alias srv.info.uptime='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "uptime"; }; _srv_remote_exec_wrapper'
# CPU Information
# Usage: srv.info.cpu <user@host>
alias srv.info.cpu='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "lscpu"; }; _srv_remote_exec_wrapper'
# Memory Usage (Human-readable)
# Usage: srv.info.ram <user@host>
alias srv.info.ram='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "free -h"; }; _srv_remote_exec_wrapper'
# Disk Filesystem Usage (Human-readable, with Filesystem Type)
# Usage: srv.info.disk <user@host>
alias srv.info.disk='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "df -hT"; }; _srv_remote_exec_wrapper'
# PCI Devices
# Usage: srv.info.pci <user@host>
alias srv.info.pci='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "lspci"; }; _srv_remote_exec_wrapper'
# USB Devices
# Usage: srv.info.usb <user@host>
alias srv.info.usb='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "lsusb"; }; _srv_remote_exec_wrapper'
# Block Devices (Disks/Partitions)
# Usage: srv.info.lsblk <user@host>
alias srv.info.lsblk='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "lsblk"; }; _srv_remote_exec_wrapper'
# Currently Logged-in Users
# Usage: srv.info.users <user@host>
alias srv.info.users='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "who"; }; _srv_remote_exec_wrapper'
# More detailed user info and activity
# Usage: srv.info.who <user@host>
alias srv.info.who='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "w"; }; _srv_remote_exec_wrapper'
# Show last logins
# Usage: srv.info.last <user@host> [count]
alias srv.info.last='_srv_remote_exec_wrapper() { count=${2:-20}; _srv_remote_exec "$1" "last -n $count"; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# Process Management
# --------------------------------------------
# List processes (All users, aux format, with full command & forest)
# Usage: srv.proc.list <user@host>
alias srv.proc.list='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "ps auxf"; }; _srv_remote_exec_wrapper'
# Interactive process viewer (requires direct SSH with -t)
# Usage: srv.proc.top <user@host>
alias srv.proc.top='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "top"; }; _srv_remote_exec_interactive_wrapper'
# Improved interactive process viewer (Needs install on server: htop)
# Usage: srv.proc.htop <user@host>
alias srv.proc.htop='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "htop"; }; _srv_remote_exec_interactive_wrapper'
# Find process PID by name/pattern (shows command line)
# Usage: srv.proc.find <user@host> <pattern>
alias srv.proc.find='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "pgrep -lf \"$2\""; }; _srv_remote_exec_wrapper'
# Send SIGTERM (15, default) to process
# Usage: srv.proc.kill <user@host> <PID>
alias srv.proc.kill='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo kill \"$2\""; }; _srv_remote_exec_wrapper'
# Send SIGKILL (9, force) to process
# Usage: srv.proc.kill9 <user@host> <PID>
alias srv.proc.kill9='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo kill -9 \"$2\""; }; _srv_remote_exec_wrapper'
# Kill processes by name (SIGTERM)
# Usage: srv.proc.pkill <user@host> <process_name>
alias srv.proc.pkill='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo pkill \"$2\""; }; _srv_remote_exec_wrapper'
# Kill processes by name (SIGKILL)
# Usage: srv.proc.pkill9 <user@host> <process_name>
alias srv.proc.pkill9='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo pkill -9 \"$2\""; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# Resource Monitoring
# --------------------------------------------
# VM Statistics (1-sec interval, 5 reports)
# Usage: srv.mon.vmstat <user@host> [interval] [count]
alias srv.mon.vmstat='_srv_remote_exec_wrapper() { interval=${2:-1}; count=${3:-5}; _srv_remote_exec "$1" "vmstat $interval $count"; }; _srv_remote_exec_wrapper'
# Disk I/O Statistics (Needs install on server: sysstat)
# Usage: srv.mon.iostat <user@host> [interval] [count]
alias srv.mon.iostat='_srv_remote_exec_wrapper() { interval=${2:-1}; count=${3:-5}; _srv_remote_exec "$1" "iostat -dx $interval $count"; }; _srv_remote_exec_wrapper'
# Interactive Disk I/O Monitor (Needs install on server: iotop; requires sudo)
# Usage: srv.mon.iotop <user@host>
alias srv.mon.iotop='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo iotop"; }; _srv_remote_exec_interactive_wrapper'
# Interactive Network Interface Traffic Monitor (Needs install on server: iftop; requires sudo)
# Usage: srv.mon.iftop <user@host> [interface]
alias srv.mon.iftop='_srv_remote_exec_interactive_wrapper() { iface_arg=${2:+-i $2}; _srv_remote_exec_interactive "$1" "sudo iftop -P $iface_arg"; }; _srv_remote_exec_interactive_wrapper'
# Per-Process Network Bandwidth Monitor (Needs install on server: nethogs; requires sudo)
# Usage: srv.mon.nethogs <user@host> [interface]
alias srv.mon.nethogs='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo nethogs $2"; }; _srv_remote_exec_interactive_wrapper'
# Summarize Disk Usage for path (Human-readable)
# Usage: srv.mon.du <user@host> /path/to/dir
alias srv.mon.du='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "du -sh \"$2\""; }; _srv_remote_exec_wrapper'
# Show open files by process (Needs install on server: lsof; requires sudo)
# Usage: srv.mon.lsof <user@host> [-p PID | -i :PORT | user | +D /dir]
alias srv.mon.lsof='_srv_remote_exec_wrapper() { target=$1; shift; _srv_remote_exec "$target" "sudo lsof $*"; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# Log Management (systemd-journald focus)
# --------------------------------------------
# View system log, latest 50 entries, with errors highlighted, no pager
# Usage: srv.log.sys <user@host> [lines]
alias srv.log.sys='_srv_remote_exec_wrapper() { lines=${2:-50}; _srv_remote_exec "$1" "sudo journalctl -xe -n $lines --no-pager"; }; _srv_remote_exec_wrapper'
# Follow (tail -f) the system log
# Usage: srv.log.tail.sys <user@host>
alias srv.log.tail.sys='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo journalctl -f"; }; _srv_remote_exec_interactive_wrapper'
# View logs since last boot
# Usage: srv.log.boot <user@host>
alias srv.log.boot='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo journalctl -b --no-pager"; }; _srv_remote_exec_wrapper'
# View logs for a specific service unit
# Usage: srv.log.service <user@host> <service_unit_name> [lines]
alias srv.log.service='_srv_remote_exec_wrapper() { lines_arg=${3:+-n $3}; _srv_remote_exec "$1" "sudo journalctl -u \"$2\" $lines_arg --no-pager"; }; _srv_remote_exec_wrapper'
# Follow (tail -f) logs for a specific service unit
# Usage: srv.log.tail.service <user@host> <service_unit_name>
alias srv.log.tail.service='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo journalctl -f -u \"$2\""; }; _srv_remote_exec_interactive_wrapper'
# View kernel messages from current boot
# Usage: srv.log.kern <user@host>
alias srv.log.kern='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo journalctl -k --no-pager"; }; _srv_remote_exec_wrapper'
# View kernel ring buffer (like dmesg) with timestamps
# Usage: srv.log.dmesg <user@host>
alias srv.log.dmesg='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "dmesg -T"; }; _srv_remote_exec_wrapper'
# Search all logs for a pattern
# Usage: srv.log.grep <user@host> <pattern>
alias srv.log.grep='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo journalctl -g \"$2\" --no-pager"; }; _srv_remote_exec_wrapper'
# Tail a specific log file
# Usage: srv.log.tail.file <user@host> /path/to/logfile
alias srv.log.tail.file='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo tail -f \"$2\""; }; _srv_remote_exec_interactive_wrapper'

# --------------------------------------------
# Service Management (systemd focus)
# --------------------------------------------
# Check service status (shows recent logs too)
# Usage: srv.svc.status <user@host> <unit_name.service>
alias srv.svc.status='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl status \"$2\""; }; _srv_remote_exec_wrapper'
# Start service (needs sudo)
# Usage: srv.svc.start <user@host> <unit_name.service>
alias srv.svc.start='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo systemctl start \"$2\""; }; _srv_remote_exec_wrapper'
# Stop service (needs sudo)
# Usage: srv.svc.stop <user@host> <unit_name.service>
alias srv.svc.stop='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo systemctl stop \"$2\""; }; _srv_remote_exec_wrapper'
# Restart service (needs sudo)
# Usage: srv.svc.restart <user@host> <unit_name.service>
alias srv.svc.restart='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo systemctl restart \"$2\""; }; _srv_remote_exec_wrapper'
# Reload service configuration (if supported) (needs sudo)
# Usage: srv.svc.reload <user@host> <unit_name.service>
alias srv.svc.reload='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo systemctl reload \"$2\""; }; _srv_remote_exec_wrapper'
# Enable service to start on boot (needs sudo)
# Usage: srv.svc.enable <user@host> <unit_name.service>
alias srv.svc.enable='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo systemctl enable \"$2\""; }; _srv_remote_exec_wrapper'
# Disable service from starting on boot (needs sudo)
# Usage: srv.svc.disable <user@host> <unit_name.service>
alias srv.svc.disable='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo systemctl disable \"$2\""; }; _srv_remote_exec_wrapper'
# Check if service is currently running
# Usage: srv.svc.is-active <user@host> <unit_name.service>
alias srv.svc.is-active='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl is-active \"$2\""; }; _srv_remote_exec_wrapper'
# Check if service is enabled to start on boot
# Usage: srv.svc.is-enabled <user@host> <unit_name.service>
alias srv.svc.is-enabled='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl is-enabled \"$2\""; }; _srv_remote_exec_wrapper'
# List running service units
# Usage: srv.svc.list <user@host>
alias srv.svc.list='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl list-units --type=service --state=running"; }; _srv_remote_exec_wrapper'
# List all loaded service units (active, inactive, failed)
# Usage: srv.svc.list.all <user@host>
alias srv.svc.list.all='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl list-units --type=service --all"; }; _srv_remote_exec_wrapper'
# List all loaded units (services, sockets, timers, etc.)
# Usage: srv.svc.list.units <user@host>
alias srv.svc.list.units='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl list-units --all"; }; _srv_remote_exec_wrapper'


# --------------------------------------------
# Package Management (Abstraction - Requires knowing target type)
# --- APT (Debian/Ubuntu) Aliases ---
alias srv.apt.update='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd apt update); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.upgrade='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd apt upgrade); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.install='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd apt install "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.remove='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd apt remove "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.purge='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd apt purge "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.search='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd apt search "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.info='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd apt info "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.list='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd apt list); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.apt.clean='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd apt clean); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
# --- DNF (RHEL/Fedora) Aliases ---
alias srv.dnf.update='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd dnf update); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.dnf.upgrade='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd dnf upgrade); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.dnf.install='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd dnf install "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.dnf.remove='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd dnf remove "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
# srv.dnf.purge -> Not available
alias srv.dnf.search='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd dnf search "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.dnf.info='_srv_remote_exec_wrapper() { target=$1; shift; cmd=$(_srv_pkg_manager_cmd dnf info "$@"); _srv_remote_exec "$target" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.dnf.list='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd dnf list); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
alias srv.dnf.clean='_srv_remote_exec_wrapper() { cmd=$(_srv_pkg_manager_cmd dnf clean); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# User Management
# --------------------------------------------
# Add a user (interactive preferred, needs -t)
# Usage: srv.user.add <user@host> <username>
alias srv.user.add='_srv_remote_exec_interactive_wrapper() { cmd=$(_srv_user_add_cmd "$2" true); _srv_remote_exec_interactive "$1" "$cmd"; }; _srv_remote_exec_interactive_wrapper'
# Add a user (non-interactive 'useradd' fallback)
# Usage: srv.user.add.basic <user@host> <username>
alias srv.user.add.basic='_srv_remote_exec_wrapper() { cmd=$(_srv_user_add_cmd "$2" false); _srv_remote_exec "$1" "$cmd"; }; _srv_remote_exec_wrapper'
# Delete a user and remove their home directory (needs sudo)
# Usage: srv.user.del <user@host> <username>
alias srv.user.del='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo userdel -r \"$2\""; }; _srv_remote_exec_wrapper'
# Change a user's password (interactive, needs sudo)
# Usage: srv.user.passwd <user@host> <username>
alias srv.user.passwd='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo passwd \"$2\""; }; _srv_remote_exec_interactive_wrapper'
# Add a group (needs sudo)
# Usage: srv.group.add <user@host> <groupname>
alias srv.group.add='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo groupadd \"$2\""; }; _srv_remote_exec_wrapper'
# Delete a group (needs sudo)
# Usage: srv.group.del <user@host> <groupname>
alias srv.group.del='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo groupdel \"$2\""; }; _srv_remote_exec_wrapper'
# Add user to a supplementary group (needs sudo)
# Usage: srv.user.addgroup <user@host> <username> <groupname>
alias srv.user.addgroup='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo usermod -aG \"$3\" \"$2\""; }; _srv_remote_exec_wrapper'
# List groups a user belongs to
# Usage: srv.user.groups <user@host> <username>
alias srv.user.groups='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "groups \"$2\""; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# Scheduled Tasks
# --------------------------------------------
# Edit current remote user's crontab (interactive)
# Usage: srv.cron.edit <user@host>
alias srv.cron.edit='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "crontab -e"; }; _srv_remote_exec_interactive_wrapper'
# List current remote user's crontab
# Usage: srv.cron.list <user@host>
alias srv.cron.list='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "crontab -l"; }; _srv_remote_exec_wrapper'
# Edit root user's crontab (interactive, needs sudo)
# Usage: srv.cron.edit.root <user@host>
alias srv.cron.edit.root='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "sudo crontab -e"; }; _srv_remote_exec_interactive_wrapper'
# List root user's crontab (needs sudo)
# Usage: srv.cron.list.root <user@host>
alias srv.cron.list.root='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo crontab -l"; }; _srv_remote_exec_wrapper'
# List all systemd timers (active and inactive)
# Usage: srv.timers.list <user@host>
alias srv.timers.list='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "systemctl list-timers --all"; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# Configuration Management
# --------------------------------------------
# Edit a file remotely using $EDITOR (interactive)
# Note: Requires $EDITOR to be set and usable on the remote host, or locally via ssh forwarding.
# Usage: srv.config.edit <user@host> /path/to/file
alias srv.config.edit='_srv_remote_exec_interactive_wrapper() { editor=${EDITOR:-vim}; _srv_remote_exec_interactive "$1" "sudo $editor \"$2\""; }; _srv_remote_exec_interactive_wrapper'
# View a file remotely (using less)
# Usage: srv.config.view <user@host> /path/to/file
alias srv.config.view='_srv_remote_exec_interactive_wrapper() { _srv_remote_exec_interactive "$1" "less \"$2\""; }; _srv_remote_exec_interactive_wrapper'
# View a file remotely (using cat)
# Usage: srv.config.cat <user@host> /path/to/file
alias srv.config.cat='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "cat \"$2\""; }; _srv_remote_exec_wrapper'
# Quick edit SSHD config
# Usage: srv.config.edit.sshd <user@host>
alias srv.config.edit.sshd='srv.config.edit $1 /etc/ssh/sshd_config'
# Quick edit Nginx main config (adjust path if needed)
# Usage: srv.config.edit.nginx <user@host>
alias srv.config.edit.nginx='srv.config.edit $1 /etc/nginx/nginx.conf'

# --------------------------------------------
# Auditing & Security
# --------------------------------------------
# View standard audit log (path varies, common locations checked)
# Usage: srv.audit.log <user@host> [lines]
alias srv.audit.log='_srv_remote_exec_wrapper() { lines_arg=${2:+-n $2}; _srv_remote_exec "$1" "sudo tail $lines_arg /var/log/audit/audit.log 2>/dev/null || sudo tail $lines_arg /var/log/syslog | grep -i audit 2>/dev/null || sudo journalctl _TRANSPORT=audit --no-pager $lines_arg"; }; _srv_remote_exec_wrapper'
# View failed SSH logins (uses journalctl or auth.log)
# Usage: srv.audit.failedlogins <user@host> [lines]
alias srv.audit.failedlogins='_srv_remote_exec_wrapper() { lines_arg=${2:+-n $2}; _srv_remote_exec "$1" "sudo journalctl _SYSTEMD_UNIT=sshd.service | grep -i \"failed password\\|invalid user\" $lines_arg --no-pager 2>/dev/null || sudo grep -i \"sshd.*fail\" /var/log/auth.log* | tail $lines_arg"; }; _srv_remote_exec_wrapper'
# List listening TCP/UDP ports (needs sudo)
# Usage: srv.audit.listening <user@host>
alias srv.audit.listening='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo ss -tlpn"; }; _srv_remote_exec_wrapper'
# Check UFW firewall status/rules (Debian/Ubuntu)
# Usage: srv.audit.firewall.ufw <user@host>
alias srv.audit.firewall.ufw='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo ufw status verbose"; }; _srv_remote_exec_wrapper'
# Check firewalld status/rules (RHEL/Fedora)
# Usage: srv.audit.firewall.firewalld <user@host>
alias srv.audit.firewall.firewalld='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo firewall-cmd --list-all"; }; _srv_remote_exec_wrapper'
# List iptables rules (legacy/direct)
# Usage: srv.audit.firewall.iptables <user@host>
alias srv.audit.firewall.iptables='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo iptables -L -v -n"; }; _srv_remote_exec_wrapper'
# Run chkrootkit (Needs install on server: chkrootkit)
# Usage: srv.sec.chkrootkit <user@host>
alias srv.sec.chkrootkit='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo chkrootkit"; }; _srv_remote_exec_wrapper'
# Run rkhunter (Needs install on server: rkhunter)
# Usage: srv.sec.rkhunter <user@host>
alias srv.sec.rkhunter='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "sudo rkhunter --check --skip-keypress"; }; _srv_remote_exec_wrapper'

# --------------------------------------------
# Networking
# --------------------------------------------
# Show IP addresses and links
# Usage: srv.net.ip <user@host>
alias srv.net.ip='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "ip addr show"; }; _srv_remote_exec_wrapper'
# Show routing table
# Usage: srv.net.routes <user@host>
alias srv.net.routes='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "ip route show"; }; _srv_remote_exec_wrapper'
# Ping a host FROM the remote server
# Usage: srv.net.ping <user@host> <destination_host> [count]
alias srv.net.ping='_srv_remote_exec_wrapper() { count_arg=${3:+-c $3}; _srv_remote_exec "$1" "ping $count_arg \"$2\""; }; _srv_remote_exec_wrapper'
# Traceroute to a host FROM the remote server
# Usage: srv.net.trace <user@host> <destination_host>
alias srv.net.trace='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "traceroute \"$2\""; }; _srv_remote_exec_wrapper'
# Perform DNS lookup FROM the remote server (Needs install on server: dnsutils/bind-utils)
# Usage: srv.net.dns.lookup <user@host> <domain_or_ip> [type]
alias srv.net.dns.lookup='_srv_remote_exec_wrapper() { type_arg=${3:-A}; _srv_remote_exec "$1" "dig \"$2\" $type_arg +short"; }; _srv_remote_exec_wrapper'
# Test network connection to a port FROM the remote server (Needs nc/ncat/telnet)
# Usage: srv.net.test.port <user@host> <destination_host> <port>
alias srv.net.test.port='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "nc -zv \"$2\" \"$3\" || telnet \"$2\" \"$3\""; }; _srv_remote_exec_wrapper'


# --------------------------------------------
# File System Operations
# --------------------------------------------
# Find files remotely
# Usage: srv.fs.find <user@host> <path> [find_options...] (e.g., -name '*.log')
alias srv.fs.find='_srv_remote_exec_wrapper() { target=$1; path=$2; shift 2; _srv_remote_exec "$target" "sudo find \"$path\" $@"; }; _srv_remote_exec_wrapper'
# Grep files remotely
# Usage: srv.fs.grep <user@host> <pattern> <path> [grep_options...]
alias srv.fs.grep='_srv_remote_exec_wrapper() { target=$1; pattern=$2; path=$3; shift 3; _srv_remote_exec "$target" "sudo grep $@ \"$pattern\" \"$path\""; }; _srv_remote_exec_wrapper'
# Make directory remotely
# Usage: srv.fs.mkdir <user@host> <dirpath>
alias srv.fs.mkdir='_srv_remote_exec_wrapper() { _srv_remote_exec "$1" "mkdir -p \"$2\""; }; _srv_remote_exec_wrapper' # -p is idempotent
# Remove file or directory remotely (use with caution!)
# Usage: srv.fs.rm <user@host> <path> [-r for recursive]
alias srv.fs.rm='_srv_remote_exec_wrapper() { target=$1; shift; _srv_remote_exec "$target" "sudo rm $@"; }; _srv_remote_exec_wrapper'
# List files remotely
# Usage: srv.fs.ls <user@host> <path> [ls_options]
alias srv.fs.ls='_srv_remote_exec_wrapper() { target=$1; path=$2; shift 2; _srv_remote_exec "$target" "ls -laht $@ \"$path\""; }; _srv_remote_exec_wrapper' # Default to good options


# --------------------------------------------
# Help
# --------------------------------------------
# List all available srv.* aliases
srv.help() {
    echo "Available Server Management Aliases (srv.*):"
    echo "Usage generally: srv.<category>.<action> <user@host> [arguments...]"
    echo "--------------------------------------------------"
    alias | grep '^srv\.' | sed 's/^alias //; s/=/        --> /' | sort
    echo "--------------------------------------------------"
    echo "Notes:"
    echo "- Assumes passwordless SSH key auth is set up."
    echo "- Most commands require <user@host> as the first argument."
    echo "- Commands needing interactivity (edit, top, htop, tail -f, adduser) use 'ssh -t'."
    echo "- Commands requiring 'sudo' will execute 'sudo' on the remote host."
    echo "- Check comments for dependencies needed on the remote server (e.g., htop, sysstat)."
    echo "- For batch operations on multiple hosts, consider tools like pssh, clusterssh, or Ansible."
}
