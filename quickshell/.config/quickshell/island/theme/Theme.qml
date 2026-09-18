pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Archive / terminal palette sampled from the existing Waybar direction.
    readonly property color island: "#FA050403"
    readonly property color islandRaised: "#FA0A0806"
    readonly property color tile: "#00000000"
    readonly property color tileHover: "#0FDDB746"
    readonly property color tileActive: "#18DDB746"
    readonly property color foreground: "#CDC8BC"
    readonly property color secondary: "#9A9283"
    readonly property color muted: "#6E675B"
    readonly property color dim: "#413B32"
    readonly property color accent: "#DDB746"
    readonly property color accentMuted: "#8A7130"
    readonly property color line: "#2B251D"
    readonly property color lineStrong: "#4A3E26"
    readonly property color track: "#2A241B"

    // Typography. Keep this generic so the user's configured monospace font can resolve.
    readonly property string fontFamily: "Mono Lisa"
    readonly property int fontSizePrimary: 11
    readonly property int fontSizeSecondary: 9
    readonly property int fontSizeMeta: 8
    readonly property int fontWeightPrimary: Font.Medium
    readonly property int letterSpacing: 0

    // Spacing
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space8: 8
    readonly property int space10: 10
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24
    readonly property int space32: 32

    // Geometry: intentionally closer to terminal/window chrome than mobile pills.
    readonly property int radiusIslandCollapsed: 4
    readonly property int radiusIslandExpanded: 6
    readonly property int radiusControl: 3
    readonly property int radiusSmall: 2
    readonly property int borderWidth: 1

    // Dimensions
    readonly property int edgeGap: 8
    readonly property int collapsedWidth: 306
    readonly property int collapsedHeight: 30
    readonly property int expandedWidth: 500
    readonly property int expandedHeight: 286
    readonly property int headerHeight: 36

    // Motion
    readonly property int durationHover: 120
    readonly property int durationStandard: 170
    readonly property int durationIsland: 250
    readonly property int easingIsland: Easing.OutCubic
}
