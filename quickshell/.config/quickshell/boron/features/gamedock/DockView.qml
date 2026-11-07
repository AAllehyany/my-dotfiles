import QtQuick
import Quickshell.Services.Mpris
import "../../theme"

// The game dock's contents: recording / streaming status, now playing, and system stats.
Rectangle {
    id: root
    required property var recording   // RecordingStatus
    required property var stats       // SystemStats
    property var player: null         // MprisPlayer or null
    readonly property real pad: Math.round(Math.min(width, height) * 0.08)
    // Three sections and two dividers: 4 gaps and 2 one-pixel lines come out of the width.
    readonly property real sectionSpace: width - 2 * pad - 4 * pad - 2
    readonly property real scale: Math.max(0.6, Math.min(1.4, height / 564))

    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88)
    border.width: 1
    border.color: Theme.border

    component Label: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Math.round(14 * root.scale)
        font.letterSpacing: 4
    }

    component Meter: Item {
        id: meter
        property real value: 0   // 0–100
        property color tone: Theme.accent
        implicitHeight: 8
        Rectangle { anchors.fill: parent; color: Theme.selection }
        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, meter.value)) / 100
            height: parent.height
            color: meter.value >= 90 ? Theme.danger : meter.tone
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }

    component ControlButton: Rectangle {
        id: button
        property string glyph: ""
        property bool available: true
        signal clicked()
        width: Math.round(80 * root.scale); height: Math.round(60 * root.scale)
        color: area.containsMouse && available ? Theme.selection : "transparent"
        border.width: 1
        border.color: Theme.border
        opacity: available ? 1 : 0.35
        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Math.round(24 * root.scale)
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.available
            onClicked: button.clicked()
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.pad

        // ---------- recording / streaming ----------
        Column {
            objectName: "dockRecording"
            width: root.sectionSpace * 0.40
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(18 * root.scale)

            Label { text: "CAPTURE" }

            Row {
                spacing: 16
                Rectangle {
                    id: dot
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(26 * root.scale); height: width; radius: width / 2
                    color: root.recording.recording ? Theme.danger : Theme.selection
                    SequentialAnimation on opacity {
                        running: root.recording.recording && !root.recording.recordPaused
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !root.recording.connected ? root.recording.offlineText
                        : root.recording.recordPaused ? "PAUSED"
                        : root.recording.recording ? "REC" : "NOT RECORDING"
                    color: root.recording.recording && !root.recording.recordPaused ? Theme.danger : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Math.round(30 * root.scale)
                    font.letterSpacing: 4
                }
            }

            Text {
                objectName: "dockRecordTime"
                text: root.recording.clock(root.recording.recordMs)
                color: root.recording.recording ? Theme.text : Theme.selection
                font.family: Theme.font
                font.pixelSize: Math.round(132 * root.scale)
                font.letterSpacing: 4
            }

            Row {
                spacing: 14
                visible: root.recording.connected
                Rectangle {
                    width: live.implicitWidth + 20; height: live.implicitHeight + 10
                    color: root.recording.streaming ? Theme.danger : "transparent"
                    border.width: 1
                    border.color: root.recording.streaming ? Theme.danger : Theme.border
                    Text {
                        id: live
                        anchors.centerIn: parent
                        text: root.recording.reconnecting ? "RECONNECTING" : "LIVE"
                        color: root.recording.streaming ? Theme.background : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Math.round(20 * root.scale)
                        font.letterSpacing: 3
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.recording.streaming ? root.recording.clock(root.recording.streamMs) : "not streaming"
                    color: root.recording.streaming ? Theme.text : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Math.round(34 * root.scale)
                }
            }
        }

        Rectangle { width: 1; height: parent.height * 0.8; anchors.verticalCenter: parent.verticalCenter; color: Theme.border }

        // ---------- now playing ----------
        Column {
            objectName: "dockMedia"
            width: root.sectionSpace * 0.34
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(16 * root.scale)

            Label { text: root.player ? "NOW PLAYING · " + (root.player.identity || "").toUpperCase() : "NOW PLAYING" }

            Text {
                width: parent.width
                text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"
                color: root.player ? Theme.text : Theme.muted
                font.family: Theme.font
                font.pixelSize: Math.round(44 * root.scale)
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: !!(root.player && root.player.trackArtist)
                text: root.player ? root.player.trackArtist : ""
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Math.round(26 * root.scale)
                elide: Text.ElideRight
            }

            Item { width: 1; height: 8 }

            Row {
                spacing: 10
                visible: !!root.player
                ControlButton {
                    glyph: "◀◀"
                    available: !!(root.player && root.player.canGoPrevious)
                    onClicked: root.player.previous()
                }
                ControlButton {
                    glyph: root.player && root.player.isPlaying ? "▮▮" : "▶"
                    available: !!(root.player && root.player.canTogglePlaying)
                    onClicked: root.player.togglePlaying()
                }
                ControlButton {
                    glyph: "▶▶"
                    available: !!(root.player && root.player.canGoNext)
                    onClicked: root.player.next()
                }
            }
        }

        Rectangle { width: 1; height: parent.height * 0.8; anchors.verticalCenter: parent.verticalCenter; color: Theme.border }

        // ---------- system ----------
        Column {
            objectName: "dockStats"
            width: root.sectionSpace * 0.26
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(12 * root.scale)

            Label { text: "GPU" }
            Row {
                spacing: 12
                Text {
                    text: root.stats.hasGpu ? Math.round(root.stats.gpuPercent) + "%" : "n/a"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Math.round(52 * root.scale)
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: root.stats.gpuTemp >= 0 ? Math.round(root.stats.gpuTemp) + "°C" : ""
                    color: root.stats.gpuTemp >= 85 ? Theme.danger : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Math.round(26 * root.scale)
                }
            }
            Meter { width: parent.width; value: root.stats.gpuPercent; visible: root.stats.hasGpu }
            Text {
                visible: root.stats.hasGpu
                text: (root.stats.vramUsed / 1024).toFixed(1) + " / " + (root.stats.vramTotal / 1024).toFixed(1) + " GB"
                    + (root.stats.fanPercent >= 0 ? "   fan " + Math.round(root.stats.fanPercent) + "%" : "")
                    + (root.stats.powerWatts >= 0 ? "   " + Math.round(root.stats.powerWatts) + " W" : "")
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Math.round(18 * root.scale)
            }

            Item { width: 1; height: 10 }

            Label { text: "CPU" }
            Row {
                spacing: 12
                Text {
                    text: Math.round(root.stats.cpuPercent) + "%"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Math.round(52 * root.scale)
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: root.stats.cpuTemp >= 0 ? Math.round(root.stats.cpuTemp) + "°C" : ""
                    color: root.stats.cpuTemp >= 90 ? Theme.danger : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Math.round(26 * root.scale)
                }
            }
            Meter { width: parent.width; value: root.stats.cpuPercent }
        }
    }
}
