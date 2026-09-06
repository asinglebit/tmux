#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

icon=$(get_tmux_option '@tmuxbar-session-icon' '')
format=$(get_tmux_option '@tmuxbar-session-format' '#S') # '#W' for the window name

echo "$icon $format"
