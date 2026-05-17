#!/bin/bash

# ================================================================
#   WIZARD TOOLKIT - Installer
#   Crafted by @Gr4y_Wizard
#   https://t.me/Gray_wiz4rd
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

REPO_USER="Graywiz4rd"
REPO_NAME="wizard-toolkit"
REPO_BRANCH="main"
REPO_URL="https://github.com/${REPO_USER}/${REPO_NAME}"
RAW_URL="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${REPO_BRANCH}"
INSTALL_DIR="/root/wizardtoolkit"

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
echo -e "${GRAY}              Crafted by ${WHITE}@Gr4y_Wizard${RESET}"
echo -e "${GRAY}          Telegram: ${CYAN}https://t.me/Gray_wiz4rd${RESET}"
echo ""
echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
echo ""

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}  [!] Please run as root: sudo bash install.sh${RESET}"
    exit 1
fi

# --- Check dependencies ---
echo -e "${YELLOW}  [*] Checking dependencies...${RESET}"

if ! command -v curl &>/dev/null; then
    echo -e "${YELLOW}  [!] curl not found. Installing...${RESET}"
    apt-get update -qq && apt-get install -y curl > /dev/null 2>&1
fi

if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}  [!] git not found. Installing...${RESET}"
    apt-get install -y git > /dev/null 2>&1
fi

echo -e "${GREEN}  [+] Dependencies ready.${RESET}"
echo ""

# --- Download repo ---
echo -e "${YELLOW}  [*] Downloading Wizard Toolkit from GitHub...${RESET}"

if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}  [!] Existing installation found. Updating...${RESET}"
    rm -rf "$INSTALL_DIR"
fi

git clone --depth=1 "${REPO_URL}.git" "$INSTALL_DIR" 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo -e "${RED}  [!] Download failed!${RESET}"
    echo -e "${YELLOW}  [i] Check your internet connection and try again.${RESET}"
    exit 1
fi

echo -e "${GREEN}  [+] Downloaded successfully.${RESET}"
echo ""

# --- Set permissions ---
echo -e "${YELLOW}  [*] Setting permissions...${RESET}"

chmod +x "$INSTALL_DIR/wizard_toolkit.sh"

# Set executable on any binary files
for f in backhaul_premium backhaul.sh x-ui.sh; do
    [[ -f "$INSTALL_DIR/$f" ]] && chmod +x "$INSTALL_DIR/$f"
done

echo -e "${GREEN}  [+] Permissions set.${RESET}"
echo ""

# --- Summary ---
echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}${GREEN}  [✔] Wizard Toolkit installed successfully!${RESET}"
echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
echo -e "${CYAN}  Location : ${WHITE}$INSTALL_DIR${RESET}"
echo -e "${GRAY}  ────────────────────────────────────────────────────${RESET}"
echo ""

# --- Auto launch ---
echo -e "${YELLOW}  [*] Launching Wizard Toolkit...${RESET}"
sleep 1

cd "$INSTALL_DIR" && bash wizard_toolkit.sh
