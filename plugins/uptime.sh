#!/usr/bin/env bash

# uptime's prose is parsed below; pin the locale so the wording stays English.
export LC_ALL=C

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

icon=$(get_tmux_option '@tmuxbar-uptime-icon' '󱎫')

# The wording varies -- "up 38 days,  4:12", "up  1:23", "up 7 mins" -- so read
# the day count and the H:M pair relative to the word "up" rather than by field
# position. Stopping at "up" also avoids mistaking the leading clock time for it.
uptime | awk -v icon="$icon" '
{
    for (i = 1; i <= NF; i++) {
        if ($i != "up") continue
        if ($(i + 1) ~ /^[0-9]+$/ && $(i + 2) ~ /^day/) { d = $(i + 1); i += 2 }
        if ($(i + 1) ~ /^[0-9]+:[0-9]+/) { split($(i + 1), t, ":"); h = t[1]; m = t[2] }
        else if ($(i + 1) ~ /^[0-9]+$/ && $(i + 2) ~ /^min/) m = $(i + 1)
        break
    }
    gsub(/,/, "", m)
    printf "%s %s%s%s\n", icon, (d ? d "D " : ""), (h ? h "H " : ""), (m ? m "M" : "")
}'
