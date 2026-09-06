#!/usr/bin/env bash

# pmset/acpi output is parsed below; pin the locale so the status words match.
export LC_ALL=C

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

charging_icon=$(get_tmux_option '@tmuxbar-battery-charging-icon' '')
low_icon=$(get_tmux_option '@tmuxbar-battery-low-icon' '󱉝')
tier_0=$(get_tmux_option '@tmuxbar-battery-percentage-0' '')
tier_1=$(get_tmux_option '@tmuxbar-battery-percentage-1' '')
tier_2=$(get_tmux_option '@tmuxbar-battery-percentage-2' '')
tier_3=$(get_tmux_option '@tmuxbar-battery-percentage-3' '')
tier_4=$(get_tmux_option '@tmuxbar-battery-percentage-4' '')

# acpi where available, otherwise the same sysfs files acpi itself reads.
linux_battery() {
    local bat
    if command -v acpi >/dev/null; then
        case $1 in
        status) acpi | cut -d: -f2- | cut -d, -f1 | tr -d ' ' ;;
        percent) acpi | cut -d: -f2- | cut -d, -f2 | tr -d '% ' ;;
        esac
        return
    fi
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] || continue
        case $1 in
        status) cat "$bat/status" ;;
        percent) cat "$bat/capacity" ;;
        esac
        return
    done
}

battery_percent() {
    case $(uname -s) in
    Linux) linux_battery percent ;;
    Darwin) pmset -g batt | grep -Eo '[0-9]+%' | tr -d '%' ;;
    esac
}

# Charging gets its own glyph; every other state is already conveyed by the tier
# glyph, so it contributes nothing.
charging_marker() {
    local status
    case $(uname -s) in
    Linux) status=$(linux_battery status) ;;
    Darwin) status=$(pmset -g batt | sed -n 2p | cut -d';' -f2 | tr -d ' ') ;;
    esac

    case $status in
    charging | Charging) echo "$charging_icon" ;;
    esac
}

# Thresholds are the originals: >90, >75, >50, >25, >10, then low.
battery_tier() {
    if [ "$1" -gt 90 ]; then
        echo "$tier_4"
    elif [ "$1" -gt 75 ]; then
        echo "$tier_3"
    elif [ "$1" -gt 50 ]; then
        echo "$tier_2"
    elif [ "$1" -gt 25 ]; then
        echo "$tier_1"
    elif [ "$1" -gt 10 ]; then
        echo "$tier_0"
    else
        echo "$low_icon"
    fi
}

percent=$(battery_percent)
# Desktops report nothing; render an empty segment rather than a bogus 0%.
[ -n "$percent" ] || exit 0

marker=$(charging_marker)
echo "${marker:+$marker }$(battery_tier "$percent") ${percent}%"
