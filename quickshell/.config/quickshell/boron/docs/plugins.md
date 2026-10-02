# Plugin protocol v1

Plugins are trusted local executables. Process separation protects responsiveness;
it is **not a sandbox**. Install code you trust. Plugins may use any language and
their own API clients; the Python SDK is a convenience, not a requirement.

## Discovery and configuration

Boron reads bundled manifests from `plugins/*/manifest.json` and user manifests
from `$XDG_DATA_HOME/boron/plugins/*/manifest.json` (normally
`~/.local/share/boron/plugins`). A plugin directory can contain its executable,
libraries, and assets.

User settings at `$XDG_CONFIG_HOME/boron/plugins.json` override the bundled
`plugins.json`. Only IDs in `enabled` run. For example:

```json
{
  "enabled": ["github", "example"],
  "config": {
    "github": {"hostname": "github.com"}
  }
}
```

Restart Boron after installing a plugin or editing this configuration. Duplicate
mode IDs/aliases, reserved built-in names, or unsupported protocol versions are
reported and skipped. Credentials should use the service's CLI/keyring or
environment, rather than being placed in configuration files or logs.

## Manifest

```json
{
  "protocolVersion": 1,
  "id": "example",
  "label": "Example",
  "aliases": ["ex"],
  "icon": "dialog-information",
  "command": ["python3", "plugin.py"]
}
```

Commands are argument arrays, run without a shell. The plugin directory is the
working directory. IDs/aliases should be lowercase words using letters, numbers,
and hyphens so they can be used as `@prefix ` shortcuts. `icon` is an optional
theme icon name for plugin metadata; result icons are URLs resolved by the plugin.

## Transport

UTF-8, one JSON object per line. Flush stdout after every response. Reserve stdout
for protocol messages; the supervisor discards stderr to avoid capturing secrets.
Each request has a unique `id`, `method`, and `params` object:

```json
{"id":1,"method":"initialize","params":{"protocolVersion":1,"config":{}}}
{"id":2,"method":"query","params":{"query":"hello","filter":""}}
{"id":3,"method":"activate","params":{"item":"hello","action":"open","values":{}}}
{"id":null,"method":"cancel","params":{"id":2}}
{"id":null,"method":"shutdown","params":{}}
```

Respond once per initialize/query/activate request, echoing its ID:

```json
{"id":1,"result":{}}
{"id":2,"result":{"items":[{"id":"hello","title":"Hello","subtitle":"Example result","actions":[{"id":"open","title":"Open"}]}]}}
{"id":3,"result":{"message":"Action completed"}}
```

Errors use `{"id":2,"error":"Human-readable explanation"}`. Cancel/shutdown
are notifications and need no response. The SDK cancels outstanding async work
on cancellation or shutdown. Plugins must clean up their child processes in
cancellation handlers.

Processes start on first use and initialize once. Query requests are debounced
200 ms; superseded requests receive cancellation, and stale responses are ignored.
Limits: 1 MiB per line, 200 results, 5 seconds for initialization, 15 seconds for
queries/read actions, 45 seconds for confirmed actions. Broken output, process
exit, or a deadline produces a mode-local error. Retry restarts that plugin.

## Results, actions, and forms

Items require unique stable string `id` and `title`. Optional fields are
`subtitle`, `icon` (a local/file/image URL), `disabled`, and an `actions` array.
Each action has `id`, `title`, and optional `disabled`. Enter runs the first action;
Ctrl+K shows all actions. Without actions, Enter sends action ID `open`.

A result may also supply `filters: [{"id":"all","label":"All"}]`; the selected
filter is returned with subsequent queries. Return an empty `items` array for
no results. Results replace the preceding list rather than appending to it.

Activation can return:

- `message`: inline outcome text.
- `openUrl`: an HTTP(S) URL to open externally, then close the launcher.
- `refresh: true`: re-query the active mode after completion.
- `prompt`: a host-rendered form or confirmation.

Example confirmation:

```json
{
  "id": 3,
  "result": {
    "prompt": {
      "title": "Confirm action",
      "description": "A concrete explanation of the action and target.",
      "submitLabel": "Apply",
      "destructive": true,
      "action": "confirm",
      "context": {"token":"one-use-server-side-reference"},
      "fields": [
        {"id":"method","label":"Method","type":"select","options":["first","second"],"value":"first"}
      ]
    }
  }
}
```

Fields support `text`, `password`, and `select`, plus `label`, `value`, and
`required`. Empty fields produce a confirmation without inputs. A form submission
sends another `activate` request for the same item and the prompt's action,
with context and field values merged into `values`, plus `confirmed: true`.
Escape dismisses the prompt without submitting. Plugin UI is structured data;
arbitrary QML is not loaded.

Put mutations behind confirmation and validate the confirmation inside the
plugin. GitHub uses a one-use token with a five-minute expiry, the repository/PR,
and the expected commit stored in its own process. Submitted confirmations run
once and are not canceled when the launcher closes. Deadlines/crashes during a
mutation report an uncertain outcome; never automatically repeat a write.

## Python SDK

Copy `features/plugins/sdk.py` alongside an external plugin or make it importable.
Implement `async handle(method, params)` and call `asyncio.run(serve(handle))`.
See `plugins/example/plugin.py` for a working minimal mode and
`plugins/github/plugin.py` for authentication, asynchronous subprocesses,
confirmation, and outcome reconciliation.

The SDK dispatches requests concurrently to support cancellation. Protect mutable
state as needed and never block the event loop with synchronous network calls.

## Built-in adapter contract

Built-in QML adapters provide `active`, `query`, `results`, `loading`,
`activate(row, actionId, values)`, and `cancel()`. Signals are
`notice(message)`, `closeRequested()`, and `promptRequested(prompt)`. Built-in
prompts carry `row` and `action` for dispatch. Register metadata in LauncherState;
keep integration behavior inside its feature directory.
