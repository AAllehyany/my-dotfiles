# Command Center (Phase 1)

This is a new, self-contained Quickshell configuration. It does not import the
`island` configurations. Phase 1 deliberately uses representative in-memory data:
the service boundaries exist, but no button runs a system command yet.

## Layout and boundaries

- `shell.qml` is the persistent, minimal composition root and owns the IPC handler.
- `theme/Theme.qml` is the single source for semantic color, type, spacing, radius,
  border, shadow, opacity, animation, icon, row, and panel tokens.
- `core/` owns state and the built-in mode registry. It knows mode metadata, not
  mode-specific behavior.
- `models/` describes the shared result and action shapes.
- `features/commandcenter/` composes the window, search, picker, results, action
  view, and keyboard policy.
- Each other `features/<mode>/` directory owns one mode adapter and any custom UI.
- `services/` contains intentionally inert integration boundaries. Future service
  implementations belong here; visual components must not invoke system APIs.
- `components/` contains presentation-only primitives.

## Start and toggle

Start one persistent process (for example from a session startup entry):

```sh
qs -p ~/.config/quickshell/command-center/shell.qml
```

Toggle its surface from another process:

```sh
qs ipc call commandCenter toggle
```

The IPC target also offers `open` and `close` commands. Applications is selected
by default, and opening the surface transfers keyboard focus immediately.

## Niri binding

`Mod+Space` is available in the repository's current Niri configuration: its only
occurrences are commented example layout bindings. Either copy the command from
`niri-binding.kdl` into the existing `binds { ... }` block:

```kdl
Mod+Space { spawn-sh "qs ipc call commandCenter toggle"; }
```

or include the standalone file at top level, adjusting the path for your dotfile
deployment:

```kdl
include "../quickshell/command-center/niri-binding.kdl"
```

Do not both include it and copy it. If `Mod+Space` later becomes active elsewhere,
choose another chord rather than defining two Niri actions for the same chord.

## Keyboard controls

| Key | Behavior |
| --- | --- |
| `Up` / `Down` or `Ctrl+P` / `Ctrl+N` | Move through results, wrapping at either end |
| `Enter` | Run the default action, or open the action view when choices exist |
| `Tab` / `Shift+Tab` | Cycle forward/backward through modes |
| `Escape` | Leave the action level, then clear the query, then close the surface |

Typing edits the query in searchable modes. System is an example of a custom
interactive view; list modes use the common result list.

## Theme customization

Edit `theme/Theme.qml`, rather than placing literal styling values in features.
Tokens cover the palette and typography as well as spacing, radii, borders,
shadow/opacity values, motion timing, icon sizes, row heights, and panel size.

## Add a built-in mode

1. Create `features/<name>/<Name>Mode.qml`.
2. Implement the adapter contract: `modeId`, `supportsSearch`, `customViewUrl`,
   `results(query)`, and `activate(result, actionId)`.
3. For a list/search mode, return objects matching `models/Result.qml` (including
   action objects matching `ResultAction.qml`) and leave `customViewUrl` empty.
4. For an interactive mode, point `customViewUrl` to a local component. The view
   may consume state, but all system integration must go through `services/`.
5. Add only its id, label, icon, and resolved adapter URL to `core/ModeRegistry.qml`.
   The window requires no mode-specific branch.

This contract permits both mode styles while keeping launch behavior, service
calls, and custom interaction details outside the command-center window.
