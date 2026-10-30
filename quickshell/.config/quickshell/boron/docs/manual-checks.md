# Session acceptance checks

Automated checks cover matching, routing, state transitions, plugin supervision,
mock Bluetooth prompts, mock Wi-Fi operations, and fake GitHub API responses.
These checks cover the remaining real-session behavior:

- Open on each monitor, including fractional scaling; verify focus returns to
  the previous application on Escape/outside click. Unplug a monitor and reopen.
- Search and launch a graphical and a terminal application; try a desktop action.
- Verify the query position stays fixed as results grow, navigation scrolls the
  list, and all form controls are reachable with Tab.
- Exercise a tray application's nested and checkable menu, then close the tray
  app while its menu is open.
- With a disposable tray app selected, press Ctrl+Q and cancel; verify it stays
  running. Repeat and confirm Quit, then verify the app exits. Also try Ctrl+Q
  from its additional actions and an app without a Quit/Exit command.
- Confirm a power prompt can be canceled. Only execute Sleep, Restart, or Shutdown
  when you intend to perform that operation.
- Connect/disconnect a saved Wi-Fi network; try an incorrect password on a new
  personal network, then correct it through Connect with password. Toggle radios
  and verify absent/blocked hardware feedback.
- Pair a Bluetooth device that requires a passkey or confirmation; cancel a
  prompt, retry, connect, disconnect, and forget. Verify discovery stops when
  leaving the Bluetooth view.
- After authenticating `gh`, search a repository, issue, and PR. Verify the merge
  confirmation and cancel it. Perform a merge only for a PR you actually intend
  to merge, then verify the reported immediate/queued/scheduled outcome.
- Disable networking during GitHub search, then reconnect and Retry. Confirm
  Applications remains usable while a remote service fails.
- Follow the README's notification-daemon handover and verify the session bus
  owner is Boron's `qs` process. Send notifications from a real application;
  check image/icon fallback, default-action clicks, explicit dismissal, and
  additional actions in Ctrl+K. Inspect the competing-daemon message with Mako
  active before switching over.
- Send a burst of notifications on each focused output. Confirm at most three
  appear per output, newest at the bottom right, no toast exceeds three seconds,
  and pointer hover or replacements do not extend its deadline. Type in another
  application while arrivals appear and click the gaps between cards: neither
  keyboard focus nor unrelated desktop clicks should be intercepted.
- Verify fractional scaling, narrow outputs, and unplugging an output with
  active toasts. Check expired toasts remain in history, offscreen entries stay
  unread until scrolled into view, arrivals stay in the center while it is open,
  Clear all works during search, and QML reloads do not replay old notifications.

Hardware and authenticated-service checks are intentionally not simulated as
successful real integrations in the test report.
