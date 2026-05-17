#!/bin/bash

# ================================================================
#   WIZARD TOOLKIT - v1.0.0
#   Crafted by @Gr4y_Wizard
#   Telegram: https://t.me/Gray_wiz4rd
# ================================================================

# --- Color Palette ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;38;5;39m'
CYAN='\033[0;38;5;51m'
MAGENTA='\033[0;38;5;213m'
ORANGE='\033[0;38;5;214m'
WHITE='\033[1;97m'
GRAY='\033[0;38;5;245m'
DIM='\033[2m'
BOLD='\033[1m'
BLINK='\033[5m'
RESET='\033[0m'

# --- Input Helper: blink prompt, green echo after input ---
read_input() {
    local prompt="$1"
    local varname="$2"
    echo -ne "${CYAN}  ${prompt}${RESET}${RED}${BLINK} ▸ ${RESET}"
    read "$varname"
    local val="${!varname}"
    echo -e "\033[1A\r${CYAN}  ${prompt}${RESET}${GREEN} ▸ ${val}${RESET}     "
}

# --- THE GUARDIAN ---
cleanup_and_menu() {
    kill $SPIN_PID 2>/dev/null
    echo -e "${RESET}"
    if [[ "$IN_PROCESS" == "true" ]]; then
        echo -e "\n${YELLOW}  [!] Operation interrupted. Returning to menu...${RESET}"
    else
        echo -e "\n${YELLOW}  [!] Use '0' to exit safely.${RESET}"
    fi
    IN_PROCESS="false"
    sleep 1.5
    main_menu
}
trap cleanup_and_menu SIGINT

# --- Spinner ---
start_spinner() {
    local msg=$1
    echo -ne "${DIM}  ◆ ${RESET}${YELLOW}$msg  ${RESET}"
    (
        local i=0
        local sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        while true; do
            printf "\b${MAGENTA}%s${RESET}" "${sp:i++%${#sp}:1}"
            sleep 0.1
        done
    ) &
    SPIN_PID=$!
}

stop_spinner() {
    kill $SPIN_PID 2>/dev/null
    wait $SPIN_PID 2>/dev/null
    printf "\b${GREEN} ✔${RESET}\n"
}

# --- Strict Enter ---
wait_for_enter() {
    echo ""
    echo -e "${DIM}  ────────────────────────────────────────────────────${RESET}"
    echo -ne "${CYAN}  Press ${YELLOW}[Enter]${CYAN} to return to menu${RESET}${RED}${BLINK} ▸ ${RESET}"
    while true; do
        read -s -n 1 key
        if [[ $key == "" ]]; then break
        else echo -ne "\n${RED}  [!] Press ENTER only: ${RESET}"; fi
    done
    echo ""
}

# --- Section Divider ---
divider() {
    echo -e "${DIM}  ════════════════════════════════════════════════════${RESET}"
}

# ================================================================
# SECTION 1 — Network & Mirror Optimizer
# ================================================================
optimize_network() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  NETWORK & MIRROR OPTIMIZER${RESET}"
    divider

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; main_menu; return
    fi

    # --- Ask server location ---
    echo -e "${YELLOW}  [?] Where is this server located?${RESET}"
    echo -e "  ${CYAN}1)${RESET}  Iran  ${GRAY}(sets local IR mirrors & IR DNS)${RESET}"
    echo -e "  ${CYAN}2)${RESET}  Kharej ${GRAY}(sets global mirrors & fast global DNS)${RESET}"
    echo ""
    read_input "Server location [1/2]" SERVER_LOC

    case "$SERVER_LOC" in
        1) _net_optimize_iran ;;
        2) _net_optimize_kharej ;;
        *)
            echo -e "${RED}  [!] Invalid choice!${RESET}"
            sleep 1.5; optimize_network; return ;;
    esac
}

# ---- Iran optimization ----
_net_optimize_iran() {
    echo ""
    echo -e "${CYAN}  [i] Optimizing for Iran server...${RESET}"
    echo ""

    start_spinner "Analyzing IR DNS latencies"
    ALL_DNS=("217.218.155.155" "185.20.163.4" "78.157.42.101" "178.22.122.100" "10.202.10.10" "185.51.200.2" "8.8.8.8" "1.1.1.1")
    tmp_dns=$(mktemp)
    for dns in "${ALL_DNS[@]}"; do
        lat=$(ping -c 1 -W 1 "$dns" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1 | cut -d'.' -f1)
        [[ -n "$lat" ]] && echo "$dns $lat" >> "$tmp_dns"
    done
    top_5=$(sort -n -k2 "$tmp_dns" | head -n 5 | awk '{print $1}')
    rm "$tmp_dns"
    stop_spinner

    if [[ -n "$top_5" ]]; then
        echo "# Optimized DNS by Wizard Toolkit" > /etc/resolv.conf
        for ip in $top_5; do echo "nameserver $ip" >> /etc/resolv.conf; done
        echo -e "${GREEN}  [+] DNS configured.${RESET}"
    fi

    start_spinner "Finding fastest IR mirror"
    IR_MIRRORS=("https://mirror.arvancloud.ir/ubuntu" "https://ubuntu.shatel.ir/ubuntu" "https://mirror.iranserver.com/ubuntu")
    fastest_m="${IR_MIRRORS[0]}"
    min_lat=999
    for m in "${IR_MIRRORS[@]}"; do
        domain=$(echo "$m" | awk -F[/:] '{print $4}')
        lat=$(ping -c 1 -W 1 "$domain" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1 | cut -d'.' -f1)
        if [[ -n "$lat" && "$lat" -lt "$min_lat" ]]; then
            min_lat=$lat; fastest_m=$m
        fi
    done
    stop_spinner
    echo -e "${GREEN}  [+] Best IR mirror: ${CYAN}$fastest_m ${GRAY}(${min_lat}ms)${RESET}"

    start_spinner "Applying mirror"
    if [[ -f "/etc/apt/sources.list.d/ubuntu.sources" ]]; then
        sed -i "s|URIs: .*|URIs: $fastest_m/|g" /etc/apt/sources.list.d/ubuntu.sources
    fi
    if [[ -f "/etc/apt/sources.list" ]]; then
        sed -i "s|https\?://[^ ]*|$fastest_m|g" /etc/apt/sources.list
    fi
    stop_spinner

    echo ""
    echo -e "${GREEN}  [✔] Iran network optimization complete!${RESET}"
    wait_for_enter
    main_menu
}

# ---- Kharej optimization ----
_net_optimize_kharej() {
    echo ""
    echo -e "${CYAN}  [i] Optimizing for Kharej server...${RESET}"
    echo ""

    start_spinner "Analyzing global DNS latencies"
    GLOBAL_DNS=("8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1" "9.9.9.9" "149.112.112.112" "208.67.222.222" "208.67.220.220")
    tmp_dns=$(mktemp)
    for dns in "${GLOBAL_DNS[@]}"; do
        lat=$(ping -c 1 -W 1 "$dns" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1 | cut -d'.' -f1)
        [[ -n "$lat" ]] && echo "$dns $lat" >> "$tmp_dns"
    done
    top_3=$(sort -n -k2 "$tmp_dns" | head -n 3 | awk '{print $1}')
    rm "$tmp_dns"
    stop_spinner

    if [[ -n "$top_3" ]]; then
        echo "# Optimized DNS by Wizard Toolkit" > /etc/resolv.conf
        for ip in $top_3; do echo "nameserver $ip" >> /etc/resolv.conf; done
        echo -e "${GREEN}  [+] DNS configured.${RESET}"
    fi

    start_spinner "Finding fastest global Ubuntu mirror"
    GLOBAL_MIRRORS=(
        "https://mirror.hetzner.com/ubuntu/packages"
        "https://ftp.halifax.rwth-aachen.de/ubuntu"
        "https://ubuntu.mirror.liteserver.nl/ubuntu"
        "https://mirrors.edge.kernel.org/ubuntu"
        "http://archive.ubuntu.com/ubuntu"
    )
    fastest_m="${GLOBAL_MIRRORS[0]}"
    min_lat=999
    for m in "${GLOBAL_MIRRORS[@]}"; do
        domain=$(echo "$m" | awk -F[/:] '{print $4}')
        lat=$(ping -c 1 -W 1 "$domain" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1 | cut -d'.' -f1)
        if [[ -n "$lat" && "$lat" -lt "$min_lat" ]]; then
            min_lat=$lat; fastest_m=$m
        fi
    done
    stop_spinner
    echo -e "${GREEN}  [+] Best global mirror: ${CYAN}$fastest_m ${GRAY}(${min_lat}ms)${RESET}"

    start_spinner "Applying mirror"
    if [[ -f "/etc/apt/sources.list.d/ubuntu.sources" ]]; then
        sed -i "s|URIs: .*|URIs: $fastest_m/|g" /etc/apt/sources.list.d/ubuntu.sources
    fi
    if [[ -f "/etc/apt/sources.list" ]]; then
        sed -i "s|https\?://[^ ]*|$fastest_m|g" /etc/apt/sources.list
    fi
    stop_spinner

    echo ""
    echo -e "${GREEN}  [✔] Kharej network optimization complete!${RESET}"
    wait_for_enter
    main_menu
}

# ================================================================
# SECTION 2 — 3X-UI Offline Installer
# ================================================================
install_3x_ui() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  3X-UI OFFLINE INSTALLER${RESET}"
    divider

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; main_menu; return
    fi

    # --- Check if already installed ---
    if [[ -f "/usr/local/x-ui/x-ui" ]] || systemctl is-active --quiet x-ui 2>/dev/null; then
        echo -e "${YELLOW}  [!] 3X-UI is already installed on this system.${RESET}"
        echo -e "${CYAN}  [i] Manage it using the '${WHITE}x-ui${CYAN}' command in terminal.${RESET}"
        wait_for_enter; main_menu; return
    fi

    # --- Find package ---
    local PKG_FILE="" PKG_TYPE=""
    PKG_FILE=$(ls ./*.tar.gz 2>/dev/null | grep -i "x-ui" | head -n 1)
    if [[ -n "$PKG_FILE" ]]; then
        PKG_TYPE="targz"
    else
        PKG_FILE=$(ls ./*.zip 2>/dev/null | grep -i "x-ui" | head -n 1)
        [[ -n "$PKG_FILE" ]] && PKG_TYPE="zip"
    fi

    if [[ -z "$PKG_FILE" ]]; then
        echo -e "${RED}  [!] No 3x-ui package found in current directory!${RESET}"
        echo -e "${CYAN}  [i] Place one of these next to the script:${RESET}"
        echo -e "${DIM}      • x-ui-linux-amd64.tar.gz${RESET}"
        echo -e "${DIM}      • 3x-ui.zip${RESET}"
        wait_for_enter; main_menu; return
    fi

    echo -e "${GREEN}  [+] Package: ${CYAN}$(basename $PKG_FILE) ${DIM}[$PKG_TYPE]${RESET}"

    local TMP_DIR="/tmp/xui_offline_$$"
    local INSTALL_DIR="/usr/local/x-ui"
    local BIN_PATH="/usr/local/bin/x-ui"
    local SERVICE_PATH="/etc/systemd/system/x-ui.service"

    start_spinner "Extracting package"
    rm -rf "$TMP_DIR"; mkdir -p "$TMP_DIR"
    if [[ "$PKG_TYPE" == "targz" ]]; then
        tar -xzf "$PKG_FILE" -C "$TMP_DIR" > /dev/null 2>&1
    else
        if ! command -v unzip &>/dev/null; then
            stop_spinner
            start_spinner "Installing unzip"
            apt-get install -y unzip > /dev/null 2>&1
            stop_spinner
            start_spinner "Extracting package"
        fi
        unzip -o "$PKG_FILE" -d "$TMP_DIR" > /dev/null 2>&1
    fi
    stop_spinner

    local XUI_BIN
    XUI_BIN=$(find "$TMP_DIR" -type f -name "x-ui" ! -name "*.sh" | head -n 1)
    if [[ -z "$XUI_BIN" ]]; then
        echo -e "${RED}  [!] Could not find 'x-ui' binary inside package!${RESET}"
        rm -rf "$TMP_DIR"; wait_for_enter; main_menu; return
    fi

    local XUI_CONTENT_DIR
    XUI_CONTENT_DIR=$(dirname "$XUI_BIN")

    start_spinner "Installing files"
    rm -rf "$INSTALL_DIR"; mkdir -p "$INSTALL_DIR"
    cp -r "$XUI_CONTENT_DIR"/. "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/x-ui"
    stop_spinner

    local SCRIPT_DIR XUI_SH_SRC=""
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/x-ui.sh" ]]; then
        XUI_SH_SRC="$SCRIPT_DIR/x-ui.sh"
        echo -e "${GREEN}  [+] x-ui.sh found next to script.${RESET}"
    elif [[ -f "$XUI_CONTENT_DIR/x-ui.sh" ]]; then
        XUI_SH_SRC="$XUI_CONTENT_DIR/x-ui.sh"
        echo -e "${GREEN}  [+] x-ui.sh found inside package.${RESET}"
    else
        echo -e "${YELLOW}  [!] x-ui.sh not found. Linking binary directly.${RESET}"
    fi

    start_spinner "Setting up x-ui command"
    if [[ -n "$XUI_SH_SRC" ]]; then
        cp -f "$XUI_SH_SRC" "$INSTALL_DIR/x-ui.sh"
        cp -f "$XUI_SH_SRC" "$BIN_PATH"
        chmod +x "$INSTALL_DIR/x-ui.sh" "$BIN_PATH"
    else
        ln -sf "$INSTALL_DIR/x-ui" "$BIN_PATH"
    fi
    stop_spinner

    mkdir -p "/etc/x-ui"

    start_spinner "Creating systemd service"
    cat > "$SERVICE_PATH" << 'EOF'
[Unit]
Description=x-ui Service
After=network.target nss-lookup.target

[Service]
Type=simple
WorkingDirectory=/usr/local/x-ui/
ExecStart=/usr/local/x-ui/x-ui
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    stop_spinner

    start_spinner "Enabling and starting x-ui"
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable x-ui > /dev/null 2>&1
    systemctl restart x-ui > /dev/null 2>&1
    sleep 3
    stop_spinner

    if ! systemctl is-active --quiet x-ui; then
        echo -e "${RED}  [!] x-ui service failed to start!${RESET}"
        echo -e "${YELLOW}  [i] Check: journalctl -u x-ui -n 50${RESET}"
    else
        echo -e "${GREEN}  [+] x-ui service is running.${RESET}"
    fi

    start_spinner "Disabling forced SSL"
    _disable_ssl_force
    stop_spinner

    rm -rf "$TMP_DIR"

    local PANEL_PORT
    PANEL_PORT=$(get_panel_port)

    echo ""
    divider
    echo -e "${BOLD}${GREEN}  [✔] 3X-UI Installation Complete!${RESET}"
    divider
    echo -e "${CYAN}  Panel URL     : ${YELLOW}http://$(hostname -I | awk '{print $1}'):${PANEL_PORT}${RESET}"
    echo -e "${CYAN}  Default Login : ${YELLOW}admin / admin${RESET}"
    echo -e "${CYAN}  CLI Command   : ${YELLOW}x-ui${RESET}"
    echo -e "${YELLOW}  [i] Forced SSL disabled. Panel runs on HTTP.${RESET}"
    divider

    wait_for_enter
    main_menu
}

_disable_ssl_force() {
    local DB_FILE="/etc/x-ui/x-ui.db"
    if [[ -f "$DB_FILE" ]] && command -v sqlite3 &>/dev/null; then
        sqlite3 "$DB_FILE" "UPDATE settings SET value='' WHERE key='webCertFile';" 2>/dev/null
        sqlite3 "$DB_FILE" "UPDATE settings SET value='' WHERE key='webKeyFile';" 2>/dev/null
        systemctl restart x-ui > /dev/null 2>&1
        return
    fi
    cat > /usr/local/x-ui/disable_ssl.sh << 'SSLEOF'
#!/bin/bash
DB="/etc/x-ui/x-ui.db"
count=0
while [[ ! -f "$DB" && $count -lt 30 ]]; do sleep 1; ((count++)); done
if [[ -f "$DB" ]] && command -v sqlite3 &>/dev/null; then
    sqlite3 "$DB" "UPDATE settings SET value='' WHERE key='webCertFile';"
    sqlite3 "$DB" "UPDATE settings SET value='' WHERE key='webKeyFile';"
    systemctl restart x-ui
fi
rm -f /usr/local/x-ui/disable_ssl.sh
SSLEOF
    chmod +x /usr/local/x-ui/disable_ssl.sh
    nohup /usr/local/x-ui/disable_ssl.sh > /dev/null 2>&1 &
}

get_panel_port() {
    local DB_FILE="/etc/x-ui/x-ui.db"
    local port="2053"
    if [[ -f "$DB_FILE" ]] && command -v sqlite3 &>/dev/null; then
        local db_port
        db_port=$(sqlite3 "$DB_FILE" "SELECT value FROM settings WHERE key='webPort';" 2>/dev/null)
        [[ -n "$db_port" ]] && port="$db_port"
    fi
    echo "$port"
}

# ================================================================
# SECTION 3 — Backhaul Premium Manager
# ================================================================

_bh_detect_service() {
    local svc=""
    for name in backhaul-iran backhaul_iran backhaul-core-iran backhaul-premium backhaul; do
        if systemctl list-units --type=service --all 2>/dev/null | grep -qw "${name}.service"; then
            svc="$name"; break
        fi
    done
    if [[ -z "$svc" ]]; then
        svc=$(systemctl list-units --type=service --all 2>/dev/null \
            | grep -i "backhaul" | awk '{print $1}' | sed 's/.service//' | head -n 1)
    fi
    echo "$svc"
}

# ---- 3.1: Install Backhaul (Offline) ----
bh_install() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  BACKHAUL PREMIUM — OFFLINE INSTALLER${RESET}"
    divider

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local BH_BIN="$SCRIPT_DIR/backhaul_premium"
    local BH_SH="$SCRIPT_DIR/backhaul.sh"
    local BH_ROOT="/root/backhaul-core"

    # --- Check already installed ---
    if [[ -f "$BH_ROOT/backhaul_premium" && -f "$BH_ROOT/backhaul.sh" ]]; then
        echo -e "${YELLOW}  [!] Backhaul Premium is already installed.${RESET}"
        echo -e "${CYAN}  [i] Use Option 2 to create/manage tunnels via: ${WHITE}cd $BH_ROOT && bash backhaul.sh${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    if [[ ! -f "$BH_BIN" ]]; then
        echo -e "${RED}  [!] File not found: backhaul_premium${RESET}"
        echo -e "${CYAN}  [i] Place 'backhaul_premium' next to this script and retry.${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    if [[ ! -f "$BH_SH" ]]; then
        echo -e "${RED}  [!] File not found: backhaul.sh${RESET}"
        echo -e "${CYAN}  [i] Place 'backhaul.sh' next to this script and retry.${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo -e "${GREEN}  [+] Found: ${CYAN}backhaul_premium${RESET}"
    echo -e "${GREEN}  [+] Found: ${CYAN}backhaul.sh${RESET}"

    start_spinner "Copying files to $BH_ROOT"
    mkdir -p "$BH_ROOT"
    cp -f "$BH_BIN" "$BH_ROOT/backhaul_premium"
    cp -f "$BH_SH"  "$BH_ROOT/backhaul.sh"
    chmod +x "$BH_ROOT/backhaul_premium"
    chmod +x "$BH_ROOT/backhaul.sh"
    stop_spinner

    echo ""
    divider
    echo -e "${BOLD}${GREEN}  [✔] Backhaul Premium Installed!${RESET}"
    divider
    echo -e "${CYAN}  Install Dir : ${YELLOW}$BH_ROOT${RESET}"
    echo -e "${CYAN}  Next Step   : ${YELLOW}Use Option 2 to launch tunnel manager${RESET}"
    echo -e "${YELLOW}  [i] After tunnel setup, use Option 3 to apply IP Spoof.${RESET}"
    divider

    wait_for_enter
    backhaul_menu
}

# ---- 3.2: Launch Backhaul Manager ----
bh_launch_manager() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  BACKHAUL PREMIUM — TUNNEL MANAGER${RESET}"
    divider

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    local BH_ROOT="/root/backhaul-core"

    if [[ ! -f "$BH_ROOT/backhaul.sh" ]]; then
        echo -e "${RED}  [!] Backhaul not installed yet!${RESET}"
        echo -e "${CYAN}  [i] Use Option 1 to install first.${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo -e "${YELLOW}  [i] Launching Backhaul Manager...${RESET}"
    echo -e "${DIM}  (You will return to Gray Wizard when you exit the manager)${RESET}"
    echo ""
    sleep 1

    # اجرا از داخل پوشه backhaul تا toml کنار باینری بسازه
    cd "$BH_ROOT" && bash backhaul.sh
    cd - > /dev/null 2>&1

    backhaul_menu
}

# ---- 3.3: Apply IP Spoof ----
bh_apply_spoof() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  BACKHAUL PREMIUM — APPLY IP SPOOF${RESET}"
    divider

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    local BH_ROOT="/root/backhaul-core"

    # --- Server role ---
    echo -e "${YELLOW}  [?] Which server is this?${RESET}"
    echo -e "${BLUE}      1)${RESET} Iran"
    echo -e "${BLUE}      2)${RESET} Kharej"
    echo ""
    read_input "Server role [1/2]" SERVER_ROLE

    local TOML_PREFIX=""
    case "$SERVER_ROLE" in
        1) TOML_PREFIX="iran" ;;
        2) TOML_PREFIX="kharej" ;;
        *)
            echo -e "${RED}  [!] Invalid choice!${RESET}"
            wait_for_enter; backhaul_menu; return ;;
    esac

    echo ""
    read_input "Tunnel port (e.g. 1234)" TUNNEL_PORT

    if [[ ! "$TUNNEL_PORT" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}  [!] Invalid port number!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    local TOML_FILE="$BH_ROOT/${TOML_PREFIX}${TUNNEL_PORT}.toml"

    if [[ ! -f "$TOML_FILE" ]]; then
        echo -e "${RED}  [!] File not found: $TOML_FILE${RESET}"
        echo -e "${CYAN}  [i] Make sure you entered the correct tunnel port.${RESET}"
        echo -e "${GRAY}  [i] Toml files are located in: /root/backhaul-core/${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo -e "${GREEN}  [+] Config: ${CYAN}$TOML_FILE${RESET}"
    echo ""
    read_input "Enter your white/spoof IP" SPOOF_IP

    if [[ ! "$SPOOF_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${RED}  [!] Invalid IP format!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo ""

    # --- Update or inject ---
    if grep -q "spoof_src_ip" "$TOML_FILE"; then
        echo -e "${YELLOW}  [!] Spoof entries exist. Updating...${RESET}"
        start_spinner "Updating spoof IPs"
        sed -i "s|spoof_src_ip = \".*\"|spoof_src_ip = \"$SPOOF_IP\"|g" "$TOML_FILE"
        sed -i "s|spoof_dst_ip = \".*\"|spoof_dst_ip = \"$SPOOF_IP\"|g" "$TOML_FILE"
        stop_spinner
    else
        start_spinner "Injecting spoof IPs before 'interface' in [ipx]"
        local IPX_LINE
        IPX_LINE=$(grep -n "^\[ipx\]" "$TOML_FILE" | head -n 1 | cut -d: -f1)
        if [[ -z "$IPX_LINE" ]]; then
            stop_spinner
            echo -e "${RED}  [!] Could not find [ipx] section in toml!${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
        local IFACE_LINE_NUM
        IFACE_LINE_NUM=$(awk "NR>$IPX_LINE && /^interface[[:space:]]*=/{print NR; exit}" "$TOML_FILE")
        if [[ -z "$IFACE_LINE_NUM" ]]; then
            stop_spinner
            echo -e "${RED}  [!] Could not find 'interface' line in [ipx]!${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
        sed -i "${IFACE_LINE_NUM}i spoof_src_ip = \"$SPOOF_IP\"\nspoof_dst_ip = \"$SPOOF_IP\"" "$TOML_FILE"
        stop_spinner
        if ! grep -q "spoof_src_ip" "$TOML_FILE"; then
            echo -e "${RED}  [!] Injection failed! Check $TOML_FILE manually.${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
    fi

    echo -e "${GREEN}  [+] Spoof IPs applied.${RESET}"

    # --- Detect and restart service ---
    start_spinner "Detecting Backhaul service"
    local BH_SERVICE
    BH_SERVICE=$(_bh_detect_service)
    stop_spinner

    if [[ -z "$BH_SERVICE" ]]; then
        echo -e "${YELLOW}  [!] Could not auto-detect service.${RESET}"
        echo ""
        read_input "Service name (e.g. backhaul-iran)" BH_SERVICE
    else
        echo -e "${GREEN}  [+] Service: ${CYAN}$BH_SERVICE${RESET}"
    fi

    start_spinner "Restarting $BH_SERVICE"
    systemctl restart "$BH_SERVICE" > /dev/null 2>&1
    sleep 2
    stop_spinner

    if systemctl is-active --quiet "$BH_SERVICE"; then
        echo -e "${GREEN}  [+] Service restarted successfully.${RESET}"
    else
        echo -e "${RED}  [!] Restart failed!${RESET}"
        echo -e "${YELLOW}  [i] Debug: journalctl -u $BH_SERVICE -n 30${RESET}"
    fi

    echo ""
    divider
    echo -e "${BOLD}${GREEN}  [✔] IP Spoof Applied!${RESET}"
    divider
    echo -e "${CYAN}  Config File  : ${YELLOW}$TOML_FILE${RESET}"
    echo -e "${CYAN}  Spoof IP     : ${YELLOW}$SPOOF_IP${RESET}"
    echo -e "${CYAN}  Service      : ${YELLOW}$BH_SERVICE${RESET}"
    divider

    wait_for_enter
    backhaul_menu
}

# ---- 3.4: Service Status / Restart ----
bh_service_status() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  BACKHAUL PREMIUM — SERVICE STATUS${RESET}"
    divider

    local BH_SERVICE
    BH_SERVICE=$(_bh_detect_service)

    if [[ -z "$BH_SERVICE" ]]; then
        echo -e "${YELLOW}  [!] Could not auto-detect Backhaul service.${RESET}"
        echo ""
        read_input "Service name (e.g. backhaul-iran)" BH_SERVICE
    else
        echo -e "${GREEN}  [+] Service: ${CYAN}$BH_SERVICE${RESET}"
    fi

    echo ""
    divider
    systemctl status "$BH_SERVICE" --no-pager -l 2>/dev/null || \
        echo -e "${RED}  [!] Service '$BH_SERVICE' not found!${RESET}"
    divider
    echo ""

    echo -e "${YELLOW}  [?] Restart this service? (y/n)${RESET}"
    read_input "Choice" do_restart

    if [[ "$do_restart" =~ ^[Yy]$ ]]; then
        start_spinner "Restarting $BH_SERVICE"
        systemctl restart "$BH_SERVICE" > /dev/null 2>&1
        sleep 2
        stop_spinner
        if systemctl is-active --quiet "$BH_SERVICE"; then
            echo -e "${GREEN}  [+] Service restarted successfully.${RESET}"
        else
            echo -e "${RED}  [!] Restart failed! Check: journalctl -u $BH_SERVICE -n 30${RESET}"
        fi
    else
        echo -e "${YELLOW}  [i] Restart cancelled.${RESET}"
    fi

    wait_for_enter
    backhaul_menu
}


# ---- 3.4: Spoof Support Test ----
bh_spoof_test() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  BACKHAUL — SPOOF SUPPORT TEST${RESET}"
    divider
    echo -e "${GRAY}  Test whether your servers support IP spoofing${RESET}"
    echo -e "${GRAY}  before setting up the Backhaul spoof tunnel.${RESET}"
    echo ""

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    # --- Server role ---
    echo -e "${YELLOW}  [?] What is the role of THIS server?${RESET}"
    echo -e "${CYAN}      1)${RESET}  Sender  ${GRAY}(sends spoofed packets)${RESET}"
    echo -e "${CYAN}      2)${RESET}  Listener ${GRAY}(receives and checks packets)${RESET}"
    echo ""
    read_input "Role [1/2]" SPOOF_ROLE

    case "$SPOOF_ROLE" in
        1) _spoof_test_sender ;;
        2) _spoof_test_listener ;;
        *)
            echo -e "${RED}  [!] Invalid choice!${RESET}"
            sleep 1.5; bh_spoof_test ;;
    esac
}

# --- Sender Mode ---
_spoof_test_sender() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  SPOOF TEST — SENDER MODE${RESET}"
    divider
    echo -e "${GRAY}  This server will send spoofed UDP packets to the listener.${RESET}"
    echo ""

    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local WHL_FILE
    WHL_FILE=$(find "$SCRIPT_DIR" -maxdepth 1 -name "scapy*.whl" 2>/dev/null | head -n 1)

    # --- Check/Install pip ---
    if ! command -v pip3 &>/dev/null; then
        start_spinner "Installing pip3"
        apt-get install -y python3-pip > /dev/null 2>&1
        stop_spinner
        if ! command -v pip3 &>/dev/null; then
            echo -e "${RED}  [!] Failed to install pip3!${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
    fi
    echo -e "${GREEN}  [+] pip3 is available.${RESET}"

    # --- Install scapy ---
    if ! python3 -c "from scapy.all import IP" &>/dev/null; then
        if [[ -n "$WHL_FILE" ]]; then
            echo -e "${GREEN}  [+] Found: ${CYAN}$(basename $WHL_FILE)${RESET}"
            start_spinner "Installing Scapy from local file"
            pip3 install "$WHL_FILE" --break-system-packages -q 2>/dev/null
            stop_spinner
        else
            echo -e "${RED}  [!] scapy .whl file not found next to script!${RESET}"
            echo -e "${CYAN}  [i] Place 'scapy-2.7.0-py3-none-any.whl' next to the script.${RESET}"
            wait_for_enter; backhaul_menu; return
        fi

        if ! python3 -c "from scapy.all import IP" &>/dev/null; then
            echo -e "${RED}  [!] Scapy installation failed!${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
    fi
    echo -e "${GREEN}  [+] Scapy is ready.${RESET}"

    # --- Get parameters ---
    echo ""
    read_input "Your spoof IP (fake source IP, e.g. 81.28.60.1)" SPOOF_SRC
    if [[ ! "$SPOOF_SRC" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${RED}  [!] Invalid IP format!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo ""
    read_input "Listener server IP (destination IP)" DST_IP
    if [[ ! "$DST_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${RED}  [!] Invalid IP format!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo ""
    echo -e "${YELLOW}  [i] Sending spoofed UDP packets to ${CYAN}$DST_IP${YELLOW}:4444${RESET}"
    echo -e "${YELLOW}  [i] Make sure the listener is running on the other server.${RESET}"
    echo -e "${GRAY}  [i] Press Ctrl+C to stop sending.${RESET}"
    echo ""
    sleep 1

    # --- Send packets ---
    sudo python3 -c "
from scapy.all import *
import random, sys

src = '$SPOOF_SRC'
dst = '$DST_IP'
port = 4444
count = 0

print('\033[0;36m  >> Sending spoofed packets... (Ctrl+C to stop)\033[0m')
try:
    while True:
        sport = random.randint(1024, 65535)
        pkt = IP(src=src, dst=dst)/UDP(dport=port, sport=sport)/Raw(load=RandString(size=random.randint(10,50)))
        send(pkt, verbose=0)
        count += 1
        sys.stdout.write(f'\r\033[0;33m  >> Packets sent: {count}\033[0m')
        sys.stdout.flush()
except KeyboardInterrupt:
    print(f'\n\033[0;32m  [+] Done. Total packets sent: {count}\033[0m')
"

    echo ""
    echo -e "${CYAN}  [i] If the listener received packets → ${GREEN}spoof is supported ✔${RESET}"
    echo -e "${CYAN}  [i] If nothing received → ${RED}spoof is NOT supported ✘${RESET}"

    wait_for_enter
    backhaul_menu
}

# --- Listener Mode ---
_spoof_test_listener() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  SPOOF TEST — LISTENER MODE${RESET}"
    divider
    echo -e "${GRAY}  This server will listen for incoming spoofed UDP packets.${RESET}"
    echo ""

    # --- Check tcpdump ---
    if ! command -v tcpdump &>/dev/null; then
        start_spinner "Installing tcpdump"
        apt-get install -y tcpdump > /dev/null 2>&1
        stop_spinner
        if ! command -v tcpdump &>/dev/null; then
            echo -e "${RED}  [!] Failed to install tcpdump!${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
    fi
    echo -e "${GREEN}  [+] tcpdump is ready.${RESET}"
    echo ""
    echo -e "${YELLOW}  [i] Listening on UDP port 4444...${RESET}"
    echo -e "${YELLOW}  [i] Start the sender on the other server now.${RESET}"
    echo -e "${GRAY}  [i] If you see packets below → spoof is supported ✔${RESET}"
    echo -e "${GRAY}  [i] Press Ctrl+C to stop listening.${RESET}"
    echo ""
    divider

    # --- Listen ---
    sudo tcpdump -n udp port 4444 -l 2>/dev/null

    echo ""
    divider
    echo -e "${CYAN}  [i] Received packets → ${GREEN}spoof is supported ✔${RESET}"
    echo -e "${CYAN}  [i] No packets received → ${RED}spoof is NOT supported ✘${RESET}"

    wait_for_enter
    backhaul_menu
}

# ---- 3.4: Spoof Support Test ----
bh_spoof_test() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  BACKHAUL — SPOOF SUPPORT TEST${RESET}"
    divider
    echo -e "${GRAY}  Tests whether your servers support IP spoofing${RESET}"
    echo -e "${GRAY}  using raw UDP packets via Scapy.${RESET}"
    echo ""

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    # --- Step 1: Install pip if missing ---
    if ! command -v pip3 &>/dev/null && ! command -v pip &>/dev/null; then
        echo -e "${YELLOW}  [!] pip not found. Installing...${RESET}"
        start_spinner "Installing pip via local mirror"
        apt-get update -o Acquire::CompressionTypes::Order::=gz > /dev/null 2>&1
        apt-get install -y python3-pip > /dev/null 2>&1
        stop_spinner
        if ! command -v pip3 &>/dev/null; then
            echo -e "${RED}  [!] Failed to install pip! Check your mirror settings.${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
    fi
    echo -e "${GREEN}  [+] pip is available.${RESET}"

    # --- Step 2: Install scapy from .whl if not installed ---
    if ! python3 -c "from scapy.all import IP" &>/dev/null; then
        local SCRIPT_DIR
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local WHL_FILE
        WHL_FILE=$(ls "$SCRIPT_DIR"/scapy*.whl 2>/dev/null | head -n 1)

        if [[ -n "$WHL_FILE" ]]; then
            local WHL_NAME
            WHL_NAME=$(basename "$WHL_FILE")
            start_spinner "Installing Scapy from $WHL_NAME"
            if pip3 install "$WHL_FILE" --break-system-packages > /tmp/scapy_install.log 2>&1; then
                : # success
            else
                pip3 install "$WHL_FILE" > /tmp/scapy_install.log 2>&1
            fi
            stop_spinner
        else
            echo -e "${YELLOW}  [!] scapy .whl not found next to script.${RESET}"
            echo -e "${YELLOW}  [?] Try installing from PyPI? (requires internet) (y/n)${RESET}"
            read_input "Choice" INSTALL_ONLINE
            if [[ "$INSTALL_ONLINE" =~ ^[Yy]$ ]]; then
                start_spinner "Installing Scapy from PyPI"
                if ! pip3 install scapy --break-system-packages > /dev/null 2>&1; then
                    pip3 install scapy > /dev/null 2>&1
                fi
                stop_spinner
            else
                echo -e "${RED}  [!] Scapy not available. Place scapy*.whl next to script.${RESET}"
                wait_for_enter; backhaul_menu; return
            fi
        fi

        if ! python3 -c "from scapy.all import IP" &>/dev/null; then
            echo -e "${RED}  [!] Scapy installation failed!${RESET}"
            wait_for_enter; backhaul_menu; return
        fi
    fi
    echo -e "${GREEN}  [+] Scapy is ready.${RESET}"
    echo ""

    # --- Step 3: Choose role ---
    echo -e "${YELLOW}  [?] What is the role of THIS server?${RESET}"
    echo -e "  ${CYAN}1)${RESET}  Sender  ${GRAY}(sends spoofed packets to the other server)${RESET}"
    echo -e "  ${CYAN}2)${RESET}  Listener ${GRAY}(listens for incoming spoofed packets)${RESET}"
    echo ""
    read_input "Role [1/2]" ROLE_CHOICE

    case "$ROLE_CHOICE" in
        1) _bh_spoof_sender ;;
        2) _bh_spoof_listener ;;
        *)
            echo -e "${RED}  [!] Invalid choice!${RESET}"
            wait_for_enter; backhaul_menu; return
            ;;
    esac
}

# --- Sender mode ---
_bh_spoof_sender() {
    echo ""
    divider
    echo -e "${BOLD}${CYAN}  ── SENDER MODE ──${RESET}"
    divider
    echo ""
    read_input "Spoof source IP (fake sender IP)" SPOOF_SRC
    echo ""
    read_input "Destination IP (listener server IP)" DST_IP
    echo ""
    read_input "Destination port (default 4444)" DST_PORT
    [[ -z "$DST_PORT" || ! "$DST_PORT" =~ ^[0-9]+$ ]] && DST_PORT="4444"
    echo ""
    read_input "Number of packets to send (default 20)" PKT_COUNT
    [[ -z "$PKT_COUNT" || ! "$PKT_COUNT" =~ ^[0-9]+$ ]] && PKT_COUNT="20"

    echo ""
    echo -e "${YELLOW}  [i] Make sure the listener server is running tcpdump:${RESET}"
    echo -e "${GRAY}      sudo tcpdump -n udp port $DST_PORT${RESET}"
    echo ""
    echo -e "${YELLOW}  [?] Ready to send $PKT_COUNT spoofed packets? (y/n)${RESET}"
    read_input "Confirm" CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  [i] Cancelled.${RESET}"
        wait_for_enter; backhaul_menu; return
    fi

    echo ""
    start_spinner "Sending $PKT_COUNT spoofed UDP packets"
    python3 - << PYEOF > /dev/null 2>&1
from scapy.all import *
import random
for _ in range($PKT_COUNT):
    send(
        IP(src="$SPOOF_SRC", dst="$DST_IP") /
        UDP(dport=$DST_PORT, sport=random.randint(1024, 65535)) /
        Raw(load=RandString(size=random.randint(10, 50))),
        verbose=0
    )
PYEOF
    stop_spinner

    echo ""
    divider
    echo -e "${BOLD}${GREEN}  [✔] Packets sent!${RESET}"
    divider
    echo -e "${CYAN}  Spoof Src IP : ${YELLOW}$SPOOF_SRC${RESET}"
    echo -e "${CYAN}  Destination  : ${YELLOW}$DST_IP:$DST_PORT${RESET}"
    echo -e "${CYAN}  Packets Sent : ${YELLOW}$PKT_COUNT${RESET}"
    divider
    echo -e "${GRAY}  [i] Check the listener server for received packets.${RESET}"
    echo -e "${GREEN}  [✔] Packets received on listener = Spoof is SUPPORTED${RESET}"
    echo -e "${RED}  [✘] No packets received          = Spoof NOT supported${RESET}"
    divider

    wait_for_enter
    backhaul_menu
}

# --- Listener mode ---
_bh_spoof_listener() {
    echo ""
    divider
    echo -e "${BOLD}${CYAN}  ── LISTENER MODE ──${RESET}"
    divider
    echo ""
    read_input "Listen port (default 4444)" LISTEN_PORT
    [[ -z "$LISTEN_PORT" || ! "$LISTEN_PORT" =~ ^[0-9]+$ ]] && LISTEN_PORT="4444"
    echo ""
    read_input "Listen duration in seconds (default 30)" LISTEN_SEC
    [[ -z "$LISTEN_SEC" || ! "$LISTEN_SEC" =~ ^[0-9]+$ ]] && LISTEN_SEC="30"

    echo ""
    echo -e "${YELLOW}  [i] Listening for ${LISTEN_SEC}s on UDP port ${LISTEN_PORT}...${RESET}"
    echo -e "${GRAY}  [i] Now go run Sender mode on the other server.${RESET}"
    echo -e "${GRAY}  [i] Press Ctrl+C to stop early.${RESET}"
    echo ""
    divider

    # Run tcpdump in background and capture output
    local TMP_LOG
    TMP_LOG=$(mktemp)
    timeout "$LISTEN_SEC" tcpdump -n -l "udp port $LISTEN_PORT" 2>/dev/null | tee "$TMP_LOG" &
    local TCPDUMP_PID=$!

    # Show live countdown
    for ((i=LISTEN_SEC; i>0; i--)); do
        echo -ne "\r${CYAN}  Time remaining: ${YELLOW}${i}s${RESET}   "
        sleep 1
    done
    echo ""

    wait $TCPDUMP_PID 2>/dev/null
    local PKT_RECEIVED
    PKT_RECEIVED=$(grep -c "UDP" "$TMP_LOG" 2>/dev/null || echo 0)
    rm -f "$TMP_LOG"

    echo ""
    divider
    if [[ "$PKT_RECEIVED" -gt 0 ]]; then
        echo -e "${BOLD}${GREEN}  [✔] SPOOF IS SUPPORTED!${RESET}"
        echo -e "${GREEN}  [+] Received $PKT_RECEIVED spoofed packet(s) on port $LISTEN_PORT${RESET}"
        echo -e "${CYAN}  [i] This server can receive spoofed traffic.${RESET}"
    else
        echo -e "${BOLD}${RED}  [✘] SPOOF NOT SUPPORTED${RESET}"
        echo -e "${RED}  [!] No packets received on port $LISTEN_PORT${RESET}"
        echo -e "${YELLOW}  [i] This server blocks spoofed traffic.${RESET}"
        echo -e "${YELLOW}  [i] Make sure sender is running and using correct IP/port.${RESET}"
    fi
    divider

    wait_for_enter
    backhaul_menu
}

# ---- Backhaul Sub-Menu ----
backhaul_menu() {
    IN_PROCESS="false"
    clear
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo -e "  ██╗    ██╗██╗███████╗ █████╗ ██████╗ ██████╗ "
    echo -e "  ██║    ██║██║╚══███╔╝██╔══██╗██╔══██╗██╔══██╗"
    echo -e "  ██║ █╗ ██║██║  ███╔╝ ███████║██████╔╝██║  ██║"
    echo -e "  ██║███╗██║██║ ███╔╝  ██╔══██║██╔══██╗██║  ██║"
    echo -e "  ╚███╔███╔╝██║███████╗██║  ██║██║  ██║██████╔╝"
    echo -e "   ╚══╝╚══╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ${RESET}"
    echo -e "${BOLD}${BLUE}      ── Backhaul Premium Manager ──${RESET}"
    echo -e "${GRAY}              Crafted by ${WHITE}@Gr4y_Wizard${RESET}"
    echo -e "${GRAY}          Telegram: ${CYAN}https://t.me/Gray_wiz4rd${RESET}"
    echo ""
    echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
    echo -e "  ${CYAN}1)${RESET}  Install Backhaul Premium ${GRAY}(Offline)${RESET}"
    echo -e "  ${CYAN}2)${RESET}  Launch Backhaul Tunnel Manager"
    echo -e "  ${CYAN}3)${RESET}  Apply IP Spoof"
    echo -e "  ${CYAN}4)${RESET}  Spoof Support Test"
    echo -e "  ${CYAN}5)${RESET}  Service Status / Restart"
    echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}0)${RESET}  Back to Main Menu"
    echo ""
    echo -ne "${CYAN}  Choose${RESET}${RED}${BLINK} ▸ ${RESET}"
    read bh_choice
    echo -e "\033[1A\r${CYAN}  Choose${RESET}${GREEN} ▸ ${bh_choice}${RESET}     "
    echo ""
    case $bh_choice in
        1) bh_install ;;
        2) bh_launch_manager ;;
        3) bh_apply_spoof ;;
        4) bh_spoof_test ;;
        5) bh_service_status ;;
        0) main_menu ;;
        *)
            echo -e "${RED}  [!] Invalid option.${RESET}"
            sleep 1.5; backhaul_menu ;;
    esac
}

# ================================================================
# MAIN MENU
# ================================================================
# ================================================================
# SECTION 4 — Folder Encryption Manager (gocryptfs)
# ================================================================

# ---- Install gocryptfs if missing ----
_enc_install_gocryptfs() {
    if command -v gocryptfs &>/dev/null; then return 0; fi
    echo -e "${YELLOW}  [!] gocryptfs not found. Installing...${RESET}"
    start_spinner "Installing gocryptfs"
    apt-get install -y gocryptfs > /dev/null 2>&1
    stop_spinner
    if ! command -v gocryptfs &>/dev/null; then
        echo -e "${RED}  [!] Installation failed! Try: apt-get install gocryptfs${RESET}"
        return 1
    fi
    echo -e "${GREEN}  [+] gocryptfs installed.${RESET}"
    return 0
}

# ---- Get target folder from user ----
_enc_get_folder() {
    echo -e "${YELLOW}  [?] Select target folder:${RESET}"
    echo -e "  ${CYAN}1)${RESET}  /root/backhaul-core ${GRAY}(default tunnel folder)${RESET}"
    echo -e "  ${CYAN}2)${RESET}  Custom path"
    echo ""
    read_input "Choice [1/2]" FOLDER_CHOICE
    echo ""
    case "$FOLDER_CHOICE" in
        1) TARGET_FOLDER="/root/backhaul-core" ;;
        2)
            read_input "Enter full folder path (e.g. /root/myfolder)" TARGET_FOLDER
            echo ""
            ;;
        *)
            echo -e "${RED}  [!] Invalid choice!${RESET}"
            return 1
            ;;
    esac
    if [[ ! -d "$TARGET_FOLDER" ]]; then
        echo -e "${RED}  [!] Folder not found: $TARGET_FOLDER${RESET}"
        return 1
    fi
    return 0
}

# ---- 4.1: Encrypt a folder ----
enc_encrypt() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  ENCRYPTION — ENCRYPT FOLDER${RESET}"
    divider
    echo -e "${GRAY}  Encrypts a folder using gocryptfs.${RESET}"
    echo -e "${GRAY}  The original folder becomes a hidden encrypted vault.${RESET}"
    echo ""

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    _enc_install_gocryptfs || { wait_for_enter; encryption_menu; return; }
    _enc_get_folder || { wait_for_enter; encryption_menu; return; }

    local FOLDER_NAME
    FOLDER_NAME=$(basename "$TARGET_FOLDER")
    local PARENT_DIR
    PARENT_DIR=$(dirname "$TARGET_FOLDER")
    local ENCRYPTED_VAULT="${PARENT_DIR}/.${FOLDER_NAME}-encrypted"
    local TEMP_DIR="${PARENT_DIR}/temp_${FOLDER_NAME}_$$"

    # Check if already encrypted
    if [[ -d "$ENCRYPTED_VAULT" ]]; then
        echo -e "${YELLOW}  [!] This folder is already encrypted (vault exists).${RESET}"
        echo -e "${CYAN}  [i] Use 'Unlock' or 'Lock' options to manage it.${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    echo -e "${YELLOW}  [!] This will encrypt: ${WHITE}$TARGET_FOLDER${RESET}"
    echo -e "${RED}  [!] IMPORTANT: Save your Master Key in a safe place!${RESET}"
    echo ""
    echo -e "${YELLOW}  [?] Proceed? (y/n)${RESET}"
    read_input "Confirm" CONFIRM
    [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { echo -e "${YELLOW}  [i] Cancelled.${RESET}"; wait_for_enter; encryption_menu; return; }

    echo ""
    start_spinner "Moving files to temp location"
    mkdir -p "$TEMP_DIR"
    mv "$TARGET_FOLDER"/* "$TEMP_DIR/" 2>/dev/null
    stop_spinner

    start_spinner "Creating encrypted vault"
    mv "$TARGET_FOLDER" "$ENCRYPTED_VAULT"
    stop_spinner

    echo ""
    echo -e "${CYAN}  [i] You will now set a password for the encrypted vault.${RESET}"
    echo -e "${RED}  [!] Save the Master Key shown after init — you cannot recover without it!${RESET}"
    echo ""
    divider
    gocryptfs -init "$ENCRYPTED_VAULT"
    divider
    echo ""

    start_spinner "Creating mount point"
    mkdir -p "$TARGET_FOLDER"
    stop_spinner

    echo -e "${CYAN}  [i] Enter your password to unlock and restore files.${RESET}"
    echo ""
    gocryptfs "$ENCRYPTED_VAULT" "$TARGET_FOLDER"

    start_spinner "Restoring files into encrypted vault"
    mv "$TEMP_DIR"/* "$TARGET_FOLDER/" 2>/dev/null
    rmdir "$TEMP_DIR" 2>/dev/null
    stop_spinner

    echo ""
    divider
    echo -e "${BOLD}${GREEN}  [✔] Folder Encrypted Successfully!${RESET}"
    divider
    echo -e "${CYAN}  Vault    : ${YELLOW}$ENCRYPTED_VAULT${RESET}"
    echo -e "${CYAN}  Mounted  : ${YELLOW}$TARGET_FOLDER ${GREEN}(visible & unlocked)${RESET}"
    echo -e "${GRAY}  [i] Use 'Lock Folder' to hide contents when done.${RESET}"
    divider

    _enc_ask_clear_history
    wait_for_enter; encryption_menu
}

# ---- 4.2: Unlock a folder ----
enc_unlock() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  ENCRYPTION — UNLOCK FOLDER${RESET}"
    divider
    echo ""

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    _enc_install_gocryptfs || { wait_for_enter; encryption_menu; return; }
    _enc_get_folder || { wait_for_enter; encryption_menu; return; }

    local FOLDER_NAME
    FOLDER_NAME=$(basename "$TARGET_FOLDER")
    local PARENT_DIR
    PARENT_DIR=$(dirname "$TARGET_FOLDER")
    local ENCRYPTED_VAULT="${PARENT_DIR}/.${FOLDER_NAME}-encrypted"

    if [[ ! -d "$ENCRYPTED_VAULT" ]]; then
        echo -e "${RED}  [!] No encrypted vault found for: $TARGET_FOLDER${RESET}"
        echo -e "${GRAY}  [i] Expected: $ENCRYPTED_VAULT${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    # Check if already mounted
    if mountpoint -q "$TARGET_FOLDER" 2>/dev/null; then
        echo -e "${YELLOW}  [!] Folder is already unlocked and mounted.${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    echo -e "${CYAN}  [i] Enter your password to unlock:${RESET}"
    echo ""
    mkdir -p "$TARGET_FOLDER"
    gocryptfs "$ENCRYPTED_VAULT" "$TARGET_FOLDER"

    if mountpoint -q "$TARGET_FOLDER" 2>/dev/null; then
        echo ""
        echo -e "${GREEN}  [✔] Folder unlocked: ${CYAN}$TARGET_FOLDER${RESET}"
    else
        echo -e "${RED}  [!] Failed to unlock. Wrong password?${RESET}"
    fi

    _enc_ask_clear_history
    wait_for_enter; encryption_menu
}

# ---- 4.3: Lock a folder ----
enc_lock() {
    IN_PROCESS="true"
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ◈  ENCRYPTION — LOCK FOLDER${RESET}"
    divider
    echo ""

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}  [!] Must be run as root!${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    _enc_get_folder || { wait_for_enter; encryption_menu; return; }

    if ! mountpoint -q "$TARGET_FOLDER" 2>/dev/null; then
        echo -e "${YELLOW}  [!] Folder is not currently mounted/unlocked.${RESET}"
        wait_for_enter; encryption_menu; return
    fi

    start_spinner "Locking folder (unmounting)"
    fusermount -uz "$TARGET_FOLDER" > /dev/null 2>&1
    sleep 1
    stop_spinner

    if ! mountpoint -q "$TARGET_FOLDER" 2>/dev/null; then
        echo -e "${GREEN}  [✔] Folder locked. Contents are now hidden.${RESET}"
        echo -e "${GRAY}  [i] The mount point ${TARGET_FOLDER} appears empty.${RESET}"
    else
        echo -e "${RED}  [!] Failed to lock. Folder may be in use.${RESET}"
    fi

    _enc_ask_clear_history
    wait_for_enter; encryption_menu
}

# ---- Ask to clear history ----
_enc_ask_clear_history() {
    echo ""
    echo -e "${YELLOW}  [?] Clear bash history and logs? (y/n)${RESET}"
    read_input "Choice" CLR_CHOICE
    if [[ "$CLR_CHOICE" =~ ^[Yy]$ ]]; then
        history -c && history -w
        echo -e "${GREEN}  [✔] History cleared.${RESET}"
    fi
}

# ---- Encryption Sub-Menu ----
encryption_menu() {
    IN_PROCESS="false"
    clear
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo -e "  ██╗    ██╗██╗███████╗ █████╗ ██████╗ ██████╗ "
    echo -e "  ██║    ██║██║╚══███╔╝██╔══██╗██╔══██╗██╔══██╗"
    echo -e "  ██║ █╗ ██║██║  ███╔╝ ███████║██████╔╝██║  ██║"
    echo -e "  ██║███╗██║██║ ███╔╝  ██╔══██║██╔══██╗██║  ██║"
    echo -e "  ╚███╔███╔╝██║███████╗██║  ██║██║  ██║██████╔╝"
    echo -e "   ╚══╝╚══╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ${RESET}"
    echo -e "${BOLD}${BLUE}      ── Folder Encryption Manager ──${RESET}"
    echo -e "${GRAY}              Crafted by ${WHITE}@Gr4y_Wizard${RESET}"
    echo -e "${GRAY}          Telegram: ${CYAN}https://t.me/Gray_wiz4rd${RESET}"
    echo ""
    echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
    echo -e "  ${CYAN}1)${RESET}  Encrypt a Folder ${GRAY}(first time setup)${RESET}"
    echo -e "  ${CYAN}2)${RESET}  Unlock a Folder ${GRAY}(mount & view contents)${RESET}"
    echo -e "  ${CYAN}3)${RESET}  Lock a Folder ${GRAY}(hide contents instantly)${RESET}"
    echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}0)${RESET}  Back to Main Menu"
    echo ""
    echo -ne "${CYAN}  Choose${RESET}${RED}${BLINK} ▸ ${RESET}"
    read enc_choice
    echo -e "\033[1A\r${CYAN}  Choose${RESET}${GREEN} ▸ ${enc_choice}${RESET}     "
    echo ""
    case $enc_choice in
        1) enc_encrypt ;;
        2) enc_unlock ;;
        3) enc_lock ;;
        0) main_menu ;;
        *)
            echo -e "${RED}  [!] Invalid option.${RESET}"
            sleep 1.5; encryption_menu ;;
    esac
}

# ── Server Info Bar (shown at top of main menu) ──
_show_server_info() {
    local SERVER_IP
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo -e "${GRAY}  ── ${BOLD}${WHITE}SERVER IP${RESET}  ${CYAN}${SERVER_IP}${RESET}  ${GRAY}──${RESET}"
    echo ""
}


main_menu() {
    IN_PROCESS="false"
    clear
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo -e "  ██╗    ██╗██╗███████╗ █████╗ ██████╗ ██████╗ "
    echo -e "  ██║    ██║██║╚══███╔╝██╔══██╗██╔══██╗██╔══██╗"
    echo -e "  ██║ █╗ ██║██║  ███╔╝ ███████║██████╔╝██║  ██║"
    echo -e "  ██║███╗██║██║ ███╔╝  ██╔══██║██╔══██╗██║  ██║"
    echo -e "  ╚███╔███╔╝██║███████╗██║  ██║██║  ██║██████╔╝"
    echo -e "   ╚══╝╚══╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ${RESET}"
    echo -e "${BOLD}${BLUE}          ── W I Z A R D   T O O L K I T  ──  v1.0.0 ──${RESET}"
    echo -e "${GRAY}              Crafted by ${WHITE}@Gr4y_Wizard${RESET}"
    echo -e "${GRAY}          Telegram: ${CYAN}https://t.me/Gray_wiz4rd${RESET}"
    echo ""
    _show_server_info
    echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
    echo -e "  ${CYAN}1)${RESET}  Optimize Network & Mirrors"
    echo -e "  ${CYAN}2)${RESET}  Install 3X-UI ${GRAY}(Offline Mode)${RESET}"
    echo -e "  ${CYAN}3)${RESET}  Backhaul Premium Manager"
    echo -e "  ${CYAN}4)${RESET}  Folder Encryption Manager"
    echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
    echo -e "  ${RED}0)${RESET}  Exit"
    echo ""
    echo -ne "${CYAN}  Choose${RESET}${RED}${BLINK} ▸ ${RESET}"
    read choice
    echo -e "\033[1A\r${CYAN}  Choose${RESET}${GREEN} ▸ ${choice}${RESET}     "
    echo ""
    case $choice in
        1) optimize_network ;;
        2) install_3x_ui ;;
        3) backhaul_menu ;;
        4) encryption_menu ;;
        0)
            echo -e "${GREEN}  Goodbye! — Gray Wizard${RESET}\n"
            exit 0 ;;
        *)
            echo -e "${RED}  [!] Invalid option.${RESET}"
            sleep 1.5; main_menu ;;
    esac
}

main_menu
