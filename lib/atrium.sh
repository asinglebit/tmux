#!/usr/bin/env bash
#
# The colours an agent's status is drawn in, and which of them pulse.
#
# They come from atrium's own theme.json, falling back to guitar's -- the same
# one-way fallback atrium itself does, and for the same reason: so that atrium's
# sidebar and this bar can never disagree about what red is.
#
# With neither installed the active tmuxbar theme's own slots stand in. The nine
# slots have no blue, green or orange, so a question and a failure both come out
# in accent, and the pulse is what still tells them apart.
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

# Loads $status_error, $status_needs, $status_working, $status_idle and the
# $status_dark every pulsing status drops to.
# Expects a tmuxbar theme already in scope, for the fallbacks.
tmuxbar_load_atrium_colors() {
    local file value

    # Attention and not-attention, which is as far as nine slots stretch.
    status_error=${accent:-red}
    status_needs=${accent:-blue}
    status_working=${fg:-orange}
    status_idle=${muted:-green}

    # The dark half of a pulse. Not a colour of atrium's, deliberately: it is
    # the tone an inactive window name already wears, so a window on the dark
    # beat reads as one of the list rather than as a fifth status.
    status_dark=${muted:-grey}

    file=$(tmuxbar_atrium_theme_file) || return 0

    # A key that is missing keeps the fallback rather than blanking the colour.
    value=$(tmuxbar_atrium_color "$file" red) && [ -n "$value" ] && status_error=$value
    value=$(tmuxbar_atrium_color "$file" blue) && [ -n "$value" ] && status_needs=$value
    value=$(tmuxbar_atrium_color "$file" orange) && [ -n "$value" ] && status_working=$value
    value=$(tmuxbar_atrium_color "$file" green) && [ -n "$value" ] && status_idle=$value

    return 0
}

# One status as a tmux style, on the lit half of its beat. The window list and
# the bar's own atrium cell both ask this rather than reaching for a colour, so
# the two cannot drift apart.
tmuxbar_atrium_style() {
    case $1 in
    error) printf 'fg=%s' "$status_error" ;;
    needs-input) printf 'fg=%s' "$status_needs" ;;
    working) printf 'fg=%s' "$status_working" ;;
    *) printf 'fg=%s' "$status_idle" ;;
    esac
}

# Whether a status pulses: the two that are still waiting do, one on you and one
# on the model. A finished agent and a failed one are settled, so the bar moves
# only where something is still going on.
#
# Nothing here can make it pulse. The terminal's own blink attribute is ignored
# by ghostty, and tmux repaints its status line only when asked, so the beat is
# kept by atrium -- see @atrium_blink in the README.
tmuxbar_atrium_pulses() {
    case $1 in
    needs-input | working) return 0 ;;
    *) return 1 ;;
    esac
}
