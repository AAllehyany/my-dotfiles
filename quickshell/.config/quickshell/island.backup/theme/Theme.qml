pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Surface colors
    readonly property color island: "#E6171822"
    readonly property color tile: "#12FFFFFF"
    readonly property color tileHover: "#1FFFFFFF"
    readonly property color tileActive: "#2B8B5CF6"
    readonly property color foreground: "#F5F3FF"
    readonly property color secondary: "#B9B6C6"
    readonly property color muted: "#777382"
    readonly property color accent: "#A78BFA"
    readonly property color track: "#2AFFFFFF"

    // Typography
    readonly property string fontFamily: "sans-serif"
    readonly property int fontSizePrimary: 14
    readonly property int fontSizeSecondary: 12
    readonly property int fontWeightPrimary: Font.DemiBold

    // Spacing
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32

    // Radius
    readonly property int radiusIslandCollapsed: 20
    readonly property int radiusIslandExpanded: 28
    readonly property int radiusControl: 16
    readonly property int radiusSmall: 10

    // Dimensions
    readonly property int edgeGap: 12
    readonly property int collapsedWidth: 276
    readonly property int collapsedHeight: 40
    readonly property int expandedWidth: 468
    readonly property int expandedHeight: 330
    readonly property int headerHeight: 48

    // Motion
    readonly property int durationHover: 140
    readonly property int durationStandard: 210
    readonly property int durationIsland: 300
    readonly property int easingIsland: Easing.OutCubic
}
