#!/bin/bash
clear
# VMess Menu
casesssa() {
vmess_menu() {
    bash /usr/bin/menu-vmess.sh
}

# VLess Menu
vless_menu() {
    bash /usr/bin/menu-vless.sh
}

# Trojan Menu
trojan_menu() {
    bash /usr/bin/menu-trojan.sh
}
}
# Main Menu
main_menu() {
    while true; do
        echo "Main Menu"
        echo "1. VMess Management"
        echo "2. VLess Management"
        echo "3. Trojan Management"
        echo "4. Exit"
        read -p "Choose an option: " option

case $option in
01 | 1) clear ; vmess-menu ;;
02 | 2) clear ; vless-menu ;;
03 | 3) clear ; trojan-menu ;;
04 | 4) clear ; exit 0 ;;
        esac
    done
}

# Run the main menu
main_menu