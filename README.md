# tmuxbar

A themed tmux status bar: a row of small widget scripts on each side, a centred
window list, and thirty-two built-in colour schemes with a `prefix + T` picker.

Based on [tmux2k](https://github.com/2KAbhishek/tmux2k) — my configs started
there, and the per-widget script layout and `@`-option style of configuration
still follow it.

## Install

With [tpm](https://github.com/tmux-plugins/tpm), in `~/.tmux.conf`:

```tmux
set -g @plugin 'asinglebit/tmux'
set -g @tmuxbar-theme 'nordfox'
set -g @tmuxbar-left-plugins "session git cwd"
set -g @tmuxbar-right-plugins "cpu ram battery network time"
```

Requires bash — 3.2 is enough, which is what macOS ships.

## Bar options

| Option | Default | Meaning |
| --- | --- | --- |
| `@tmuxbar-theme` | `default` | Bundled or user theme name |
| `@tmuxbar-theme-key` | `T` | `prefix + <key>` opens the picker; `none` disables it |
| `@tmuxbar-ghostty` | `false` | Sync the theme's background into ghostty; `true` finds its config, or give a path |
| `@tmuxbar-left-plugins` | `session git cwd` | Widgets, left to right |
| `@tmuxbar-right-plugins` | `cpu ram battery network time` | Widgets, left to right |
| `@tmuxbar-refresh-rate` | `60` | Seconds between widget re-runs (`status-interval`) |
| `@tmuxbar-show-powerline` | `true` | Draw the end-cap glyphs |
| `@tmuxbar-left-sep` | `` | Left-side separator glyph |
| `@tmuxbar-right-sep` | `` | Right-side separator glyph |
| `@tmuxbar-window-list-alignment` | `absolute-centre` | Passed to `status-justify` |
| `@tmuxbar-prefix-highlight-color` | theme `accent` | Session segment colour while the prefix is held |
| `@tmuxbar-workspace-key` | `w` | `prefix + <key>` opens the workspace menu; `none` disables it |

## Widgets

Anything in `plugins/` can be named in a plugin list. Each is a standalone script
that prints one line; tmux re-runs it every `@tmuxbar-refresh-rate` seconds.

| Widget | Shows | Options |
| --- | --- | --- |
| `session` | Session name | `-session-icon`, `-session-format` (`#S`, or `#W` for the window) |
| `cwd` | Active pane's directory, shortened | `-cwd-icon`, `-cwd-limit` (`20`) |
| `git` | Branch and working-tree counts | `-git-show-changes` (`true`), `-git-{added,modified,updated,deleted,repo,diff,no-repo}-icon` |
| `time` | Clock, in your locale | `-time-icon`, `-time-format` (`%a %I:%M %p`) |
| `cpu` | CPU percentage, or load average | `-cpu-icon`, `-cpu-display-load` (`false`) |
| `ram` | Memory percentage | `-ram-icon` |
| `battery` | Level glyph and percentage | `-battery-charging-icon`, `-battery-low-icon`, `-battery-percentage-0`…`-4` |
| `network` | SSID, `Eth`, or `Offline` | `-network-{ethernet,wifi,offline}-icon` |
| `uptime` | Days / hours / minutes | `-uptime-icon` |
| `atrium` | Agents held across the server, and how many want you | `-atrium-icon`, `-atrium-{needs,error}-icon`, `-atrium-none-text` (`-`) |

All option names take the `@tmuxbar-` prefix, e.g. `set -g @tmuxbar-cpu-icon ''`.

Two platform notes: `battery` prints nothing on a machine without one, and on
macOS 26 `network` always reports `Eth` because Apple gated SSID lookup behind
entitlements that `networksetup` no longer has.

### Adding one

Drop an executable script in `plugins/<name>.sh` that echoes a single line, then
add `<name>` to a plugin list. Source `lib/utils.sh` for `get_tmux_option`,
`pad_center`, and `pane_cwd`.

## Themes

`prefix + T` opens a menu of every available theme and applies it instantly. The
pick is remembered in `~/.cache/tmuxbar/theme`, so it survives a tmux restart and
takes precedence over `@tmuxbar-theme` until you choose *reset to config default*.
tmux silently refuses a menu taller than the window, so the list is cut to fit and
carries on behind a *more...* entry.

Each bundled theme lifts its nine colours from the matching Neovim colourscheme's
own palette, so an editor and its status bar can be moved between themes by name.

With `@tmuxbar-ghostty` set, a switch also writes the theme's `bg` to ghostty's
`background`. tmux paints the pane area itself, so what this fixes is the parts
it does not cover: the sub-cell remainder of the window size, the padding, and a
window that has not attached yet. Terminals already open are repainted with
OSC 11, since ghostty reloads its config only from a keybind.

| Family | Themes |
| --- | --- |
| — | `default`, `onedark` |
| Catppuccin | `catppuccin-mocha`, `catppuccin-macchiato`, `catppuccin-frappe`, `catppuccin-latte` (light) |
| Tokyo Night | `tokyonight-night`, `tokyonight-storm`, `tokyonight-moon`, `tokyonight-day` (light) |
| Rose Pine | `rose-pine`, `rose-pine-moon`, `rose-pine-dawn` (light) |
| Nightfox | `nightfox`, `duskfox`, `nordfox`, `terafox`, `carbonfox`, `dayfox` (light), `dawnfox` (light) |
| Kanagawa | `kanagawa-wave`, `kanagawa-dragon`, `kanagawa-lotus` (light) |
| Gruvbox | `gruvbox-dark`, `gruvbox-light` (light) |
| Everforest | `everforest-dark`, `everforest-light` (light) |
| Dracula | `dracula`, `dracula-soft` |
| Oxocarbon | `oxocarbon-dark`, `oxocarbon-light` (light) |
| Nord | `nord` |

There is also a CLI, which the key binding and the menu entries call:

```bash
bin/tmuxbar-theme list
bin/tmuxbar-theme current
bin/tmuxbar-theme set rose-pine
bin/tmuxbar-theme set -          # back to @tmuxbar-theme
bin/tmuxbar-theme menu           # what prefix + T runs
```

### Writing a theme

A theme is a shell fragment assigning nine colours. Slots are named by role rather
than by lightness, so a light theme just assigns light values to `bg`.

| Slot | Used for |
| --- | --- |
| `bg` | Status bar and window list background, pane and pane border background |
| `bg_dim` | Reserved |
| `surface` | Widget background, pane border lines |
| `surface_hi` | First and last widget (the end caps) background |
| `muted` | Inactive window name |
| `dim` | Reserved |
| `fg` | Status foreground, widget text, active window name |
| `fg_hi` | End cap text, pane foreground |
| `accent` | Prefix-active highlight background (its text uses `bg`) |

`bg_dim` and `dim` are reserved: nothing reads them today. Every theme still
assigns them, and a new theme should too, so the set stays complete if a use
turns up.

Drop a file into `~/.config/tmuxbar/themes/<name>.sh` and it appears in the picker
next to the bundled ones, shadowing a bundled theme of the same name.

```bash
bg='#2e3440'
bg_dim='#232831'
surface='#3e4a5b'
surface_hi='#4f6074'
muted='#60728a'
dim='#7e8188'
fg='#abb1bb'
fg_hi='#cdcecf'
accent='#81a1c1'
```

## Workspaces

A **workspace** is a git worktree, the tmux window laid out for it, and whatever
is running in that window's panes. Nothing here keeps a list: git says which
worktrees exist and tmux says which of them have a window, so the two can never
drift from the machine.

```
prefix + w              pick a workspace; a dot marks the ones already up
bin/workspace list      every worktree, its branch, and up or down
bin/workspace up PATH   build the window from the project's plan
bin/workspace down PATH kill it
```

A window is bound to its worktree by a `@workspace` window option, set when the
window is built. Lookups are server-wide (`list-windows -a`) rather than
per-session, because grouped sessions share their windows.

### Plans

`~/.config/tmuxbar/workspaces/<project>.plan` says how to lay a project's
windows out. Worktrees inherit their main checkout's plan, so `customer-portal`
and `customer-portal-test` are laid out the same way. With no file, you get
atrium over a working shell.

One line per pane, in creation order:

```
# from split size cwd           delay  command
-     -     -     .             0      a
1     v     40%   .             gate   pnpm reset && pnpm i
1     h     50%   packages/api  +15    pnpm watch
```

| Field | Meaning |
| --- | --- |
| `from` | Which pane to split, 1-based in creation order; `-` opens the window |
| `split` | `h` or `v`; `-` for the window's own pane |
| `size` | What the **new** pane takes, e.g. `40%`; `-` lets tmux decide |
| `cwd` | Relative to the worktree root; `.` for its root |
| `delay` | `0` to run at once, `gate` to be the gate, `+N` for N seconds after the gate opens |
| `command` | `-` for a bare shell |

The gate is for a command everything else waits on -- an install, a reset. It
writes its exit status to a file keyed on the window id, and `+N` panes wait for
that before counting their offset. A gate that fails still opens it, and the
panes waiting say so rather than starting into a half-built tree.

## Agent feedback

atrium writes what it needs onto the pane it draws in:

| Option | Scope | Value |
| --- | --- | --- |
| `@atrium_status` | pane | `idle`, `working`, `needs-input` or `error` |
| `@atrium_agents` | pane | `<held> <working> <needs> <error>` |

The window list colours each window by the worst thing the atriums **in that
window** need. That rollup is a format string -- `#{P:#{@atrium_status}}` walks
the window's own panes as tmux paints -- so there is no daemon, nothing polls,
and a window with no atrium in it keeps its usual colour.

Colours come from `~/.config/atrium/theme.json`, falling back to guitar's, which
is the same one-way fallback atrium itself does: retheme atrium and the bar
follows, and the three tools can never disagree about what red is. With neither
installed the theme's own `accent` stands in, which cannot tell an error from a
question -- the nine slots have no red and no green.

Because atrium pushes a repaint when it publishes, feedback does not wait for
`@tmuxbar-refresh-rate`.

### Telling tmux about a new worktree

`WORKTREE_HOOK` names one executable, which atrium and guitar both run as
`$WORKTREE_HOOK created <path>` whenever they make a worktree. Point it at
`bin/workspace`, whose `created` verb stamps `@workspaces_dirty`, says so once,
and asks for a repaint.

```sh
export WORKTREE_HOOK="$HOME/.config/tmux/plugins/tmux/bin/workspace"
```

Nothing is lost with it unset: atrium notices a worktree it did not make within
three seconds, and the menu asks git directly every time it opens.

## Layout

```
tmuxbar.tmux        entry point; generates every tmux option the bar needs
bin/tmuxbar-theme   theme picker: draws the prefix + T menu, applies a pick
lib/theme.sh        theme resolution and loading
lib/ghostty.sh      writes the theme background out to ghostty
lib/utils.sh        helpers shared by the bar and the widgets
plugins/            one script per widget
themes/             one file per colour scheme
```
