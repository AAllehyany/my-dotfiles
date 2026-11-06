import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../theme"

// The session lock. lock() finds the focused monitor (it gets the password field), then locks
// every monitor. Only a correct password unlocks; there is deliberately no other way.
Scope {
    id: root
    readonly property bool locked: session.locked

    function lock() {
        if (session.locked || focused.pending) return;
        lockState.reset();
        wallpaperSource.refresh();
        focused.query();
    }

    PamAuthenticator { id: pam }
    WallpaperSource { id: wallpaperSource }
    LockState {
        id: lockState
        authenticator: pam
        active: session.locked
        onUnlocked: session.locked = false
    }
    FocusedOutput {
        id: focused
        onResolved: name => {
            const screens = Quickshell.screens;
            const known = screens.some(s => s.name === name);
            lockState.inputScreen = known ? name : (screens.length ? screens[0].name : "");
            session.locked = true;
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
            }
        }
    }
}
