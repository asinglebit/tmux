#!/usr/bin/env bash
#
# What the atriums on this server need, in one cell.
#
# The numbers come from the panes themselves: an atrium writes @atrium_status
# and @atrium_agents onto the pane it draws in, so nothing here has to find or
# talk to a running atrium.

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/theme.sh"
source "$current_dir/../lib/atrium.sh"

held_icon=$(get_tmux_option '@tmuxbar-atrium-icon' '󰚩')
needs_icon=$(get_tmux_option '@tmuxbar-atrium-needs-icon' '●')
error_icon=$(get_tmux_option '@tmuxbar-atrium-error-icon' '✗')
none_text=$(get_tmux_option '@tmuxbar-atrium-none-text' '-')

# The worse of two statuses, so the cell says the thing worth acting on -- in
# the order atrium ranks them itself.
worse_of() {
    local word
    for word in needs-input working error done idle; do
        case " $1 $2 " in *" $word "*)
            echo "$word"
            return
            ;;
        esac
    done
    echo ''
}

main() {
    local line status agents worst='' held=0 working=0 needs=0 error=0 style out

    tmuxbar_load_theme
    tmuxbar_load_atrium_colors

    # Deduplicated on the pane id: a window in two grouped sessions is listed
    # once per session, and its agents would otherwise be counted twice.
    while IFS='|' read -r _ status agents; do
        [ -n "$status" ] || continue
        # shellcheck disable=SC2086
        set -- $agents
        held=$((held + ${1:-0}))
        working=$((working + ${2:-0}))
        needs=$((needs + ${3:-0}))
        error=$((error + ${4:-0}))
        worst=$(worse_of "$worst" "$status")
    done < <(tmux list-panes -a -F '#{pane_id}|#{@atrium_status}|#{@atrium_agents}' 2>/dev/null | sort -u)

    if [ -z "$worst" ]; then
        echo "${held_icon:+$held_icon }$none_text"
        return
    fi

    # Orange while anything is waiting on you, the way the windows it sums up
    # are, and the segment's own colours otherwise. It never flickers: this
    # output is cached until the next status-interval, so whatever half of the
    # beat it printed would be the half it wore for the next minute.
    style=$(tmuxbar_atrium_style "$worst")

    out="${held_icon:+$held_icon }$held"
    [ "$needs" -gt 0 ] && out="$out  $needs_icon$needs"
    [ "$error" -gt 0 ] && out="$out  $error_icon$error"

    # A widget's output is not stripped of styles, so the cell styles itself --
    # and says nothing when it has nothing to say, since `#[default]` would take
    # the segment's background with it.
    if [ -n "$style" ]; then
        printf '#[%s]%s\n' "$style" "$out"
    else
        printf '%s\n' "$out"
    fi
}

main
