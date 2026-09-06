#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

icon=$(get_tmux_option '@tmuxbar-cwd-icon' '')
limit=$(get_tmux_option '@tmuxbar-cwd-limit' 20)

# Shorten a path to fit the bar: abbreviate every parent to two characters, then
# elide the middle if it is still deep. Short paths are left alone.
truncate_path() {
    local path=$1 short='' i last parts
    [ "${#path}" -le "$limit" ] && { printf '%s\n' "$path"; return; }

    IFS='/' read -r -a parts <<<"$path"
    last=$((${#parts[@]} - 1))
    for ((i = 0; i < last; i++)); do
        short+="${parts[$i]:0:2}/"
    done
    short+="${parts[$last]}"

    IFS='/' read -r -a parts <<<"$short"
    last=$((${#parts[@]} - 1))
    if [ "$last" -gt 4 ]; then
        printf '%s/%s/.../%s/%s\n' \
            "${parts[0]}" "${parts[1]}" "${parts[$((last - 1))]}" "${parts[$last]}"
    else
        printf '%s\n' "$short"
    fi
}

# tmux reports a pane's cwd as the kernel sees it, with every symlink already
# resolved, while $HOME keeps whatever spelling the login gave it. The two differ
# on image-based distributions -- /home is a symlink to /var/home on ostree
# systems, so $HOME is /home/user while the pane reports /var/home/user -- and a
# single substitution silently misses, leaving the bar showing an unabbreviated
# absolute path. Try both spellings.
home_relative() {
    local path=$1 home_real
    home_real=$(cd "$HOME" 2>/dev/null && pwd -P) || home_real=$HOME

    case $path in
    "$HOME") echo '~' ;;
    "$HOME"/*) echo "~${path#"$HOME"}" ;;
    "$home_real") echo '~' ;;
    "$home_real"/*) echo "~${path#"$home_real"}" ;;
    *) echo "$path" ;;
    esac
}

cwd=$(pane_cwd)
echo "$icon $(truncate_path "$(home_relative "$cwd")")"
