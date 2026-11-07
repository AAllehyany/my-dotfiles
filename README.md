# my-dotfiles

The configuration for my Fedora desktop: the [Niri](https://github.com/YaLTeR/niri) scrolling
compositor, a [Quickshell](https://quickshell.org) shell called **Boron** (launcher, notifications,
lock screen), Neovim and Kitty. Everything shares one theme, **BLACKOUT**
(black / graphite / silver / blood red, MonoLisa font).

Each top-level folder is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors
the home directory, so `nvim/.config/nvim` becomes `~/.config/nvim`.

## What's inside

| Package | Installs to | Responsible for |
|---|---|---|
| [`niri/`](niri/.config/niri) | `~/.config/niri` | The compositor: outputs, layout, named workspaces, window rules, key binds, and the programs that start with the session |
| [`quickshell/`](quickshell/.config/quickshell) | `~/.config/quickshell` | The desktop shell (Boron) and older shell experiments |
| [`nvim/`](nvim/.config/nvim) | `~/.config/nvim` | The editor: plugins, LSP, formatting, Tree-sitter textobjects and folding, theme |
| [`kitty/`](kitty/.config/kitty) | `~/.config/kitty` | The terminal: font, colors, split layouts and split key binds |

### niri

- **`config.kdl`**:
  - **Session startup:** Boron (`qs -c boron`), the wallpaper (`swaybg`), the volume OSD
    (`wob-volume-server`), the polkit agent (`mate-polkit`), and `swayidle`, which locks before sleep.
    There is no idle timer.
  - **Named workspaces:** `focus`, `record`, `code` and `games`.
  - **Key binds:** see [Using it](#using-it).
- **`scripts/`**:

  | Script | What it does |
  |---|---|
  | `game-layout` | `Mod+Alt+G`: the [game layout](#game-layout): the focused game at 2/3 width and exactly 16:9, everything else as tabs beside it, Boron's game dock under it |
  | `aspect-ratio-script` | `Mod+Alt+0` / `Mod+Alt+Shift+0`: resizes the focused window to 16:9 / 4:3 of its width |
  | `niri-workspace-wallpaper` | Optional daemon that changes the wallpaper per workspace (needs `swww`/`awww`; not started by default) |

### quickshell

| Config | Status | What it is |
|---|---|---|
| [`boron/`](quickshell/.config/quickshell/boron) | **In use** | Keyboard-first launcher (apps, files, devices, plugins), notifications, tray and power menu, the glitch lock screen, and the game dock. Its own [README](quickshell/.config/quickshell/boron/README.md) covers features, IPC, tests and plugins. |
| `boron-lab/` | Experiment | Scratch copy of the launcher for trying ideas |
| [`command-center/`](quickshell/.config/quickshell/command-center/README.md) | Experiment | A command-palette shell (UI and state only, no system actions yet) |
| [`island/`](quickshell/.config/quickshell/island/README.md), `island.backup/` | Experiment | A floating top-center "island" bar |

Only `boron` starts with the session. Run any of the others with `qs -c <name>`.

### nvim

Neovim 0.12+, using the built-in package manager (`vim.pack`). Plugins install on first launch and
are pinned in `nvim-pack-lock.json`.

| File | Responsible for |
|---|---|
| `init.lua` | Leader key (Space) and the load order of the modules below |
| `lua/config/options.lua` | Editor options: line numbers, indentation, clipboard, splits |
| `lua/config/packages.lua` | The plugin list |
| `lua/config/treesitter.lua` | Parsers through [arborist.nvim](https://github.com/arborist-ts/arborist.nvim) (installed on demand), auto-closing tags |
| `lua/config/theme.lua` | The BLACKOUT colorscheme |
| `lua/config/mini.lua` | mini.nvim: picker, file explorer, git and diff, completion, pairs, surround, bracket jumps |
| `lua/config/textobjects.lua` | Tree-sitter textobjects: select, jump and swap functions, classes and arguments |
| `lua/config/folds.lua` | Tree-sitter folding; doc comments start folded |
| `lua/config/keymaps.lua` | Pickers, file explorer, buffers, splits, git |
| `lua/config/lsp.lua` | Language servers. Roslyn (C#) is always enabled; others only when their binary is installed. Also Angular and Astro helpers |
| `lua/config/csharp.lua` | Fills new C# files with a namespace and type from their path (`:CsScaffold`) |
| `lua/config/format.lua` | Format on save with conform.nvim (prettier for web files) |
| `queries/*/folds.scm` | Extra fold rules for doc comments (C#, JS/TS, Lua) |

### kitty

- **`kitty.conf`**: MonoLisa 13, 90% background opacity, split layouts, and `Ctrl+Alt` binds to split,
  move between and resize panes.
- **`current-theme.conf`**: the BLACKOUT colors.

## Installing

### 1. Dependencies (Fedora)

```sh
sudo dnf install stow git niri neovim swaybg swayidle swaylock mate-polkit wob \
  tree-sitter-cli python3-gobject NetworkManager bluez

# Quickshell 0.3.1 comes from the avengemedia/danklinux COPR
sudo dnf copr enable avengemedia/danklinux
sudo dnf install quickshell

# Kitty, from the official installer (installs to ~/.local/kitty.app)
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# OBS, from Flathub. Fedora's obs-studio RPM crashes at startup against Qt 6.11.
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.obsproject.Studio
```

Not in this repo, set up separately:
- **MonoLisa**, a paid font: install it to `~/.local/share/fonts`.
- **Wallpaper:** `~/wallpapers/niri/lab.png`. Change the `swaybg` line in `config.kdl` to use another.
- **Volume OSD:** `~/.local/bin/wob-volume-server`. Remove its startup line if you don't have it.
- **Neovim tooling (optional):** language servers (`roslyn`, `vtsls`, `pyright`, `gopls`, …) and
  `prettier`. Each is used only if it's installed.
- **Login screen:** `greetd` + `tuigreet`, configured in `/etc/greetd/config.toml`.

### 2. Clone

```sh
git clone https://github.com/AAllehyany/my-dotfiles ~/config-repositories/my-dotfiles
cd ~/config-repositories/my-dotfiles
```

### 3. Link with Stow

The repo doesn't live directly in `~`, so always pass `-t ~` (target = home directory).
Stow refuses to overwrite real files, so move any existing configs out of the way first:

```sh
for app in niri quickshell nvim kitty; do
  [ -e ~/.config/$app ] && [ ! -L ~/.config/$app ] && mv ~/.config/$app ~/.config/$app.pre-stow
done
```

Preview, then link:

```sh
stow -n -v -t ~ niri quickshell nvim kitty   # dry run: shows what would be linked
stow -v -t ~ niri quickshell nvim kitty      # create the links
```

Each app folder becomes one symlink, for example `~/.config/nvim -> ../config-repositories/my-dotfiles/nvim/.config/nvim`.
Packages are independent, so you can install just one (`stow -t ~ nvim`).

Other Stow commands:

```sh
stow -R -t ~ niri       # re-link (after adding or removing files in a package)
stow -D -t ~ kitty      # remove a package's links (the repo files stay)
```

### 4. First start

1. Log into a **Niri** session. Boron, the wallpaper and the idle/sleep lock start on their own.
2. Open Neovim once. `vim.pack` installs the plugins, and arborist installs Tree-sitter parsers
   as you open files.
3. If Boron isn't running: `qs -c boron -d`.

## Using it

`Mod` is the Super key.

| Keys | Action |
|---|---|
| `Mod+Space` | Boron launcher (apps, files, devices, plugins) |
| `Mod+T` | Kitty |
| `Super+Alt+L` | Lock the screen (Boron lock; falls back to swaylock) |
| `Mod+1`… | Switch workspace (`focus`, `record`, `code`, `games`) |
| `Mod+Alt+G` | Game layout (see below) |
| `Mod+Alt+0` / `Mod+Alt+Shift+0` | Resize window to 16:9 / 4:3 |
| `Mod+Shift+/` | Niri's list of every key bind |

Neovim: `Space` is the leader. `<leader>ff` finds files, `<leader>fg` greps, `<leader>e` opens
the file explorer, and `]f` / `]c` / `]a` jump between functions, classes and arguments.
`af` / `ac` / `aa` select them. The full lists are at the top of `textobjects.lua` and `folds.lua`.

### Game layout

Focus the game (usually on the `games` workspace) and press `Mod+Alt+G`:

```
+--------------------------+-----------+
|                          |  [tabs]   |   game: alone, 2/3 of the screen width, exactly 16:9
|   GAME  2560×1440 px     |  every    |         (2048×1152 logical at scale 1.25)
|                          |  other    |   side: every other window as tabs, full height
+--------------------------+  window   |         (switch tabs with Mod+J / Mod+K)
|  Boron game dock         |           |   dock: recording / streaming time, now playing,
+--------------------------+-----------+         CPU and GPU load and temperature
```

- Open windows in any order. Pressing it again changes nothing.
- To put a window under the game instead of the dock, move it into the game's column (`Mod+Comma`
  from the game) and press `Mod+Alt+G` again. That window stays and the dock steps aside.
- Another size: `game-layout 3/4` (the fraction of the screen width; default `2/3`).
- For pixel-exact games, run them in gamescope at the window's size: `gamescope -W 2560 -H 1440 -- %command%`.
- The dock's recording status comes from OBS: in OBS, turn on Tools → WebSocket Server Settings →
  Enable WebSocket server. The dock reads the port and password from OBS's own config.

## Editing

The links point into this repo, so editing `~/.config/...` edits the repo directly. Commit from here.
Niri and Quickshell reload their configs on save. Kitty reloads automatically. Restart Neovim to
pick up changes.
