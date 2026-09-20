# tmuxbar

A themed tmux status bar: a row of small widget scripts on each side, a centred
window list, and sixty built-in colour schemes with a `prefix + T` picker.

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
| `@tmuxbar-menu-border-lines` | `rounded` | Frame around both pickers; any `popup-border-lines` value, e.g. `single` or `none` |

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

Both pickers -- this one and `prefix + w` -- are tmux menus, so the theme paints
them too: the pane's own background, a rounded frame and title in `muted`, and
`surface` under the selected row. `@tmuxbar-menu-border-lines` changes the frame,
and a tmux older than 3.4, which had no menu styling at all, draws its own plain
one instead.

Each bundled theme lifts its nine colours from the matching Neovim colourscheme's
own palette, so an editor and its status bar can be moved between themes by name.
The twenty-eight with no Neovim port of their own come from
[guitar](https://github.com/asinglebit/guitar)'s palette instead — the same place
the `guitar-*` colourschemes get theirs — read off its thirty-two slots: `bg` is
guitar's background, `fg` and `fg_hi` its `text` and `highlighted`, the rest its
grey ramp, and `accent` the first of its blues that stays legible on that
background. `ansi` and `monochrome` are the terminal's own sixteen colours,
because that is what they are in guitar too.

With `@tmuxbar-ghostty` set, a switch also writes the theme's `bg` to ghostty's
`background`. tmux paints the pane area itself, so what this fixes is the parts
it does not cover: the sub-cell remainder of the window size, the padding, and a
window that has not attached yet. Terminals already open are repainted with
OSC 11, since ghostty reloads its config only from a keybind.

| Family | Themes |
| --- | --- |
| — | `default`, `onedark`, `material`, `palenight`, `zenburn`, `horizon`, `synthwave-84`, `matrix` |
| Terminal | `ansi`, `monochrome` |
| Catppuccin | `catppuccin-mocha`, `catppuccin-macchiato`, `catppuccin-frappe`, `catppuccin-latte` (light) |
| Tokyo Night | `tokyonight-night`, `tokyonight-storm`, `tokyonight-moon`, `tokyonight-day` (light) |
| Rose Pine | `rose-pine`, `rose-pine-moon`, `rose-pine-dawn` (light) |
| Nightfox | `nightfox`, `duskfox`, `nordfox`, `terafox`, `carbonfox`, `dayfox` (light), `dawnfox` (light) |
| Kanagawa | `kanagawa-wave`, `kanagawa-dragon`, `kanagawa-lotus` (light) |
| Gruvbox | `gruvbox-dark`, `gruvbox-light` (light) |
| Everforest | `everforest-dark`, `everforest-light` (light) |
| Dracula | `dracula`, `dracula-soft`, `dracula-light` (light) |
| Oxocarbon | `oxocarbon-dark`, `oxocarbon-light` (light) |
| Nord | `nord` |
| Monokai | `monokai-dark`, `monokai-light` (light) |
| Atom | `atom-dark`, `atom-light` (light) |
| VS Code | `vscode-dark`, `vscode-light` (light) |
| Solarized | `solarized-dark`, `solarized-light` (light) |
| GitHub | `github-dark`, `github-dark-dimmed`, `github-light` (light) |
| Owl | `night-owl`, `light-owl` (light) |
| Ayu | `ayu-dark`, `ayu-mirage`, `ayu-light` (light) |
| Base16 | `base16-tomorrow`, `base16-ocean`, `base16-eighties` |

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
| `bg` | Status bar and window list background, pane and pane border background, menu background |
| `bg_dim` | Reserved |
| `surface` | Widget background, pane border lines, selected menu row |
| `surface_hi` | First and last widget (the end caps) background |
| `muted` | Inactive window name, menu frame and title |
| `dim` | Reserved |
| `fg` | Status foreground, widget text, active window name, menu text |
| `fg_hi` | End cap text, pane foreground, selected menu row text |
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
prefix + w                pick a workspace; a dot marks the ones already up
bin/workspace list        every worktree, its branch, and up or down
bin/workspace up PATH     build the window from the project's own plan
bin/workspace down PATH   kill it
bin/workspace save        write this window down as the project's plan
bin/workspace save -g     ...in ~/.config/workspace, for a repo you cannot write to
```

A window is bound to its worktree by a `@workspace` window option, set when the
window is built. Lookups are server-wide (`list-windows -a`) rather than
per-session, because grouped sessions share their windows.

### Plans

A project says how its own window is laid out. tmuxbar holds no layouts and no
list of projects -- it asks the repository, then one shared directory, then
gives up and opens an empty window.

| | Where | For |
| --- | --- | --- |
| 1 | `<main checkout>/.workspace` | Repositories that are yours to write to |
| 2 | `~/.config/workspace/<project>.workspace` | Ones that are not |
| 3 | `~/.config/workspace/default.workspace` | Everything else, if you make one |
| 4 | — | One empty window |

Tier 3 is a file you create; nothing here ships one. Make it and every project
without a plan of its own opens that way instead of empty. A project actually
named `default` would collide with it, which is the one name to avoid in tier 2.

Both tiers are keyed on the **main checkout**, never the worktree, so
`customer-portal-test` uses `customer-portal`'s layout either way.

> **Tier 2 is not only for other people's repositories.** A layout whose gate
> runs something like `pnpm reset` is usually running `git clean -fdx`, and that
> removes ignored and untracked files at the root -- so an in-repo `.workspace`
> you deliberately left untracked gets deleted by the very window it opens. Put
> those in tier 2. A *committed* `.workspace` is safe, because `git clean` does
> not touch tracked files.

```
# name    from    split size  cwd             delay  command
guitar    -       -     -     .               0      g
types     guitar  h     10%   packages/types  +0     pnpm watch
nvim      guitar  v     90%   .               0      n
cli       guitar  h     67%   .               0      -
reset     cli     h     50%   .               gate   pnpm reset && pnpm i
```

| Field | Meaning |
| --- | --- |
| `name` | What `from` refers to. Insert a pane and nothing renumbers |
| `from` | Which pane to split, **by name**; `-` opens the window |
| `split` | `h` or `v`; `-` for the window's own pane |
| `size` | What the **new** pane takes, e.g. `40%`; `-` lets tmux decide |
| `cwd` | Relative to the worktree root; `.` for its root |
| `delay` | `0` now, `gate` to be the gate, `+N` for N seconds after it opens |
| `command` | `-` for a bare shell |

The cursor lands in **the first pane you left empty** -- the one with no
command, which is the one you meant to type in.

The gate is for a command everything else waits on: an install, a reset. It
writes its exit status to a file keyed on the window id, and `+N` panes wait for
that before counting their offset. A gate that fails still opens it, and the
panes waiting say so rather than starting into a half-built tree.

### Capturing one

Nobody should work out percentages by hand. Split a window until it looks right,
then write it down:

```sh
workspace save          # this window, to wherever its plan already lives
workspace save -g       # to ~/.config/workspace instead, for a repo you cannot write to
workspace save -d       # as the default, for every project without a plan
workspace save -f       # overwrite one that is already there
```

With no plan yet and no `-g`, it writes the repository's own `.workspace`.

That records tmux's own `#{window_layout}` as a `layout` line, which `up` hands
straight back to `select-layout`, so the geometry comes back exact to the cell.
The line carries a checksum and is not one to edit -- rearrange and save again.
If it stops fitting, because a row was added by hand, tmux refuses it and the
`split`/`size` columns lay the window out instead. A worse layout, never a
broken one.

**Commands are a hint, not a capture.** tmux only reports the foreground
process, so a pane running `pnpm watch` comes back as `node` and one sitting at
a prompt comes back as a shell. Those rows are written with a note to check
them. Geometry and directories are exact, which is the part that was tedious.

### A plan is data, not a script

Deliberately. It cannot branch, loop, or compute, and two things were dropped
rather than grow it into a language: a warning when the window was too small for
the layout, and a pane rooted outside the worktree. Anything genuinely needing
logic belongs in a shell function, the way `tds` and `glf` still do -- they open
six different repos in one window, so no single repo could own them.

## Agent feedback

atrium writes what it needs onto the pane it draws in:

| Option | Scope | Value |
| --- | --- | --- |
| `@atrium_status` | pane | `idle`, `working`, `needs-input` or `error` |
| `@atrium_agents` | pane | `<held> <working> <needs> <error>` |
| `@atrium_blink` | server | `0` on the dark half of the pulse; lit on anything else, unset included |

The window list colours each window by the worst thing the atriums **in that
window** need. That rollup is a format string -- `#{P:#{@atrium_status}}` walks
the window's own panes as tmux paints -- so there is no daemon, nothing polls,
and a window with no atrium in it keeps its usual colour.

| Status | Window name | Palette key | Means |
| --- | --- | --- | --- |
| `needs-input` | blue, pulsing | `blue` | An agent is waiting on you |
| `working` | orange, pulsing | `orange` | It is waiting on the model |
| `idle` | green | `green` | It has finished and wants nothing |
| `error` | red | `red` | It failed |

Only the two that are still waiting pulse, so the bar moves where something is
going on and sits still where it is not. The `atrium` widget's cell takes the
same colours but holds them steady: its output is cached until the next
`status-interval`, so whichever half of the beat it printed is the half it would
wear for the next minute.

**The pulse is drawn, not asked for.** `#[blink]` is the obvious way to write
this and it does not work: it emits SGR 5, which ghostty parses and ignores.
Nor can the bar keep its own time -- tmux repaints the status line only when
something asks it to. So atrium keeps the beat, because it is the thing already
running and already knows an agent is waiting: while one is, it writes
`@atrium_blink` and asks for a repaint twice a second, and the window drops to
the theme's `muted` on the dark half. Nothing waiting, nothing ticking.

A window whose beat has stopped -- no atrium running, one killed before it could
stop cleanly -- holds the **lit** colour. The format dims on an explicit `0` and
lights on everything else, so the worst a missing beat can do is stop the
movement, never leave a window greyed out.

Colours come from `~/.config/atrium/theme.json`, falling back to guitar's, which
is the same one-way fallback atrium itself does: retheme atrium and the bar
follows, and the three tools can never disagree about what red is. With neither
installed the theme's own `accent` stands in for both red and blue -- the nine
slots have neither -- and the pulse is all that tells a question from a failure.

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
