#!/usr/bin/env bash
#
# The colours an agent's status is drawn in.
#
# Taken from atrium's own theme.json, falling back to guitar's -- the same
# one-way fallback atrium itself does, and for the same reason: so that atrium's
# sidebar and this bar can never disagree about what red is.
#
# With neither installed the active tmuxbar theme's own slots stand in. They
# cannot tell error from needs-you, because the nine-slot contract has no red
# and no green; that is the honest cost of not having atrium's palette.
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

# Loads $status_error, $status_needs, $status_working and $status_idle.
# Expects a tmuxbar theme already in scope, for the fallbacks.
tmuxbar_load_atrium_colors() {
    local file value

    # Attention and not-attention, which is as far as nine slots stretch.
    status_error=${accent:-red}
    status_needs=${accent:-green}
    status_working=${fg:-white}
    status_idle=${muted:-grey}

    file=$(tmuxbar_atrium_theme_file) || return 0

    # A key that is missing keeps the fallback rather than blanking the colour.
    value=$(tmuxbar_atrium_color "$file" red) && [ -n "$value" ] && status_error=$value
    value=$(tmuxbar_atrium_color "$file" green) && [ -n "$value" ] && status_needs=$value
    value=$(tmuxbar_atrium_color "$file" amber) && [ -n "$value" ] && status_working=$value
    value=$(tmuxbar_atrium_color "$file" grey_400) && [ -n "$value" ] && status_idle=$value

    return 0
}
