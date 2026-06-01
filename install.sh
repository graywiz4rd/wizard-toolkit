#!/bin/bash

# ================================================================
#   WIZARD TOOLKIT - Installer (GitHub Edition)
#   Crafted by @Gr4y_Wizard | https://t.me/Gray_wiz4rd
# ================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;38;5;51m'
BLUE='\033[0;38;5;39m'
WHITE='\033[1;97m'
GRAY='\033[0;38;5;245m'
BOLD='\033[1m'
RESET='\033[0m'

GITHUB_RAW="https://raw.githubusercontent.com/Graywiz4rd/wizard-toolkit/main"
GITHUB_USER="Graywiz4rd"
GITHUB_REPO="wizard-toolkit"
INSTALL_DIR="/root/wizardtoolkit"

# Auto-detect latest release tag
LATEST_TAG=$(curl -s "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
if [[ -z "$LATEST_TAG" ]]; then
    echo -e "${RED}  [!] Could not fetch latest release info from GitHub!${RESET}"
    exit 1
fi
GITHUB_RELEASE="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/download/${LATEST_TAG}"

# فایل‌های معمولی از main branch
GITHUB_FILES=(
    "wizard_toolkit.sh"
    "backhaul_premium"
    "backhaul.sh"
    "x-ui.sh"
    "scapy-2.7.0-py3-none-any.whl"
    "pip-26.1.1-py3-none-any.whl"
)

# فایل‌های بزرگ از Release
RELEASE_FILES=(
    "x-ui-linux-amd64.tar.gz"
)

divider() { echo -e "${GRAY}  ════════════════════════════════════════════════════${RESET}"; }

clear
echo ""
echo -e "${CYAN}${BOLD}"
echo -e "  ██╗    ██╗██╗███████╗ █████╗ ██████╗ ██████╗ "
echo -e "  ██║    ██║██║╚══███╔╝██╔══██╗██╔══██╗██╔══██╗"
echo -e "  ██║ █╗ ██║██║  ███╔╝ ███████║██████╔╝██║  ██║"
echo -e "  ██║███╗██║██║ ███╔╝  ██╔══██║██╔══██╗██║  ██║"
echo -e "  ╚███╔███╔╝██║███████╗██║  ██║██║  ██║██████╔╝"
echo -e "   ╚══╝╚══╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ${RESET}"
echo -e "${BOLD}${BLUE}          ── W I Z A R D   T O O L K I T ──${RESET}"
echo -e "${GRAY}  Crafted by ${WHITE}@Gr4y_Wizard${GRAY}  |  Telegram: ${CYAN}https://t.me/Gray_wiz4rd${RESET}"
echo ""
divider
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}  [!] Please run as root!${RESET}"
    exit 1
fi

if ! command -v curl &>/dev/null; then
    apt-get install -y curl > /dev/null 2>&1
fi

echo -e "${YELLOW}  [*] Preparing install directory...${RESET}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
echo -e "${GREEN}  [+] Directory: ${CYAN}$INSTALL_DIR${RESET}"
echo ""

# --- Download from GitHub ---
echo -e "${YELLOW}  [*] Downloading from GitHub...${RESET}"
echo ""
FAILED=0
for FILE in "${GITHUB_FILES[@]}"; do
    echo -ne "${GRAY}  ◆ ${RESET}${YELLOW}$FILE${RESET}  "
    HTTP_CODE=$(curl -s -o "$INSTALL_DIR/$FILE" -w "%{http_code}" "$GITHUB_RAW/$FILE")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "${GREEN}✔${RESET}"
    else
        echo -e "${RED}✘ (skipped)${RESET}"
        rm -f "$INSTALL_DIR/$FILE"
        ((FAILED++))
    fi
done

echo ""

# --- Download large files from GitHub Release ---
echo -e "${YELLOW}  [*] Downloading large files from GitHub Release...${RESET}"
echo ""
for FILE in "${RELEASE_FILES[@]}"; do
    echo -ne "${GRAY}  ◆ ${RESET}${YELLOW}$FILE${RESET}  "
    HTTP_CODE=$(curl -L -s -o "$INSTALL_DIR/$FILE" -w "%{http_code}" "$GITHUB_RELEASE/$FILE")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "${GREEN}✔${RESET}"
    else
        echo -e "${YELLOW}✘ (skipped)${RESET}"
        rm -f "$INSTALL_DIR/$FILE"
    fi
done

echo ""

# --- Set permissions ---
echo -e "${YELLOW}  [*] Setting permissions...${RESET}"
[[ -f "$INSTALL_DIR/wizard_toolkit.sh" ]] && chmod +x "$INSTALL_DIR/wizard_toolkit.sh"
[[ -f "$INSTALL_DIR/backhaul_premium" ]]  && chmod +x "$INSTALL_DIR/backhaul_premium"
[[ -f "$INSTALL_DIR/backhaul.sh" ]]       && chmod +x "$INSTALL_DIR/backhaul.sh"
[[ -f "$INSTALL_DIR/x-ui.sh" ]]           && chmod +x "$INSTALL_DIR/x-ui.sh"
echo -e "${GREEN}  [+] Permissions set.${RESET}"
echo ""

divider
echo -e "${BOLD}${GREEN}  [✔] Wizard Toolkit Ready!${RESET}"
divider
echo -e "${CYAN}  Location : ${YELLOW}$INSTALL_DIR${RESET}"
[[ $FAILED -gt 0 ]] && echo -e "${YELLOW}  [!] $FAILED file(s) not found on GitHub (skipped).${RESET}"
divider
echo ""

if [[ -f "$INSTALL_DIR/wizard_toolkit.sh" ]]; then
    echo -e "${YELLOW}  [*] Launching Wizard Toolkit...${RESET}"
    sleep 1
    cd "$INSTALL_DIR" && bash wizard_toolkit.sh
else
    echo -e "${RED}  [!] wizard_toolkit.sh not found. Cannot launch.${RESET}"
fi
