# Quickshell Island — Phase 0

Phase 0 implementation of the floating top-center island for Niri + Quickshell.

This revision follows the current stable Quickshell 0.3.1 API and current configuration guidance.

## Quickshell patterns used

- `Variants` owns one `IslandSurface` instance per connected output.
- `Quickshell.screens` is used only as the reactive `Variants.model`; no application logic manually iterates or stores `ShellScreen` objects.
- orchestration uses `Variants.instances` and stable output-name strings.
- `ShellScreen` references stay local to the `IslandSurface` delegate via `modelData`.
- root-relative `qs.*` imports are used instead of relative directory imports.
- design tokens are a Quickshell `Singleton`.
- `.qmlls.ini` is included so Quickshell/qmlls can generate the local language-server configuration; it is gitignored because the generated contents are machine-specific.
- the config is intended to live in a named Quickshell directory rather than the bare `~/.config/quickshell` root.
- `SystemClock` runs at minute precision; no clock process or high-frequency timer is used.

The required per-output pattern is therefore:

```qml
Variants {
    model: Quickshell.screens

    IslandSurface {
        // modelData is injected by Variants and consumed by IslandSurface.
    }
}
```

`Variants` and `Quickshell.screens` are not alternatives: `Variants` is the instantiator, and `Quickshell.screens` is the reactive output model it consumes.

## What is implemented

- one island surface per connected output through `Variants`
- centered floating collapsed island
- placeholder workspace (`02 · dev`)
- live 24-hour clock using `SystemClock` at minute precision
- same-surface expand/collapse animation
- click-away close
- Escape close
- only one expanded output at a time
- Quickshell IPC: `island.toggle`, `island.open`, `island.close`
- output-targeted helper IPC: `toggleOn <output>`, `openOn <output>`
- transparent full-output host with an input mask
- `ExclusionMode.Ignore`, so expansion never reserves more compositor space or reflows tiled windows
- placeholder-only connectivity/audio/brightness/power UI
- centralized singleton design tokens
- reloadable window identifier for smoother Quickshell reload matching

No audio, NetworkManager, BlueZ, brightness, battery, media, launcher, or notification integration is present.

## Install

Quickshell currently recommends named configuration directories. Install this as `island`:

```sh
mkdir -p ~/.config/quickshell/island
cp -r ./* ~/.config/quickshell/island/
cp .qmlls.ini .gitignore ~/.config/quickshell/island/
```

Start it with:

```sh
qs -c island
```

Quickshell watches configuration files by default, so normal edits can use its reload behavior.

## IPC

Inspect registered IPC for this config:

```sh
qs -c island ipc show
```

Toggle the island:

```sh
qs -c island ipc call island toggle
```

Open/close explicitly:

```sh
qs -c island ipc call island open
qs -c island ipc call island close
```

Target a known output name:

```sh
qs -c island ipc call island toggleOn DP-1
```

## Niri binding

Add this to the existing `binds {}` section in `~/.config/niri/config.kdl`:

```kdl
Mod+C repeat=false { spawn "qs" "-c" "island" "ipc" "call" "island" "toggle"; }
```

Niri passes the spawn arguments directly, so no shell wrapper is needed.

## Phase 0 multi-monitor IPC limitation

Pointer opening is output-correct because each `IslandSurface` receives its own `ShellScreen` from `Variants.modelData`. The generic IPC command cannot yet know Niri's focused output because focused-output IPC/event integration belongs to Phase 1.

For Phase 0, `island.toggle` behaves as follows:

1. if an island is expanded, close it;
2. otherwise open the most recently interacted output;
3. if there is no prior output, open the first live `Variants` instance.

`toggleOn <output-name>` is provided for deterministic testing. In Phase 1, the Niri service should supply `focusedOutput`, and the zero-argument toggle can route to that output.

## Window/input model

Each output receives one transparent `PanelWindow` spanning that output. It uses `ExclusionMode.Ignore`, so it never reserves an expanded exclusive zone.

The `QsWindow.mask` is dynamic:

- collapsed: only the island rectangle accepts pointer input; all other clicks pass through to applications;
- expanded: the full transparent host accepts input; its background `MouseArea` closes the island, while the island surface swallows inside clicks.

This keeps the visible island as one continuously morphing QML object rather than swapping to a separate popup window.

## Recommended checks

- `qs -c island` starts cleanly.
- one island appears on every connected output.
- hotplug creates/removes delegates through `Variants`.
- the time changes at minute boundaries.
- clicking an island expands that output and closes a previously expanded output.
- clicking outside the expanded island closes it.
- Escape closes it.
- `qs -c island ipc call island toggle` works.
- expanding/collapsing does not resize or reflow Niri windows.
- disconnecting an output does not leave orchestration stuck on that output.
- placeholder controls do not perform system actions.

## Next phase

Phase 1 should add a `services/Niri.qml` event-stream abstraction and replace `workspaceText: "02 · dev"` with per-output reactive workspace state. It should also use `Niri.focusedOutput` for the no-argument IPC toggle.
