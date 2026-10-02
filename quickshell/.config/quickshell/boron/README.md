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

| Key | Action |
|---|---|
| Up/Down, Ctrl+P/N | Select a result |
| Enter | Default action |
| Ctrl+K, right-click | Additional actions |
| Ctrl+M, mode button | Searchable mode picker |
| Ctrl+Tab / Ctrl+Shift+Tab | Next / previous device tab in Devices; next / previous mode elsewhere |
| Ctrl+PageDown / Ctrl+PageUp | Next / previous launcher mode from any mode |
| Alt+Left / Alt+Right | Previous / next Wi-Fi or Bluetooth tab in Devices |
| Tab / Shift+Tab | Move through controls and forms |
| Escape | Dismiss prompt/actions, clear search, then close |
| Click outside | Close |

Type `@apps `, `@tray `, `@devices `, or `@github ` to switch modes.
`@wifi ` and `@bluetooth ` enter a specific Devices section; `@gh ` is a GitHub
alias. Typing `@` lists available modes and aliases; `@wi` and `@blu` narrow to
Wi-Fi and Bluetooth. Use Up/Down to select a suggestion and Tab, Enter, or a
click to enter that mode. Escape clears the suggestions. Enabled plugin modes
and aliases appear automatically; completion does not send queries to plugins.
Full prefixes are also consumed when followed by a space, preserving any search
text after them (for example, `@wifi office`). Opening the launcher
always starts in Applications. Searching does not contact other modes.

In Devices, Tab moves through **search → active tab → results → mode button**;
Shift+Tab reverses that order. While a tab is focused, Left/Right switches tabs
with wrapping, Home/End selects the first/last tab, and Down, Enter, or Space
enters the results without activating a device. Up or Shift+Tab returns to search.
The active tab has an underline; keyboard focus adds an outer border.

Within focused results, Up/Down selects a row, Enter runs its action, Home/End
selects the first/last row, and PageUp/PageDown moves by a visible page. Up from
the first result returns to the tabs. Typing from tabs or results resumes search.
Ctrl+Tab and Alt+Left/Right retain the current focus area. Switching tabs clears
the search and starts the new list at the top. These shortcuts are inactive while
a confirmation or password prompt is open.

The panel appears on Niri's focused output, with a first-screen fallback if Niri
is unavailable. It fits the output and shows up to eight rows before scrolling.

## Modes

- **Applications:** desktop-entry name/keyword search, fuzzy matching, desktop
  actions, and terminal application support through Kitty.
- **System Tray:** live tray entries, nested application menus, and Sleep,
  Restart, and Shutdown. Restart/Shutdown require confirmation.
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

## Organization

```text
shell.qml                   Composition and launcher IPC
core/                       Pure matching/routing functions
theme/                      Shared BLACKOUT tokens
components/                 Presentation primitives
features/
  launcher/                 Window, state, keyboard policy, forms
  applications/             Desktop-entry integration
  systemtray/               Tray menus and power actions
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
QT_QPA_PLATFORM=offscreen qs -p smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p scroll-smoke.qml --no-color
QT_QPA_PLATFORM=offscreen qs -p navigation-smoke.qml --no-color
```

`smoke.qml` checks QML state transitions and adapters with fixture network data.
It exits after logging `STATE SMOKE PASSED`. Its imports need the project root,
which is why it is beside `shell.qml`.

`scroll-smoke.qml` exercises a real ListView with fixture devices: refreshed
statuses, insertion, reordering, disappearing devices, keyboard navigation,
tab changes, and empty/repopulated lists. It logs `SCROLL SMOKE PASSED`.

`navigation-smoke.qml` uses QtTest to send real keyboard/mouse events to the
production launcher view with inert device fixtures. It verifies tab switching,
focus traversal, search editing, result activation, live refresh, and prompt
guards, then logs `NAVIGATION SMOKE PASSED`. It requires the QtTest QML module.

For a short visual fixture preview on Wayland:

```sh
qs -p preview.qml --no-color
```

The preview cycles through compact, expanded, confirmation, and device views,
saves panel-only screenshots under `/tmp/boron-*.png`, and exits automatically.
It never invokes real actions.

Real hardware pairing, authenticated GitHub access, and power operations still
need verification in your session. The automated suite substitutes fixtures for
those operations. Use the [manual checks](docs/manual-checks.md) when activating.
