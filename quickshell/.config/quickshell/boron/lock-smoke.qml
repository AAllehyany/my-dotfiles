// Lock screen state and parsing checks with a fake authenticator. Never locks the session or touches PAM.
import QtQuick
import Quickshell
import QtTest 1.2
import "core"
import "features/lock"
import "theme"

ShellRoot {
    id: test
    property int tick: 0
    property int shakes: 0
    property int unlocks: 0

    QtObject {
        id: fake
        signal succeeded()
        signal failed(string message)
        property string last: ""
        property int starts: 0
        function start(password) { last = password; starts++; }
    }
    LockState {
        id: state
        authenticator: fake
        active: true
        inputScreen: "A"
        onShake: test.shakes++
        onUnlocked: test.unlocks++
    }
    WallpaperSource { id: wallpaper }
    FocusedOutput { id: focused }

    Window {
        visible: true; width: 1600; height: 900
        Row {
            anchors.fill: parent
            LockScreen { id: screenA; width: 800; height: 900; state: state; screenName: "A" }
            LockScreen {
                id: screenB; width: 800; height: 900; state: state; screenName: "B"
                TestEvent { id: keys }
            }
        }
    }

    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    function check(condition, message) {
        if (!condition) { ticks.stop(); throw new Error("LOCK SMOKE FAILED at tick " + tick + ": " + message); }
    }
    function press(key) { check(keys.keyClick(key, Qt.NoModifier, 0), "key delivered"); }
    function typeText(text) { for (const c of text) keys.keyClickChar(c, Qt.NoModifier, 0); }

    Timer {
        id: ticks
        interval: 100; running: true; repeat: true
        onTriggered: {
            switch (test.tick++) {
            case 2:
                // Parsing: swaybg arguments from /proc (one per line) and both compositors' focus JSON.
                check(wallpaper.parse("swaybg\n-i\n/home/me/my walls/lab.png\n-m\nfill\n") === "/home/me/my walls/lab.png", "swaybg -i path with spaces");
                check(wallpaper.parse("swaybg\n--image=/w/a.png\n") === "/w/a.png", "swaybg --image=");
                check(wallpaper.parse("swaybg\n-i/w/b.png\n") === "/w/b.png", "swaybg -iPATH");
                check(wallpaper.parse("swaybg\n-c\n#000000\n") === "", "swaybg without an image");
                check(wallpaper.parse("") === "", "swaybg not running");
                check(focused.parse('{"name":"HDMI-A-3","make":"x"}') === "HDMI-A-3", "niri focused output");
                check(focused.parse('[{"name":"DP-1","focused":false},{"name":"HDMI-A-1","focused":true}]') === "HDMI-A-1", "hyprland focused monitor");
                check(focused.parse("null") === "" && focused.parse("oops") === "", "bad focus output falls back");

                // Layout: date everywhere, password field only on the input monitor.
                check(/^[A-Z]{3} \d\d [A-Z]{3} \d{4}$/.test(state.dateText), "date format: " + state.dateText);
                check(/^\d\d:\d\d$/.test(state.timeText), "time format: " + state.timeText);
                check(find(screenA, "lockInput").visible && find(screenA, "lockDate").visible, "input monitor shows field and date");
                check(!find(screenB, "lockInput").visible && find(screenB, "lockDate").visible && find(screenB, "lockIcon").visible, "other monitor shows only lock and date");

                // Keys typed on the monitor without the field still reach the shared password.
                check(state.phase === "idle" && Math.abs(state.glitch - state.baseline) < 0.01, "idle glitch at baseline");
                screenB.forceActiveFocus();
                typeText("ab");
                check(state.buffer === "ab", "typing from the other monitor: " + state.buffer);
                check(state.glitch > 0.4 && state.flash > 0.3, "keystroke glitch pulse");
                press(Qt.Key_Backspace);
                check(state.buffer === "a", "backspace");
                press(Qt.Key_Escape);
                check(state.buffer === "", "escape clears");
                press(Qt.Key_Return);
                check(state.phase === "idle" && fake.starts === 0, "empty password is not submitted");

                // Wrong password.
                typeText("wrong");
                press(Qt.Key_Return);
                check(state.phase === "checking" && fake.last === "wrong" && fake.starts === 1, "submit starts auth");
                typeText("x");
                press(Qt.Key_Return);
                check(state.buffer === "wrong" && fake.starts === 1, "input ignored while checking");
                fake.failed("");
                check(state.phase === "failed" && state.buffer === "" && state.message === "wrong password", "failure clears and explains");
                check(test.shakes === 1 && state.flash > 0.5 && Qt.colorEqual(state.tintColor, Theme.danger) && state.glitch > 0.9, "failure: shake + red burst");
                check(test.unlocks === 0, "no unlock on failure");
                fake.succeeded();
                check(state.phase === "failed" && test.unlocks === 0, "late success outside checking is ignored");
                break;
            case 25:
                check(state.phase === "idle" && state.message === "", "failure returns to idle");
                // Correct password.
                typeText("right");
                press(Qt.Key_Return);
                fake.succeeded();
                check(state.phase === "unlocking" && state.buffer === "", "success starts unlocking");
                typeText("z");
                check(state.buffer === "", "no typing while unlocking");
                break;
            case 40:
                check(state.shackleOpen && state.fade === 0 && state.glitch === 0, "clean icon, shackle open, faded");
                check(state.reveal === 1, "blur cleared");
                check(test.unlocks === 1, "unlocked once");
                state.reset();
                check(state.phase === "idle" && !state.shackleOpen && state.fade === 1 && state.reveal === 0, "reset for the next lock");
                console.warn("LOCK SMOKE PASSED");
                Qt.quit();
            }
        }
    }
}
