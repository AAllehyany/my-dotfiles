import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../theme"

// The session lock. lock() snapshots every monitor and finds the focused one (it gets the password
// field), then locks every monitor. Only a correct password unlocks; there is deliberately no other way.
Scope {
    id: root
    readonly property bool locked: session.locked
    property bool pending: false
    property bool focusReady: false
    property bool snapshotReady: false

    function lock() {
        if (session.locked || pending) return;
        pending = true;
        focusReady = false;
        snapshotReady = false;
        lockState.reset();
        wallpaperSource.refresh();
        desktopSnapshot.capture();
        focused.query();
    }

    function finishLocking() {
        if (!pending || !focusReady || !snapshotReady) return;
        pending = false;
        session.locked = true;
    }

    PamAuthenticator { id: pam }
    WallpaperSource { id: wallpaperSource }
    DesktopSnapshot {
        id: desktopSnapshot
        onFinished: { root.snapshotReady = true; root.finishLocking(); }
    }
    LockState {
        id: lockState
        authenticator: pam
        active: session.locked
        onUnlocked: {
            session.locked = false;
            releaseSnapshot.restart();
        }
    }
    // Drop the frames once the lock surfaces are gone, so no copy of the screen stays in memory.
    Timer { id: releaseSnapshot; interval: 1000; onTriggered: if (!session.locked) desktopSnapshot.clear() }
    FocusedOutput {
        id: focused
        onResolved: name => {
            const screens = Quickshell.screens;
            const known = screens.some(s => s.name === name);
            lockState.inputScreen = known ? name : (screens.length ? screens[0].name : "");
            root.focusReady = true;
            root.finishLocking();
        }
    }

    WlSessionLock {
        id: session
        WlSessionLockSurface {
            id: surface
            color: Theme.background
            LockScreen {
                anchors.fill: parent
                state: lockState
                screenName: surface.screen ? surface.screen.name : ""
                wallpaper: wallpaperSource.path
                snapshot: surface.screen ? desktopSnapshot.frames[surface.screen.name] || "" : ""
            }
        }
    }
}
