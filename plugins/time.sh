#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

icon=$(get_tmux_option '@tmuxbar-time-icon' '')
format=$(get_tmux_option '@tmuxbar-time-format' '%a %I:%M %p')

# No LC_ALL here: the day name should follow the user's locale.
date +"$icon $format"
