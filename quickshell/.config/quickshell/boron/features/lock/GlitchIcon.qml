import QtQuick
import "../../theme"

// The lock glyph run through shaders/glitch.frag. The glyph renders into a padded hidden texture
// so displaced slices and color fringes can spill past the icon's edges without clipping.
Item {
    id: root
    property real intensity: 0
    property color tint: Theme.accent
    property real flash: 0
    property bool open: false
    property bool running: true
    readonly property real pad: width * 0.2
    implicitWidth: 512
    implicitHeight: 512

    Item {
        id: canvas
        width: root.width + root.pad * 2
        height: root.height + root.pad * 2
        // Hidden by the ShaderEffectSource (hideSource); `visible: false` would leave the texture empty.
        LockGlyph {
            x: root.pad
            y: root.pad
            width: root.width
            height: root.height
            open: root.open
        }
    }

    ShaderEffectSource {
        id: texture
        sourceItem: canvas
        hideSource: true
        live: true
        smooth: true
    }

    ShaderEffect {
        id: effect
        x: -root.pad
        y: -root.pad
        width: canvas.width
        height: canvas.height
        property variant source: texture
        property real time: 0
        property real intensity: root.intensity
        property real flash: root.flash
        property color tint: root.tint
        fragmentShader: Qt.resolvedUrl("shaders/glitch.frag.qsb")
    }

    FrameAnimation {
        running: root.running && root.visible
        onTriggered: effect.time += frameTime
    }
}
