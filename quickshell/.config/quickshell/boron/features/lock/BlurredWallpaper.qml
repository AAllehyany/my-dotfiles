import QtQuick
import QtQuick.Effects
import "../../theme"

// A heavily blurred, dimmed copy of the desktop wallpaper. The image loads at about a third of
// the screen's size first, which makes the blur stronger and cheaper. Plain Theme.background if there's no image.
Item {
    id: root
    property string path: ""
    clip: true

    Rectangle { anchors.fill: parent; color: Theme.background }

    Image {
        id: image
        // Oversized so the blur's soft edges fall off-screen.
        anchors.fill: parent
        anchors.margins: -80
        source: root.path ? "file://" + root.path.split("/").map(encodeURIComponent).join("/") : ""
        sourceSize.width: Math.max(480, Math.round(root.width / 3))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
    }

    MultiEffect {
        anchors.fill: image
        source: image
        visible: image.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: -0.25
    }

    Rectangle { anchors.fill: parent; color: Theme.background; opacity: 0.55 }
}
