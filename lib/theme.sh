#!/usr/bin/env bash
#
# Theme resolution and loading.
#
# A theme is a shell fragment assigning the nine role slots below. Slots are
# named by role rather than by lightness, so a light theme (dawnfox) works by
# assigning light values to $bg -- there is no special casing anywhere else.
#
#   bg          status bar and window list background
#   bg_dim      inactive pane background
#   surface     plugin background, pane borders
#   surface_hi  first/last plugin (the end caps) background
#   muted       inactive window name
#   dim         inactive pane foreground
#   fg          status foreground, plugin text
#   fg_hi       end cap text, active pane foreground
#   accent      prefix-active highlight background (its text uses $bg)
#
# Drop a file with those nine assignments into ~/.config/tmuxbar/themes/ and it
# shows up in the picker alongside the bundled ones.

tmuxbar_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmuxbar_user_themes="${XDG_CONFIG_HOME:-$HOME/.config}/tmuxbar/themes"
tmuxbar_theme_cache="${XDG_CACHE_HOME:-$HOME/.cache}/tmuxbar/theme"

# shellcheck source=lib/utils.sh
source "$tmuxbar_root/lib/utils.sh"

# Resolve a theme name to a file. User themes shadow bundled ones.
tmuxbar_theme_path() {
    local name="$1" candidate
    for candidate in "$tmuxbar_user_themes/$name.sh" "$tmuxbar_root/themes/$name.sh"; do
        if [ -r "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# Every available theme name, deduped and sorted.
tmuxbar_list_themes() {
    local dir file
    for dir in "$tmuxbar_user_themes" "$tmuxbar_root/themes"; do
        [ -d "$dir" ] || continue
        for file in "$dir"/*.sh; do
            [ -r "$file" ] || continue
            basename "$file" .sh
        done
    done | sort -u
}

# The theme that should be active: a live pick from the picker wins over the
# configured default, so switching survives a tmux server restart.
tmuxbar_active_theme() {
    local name=""
    if [ -r "$tmuxbar_theme_cache" ]; then
        name="$(tr -d '[:space:]' <"$tmuxbar_theme_cache")"
        if [ -n "$name" ] && tmuxbar_theme_path "$name" >/dev/null; then
            echo "$name"
            return
        fi
    fi
    get_tmux_option '@tmuxbar-theme' 'default'
}

# Source the active theme, falling back to default rather than rendering a
# broken bar. Sets $tmuxbar_theme_name to whatever actually got loaded.
tmuxbar_load_theme() {
    local name path
    name="$(tmuxbar_active_theme)"

    if ! path="$(tmuxbar_theme_path "$name")"; then
        tmux display-message "tmuxbar: unknown theme '$name', using default"
        name="default"
        path="$tmuxbar_root/themes/default.sh"
    fi

    # shellcheck source=/dev/null
    source "$path"
    tmuxbar_theme_name="$name"
}
