#!/bin/bash

# Function to clean up logs and temporary files
auto_cleaner() {
    echo "Running auto cleaner..."
    journalctl --vacuum-time=1d
    rm -f /etc/xray/temp.json
    echo "Auto cleaning completed."
}

# Monitor Connections and Apply Limits
monitor_connections() {
    while true; do
        # Monitor VMess connections
        vmess_users=$(cat /etc/xray/users/vmess_users.txt)
        for user in $vmess_users; do
            uuid=$(echo $user | awk '{print $1}')
            max_ips=$(echo $user | awk '{print $2}')
            quota=$(echo $user | awk '{print $3}')
            remarks=$(echo $user | awk '{print $4}')
            expiration_date=$(echo $user | awk '{print $5}')

            # Check expiration date
            current_date=$(date +%Y-%m-%d)
            if [[ "$current_date" > "$expiration_date" ]]; then
                echo "Deleting expired VMess user $uuid"
                jq --arg uuid "$uuid" 'del(.inbounds[3].settings.clients[] | select(.id == $uuid))' /etc/xray/config.json > temp.json && mv temp.json /etc/xray/config.json
                sed -i "/$uuid/d" /etc/xray/users/vmess_users.txt
                systemctl restart xray
                continue
            fi

            # Get connected IPs for VMess
            connected_ips=$(journalctl -u xray | grep "inboundTag:vmess_in" | grep "$uuid" | awk '{print $10}' | cut -d'=' -f2 | sort | uniq)
            ip_count=$(echo "$connected_ips" | wc -l)

            if [ "$ip_count" -gt "$max_ips" ]; then
                echo "Locking VMess user $uuid due to exceeding IP limit ($ip_count > $max_ips)"
                jq --arg uuid "$uuid" 'del(.inbounds[3].settings.clients[] | select(.id == $uuid))' /etc/xray/config.json > temp.json && mv temp.json /etc/xray/config.json
                systemctl restart xray
            fi
        done

        # Monitor VLess connections
        vless_users=$(cat /etc/xray/users/vless_users.txt)
        for user in $vless_users; do
            uuid=$(echo $user | awk '{print $1}')
            max_ips=$(echo $user | awk '{print $2}')
            quota=$(echo $user | awk '{print $3}')
            remarks=$(echo $user | awk '{print $4}')
            expiration_date=$(echo $user | awk '{print $5}')

            # Check expiration date
            current_date=$(date +%Y-%m-%d)
            if [[ "$current_date" > "$expiration_date" ]]; then
                echo "Deleting expired VLess user $uuid"
                jq --arg uuid "$uuid" 'del(.inbounds[0].settings.clients[] | select(.id == $uuid))' /etc/xray/config.json > temp.json && mv temp.json /etc/xray/config.json
                sed -i "/$uuid/d" /etc/xray/users/vless_users.txt
                systemctl restart xray
                continue
            fi

            # Get connected IPs for VLess
            connected_ips=$(journalctl -u xray | grep "inboundTag:vless_in" | grep "$uuid" | awk '{print $10}' | cut -d'=' -f2 | sort | uniq)
            ip_count=$(echo "$connected_ips" | wc -l)

            if [ "$ip_count" -gt "$max_ips" ]; then
                echo "Locking VLess user $uuid due to exceeding IP limit ($ip_count > $max_ips)"
                jq --arg uuid "$uuid" 'del(.inbounds[0].settings.clients[] | select(.id == $uuid))' /etc/xray/config.json > temp.json && mv temp.json /etc/xray/config.json
                systemctl restart xray
            fi
        done

        # Monitor Trojan connections
        trojan_users=$(cat /etc/xray/users/trojan_users.txt)
        for user in $trojan_users; do
            password=$(echo $user | awk '{print $1}')
            max_ips=$(echo $user | awk '{print $2}')
            quota=$(echo $user | awk '{print $3}')
            remarks=$(echo $user | awk '{print $4}')
            expiration_date=$(echo $user | awk '{print $5}')

            # Check expiration date
            current_date=$(date +%Y-%m-%d)
            if [[ "$current_date" > "$expiration_date" ]]; then
                echo "Deleting expired Trojan user $password"
                jq --arg password "$password" 'del(.inbounds[2].settings.clients[] | select(.password == $password))' /etc/xray/config.json > temp.json && mv temp.json /etc/xray/config.json
                sed -i "/$password/d" /etc/xray/users/trojan_users.txt
                systemctl restart xray
                continue
            fi

            # Get connected IPs for Trojan
            connected_ips=$(journalctl -u xray | grep "inboundTag:trojan_in" | grep "$password" | awk '{print $10}' | cut -d'=' -f2 | sort | uniq)
            ip_count=$(echo "$connected_ips" | wc -l)

            if [ "$ip_count" -gt "$max_ips" ]; then
                echo "Locking Trojan user $password due to exceeding IP limit ($ip_count > $max_ips)"
                jq --arg password "$password" 'del(.inbounds[2].settings.clients[] | select(.password == $password))' /etc/xray/config.json > temp.json && mv temp.json /etc/xray/config.json
                systemctl restart xray
            fi
        done

        # Run auto cleaner every 24 hours
        current_hour=$(date +%H)
        if [ "$current_hour" -eq "0" ]; then
            auto_cleaner
        fi

        sleep 60
    done
}

# Run monitoring
monitor_connections