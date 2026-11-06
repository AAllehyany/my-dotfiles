import QtQuick
import Quickshell
import "../../theme"

// Shared lock-screen state: the typed password, the auth phase, and the glitch levels every
// monitor draws from. No visuals; `authenticator` is PamAuthenticator or a test fake.
Scope {
    id: root
    required property var authenticator
    property bool active: false

    property string buffer: ""
    property string phase: "idle" // idle | checking | failed | unlocking
    property string message: ""
    property string inputScreen: ""
    property bool shackleOpen: false
    property real fade: 1
    property real reveal: 0   // 0 → 1 on unlock: the blurred desktop behind the lock clears

    // Glitch: idle shimmer + keystroke pulse + random spikes + checking jitter.
    readonly property real baseline: 0.06
    property real pulse: 0
    property real spike: 0
    property real checkLevel: 0
    property real settleLevel: 0
    readonly property real glitch: phase === "unlocking" ? settleLevel
        : Math.min(1, baseline + pulse + spike + checkLevel)
    property color tintColor: Theme.accent
    property real flash: 0

    readonly property bool busy: phase === "checking" || phase === "unlocking"

    property SystemClock clock: SystemClock { precision: SystemClock.Minutes; enabled: root.active }
    readonly property string dateText: clock.date.toLocaleString(Qt.locale("en_US"), "ddd dd MMM yyyy").toUpperCase()
    readonly property string timeText: clock.date.toLocaleString(Qt.locale("en_US"), "HH:mm")

    signal shake()
    signal unlocked()

    function reset() {
        unlockSequence.stop();
        failSequence.stop();
        buffer = "";
        phase = "idle";
        message = "";
        shackleOpen = false;
        fade = 1;
        reveal = 0;
        pulse = 0;
        spike = 0;
        checkLevel = 0;
        flash = 0;
    }

    function keyPulse() {
        pulseAnim.restart();
        flashAnim.restart();
    }

    function type(text) {
        if (busy || !text) return;
        if (phase === "failed") { failSequence.stop(); phase = "idle"; message = ""; flash = 0; }
        buffer += text;
        keyPulse();
    }

    function backspace() {
        if (busy || !buffer) return;
        buffer = buffer.slice(0, -1);
        keyPulse();
    }

    function clear() {
        if (busy || !buffer) return;
        buffer = "";
        keyPulse();
    }

    function submit() {
        if (busy || !buffer) return;
        phase = "checking";
        message = "";
        const password = buffer;
        authenticator.start(password);
    }

    // Shared by every monitor's surface, so typing works wherever the compositor sends keys.
    function handleKey(event) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { submit(); return true; }
        if (event.key === Qt.Key_Backspace) { if (ctrl) clear(); else backspace(); return true; }
        if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_U)) { clear(); return true; }
        if (ctrl || (event.modifiers & Qt.MetaModifier)) return false;
        if (event.text && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            type(event.text);
            return true;
        }
        return false;
    }

    Connections {
        target: root.authenticator
        function onSucceeded() {
            if (root.phase !== "checking") return;
            root.settleLevel = root.glitch;
            root.buffer = "";
            root.message = "";
            root.phase = "unlocking";
            unlockSequence.restart();
        }
        function onFailed(message) {
            if (root.phase !== "checking") return;
            root.buffer = "";
            root.phase = "failed";
            root.message = message || "wrong password";
            root.shake();
            failSequence.restart();
        }
    }

    NumberAnimation { id: pulseAnim; target: root; property: "pulse"; from: 0.7; to: 0; duration: 260; easing.type: Easing.OutQuad }
    SequentialAnimation {
        id: flashAnim
        ScriptAction { script: root.tintColor = Theme.accent }
        NumberAnimation { target: root; property: "flash"; from: 0.55; to: 0; duration: 220; easing.type: Easing.OutQuad }
    }

    // Idle: a short spike every 1.5–4 s.
    Timer {
        id: spikeTimer
        running: root.active && root.phase === "idle"
        interval: 2500
        onTriggered: {
            spikeUp.to = 0.25 + Math.random() * 0.15;
            spikeHold.duration = 80 + Math.random() * 70;
            spikeAnim.restart();
            interval = 1500 + Math.random() * 2500;
            restart();
        }
    }
    SequentialAnimation {
        id: spikeAnim
        NumberAnimation { id: spikeUp; target: root; property: "spike"; to: 0.3; duration: 30 }
        PauseAnimation { id: spikeHold; duration: 100 }
        NumberAnimation { target: root; property: "spike"; to: 0; duration: 60 }
    }

    // Checking: jitter between 0.5 and 0.8 until PAM answers.
    Timer {
        running: root.active && root.phase === "checking"
        interval: 70
        repeat: true
        onTriggered: root.checkLevel = 0.42 + Math.random() * 0.3
        onRunningChanged: if (!running) root.checkLevel = 0
    }

    // Wrong password: a red burst at full strength, then back to idle.
    SequentialAnimation {
        id: failSequence
        ScriptAction { script: { flashAnim.stop(); pulseAnim.stop(); root.tintColor = Theme.danger; root.flash = 0.85; root.pulse = 0.94; } }
        PauseAnimation { duration: 380 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulse"; to: 0; duration: 300; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "flash"; to: 0; duration: 300; easing.type: Easing.OutQuad }
        }
        PauseAnimation { duration: 1200 }
        ScriptAction { script: { if (root.phase === "failed") { root.phase = "idle"; root.message = ""; } } }
    }

    // Correct password: settle to a clean lock, lift the shackle, then fade it while the blur clears.
    SequentialAnimation {
        id: unlockSequence
        NumberAnimation { target: root; property: "settleLevel"; to: 0; duration: 260; easing.type: Easing.OutCubic }
        ScriptAction { script: root.shackleOpen = true }
        PauseAnimation { duration: 320 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "fade"; to: 0; duration: Theme.motion * 2; easing.type: Easing.InQuad }
            NumberAnimation { target: root; property: "reveal"; to: 1; duration: 520; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: root.unlocked() }
    }
}
