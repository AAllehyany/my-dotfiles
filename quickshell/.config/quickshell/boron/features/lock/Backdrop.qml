import QtQuick
import QtQuick.Effects
import "../../theme"

// The lock's background: this monitor's desktop as it was when locking, blurred, dimmed and slightly
// zoomed. `clarity` going 0 → 1 on unlock clears all three, so the last frame is the desktop itself.
// Without a snapshot it shows the swaybg wallpaper blurred instead (loaded at a third of the screen
// size, which makes the blur stronger and cheaper), and plain Theme.background if there's neither.
Item {
    id: root
    property string snapshot: ""
    property string wallpaper: ""
    property real clarity: 0
    readonly property bool hasSnapshot: snapshotImage.status === Image.Ready
    // The wallpaper never matches the desktop, so it stays hazy; the lock just fades on unlock.
    readonly property real haze: hasSnapshot ? 1 - clarity : 1
    readonly property Image current: hasSnapshot ? snapshotImage : wallpaperImage
    clip: true

    Rectangle { anchors.fill: parent; color: Theme.background }

    Image {
        id: snapshotImage
        anchors.fill: parent
        source: root.snapshot
        fillMode: Image.Stretch
        cache: false
        visible: false
    }

    Image {
        id: wallpaperImage
        // Oversized so the blur's soft edges fall off-screen.
        anchors.fill: parent
        anchors.margins: -80
        source: !root.snapshot && root.wallpaper
            ? "file://" + root.wallpaper.split("/").map(encodeURIComponent).join("/") : ""
        sourceSize.width: Math.max(480, Math.round(root.width / 3))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
    }

    MultiEffect {
        anchors.fill: root.current
        source: root.current
        visible: root.current.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: root.haze
        blurMax: 64
        // The snapshot is full resolution, so it needs a wider blur to look like the wallpaper did.
        blurMultiplier: root.hasSnapshot ? 2 : 0
        saturation: -0.25 * root.haze
        // The zoom hides the blur's soft edges and makes the unlock feel like it settles into place.
        scale: root.hasSnapshot ? 1 + 0.04 * root.haze : 1
    }

    Rectangle { anchors.fill: parent; color: Theme.background; opacity: 0.55 * root.haze }
}
