# tmuxbar

A themed tmux status bar: a row of small widget scripts on each side, a centred
window list, and ten built-in colour schemes with a `prefix + T` picker.

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
| `@tmuxbar-left-plugins` | `session git cwd` | Widgets, left to right |
| `@tmuxbar-right-plugins` | `cpu ram battery network time` | Widgets, left to right |
| `@tmuxbar-refresh-rate` | `60` | Seconds between widget re-runs (`status-interval`) |
| `@tmuxbar-show-powerline` | `true` | Draw the end-cap glyphs |
| `@tmuxbar-left-sep` | `` | Left-side separator glyph |
| `@tmuxbar-right-sep` | `` | Right-side separator glyph |
| `@tmuxbar-window-list-alignment` | `absolute-centre` | Passed to `status-justify` |
| `@tmuxbar-prefix-highlight-color` | theme `accent` | Session segment colour while the prefix is held |

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

Bundled: `default`, `nordfox`, `carbonfox`, `duskfox`, `terafox`, `dawnfox` (light),
`catppuccin-mocha`, `gruvbox-dark`, `tokyonight-storm`, `rose-pine`.

There is also a CLI, which the menu entries call:

```bash
bin/tmuxbar-theme list
bin/tmuxbar-theme current
bin/tmuxbar-theme set rose-pine
bin/tmuxbar-theme set -          # back to @tmuxbar-theme
```

### Writing a theme

A theme is a shell fragment assigning nine colours. Slots are named by role rather
than by lightness, so a light theme just assigns light values to `bg`.

| Slot | Used for |
| --- | --- |
| `bg` | Status bar, window list, and pane border background |
| `bg_dim` | Inactive pane background |
| `surface` | Widget background, pane border lines |
| `surface_hi` | First and last widget (the end caps) background |
| `muted` | Inactive window name |
| `dim` | Inactive pane foreground |
| `fg` | Status foreground, widget text |
| `fg_hi` | End cap text, active pane foreground |
| `accent` | Prefix-active highlight background (its text uses `bg`) |

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

## Layout

```
tmuxbar.tmux        entry point; generates every tmux option the bar needs
bin/tmuxbar-theme   theme picker back end
lib/theme.sh        theme resolution and loading
lib/utils.sh        helpers shared by the bar and the widgets
plugins/            one script per widget
themes/             one file per colour scheme
```
