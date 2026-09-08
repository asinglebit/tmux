#!/usr/bin/env bash
#
# Push the active theme's background out to ghostty's own config.
#
# tmux paints the pane area itself, via window-style, so inside a full-screen
# session the terminal's background is nearly invisible -- nearly. What shows is
# the sub-cell remainder of the window size, which window-padding-balance sends
# to an edge, plus any padding, plus every ghostty window before tmux attaches.
# Left alone that reads as a mismatched strip down the side of the screen.
#
# Off unless @tmuxbar-ghostty is set: true to find ghostty's config in the usual
# places, or the path to it.
#
# Everything here must run under bash 3.2, like the rest of lib/.

# Path to the config to rewrite, or failure when the feature is off or no
# config is there to edit.
tmuxbar_ghostty_config() {
    local option candidate

    option="$(get_tmux_option '@tmuxbar-ghostty' false)"
    case "$option" in
    '' | false | off | 0)
        return 1
        ;;
    true | on | 1)
        # tmux hands option values over unexpanded, so a leading ~ is ours to
        # deal with.
        for candidate in \
            "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config" \
            "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.ghostty" \
            "$HOME/Library/Application Support/com.mitchellh.ghostty/config"; do
            if [ -f "$candidate" ]; then
                echo "$candidate"
                return 0
            fi
        done
        return 1
        ;;
    *)
        candidate="${option/#\~/$HOME}"
        [ -f "$candidate" ] || return 1
        echo "$candidate"
        ;;
    esac
}

# Rewrite the background line, or add one if the config has none.
#
# The write goes through a redirect rather than sed -i because this file is
# commonly a symlink out of a dotfiles repo, and sed -i renames over the path:
# the symlink would be replaced by a regular file. A redirect follows it, and
# leaves the inode and mode alone.
tmuxbar_ghostty_write_bg() {
    local config="$1" hex="$2" tmp

    # Nothing to do when the value already stands, in either hex spelling. This
    # is what keeps re-applying the same theme from touching a tracked file.
    grep -qE "^[[:space:]]*background[[:space:]]*=[[:space:]]*#?${hex}[[:space:]]*$" "$config" && return 0

    tmp="$(mktemp "${TMPDIR:-/tmp}/tmuxbar-ghostty.XXXXXX")" || return 1
    if grep -qE '^[[:space:]]*background[[:space:]]*=' "$config"; then
        # \1 is the assignment as the file already spells it, spacing included.
        # A commented-out line does not match the anchor, so it stays commented.
        sed -E "s|^([[:space:]]*background[[:space:]]*=[[:space:]]*).*|\1${hex}|" "$config" >"$tmp"
    else
        {
            cat "$config"
            printf 'background = %s\n' "$hex"
        } >"$tmp"
    fi
    cat "$tmp" >"$config"
    rm -f "$tmp"
}

# Repaint the terminals that are already running. Ghostty reloads its config
# only from a keybind -- there is no IPC and no signal for it -- so the config
# write alone would not be seen until the next window. OSC 11 sets the default
# background directly.
#
# The sequence goes to each client's tty, which is the pty ghostty owns, so it
# reaches ghostty without tmux's passthrough. It has to: run-shell, which is how
# the picker calls in, has no tty of its own to write to and its stdout becomes
# a tmux message rather than pane output.
tmuxbar_ghostty_osc11() {
    local color="$1" tty
    while IFS= read -r tty; do
        [ -n "$tty" ] || continue
        [ -w "$tty" ] || continue
        printf '\033]11;%s\007' "$color" >"$tty" 2>/dev/null || true
    done < <(tmux list-clients -F '#{client_tty}' 2>/dev/null || true)
}

# The one entry point. Expects a loaded theme, i.e. $bg in scope.
tmuxbar_sync_ghostty() {
    local config
    config="$(tmuxbar_ghostty_config)" || return 0
    # A config that could not be written is still worth repainting for.
    tmuxbar_ghostty_write_bg "$config" "${bg#\#}" || true
    tmuxbar_ghostty_osc11 "$bg"
}
