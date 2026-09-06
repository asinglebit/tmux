#!/usr/bin/env bash

# free/vm_stat output is parsed below; pin the locale so the labels and number
# formatting stay predictable.
export LC_ALL=C

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

ram_percent() {
    local used total
    case $(uname -s) in
    Linux)
        free -m | awk '/^Mem/ {printf "%d%%\n", $3 * 100 / $2}'
        ;;
    Darwin)
        # vm_stat counts pages. Active + wired is the closest analogue to "used"
        # that excludes reclaimable cache.
        used=$(vm_stat | awk -v page="$(pagesize)" '
            /Pages active/ || /Pages wired down/ { gsub(/[^0-9]/, "", $NF); sum += $NF }
            END { print sum * page }')
        total=$(sysctl -n hw.memsize)
        echo "$((used * 100 / total))%"
        ;;
    esac
}

icon=$(get_tmux_option '@tmuxbar-ram-icon' '')
echo "$icon $(pad_center "$(ram_percent)")"
