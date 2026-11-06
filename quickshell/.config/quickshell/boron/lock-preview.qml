// Lock screen preview in a normal window. Never locks the session: the password is checked by a fake
// (type "boron" to see the unlock, anything else to see a failure). Press Escape twice with an empty field to close.
//   qs -p lock-preview.qml
// BORON_LOCK_CAPTURE=1 plays a scripted run instead and saves /tmp/boron-lock-*.png frames.
import QtQuick
import Quickshell
import QtTest 1.2
import "features/lock"

ShellRoot {
    id: preview
    readonly property bool capture: Quickshell.env("BORON_LOCK_CAPTURE") === "1"
    property int tick: 0
    property int escapes: 0

    QtObject {
        id: fake
        signal succeeded()
        signal failed(string message)
        property string pending: ""
        function start(password) { pending = password; answer.restart(); }
    }
    Timer {
        id: answer
        interval: 900
        onTriggered: fake.pending === "boron" ? fake.succeeded() : fake.failed("")
    }

    WallpaperSource { id: wallpaper }
    LockState {
        id: state
        authenticator: fake
        active: true
        inputScreen: "preview"
        onUnlocked: preview.capture ? null : resetLater.restart()
    }
    Timer { id: resetLater; interval: 800; onTriggered: state.reset() }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1600
        implicitHeight: 1000
        color: "black"
        LockScreen {
            id: screen
            anchors.fill: parent
            state: state
            screenName: "preview"
            wallpaper: wallpaper.path
            Keys.onEscapePressed: event => {
                if (state.buffer) { state.clear(); preview.escapes = 0; }
                else if (++preview.escapes >= 2) Qt.quit();
            }
            TestEvent { id: keys }
        }
    }

    function save(name) { screen.grabToImage(result => result.saveToFile("/tmp/boron-lock-" + name + ".png")); }
    function typeText(text) { for (const c of text) keys.keyClickChar(c, Qt.NoModifier, 0); }

    Timer {
        interval: 50; repeat: true; running: preview.capture
        onTriggered: {
            switch (preview.tick++) {
            case 30: preview.save("idle"); break;
            case 32: preview.typeText("abc"); preview.save("typing"); break;
            case 40: keys.keyClick(Qt.Key_Return, Qt.NoModifier, 0); break;
            case 46: preview.save("checking"); break;
            case 59: preview.save("failed"); break;
            case 100: preview.typeText("boron"); keys.keyClick(Qt.Key_Return, Qt.NoModifier, 0); break;
            case 127: preview.save("unlocking"); break;
            case 140: console.warn("LOCK PREVIEW SAVED"); Qt.quit();
            }
        }
    }
}
