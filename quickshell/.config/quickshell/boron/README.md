# Boron

A keyboard-first Quickshell launcher for Niri. Square geometry, MonoLisa, and the
BLACKOUT palette from your Neovim and Kitty theme files. It opens compactly,
keeps the search field stationary, and expands downward as you type.

## Run

Requires Quickshell **0.3.1**, Qt Quick Controls, Python 3, and a Wayland session.
The device features use NetworkManager, BlueZ, and Python's PyGObject/Gio bindings
(`python3-gobject` on Fedora). Terminal applications launch in Kitty.

```sh
qs -c boron
```

From another terminal or a compositor binding:

```sh
qs -c boron ipc call launcher toggle
qs -c boron ipc call launcher open
qs -c boron ipc call launcher close
```

For an undeployed checkout, use `qs -p /absolute/path/to/boron` and
`qs -p /absolute/path/to/boron ipc call launcher toggle`.

### Niri switch-over

In your Niri configuration, replace the existing startup line:

```kdl
spawn-at-startup "qs" "-c" "boron-lab"
```

with:

```kdl
spawn-at-startup "qs" "-c" "boron"
```

Inside the existing `binds` block, replace the active Mod+Space binding with:

```kdl
Mod+Space { spawn "qs" "-c" "boron" "ipc" "call" "launcher" "toggle"; }
```

These are replacements, not additional bindings. Niri's startup entry takes
effect next login. To try Boron now, start `qs -c boron` in a terminal and use
the IPC command. The implementation does not change your Niri configuration.

## Controls

Everything works from the keyboard. Press **Ctrl+/** (or **F1**) inside Boron for a
searchable list of the keys available in the current mode.

| Key | Action |
|---|---|
| Up/Down, Ctrl+N/P, Alt+J/K | Select a result |
| Enter | Default action |
| Shift+Enter | Secondary action (shown in the footer, e.g. a desktop action or Show menu) |
| Alt+1–9 | Run the Nth visible result (rows show their number) |
| Ctrl+K, right-click | Additional actions |
| Page Up / Page Down | Move by a page |
| Home / End | First / last result while the search is empty |
| Ctrl+1–9 | Switch to the Nth mode (Applications, System Tray, Devices, Notifications, then plugins) |
| Ctrl+M, mode button | Searchable mode picker (lists the Ctrl+N number of each mode) |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous tab in modes with tabs (Devices, GitHub); next / previous mode elsewhere |
| Alt+Left / Alt+Right | Previous / next tab in modes with tabs |
| Ctrl+PageDown / Ctrl+PageUp | Next / previous launcher mode from any mode |
| Ctrl+Q | Confirm quitting the selected tray app (System Tray only) |
| Ctrl+D, Delete in results | Dismiss the selected notification; remove an app from Recent |
| Ctrl+Shift+D | Clear all notifications (asks first) |
| Ctrl+R | Retry after a plugin error |
| Tab / Shift+Tab | Move through search, tabs, results, toolbar buttons and the mode button |
| Backspace on empty search | Go up one level: help, actions, tray submenu, mode picker, then back to Applications |
| Left / Right on empty search | Leave / open a tray menu (System Tray only) |
| Ctrl+Enter | Submit a form or confirmation from any field |
| Left / Right on prompt buttons | Move between Cancel and Confirm; Enter or Space presses the focused button |
| Escape | Dismiss prompt/actions/help, clear search, then close |
| Ctrl+W, Shift+Escape | Close immediately from any depth |
| Click outside | Close |

Type `@apps `, `@tray `, `@devices `, `@notifications `, or `@github ` to switch modes.
`@wifi ` and `@bluetooth ` enter a specific Devices section; `@gh ` is a GitHub
alias. Typing `@` lists available modes and aliases; `@wi` and `@blu` narrow to
Wi-Fi and Bluetooth. Use Up/Down to select a suggestion and Tab, Enter, or a
click to enter that mode. Escape clears the suggestions. Enabled plugin modes
and aliases appear automatically; completion does not send queries to plugins.
Full prefixes are also consumed when followed by a space, preserving any search
text after them (for example, `@wifi office`). Opening the launcher
always starts in Applications. Searching does not contact other modes.
Typing new search text always selects the best match.

In every mode, Tab moves through **search → tabs (if any) → results → toolbar
buttons (Clear all, Retry) → mode button**; Shift+Tab reverses that order. While a
tab is focused, Left/Right switches tabs with wrapping, Home/End selects the
first/last tab, and Down, Enter, or Space enters the results without activating
anything. Up or Shift+Tab returns to search. The active tab has an underline;
keyboard focus adds an outer border.

Within focused results, Up/Down selects a row, Enter runs its action, Home/End
selects the first/last row, and PageUp/PageDown moves by a visible page. Up from
the first result returns to the tabs (or search). Typing from tabs or results
resumes search. Ctrl+Tab and Alt+Left/Right retain the current focus area.
Switching tabs clears the search and starts the new list at the top. These
shortcuts are inactive while a confirmation or password prompt is open.

The footer always shows the keys that apply to the current selection.

The panel appears on Niri's focused output, with a first-screen fallback if Niri
is unavailable. It fits the output and shows up to eight rows before scrolling.

## Modes

- **Applications:** desktop-entry name/keyword search, fuzzy matching, desktop
  actions, and terminal application support through Kitty. With an empty search
  the list shows up to eight **Recent** apps ranked by frecency (launch count with
  a one-week half-life), so Mod+Space then Enter relaunches your latest app.
  Frequently used apps also rank slightly higher in search. History lives in
  `$XDG_STATE_HOME/boron/history.json` (default `~/.local/state`); remove an
  entry with Ctrl+D or **Remove from recent**, or delete the file to reset it.
- **System Tray:** live tray entries, nested application menus, and Sleep,
  Restart, and Shutdown. Ctrl+Q finds the selected app's enabled Quit/Exit menu
  command and asks for confirmation; it also works from the app's additional
  actions. Apps without a supported command show a notice. Restart/Shutdown
  require confirmation.
- **Devices:** adapter selection, Wi-Fi radio/network controls, personal-network
  passwords, Bluetooth discovery, pairing prompts, trust, connect/disconnect,
  and forget. Fixed Wi-Fi/Bluetooth tabs show the active section. Live refreshes
  preserve the visible device and scroll offset; keyboard selection has a distinct
  highlight. Discovery runs only while the relevant view is active. Advanced
  Wi-Fi configuration opens `nm-connection-editor`; install it for enterprise
  profiles, certificates, or hidden networks. Existing enterprise profiles can
  connect directly.
- **GitHub:** separate repository, issue, and PR searches; browser opening; and
  confirmed PR merges. Search accepts GitHub qualifiers. Results are capped at
  30 per query; narrow the search to find more specific results.
- **Notifications:** desktop notification history, newest first. Search title,
  body, or application; click/Enter invokes the sender's default action when
  supplied and removes the entry. Ctrl+K lists other sender actions and Dismiss.
  The header's NOTIFS button shows the unread count and opens this mode;
  `@notifs ` is an alias. Only entries visible in the center become read.
  Clear all removes the entire history, including entries hidden by search.

### Desktop notifications

Boron receives standard Linux desktop notifications. Toasts appear at the bottom
right of Niri's focused output, with a first-output fallback. Each output shows
up to three cards, newest at the bottom; overflow remains in history. Each card
disappears within three seconds, including critical notifications. Hovering and
replacement updates do not extend that deadline. Clicking invokes the sender's
default action if available, then removes the notification; the × dismisses it
without running an action. Images fall back to application icons when available.

Opening Notifications mode hides the toast stack. New arrivals appear only in
the center while that mode is open, and leaving does not replay them. History
stays in memory until cleared or Boron exits. QML reloads restore live entries
as read without replaying toasts. Sender-withdrawn entries are removed; transient
notifications are toast-only and expire completely. Existing device/plugin
status messages remain in their current UI. There is no disk history, sound,
inline reply, or Do Not Disturb mode.

Open the center directly from a compositor binding or terminal:

```sh
qs -c boron ipc call notifications open
```

Only one daemon can own `org.freedesktop.Notifications`. This session had Mako
running, and Fedora provides D-Bus activation through `mako.service`. Boron reports
a competing daemon in Notifications mode and automatically takes over when it
exits; it does not stop another daemon or change your startup configuration.

To switch over, first keep Boron running and verify that Notifications mode opens.
Remove any Mako startup entry from your compositor/autostart configuration (the
Mako line in this checkout's Niri configuration was already commented). Then:

```sh
systemctl --user mask --now mako.service
busctl --user status org.freedesktop.Notifications
notify-send -a 'Boron test' 'Notifications ready' 'This toast lasts three seconds.'
```

The bus owner should be Boron's `qs` process. Allow up to five seconds for the
center's ownership message to clear. If Mako was launched directly rather than
through its service, stop that specific process as well. Other distributions
may use different activation mechanisms; disable the competing daemon's actual
launcher. If a toast has expired, verify it remains in the center.

To roll back, stop the Boron instance, then restore Mako:

```sh
qs -c boron kill
systemctl --user unmask mako.service
systemctl --user start mako.service
```

Restore its previous startup entry if you removed one. To run Boron's launcher
alongside Mako, remove `NotificationBackend { service: notifications }` from
`shell.qml` before restarting Boron; its notification center will then be empty.

### GitHub setup

Install GitHub CLI (`gh`), then authenticate in a terminal:

```sh
gh auth login
gh auth status
```

For Fedora, GitHub CLI is available as the `gh` package. Credentials remain
managed by `gh`; Boron does not store tokens. Permissions and repository rules
apply to every action. The GitHub mode reports missing authentication, network
errors, and rate limits with a Retry action.

To merge, find an open PR, open its actions with Ctrl+K, and select **Merge pull
request…**. Confirmation shows the repository, PR, base branch, commit, checks,
review state, and enabled merge methods. Squash is preferred when enabled.
The confirmed commit must still match immediately before submission; an updated
PR requires fresh confirmation. Boron never uses administrator bypass or requests
branch deletion (repository auto-deletion settings still apply).

GitHub may merge immediately, enqueue the PR, or schedule it when branch rules
require a queue. The confirmation explains this and the outcome distinguishes
these states. An interrupted request is not automatically retried. Check GitHub
if the outcome is uncertain. Closing the launcher does not cancel an already
submitted merge; its completion is shown when you next open the launcher.

## Lock screen

A 512 px lock that glitches and the date and time in MonoLisa, over a blurred copy
of the desktop as it was the moment you locked. Every keystroke sends a glitch pulse through the
icon, and it keeps glitching while the password is checked. A wrong password
gives a red burst, the field shakes, and the input clears. The right one settles
the icon into a clean lock, lifts the shackle, and fades it while the blur clears
back into your desktop, then unlocks.

Just before locking, each monitor is captured with screencopy (about 100 ms).
The frames stay in memory, are never written to disk, and are dropped a second
after unlocking. If a monitor can't be captured, its lock shows the blurred swaybg
wallpaper instead.

```sh
tools/lock                       # lock (falls back to swaylock if Boron isn't running)
qs -c boron ipc call lock lock   # the same, without the fallback
```

Every monitor shows the lock and the date. Only the monitor that was focused when
locking shows the password field; click another monitor to move it there. Typing
works whichever monitor the compositor sends keys to. Escape or Ctrl+U clears the
field and Ctrl+Backspace deletes it all. The focused monitor comes from `niri msg`
or `hyprctl`, so the lock works the same on Niri and Hyprland.

There is deliberately no IPC unlock: only the password unlocks. Passwords are
checked through PAM with `pam/password.conf` (`pam_unix`), so the lock doesn't
depend on any other locker's PAM file.

In Niri, `Super+Alt+L` and swayidle (before sleep; there is no idle timer) call
`tools/lock`. On Hyprland, use the same script from a bind and from hypridle's `lock_cmd`.

**If the lock ever hangs** (for example, Quickshell crashes while locked), the
session stays locked rather than opening. Switch to a text console with
Ctrl+Alt+F3, log in, and run `WAYLAND_DISPLAY=wayland-1 swaylock` (your socket
name is in `echo $WAYLAND_DISPLAY` from a desktop terminal). Swaylock takes over
the lock, so switch back with Ctrl+Alt+F1 or F2 and unlock with it.

To tune the look without locking anything, run `qs -p lock-preview.qml`. It uses a
fake password check: type `boron` to see the unlock, anything else for a failure,
and press Escape twice to close. Its background is a capture of your first monitor,
or any image with `BORON_LOCK_SNAPSHOT=/path/to/image.png`. The glitch is a fragment shader: after editing
`features/lock/shaders/glitch.frag`, run `tools/build-shaders.sh` (needs `qsb`
from `qt6-qtshadertools`).

## Game dock

A panel for the strip under the game in niri's game layout (`niri/scripts/game-layout`, bound to
`Mod+Alt+G`). It shows:
- **OBS capture:** a red `REC` with the recording time, `PAUSED`, and a separate `LIVE` badge with the
  stream time.
- **Now playing:** the active MPRIS player (Spotify, browsers, …) with previous, play/pause and next buttons.
- **System:** GPU load, temperature, VRAM, fan and power from `nvidia-smi`, and CPU load (`/proc/stat`)
  and temperature (`k10temp`).

The layout script places it over IPC, in output-logical pixels:

```sh
qs -c boron ipc call gamedock place HDMI-A-3 4 77 4 1160 2048 564   # output workspace-id game-id x y w h
qs -c boron ipc call gamedock remove
```

These are not named `show`/`hide`, because `qs ipc call gamedock show` parses `show` as the
`qs ipc show` subcommand. The dock sits on the bottom layer: above the wallpaper, below windows. It only
appears while its workspace is active on that output, and goes away when the game window closes
(from `niri msg --json event-stream`).
Its helpers run only while it's visible.

Recording status comes from obs-websocket, built into OBS 28+. In OBS, turn on Tools → WebSocket
Server Settings → Enable WebSocket server. `features/gamedock/obs_status.py` (standard library
only) reads the port and password from OBS's own config, Flatpak or native. If OBS isn't running,
the dock says `OBS OFFLINE`; other messages are `OBS WEBSOCKET OFF`, `OBS PASSWORD REJECTED` and
`OBS NOT SET UP`.

## Organization

```text
shell.qml                   Composition, launcher, lock and game dock IPC
core/                       Pure matching, routing and frecency functions; focused-output lookup
pam/                        PAM config for the lock screen
tools/                      Lock command and shader build script
theme/                      Shared BLACKOUT tokens
components/                 Presentation primitives
features/
  launcher/                 Window, state, keyboard policy, forms
  applications/             Desktop-entry integration
  systemtray/               Tray menus and power actions
  lock/                     Session lock, desktop snapshot, PAM check, glitch shader
  gamedock/                 Game dock: placement, OBS status helper, system stats, view
  devices/                  Network/Bluetooth integration and pairing agent
  plugins/                  Process supervisor, adapter, Python SDK
plugins/
  github/                   GitHub mode implementation
  example/                  Small working plugin (disabled by default)
tests/                      Offline Python/JavaScript fixtures and checks
```

Mode-specific system calls stay inside their feature. The launcher renders a
common result/action/form interface. Remote plugins run in separate processes;
adding a plugin requires no launcher UI edits. See [the plugin guide](docs/plugins.md).

## Validation

These tests never contact GitHub or perform power/device actions:

```sh
python3 -m unittest discover -s tests -v
node tests/test_search.cjs
node tests/test_frecency.cjs
QT_QPA_PLATFORM=offscreen qs -p smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p scroll-smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p navigation-smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p tray-quit-smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p notifications-smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p lock-smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p gamedock-smoke.qml --no-color
python3 tests/test_notifications_bus.py
```

`tests/test_obs_status.py` (part of the unittest run) checks the OBS helper's websocket handshake
and password against a fake obs-websocket server. `gamedock-smoke.qml` checks dock placement and
visibility from niri event lines, plus the CPU, GPU and recording parsing, and logs
`GAMEDOCK SMOKE PASSED`. With `BORON_DOCK_CAPTURE=1` and the GPU-rendering variables shown below,
it also saves `/tmp/boron-gamedock-recording.png` and `-idle.png`.

`lock-smoke.qml` drives the lock screen's state with a fake password check: key
handling from a monitor without the field, wrong and right passwords, the
glitch levels, and the swaybg and focused-output parsing. It never locks the
session or touches PAM, and it logs `LOCK SMOKE PASSED`. To render the lock
screen's states to `/tmp/boron-lock-*.png` without a window (GPU rendering, so
the shader and blur show; offscreen can't capture the screen, so pass an image
as the desktop):

```sh
QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl QT_QPA_PLATFORM=offscreen BORON_LOCK_CAPTURE=1 BORON_LOCK_SNAPSHOT=$HOME/wallpapers/niri/lab.png qs -p lock-preview.qml --no-color
```

`smoke.qml` checks QML state transitions and adapters with fixture network data.
It exits after logging `STATE SMOKE PASSED`. Its imports need the project root,
which is why it is beside `shell.qml`.

`scroll-smoke.qml` exercises a real ListView with fixture devices: refreshed
statuses, insertion, reordering, disappearing devices, keyboard navigation,
tab changes, and empty/repopulated lists. It logs `SCROLL SMOKE PASSED`.

`navigation-smoke.qml` uses QtTest to send real keyboard/mouse events to the
production launcher view with inert device and tray fixtures. It verifies tab
switching, focus traversal, search editing, result activation, live refresh,
Ctrl+Q quit confirmation, and shortcut guards, then logs `NAVIGATION SMOKE PASSED`.
It requires the QtTest QML module.

`tray-quit-smoke.qml` checks quit confirmation and cancellation, nested and
delayed menus, unavailable commands, disappearing apps, and menu cleanup with
inert tray fixtures. It logs `TRAY QUIT SMOKE PASSED` and never quits real apps.

For a short visual fixture preview on Wayland:

```sh
qs -p preview.qml --no-color
```

The preview cycles through compact, expanded, confirmation, and device views,
saves panel-only screenshots under `/tmp/boron-*.png`, and exits automatically.
It never invokes real actions.

`notifications-smoke.qml` checks toast deadlines, overflow, independent outputs,
monitor removal, action lifecycles, search, unread visibility, and center controls
using inert notifications. It never starts a desktop notification server.
`test_notifications_bus.py` additionally checks real D-Bus notifications, image
data, close reasons, actions, daemon handover, and QML reloads on a private bus
with desktop-service activation disabled. It requires `dbus-run-session`,
`busctl`, and Python's Gio bindings, and runs separately from unittest discovery.

For a short Wayland notification preview:

```sh
qs -p notification-preview.qml --no-color
```

This shows fixture-only toasts and the center, saves screenshots under
`/tmp/boron-toast-*.png` and `/tmp/boron-notification-center.png`, then exits.
Its missing-image warning deliberately exercises application-icon fallback.

Real hardware pairing, authenticated GitHub access, and power operations still
need verification in your session. The automated suite substitutes fixtures for
those operations. Use the [manual checks](docs/manual-checks.md) when activating.
