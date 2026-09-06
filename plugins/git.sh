#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

show_changes=$(get_tmux_option '@tmuxbar-git-show-changes' true)
added_icon=$(get_tmux_option '@tmuxbar-git-added-icon' '')
modified_icon=$(get_tmux_option '@tmuxbar-git-modified-icon' '')
updated_icon=$(get_tmux_option '@tmuxbar-git-updated-icon' '')
deleted_icon=$(get_tmux_option '@tmuxbar-git-deleted-icon' '')
repo_icon=$(get_tmux_option '@tmuxbar-git-repo-icon' '')
diff_icon=$(get_tmux_option '@tmuxbar-git-diff-icon' '')
no_repo_icon=$(get_tmux_option '@tmuxbar-git-no-repo-icon' '')

# Tally porcelain output by its two-character status field, so that ??, MM, AM
# and renames are all classified instead of being skipped or miscounted.
count_changes() {
    local line added=0 modified=0 deleted=0 updated=0 out=''

    while IFS= read -r line; do
        case "${line:0:2}" in
        *U* | AA | DD) updated=$((updated + 1)) ;;
        '??' | A*) added=$((added + 1)) ;;
        *D*) deleted=$((deleted + 1)) ;;
        *) modified=$((modified + 1)) ;;
        esac
    done

    [ "$added" -gt 0 ] && out+=" ${added} $added_icon"
    [ "$modified" -gt 0 ] && out+=" ${modified} $modified_icon"
    [ "$updated" -gt 0 ] && out+=" ${updated} $updated_icon"
    [ "$deleted" -gt 0 ] && out+=" ${deleted} $deleted_icon"

    printf '%s\n' "${out# }"
}

main() {
    local path branch changes
    path=$(pane_cwd)

    # One rev-parse decides both "is this a repo" and "which branch".
    branch=$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null) || {
        echo "$no_repo_icon"
        return
    }
    branch=${branch:0:20}

    changes=$(git -C "$path" status --porcelain 2>/dev/null | count_changes)

    if [ -z "$changes" ]; then
        echo "${repo_icon:+$repo_icon }$branch"
    elif [ "$show_changes" = true ]; then
        echo "${diff_icon:+$diff_icon }$changes $branch"
    else
        echo "${diff_icon:+$diff_icon }$branch"
    fi
}

main
