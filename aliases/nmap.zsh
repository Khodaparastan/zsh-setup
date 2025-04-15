# ============================================
# Nmap Aliases (nmap.*)
# ============================================
# Assumes nmap is installed. Many scans require sudo.


# ============================================
# Example Usage:
# ============================================

#nmap.scan.tcp.web 192.168.1.1          # Scan common web ports on 192.168.1.1 (needs sudo)
#nmap.scan.aggressive scanme.nmap.org   # Perform OS/Version/Script/Traceroute scan
#nmap.ping 192.168.1.0/24               # Discover hosts on the local /24 network
#nmap.scripts.vuln -p 80,443 target.com # Check for web vulnerabilities
#nmap.scan.version.intense --top-ports 20 10.0.0.5 # Intense version scan on top 20 ports
#nmap.out.all myscan nmap.scan.tcp -p 1-1000 server.local # Scan TCP 1-1000, output all formats to myscan.*

# --- Basic Host Discovery (Ping Scans) ---
# Standard Ping Scan (ICMP Echo/Timestamp, TCP SYN/ACK) - No ports scanned
# (Append <target(s)>)
alias nmap.ping='nmap -sn'
# Ping Scan using only ARP (Fast on Local Network)
# (Append <target(s)>)
alias nmap.ping.arp='sudo nmap -sn -PR'
# Ping Scan using only ICMP echo
# (Append <target(s)>)
alias nmap.ping.icmp='sudo nmap -sn -PE'
# Ping Scan using TCP SYN to specific ports (e.g., 80, 443)
# (Append -PS80,443 <target(s)>)
alias nmap.ping.syn='sudo nmap -sn -PS'
# Ping Scan using TCP ACK to specific ports (Good for stateless firewalls)
# (Append -PA80,443 <target(s)>)
alias nmap.ping.ack='sudo nmap -sn -PA'
# Scan ALL targets: Skip host discovery, assume all are up (Useful if ping is blocked)
# (Append <target(s)>)
alias nmap.scan.no-ping='nmap -Pn'

# --- Common Port Scan Techniques ---
# Default TCP SYN Scan (Stealthy, requires sudo) - Scans default ~1000 ports
# (Append <target(s)>)
alias nmap.scan.tcp='sudo nmap -sS'
# TCP Connect Scan (No sudo needed, more noisy/detectable) - Scans default ~1000 ports
# (Append <target(s)>)
alias nmap.scan.tcp.connect='nmap -sT'
# UDP Scan (Slow, requires sudo) - Scans default ~1000 UDP ports
# (Append <target(s)>)
alias nmap.scan.udp='sudo nmap -sU'
# Fast Scan (Top 100 ports, combines methods)
# (Append <target(s)>)
alias nmap.scan.fast='nmap -F'
# Scan ALL TCP ports (65535 ports - VERY SLOW)
# (Append <target(s)>)
alias nmap.scan.tcp.allports='sudo nmap -sS -p-'
# Scan common TCP web ports (80, 443, 8080, 8443)
# (Append <target(s)>)
alias nmap.scan.tcp.web='sudo nmap -sS -p 80,443,8080,8443'

# --- Advanced/Stealth TCP Scans (Require sudo) ---
# TCP Null Scan (-sN), FIN Scan (-sF), Xmas Scan (-sX) - Can bypass some firewalls/IDS
# (Append <target(s)>)
alias nmap.scan.tcp.null='sudo nmap -sN'
alias nmap.scan.tcp.fin='sudo nmap -sF'
alias nmap.scan.tcp.xmas='sudo nmap -sX'
# TCP ACK Scan (Good for mapping firewall rulesets, doesn't determine open/closed well)
# (Append <target(s)>)
alias nmap.scan.tcp.ack='sudo nmap -sA'
# TCP Window Scan (Similar to ACK but can sometimes differentiate open/closed)
# (Append <target(s)>)
alias nmap.scan.tcp.window='sudo nmap -sW'

# --- Service, Version & OS Detection ---
# Default Service/Version Detection scan (Uses -sS if root, -sT otherwise)
# (Append <target(s)>)
alias nmap.scan.version='nmap -sV'
# More intense version detection (Level 9)
# (Append <target(s)>)
alias nmap.scan.version.intense='nmap -sV --version-intensity 9'
# OS Detection (Requires sudo, needs open and closed TCP port)
# (Append <target(s)>)
alias nmap.scan.os='sudo nmap -O'
# Aggressive Scan: Enables OS detection (-O), version detection (-sV), script scanning (-sC), and traceroute (--traceroute)
# (Append <target(s)>)
alias nmap.scan.aggressive='nmap -A'

# --- Nmap Scripting Engine (NSE) ---
# Run Default safe scripts (equivalent to -sC)
# (Append <target(s)>)
alias nmap.scripts.default='nmap -sC'
# Scan with 'discovery' category scripts
# (Append <target(s)>)
alias nmap.scripts.discovery='nmap --script discovery'
# Scan with 'vuln' category scripts (Potentially intrusive, use responsibly)
# (Append <target(s)>)
alias nmap.scripts.vuln='nmap --script vuln'
# Scan with 'auth' category scripts
# (Append <target(s)>)
alias nmap.scripts.auth='nmap --script auth'
# Scan with 'exploit' category scripts (Highly intrusive, use with extreme caution and permission)
# (Append <target(s)>)
alias nmap.scripts.exploit='nmap --script exploit'
# Run specific script(s)
# (Append --script=http-title,dns-brute <target(s)>)
alias nmap.scripts.custom='nmap --script'
# Run scripts with arguments
# (Append --script=http-enum --script-args http-enum.fingerprintPath=/path/to/list <target(s)>)
alias nmap.scripts.withargs='nmap --script-args' # Remember to also specify --script

# --- Timing & Performance ---
# Insane speed scan (T5 - very fast, assumes reliable network, may sacrifice accuracy)
# (Append <target(s)>)
alias nmap.timing.insane='nmap -T5'
# Aggressive speed scan (T4 - default)
alias nmap.timing.aggressive='nmap -T4' # This is default but explicit alias can be useful
# Polite speed scan (T2 - slower, less likely to overwhelm targets/IDS)
# (Append <target(s)>)
alias nmap.timing.polite='nmap -T2'
# Sneaky speed scan (T1 - very slow, for IDS evasion)
# (Append <target(s)>)
alias nmap.timing.sneaky='nmap -T1'

# --- Output Formats ---
# Save output to Normal format
# (Append -oN scan_output.txt <target(s)>)
alias nmap.out.normal='nmap -oN'
# Save output to XML format
# (Append -oX scan_output.xml <target(s)>)
alias nmap.out.xml='nmap -oX'
# Save output to Grepable format
# (Append -oG scan_output.gnmap <target(s)>)
alias nmap.out.grep='nmap -oG'
# Save output to ALL major formats (Normal, XML, Grepable) - needs base filename
# (Append -oA scan_output_basename <target(s)>)
alias nmap.out.all='nmap -oA'
# Increase verbosity (-v or -vv)
alias nmap.verbose='nmap -v'
alias nmap.vverbose='nmap -vv'
# Show reason port is open/closed/filtered
alias nmap.reason='nmap --reason'
# Only show open ports (and potentially open|filtered)
alias nmap.open='nmap --open'
# Show packet trace (very verbose)
alias nmap.debug.packets='nmap --packet-trace'

# --- Firewall/IDS Evasion (Use ethically and responsibly) ---
# Fragment packets (-f uses 8-byte fragments, --mtu sets specific size)
# (Append -f <target(s)> or --mtu 16 <target(s)>)
alias nmap.evade.frag='nmap -f'
# Use Decoys (Makes scan appear to come from decoys too; ME=your real IP)
# (Append -D RND:5,ME <target(s)>) # Example: 5 random decoys + you
alias nmap.evade.decoy='nmap -D'
# Specify source port
# (Append -g <port_num> <target(s)>)
alias nmap.evade.srcport='nmap -g'
# Randomize target scan order
alias nmap.evade.random='nmap --randomize-hosts'

# --- Miscellaneous ---
# Enable IPv6 scanning
# (Append -6 <target(s)>)
alias nmap.ipv6='nmap -6'
# List interfaces and routes as seen by nmap
alias nmap.iflist='nmap --iflist'
# Resume an aborted scan (from -oN or -oG output file)
# (Append <scan_output.nmap or scan_output.gnmap>)
alias nmap.resume='nmap --resume'