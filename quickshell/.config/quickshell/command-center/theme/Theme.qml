pragma Singleton
import QtQuick

QtObject {
    readonly property color surface: "#171922"
    readonly property color surfaceRaised: "#20232e"
    readonly property color surfaceSelected: "#303747"
    readonly property color textPrimary: "#f2f4f8"
    readonly property color textMuted: "#a7adbb"
    readonly property color accent: "#8aadf4"
    readonly property color danger: "#ed8796"
    readonly property color border: "#3a4050"

    readonly property string fontFamily: "sans-serif"
    readonly property int fontBody: 15
    readonly property int fontSmall: 12
    readonly property int fontTitle: 20
    readonly property int fontWeightStrong: Font.DemiBold

    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 18
    readonly property int spaceXl: 24
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 16
    readonly property int borderWidth: 1
    readonly property int shadowSize: 20
    readonly property real shadowOpacity: 0.35
    readonly property real disabledOpacity: 0.45
    readonly property int animationFast: 100
    readonly property int animationNormal: 180
    readonly property int iconSm: 16
    readonly property int iconMd: 22
    readonly property int iconLg: 30
    readonly property int rowHeight: 52
    readonly property int modeRowHeight: 40
    readonly property int panelWidth: 680
    readonly property int panelHeight: 560
}
