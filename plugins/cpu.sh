#!/usr/bin/env bash

# top/ps/uptime output is parsed below, so pin the locale: it fixes both the
# decimal separator and the English column labels the patterns rely on.
export LC_ALL=C

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

cpu_percent() {
    local total cores
    case $(uname -s) in
    Linux)
        top -bn2 -d 0.01 | grep 'Cpu(s)' | tail -1 |
            sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1"%"}'
        ;;
    Darwin)
        total=$(ps -A -o %cpu | awk -F. '{s += $1} END {print s}')
        cores=$(sysctl -n hw.logicalcpu)
        echo "$((total / cores))%"
        ;;
    esac
}

# The three load averages, as an alternative to a single percentage.
cpu_load() {
    uptime | awk -F'load average[s]*:' '{print $2}' | sed 's/,//g;s/^ *//'
}

if [ "$(get_tmux_option '@tmuxbar-cpu-display-load' false)" = true ]; then
    cpu_load
else
    icon=$(get_tmux_option '@tmuxbar-cpu-icon' '')
    echo "$icon $(pad_center "$(cpu_percent)")"
fi
