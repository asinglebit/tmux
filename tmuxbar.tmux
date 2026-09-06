#!/usr/bin/env bash
#
# tmuxbar -- a themed tmux status bar.
#
# This is a code generator, not a daemon. It runs once per apply and writes tmux
# format strings into status-left, status-right and the window-status formats.
# The widgets in plugins/ are then re-run by tmux itself every status-interval
# seconds, via the #(...) references embedded in those strings.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/theme.sh
source "$root/lib/theme.sh" # pulls in lib/utils.sh

refresh_rate=$(get_tmux_option '@tmuxbar-refresh-rate' 60)
show_powerline=$(get_tmux_option '@tmuxbar-show-powerline' true)
window_list_alignment=$(get_tmux_option '@tmuxbar-window-list-alignment' 'absolute-centre')
theme_key=$(get_tmux_option '@tmuxbar-theme-key' 'T')

# Powerline end caps, U+E0B0 and U+E0B2, spelled as UTF-8 bytes: bash 3.2 has
# no $'\uXXXX', and raw glyphs here would be invisible in most editors.
left_sep=$(get_tmux_option '@tmuxbar-left-sep' $'\xee\x82\xb0')
right_sep=$(get_tmux_option '@tmuxbar-right-sep' $'\xee\x82\xb2')

IFS=' ' read -r -a left_plugins <<<"$(get_tmux_option '@tmuxbar-left-plugins' 'session git cwd')"
IFS=' ' read -r -a right_plugins <<<"$(get_tmux_option '@tmuxbar-right-plugins' 'cpu ram battery network time')"

apply_theme() {
    tmuxbar_load_theme
    prefix_highlight=$(get_tmux_option '@tmuxbar-prefix-highlight-color' "$accent")
}

set_options() {
    tmux set-option -g status-interval "$refresh_rate"
    tmux set-option -g status-left-length 100
    tmux set-option -g status-right-length 100
    tmux set-option -g status-left ''
    tmux set-option -g status-right ''
    tmux set-option -g status-justify "$window_list_alignment"
    tmux set-option -g status-style "bg=${bg},fg=${fg}"
    tmux set-option -g message-style "bg=${bg},fg=${fg}"
    tmux set-option -g pane-border-style "bg=${bg},fg=${surface}"
    tmux set-option -g pane-active-border-style "bg=${bg},fg=${surface}"
    tmux set-option -g window-style "fg=${dim},bg=${bg_dim}"
    tmux set-option -g window-active-style "fg=${fg_hi},bg=${bg}"
    tmux set-window-option -g window-status-activity-style bold
    tmux set-window-option -g window-status-bell-style bold
    tmux set-window-option -g window-status-current-style bold
}

# One widget's cell: its colours, then the #() that tmux re-runs on each refresh.
segment() {
    local plugin=$1 seg_bg=$2 seg_fg=$3 body
    body="#[fg=${seg_fg},bg=${seg_bg}]"
    # The session name doubles as the prefix indicator: while the tmux prefix is
    # held, this one segment flips to the highlight colour.
    if [ "$plugin" = session ]; then
        body+="#{?client_prefix,#[fg=${bg}#,bg=${prefix_highlight}],}"
    fi
    printf '%s %s ' "$body" "#($root/plugins/$plugin.sh)"
}

# The glyph that hands a segment off to its neighbour: drawn in the segment's own
# background so it appears to taper into the neighbour's. Two segments that share
# a background need nothing between them.
separator() {
    local glyph=$1 from=$2 to=$3
    [ "$show_powerline" = true ] || return 0
    [ "$from" = "$to" ] && return 0
    printf '#[fg=%s,bg=%s]%s' "$from" "$to" "$glyph"
}

status_left() {
    local n=${#left_plugins[@]} i seg_bg seg_fg next_bg
    for ((i = 0; i < n; i++)); do
        # The outermost segment is the end cap; the rest share the surface colour.
        if [ "$i" -eq 0 ]; then
            seg_bg=$surface_hi seg_fg=$fg_hi
        else
            seg_bg=$surface seg_fg=$fg
        fi
        # Hand off to the next segment, or to the bar itself after the last one.
        if [ "$i" -eq $((n - 1)) ]; then
            next_bg=$bg
        else
            next_bg=$surface
        fi
        tmux set-option -ga status-left \
            "$(segment "${left_plugins[$i]}" "$seg_bg" "$seg_fg")$(separator "$left_sep" "$seg_bg" "$next_bg")"
    done
}

# Mirror of status_left: the end cap is the last segment, and each separator
# leads its segment rather than trailing it.
status_right() {
    local n=${#right_plugins[@]} i seg_bg seg_fg prev_bg
    for ((i = 0; i < n; i++)); do
        if [ "$i" -eq $((n - 1)) ]; then
            seg_bg=$surface_hi seg_fg=$fg_hi
        else
            seg_bg=$surface seg_fg=$fg
        fi
        if [ "$i" -eq 0 ]; then
            prev_bg=$bg
        else
            prev_bg=$surface
        fi
        tmux set-option -ga status-right \
            "$(separator "$right_sep" "$seg_bg" "$prev_bg")$(segment "${right_plugins[$i]}" "$seg_bg" "$seg_fg")"
    done
}

window_list() {
    tmux set-window-option -g window-status-current-format "#[fg=${fg},bg=${bg}] #I:#W "
    tmux set-window-option -g window-status-format "#[fg=${muted},bg=${bg}] #I:#W "
}

# Rebuilt on each apply so the active marker stays accurate and new files in
# ~/.config/tmuxbar/themes show up without a reload.
bind_theme_menu() {
    [ "$theme_key" = none ] && return 0

    # One hotkey per theme; 0 is held back for the reset entry below.
    local keys='123456789abcdefgijklmnopqrsuvwxyz'
    local menu=() i=0 name marker

    while IFS= read -r name; do
        [ -n "$name" ] || continue
        marker=''
        [ "$name" = "$tmuxbar_theme_name" ] && marker=' ●'
        menu+=("${name}${marker}" "${keys:$i:1}" "run-shell '$root/bin/tmuxbar-theme set $name'")
        i=$((i + 1))
    done < <(tmuxbar_list_themes)

    menu+=('') # horizontal rule
    menu+=('reset to config default' '0' "run-shell '$root/bin/tmuxbar-theme set -'")

    tmux bind-key "$theme_key" display-menu -T ' theme ' -x C -y C "${menu[@]}"
}

apply_theme
set_options
status_left
window_list
status_right
bind_theme_menu
