#!/usr/bin/env bash
#
# The colours an agent's status is drawn in.
#
# They come from atrium's own theme.json, falling back to guitar's -- the same
# one-way fallback atrium itself does, and for the same reason: so that atrium's
# sidebar and this bar can never disagree about what orange is.
#
# The greys are not atrium's. A window with nothing to say keeps the grey the
# theme already gives it, and one that is working flickers between that grey
# and one a shade lighter, so a busy window still reads as part of the list.
#
# With neither theme.json installed the active tmuxbar theme's own slots stand
# in. The nine slots have no orange, red or green, so a question and a failure
# both come out in accent, and a finished turn in the brightest text there is.
#
# Everything here must run under bash 3.2, like the rest of lib/.

# atrium's theme, else guitar's, else nothing.
tmuxbar_atrium_theme_file() {
    local config="${XDG_CONFIG_HOME:-$HOME/.config}" candidate
    for candidate in "$config/atrium/theme.json" "$config/guitar/theme.json"; do
        if [ -r "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# One entry out of the theme's `colors` table. jq where it is installed, and a
# sed that leans on the file being written one key to a line where it is not.
tmuxbar_atrium_color() {
    local file=$1 key=$2
    if command -v jq >/dev/null 2>&1; then
        jq -r --arg key "$key" '.colors[$key] // empty' "$file" 2>/dev/null
        return
    fi
    sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n1
}

# Loads $status_needs, $status_error and $status_done: a question, a failed turn
# and a finished one. Expects a tmuxbar theme already in scope, for the
# fallbacks.
tmuxbar_load_atrium_colors() {
    local file value

    status_needs=${accent:-orange}
    status_error=${accent:-red}
    status_done=${fg_hi:-green}

    file=$(tmuxbar_atrium_theme_file) || return 0

    # A key that is missing keeps the fallback rather than blanking the colour.
    value=$(tmuxbar_atrium_color "$file" orange) && [ -n "$value" ] && status_needs=$value
    value=$(tmuxbar_atrium_color "$file" red) && [ -n "$value" ] && status_error=$value
    value=$(tmuxbar_atrium_color "$file" green) && [ -n "$value" ] && status_done=$value

    return 0
}

# Halfway between two colours: the lit half of a working window's flicker,
# between the grey it wears and the next grey up. Only hex can be mixed, so a
# theme of colourN or default gets the second colour -- the brighter of the two
# asked for -- which still flickers, only further.
tmuxbar_mix() {
    local from=$1 to=$2 hex='^#[0-9a-fA-F]{6}$'
    if ! [[ $from =~ $hex && $to =~ $hex ]]; then
        printf '%s' "$to"
        return
    fi
    printf '#%02x%02x%02x' \
        $(((16#${from:1:2} + 16#${to:1:2}) / 2)) \
        $(((16#${from:3:2} + 16#${to:3:2}) / 2)) \
        $(((16#${from:5:2} + 16#${to:5:2}) / 2))
}

# The bar's own atrium cell, as a tmux style: orange while anything is waiting
# on you, and nothing of its own otherwise. The cell sums up every window, so it
# cannot know which endings have been seen -- saying green there would outlast
# the green on the windows it sums up.
tmuxbar_atrium_style() {
    case $1 in
    needs-input) printf 'fg=%s' "$status_needs" ;;
    esac
}
