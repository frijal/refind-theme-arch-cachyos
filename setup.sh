#!/usr/bin/env bash
set -e

# Colors
GREEN="\e[32;1m"
RED="\e[31;1m"
YELLOW="\e[33;1m"
BLUE="\e[34;1m"
RESET="\e[0m"

# Ensure root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run with sudo or as root.${RESET}"
    exit 1
fi

# Theme settings
THEME="cachy"
THEMES_DIR="themes"

# Welcome
echo -e "${GREEN}Welcome to the ${THEME} theme manager for rEFInd.${RESET}"
echo -e "${RED}Warning! Root privileges are required.${RESET}"
echo ""

# Detect ESP
if [ -z "$ESP" ]; then
    if [ -d "/boot/efi/EFI" ]; then
        ESP="/boot/efi"
    elif [ -d "/boot/EFI" ]; then
        ESP="/boot"
    elif [ -d "/efi/EFI" ]; then
        ESP="/efi"
    else
        ESP="/boot/efi"
        echo -e "${YELLOW}Warning: Could not find ESP, falling back to /boot/efi${RESET}"
        echo -e "${YELLOW}Tip: run ESP=/path/to/esp $0 to override.${RESET}"
    fi
fi

# Install theme
function install_theme {
    local conf_path="$ESP/EFI/refind/refind.conf"
    local backup_path="$conf_path.bak"
    local theme_path="$ESP/EFI/refind/$THEMES_DIR/$THEME"
    local include_path="$THEMES_DIR/$THEME/$THEME.conf"

    if [ ! -f "$conf_path" ]; then
        echo -e "${RED}Error: $conf_path not found. Is rEFInd properly installed?${RESET}"
        exit 1
    fi

    for dir in banners icons; do
        if [ ! -d "$dir" ]; then
            echo -e "${RED}Missing directory: $dir${RESET}"
            exit 1
        fi
    done

    if [ ! -f "$THEME.conf" ]; then
        echo -e "${RED}Missing file: $THEME.conf${RESET}"
        exit 1
    fi

    if [ ! -f "$backup_path" ]; then
        cp "$conf_path" "$backup_path"
        echo -e "${BLUE}Backup created at ${backup_path}.${RESET}"
    fi

    if ! grep -Fxq "include $include_path" "$conf_path"; then
        echo "include $include_path" >> "$conf_path"
        echo -e "${BLUE}Include added to refind.conf.${RESET}"
    else
        echo -e "${YELLOW}Include already exists in refind.conf. Skipping.${RESET}"
    fi

    mkdir -p "$theme_path"
    cp -r banners/ icons/ "$THEME.conf" "$theme_path/"
    echo -e "${GREEN}Theme installed at $theme_path${RESET}"
    echo -e "${GREEN}Installation complete. Reboot to see the new rEFInd theme.${RESET}"
}

# Uninstall theme
function uninstall_theme {
    local conf_path="$ESP/EFI/refind/refind.conf"
    local backup_path="$conf_path.bak"
    local theme_path="$ESP/EFI/refind/$THEMES_DIR/$THEME"

    if [ -f "$backup_path" ]; then
        mv "$backup_path" "$conf_path"
        echo -e "${BLUE}refind.conf restored from backup.${RESET}"
    else
        echo -e "${YELLOW}No backup found. Skipping restore.${RESET}"
    fi

    rm -rf "$theme_path"
    echo -e "${GREEN}Theme uninstalled from $theme_path${RESET}"
}

# Show menu
echo -e "${BLUE}Choose an option:${RESET}"
echo "1) Install theme"
echo "2) Uninstall theme"
echo "3) Cancel"

read -rp $'\nSelect an option [1-3]: ' choice

case "$choice" in
    1)
        install_theme
        ;;
    2)
        uninstall_theme
        ;;
    3)
        echo -e "${YELLOW}Operation canceled by user.${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting.${RESET}"
        exit 1
        ;;
esac
