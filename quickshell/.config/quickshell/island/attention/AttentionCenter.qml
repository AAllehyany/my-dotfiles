pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var current: null

    readonly property bool active: root.current !== null

    function publish(event) {
        if (event === null || event === undefined)
            return;

        const duration = event.duration ?? 900;

        root.current = {
            key: event.key ?? "",
            kind: event.kind ?? "info",
            label: event.label ?? "",
            valueText: event.valueText ?? "",
            data: event.data ?? null,
            duration: duration
        };

        clearTimer.interval = duration;
        clearTimer.restart();
    }

    function dismiss() {
        clearTimer.stop();
        root.current = null;
    }

    Timer {
        id: clearTimer

        repeat: false

        onTriggered: {
            root.current = null;
        }
    }
}
