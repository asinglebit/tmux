#!/usr/bin/env bash
#
# Helpers shared by tmuxbar.tmux and every widget in plugins/.
#
# Everything here must run under bash 3.2 -- that is what macOS ships, and on
# many machines it is the only bash. So: no associative arrays, no negative
# array indices, no $'\uXXXX' escapes.

# Read a tmux user option, falling back to a default when unset or empty. This
# is the only configuration mechanism tmuxbar has.
get_tmux_option() {
    local value
    value=$(tmux show-option -gqv "$1")
    echo "${value:-${2-}}"
}

# Centre a value in a fixed-width field so the bar does not jitter as numbers
# change width (7% -> 100%). Odd padding puts the extra space on the left.
pad_center() {
    local value=$1 width=${2:-4} pad left right
    pad=$((width - ${#value}))
    if [ "$pad" -le 0 ]; then
        printf '%s\n' "$value"
        return
    fi
    left=$(((pad + 1) / 2))
    right=$((pad / 2))
    printf '%*s%s%*s\n' "$left" '' "$value" "$right" ''
}

# Working directory of the pane the user is looking at. Widgets are run from
# tmux's #() so there is no useful inherited cwd to read.
pane_cwd() {
    tmux display-message -p '#{pane_current_path}'
}
