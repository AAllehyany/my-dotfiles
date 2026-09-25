pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property QtObject palette: QtObject {
        readonly property color background: "#0D0B11"
        readonly property color surface: "#17131E"
        readonly property color surfaceRaised: "#211A2A"

        readonly property color text: "#F2EDF7"
        readonly property color textMuted: "#A79EAE"

        readonly property color border: "#342A40"

        readonly property color accent: "#A78BFA"
        readonly property color accentWarm: "#E2B65A"

        readonly property color danger: "#EF6A78"
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
        readonly property int xxl: 32
    }

    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 18
        readonly property int xl: 24
    }

    readonly property QtObject typography: QtObject {
        readonly property string family: "Mono Lisa"

        readonly property int small: 12
        readonly property int body: 14
        readonly property int title: 18
        readonly property int heading: 24
    }

    readonly property QtObject motion: QtObject {
        readonly property int fast: 120
        readonly property int normal: 180
        readonly property int slow: 260
    }
}
