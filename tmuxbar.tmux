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
# shellcheck source=lib/atrium.sh
source "$root/lib/atrium.sh"

refresh_rate=$(get_tmux_option '@tmuxbar-refresh-rate' 60)
show_powerline=$(get_tmux_option '@tmuxbar-show-powerline' true)
window_list_alignment=$(get_tmux_option '@tmuxbar-window-list-alignment' 'absolute-centre')
menu_border_lines=$(get_tmux_option '@tmuxbar-menu-border-lines' 'rounded')
theme_key=$(get_tmux_option '@tmuxbar-theme-key' 'T')
workspace_key=$(get_tmux_option '@tmuxbar-workspace-key' 'w')

# Powerline end caps, U+E0B0 and U+E0B2, spelled as UTF-8 bytes: bash 3.2 has
# no $'\uXXXX', and raw glyphs here would be invisible in most editors.
left_sep=$(get_tmux_option '@tmuxbar-left-sep' $'\xee\x82\xb0')
right_sep=$(get_tmux_option '@tmuxbar-right-sep' $'\xee\x82\xb2')

IFS=' ' read -r -a left_plugins <<<"$(get_tmux_option '@tmuxbar-left-plugins' 'session git cwd')"
IFS=' ' read -r -a right_plugins <<<"$(get_tmux_option '@tmuxbar-right-plugins' 'cpu ram battery network time')"

apply_theme() {
    tmuxbar_load_theme
    tmuxbar_load_atrium_colors
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
    # Active and inactive panes carry the same colours, borders included, so the
    # cursor is the only cue for which pane is active.
    tmux set-option -g window-style "fg=${fg_hi},bg=${bg}"
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

# One status as the window wears it. A settled status is one colour; a pulsing
# one is two, chosen by the beat atrium is keeping in `@atrium_blink`.
#
# The test is for an explicit `0` rather than for truth, so everything else --
# `1`, and an option never set at all because no atrium is running or one was
# killed before it could stop the beat -- leaves the window lit. A window that
# has stopped pulsing still says blue; one stuck on the dark half would just
# look broken.
atrium_style() {
    local status=$1
    if tmuxbar_atrium_pulses "$status"; then
        printf '#{?#{==:#{@atrium_blink},0},#[fg=%s],#[%s]}' "$status_dark" "$(tmuxbar_atrium_style "$status")"
    else
        printf '#[%s]' "$(tmuxbar_atrium_style "$status")"
    fi
}

# A window is coloured by the worst thing the atriums in it need, and pulses
# while that thing is still waiting.
#
# `#{P:...}` walks the panes of the window being drawn and reads the option each
# atrium writes onto its own pane, so the whole rollup is a format string that
# tmux evaluates as it paints. Nothing polls, nothing aggregates, and a window
# with no atrium in it matches none of the patterns and keeps its usual colour.
#
# The patterns are tried worst first, so a window holding one agent that failed
# and one that finished says the failure. `idle` is matched rather than left to
# the fallback, because a finished agent is something to say -- green -- and not
# merely the absence of anything to say.
atrium_fg() {
    local fallback=$1 rollup='#{P:#{@atrium_status}}'
    printf '#{?#{m:*error*,%s},%s,#{?#{m:*needs-input*,%s},%s,#{?#{m:*working*,%s},%s,#{?#{m:*idle*,%s},%s,#[fg=%s]}}}}' \
        "$rollup" "$(atrium_style error)" \
        "$rollup" "$(atrium_style needs-input)" \
        "$rollup" "$(atrium_style working)" \
        "$rollup" "$(atrium_style idle)" \
        "$fallback"
}

window_list() {
    tmux set-window-option -g window-status-current-format "#[bg=${bg}]$(atrium_fg "$fg") #I:#W "
    tmux set-window-option -g window-status-format "#[bg=${bg}]$(atrium_fg "$muted") #I:#W "
}

# Both pickers are tmux menus, so painting them is painting every menu the server
# draws. A menu floats over a pane, so it takes the pane's own background and a
# rounded frame, the way atrium draws a modal.
#
# The title rides in the border and is painted in the border's colour, so that
# has to be a colour text stays readable in: surface is a pane-border tone, dark
# enough in some themes that ' theme ' would vanish into the frame it sits in.
menu_options() {
    # tmux learned these in 3.4; an older one keeps its own plain menu rather
    # than answering every apply with four unknown-option errors.
    tmux show-options -gv menu-border-lines >/dev/null 2>&1 || return 0

    tmux set-option -g menu-style "bg=${bg},fg=${fg}"
    tmux set-option -g menu-selected-style "bg=${surface},fg=${fg_hi}"
    tmux set-option -g menu-border-style "bg=${bg},fg=${muted}"
    tmux set-option -g menu-border-lines "$menu_border_lines"
}

# The menu itself is built by bin/tmuxbar-theme on open, so the active marker
# stays accurate, new files in ~/.config/tmuxbar/themes show up without a
# reload, and the list can be sliced to what the client is tall enough to show.
bind_theme_menu() {
    [ "$theme_key" = none ] && return 0
    tmux bind-key "$theme_key" run-shell "$root/bin/tmuxbar-theme menu"
}

# The menu is built on open for the same reason the theme menu is: whether a
# workspace has a window is only knowable then.
bind_workspace_menu() {
    [ "$workspace_key" = none ] && return 0
    tmux bind-key "$workspace_key" run-shell "$root/bin/workspace menu"
}

apply_theme
set_options
status_left
window_list
status_right
menu_options
bind_theme_menu
bind_workspace_menu
