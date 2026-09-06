#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

ethernet_icon=$(get_tmux_option '@tmuxbar-network-ethernet-icon' '󰈀')
wifi_icon=$(get_tmux_option '@tmuxbar-network-wifi-icon' '')
offline_icon=$(get_tmux_option '@tmuxbar-network-offline-icon' '󰌙')

# Reachability probe: the first host to answer wins, so this is usually one ping.
probe_hosts='google.com github.com example.com'

# The Wi-Fi network name, falling back to a plain ethernet label when there is no
# SSID to report.
#
# On macOS 26 `networksetup -getairportnetwork` answers "You are not associated
# with an AirPort network" even with Wi-Fi up, because Apple gated SSID access
# behind entitlements. So this shows ethernet on current macOS. Left alone rather
# than reaching for a private API.
connection_label() {
    local ssid='' device
    case $(uname -s) in
    Linux)
        ssid=$(iwgetid -r 2>/dev/null)
        ;;
    Darwin)
        device=$(networksetup -listallhardwareports | awk '/Wi-Fi/ {getline; print $2; exit}')
        ssid=$(networksetup -getairportnetwork "$device" 2>/dev/null |
            awk -F': ' '/Current Wi-Fi/ {print $2}')
        ;;
    esac

    if [ -n "$ssid" ]; then
        echo "$wifi_icon $ssid"
    else
        echo "$ethernet_icon Eth"
    fi
}

for host in $probe_hosts; do
    if ping -q -c 1 -W 1 "$host" >/dev/null 2>&1; then
        connection_label
        exit 0
    fi
done

echo "$offline_icon Offline"
