#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

ethernet_icon=$(get_tmux_option '@tmuxbar-network-ethernet-icon' '󰈀')
wifi_icon=$(get_tmux_option '@tmuxbar-network-wifi-icon' '')
offline_icon=$(get_tmux_option '@tmuxbar-network-offline-icon' '󰌙')

# Connectivity, without putting traffic on the wire on every refresh. This widget
# re-runs once per status-interval, and pinging google.com (then github.com, then
# example.com) each time cost a DNS lookup and an ICMP round trip per refresh --
# and blocked the status bar for up to three seconds whenever the link was
# actually down, which is exactly when it was least welcome.
#
# NetworkManager already runs its own periodic connectivity probe, so read the
# verdict it has cached rather than repeating the work. Failing that, ask whether
# there is a default route at all, which the kernel answers for free.
is_online() {
    local state
    if command -v nmcli >/dev/null 2>&1; then
        state=$(nmcli -t -f CONNECTIVITY general 2>/dev/null)
        case $state in
        # portal and limited both mean "on a network, just not the whole
        # internet" -- still a connection worth naming rather than Offline.
        full | portal | limited) return 0 ;;
        none) return 1 ;;
        esac
        # 'unknown' falls through to the route check below.
    fi

    case $(uname -s) in
    Linux) [ -n "$(ip route show default 2>/dev/null)" ] ;;
    Darwin) route -n get default >/dev/null 2>&1 ;;
    *) return 0 ;;
    esac
}

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
        # iwgetid ships in wireless-tools, which current distributions largely no
        # longer install -- Fedora and the image-based spins built on it do not,
        # so this branch used to report ethernet on a machine sitting on Wi-Fi.
        # `iw` is the kernel-native replacement and needs no privileges; nmcli
        # answers wherever NetworkManager owns the link. Both print nothing on a
        # wired machine, which is the ethernet fallback below.
        if command -v iw >/dev/null 2>&1; then
            ssid=$(iw dev 2>/dev/null | sed -n 's/^[[:space:]]*ssid //p' | head -n1)
        fi
        if [ -z "$ssid" ] && command -v nmcli >/dev/null 2>&1; then
            # -t escapes a colon inside an SSID as '\:', so unescape after
            # splitting on the delimiter.
            ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null |
                sed -n 's/^yes://p' | head -n1 | sed 's/\\:/:/g')
        fi
        if [ -z "$ssid" ] && command -v iwgetid >/dev/null 2>&1; then
            ssid=$(iwgetid -r 2>/dev/null)
        fi
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

if is_online; then
    connection_label
else
    echo "$offline_icon Offline"
fi
