import QtQuick
import QtQuick.Layouts

import qs.island.components
import qs.services
import qs.theme

IslandPage {
    id: root
    signal passwordPageRequested(var network)
    title: "Wi-Fi Networks"

    empty:
        !Wifi.available
        || !Wifi.hardwareEnabled
        || !Wifi.enabled
        || networkList.count === 0

    emptyText:
        !Wifi.available
            ? "NO WI-FI DEVICE"
            : !Wifi.hardwareEnabled
                ? "WI-FI HARDWARE DISABLED"
                : !Wifi.enabled
                    ? "WI-FI OFF"
                    : "NO NETWORKS FOUND"

    footer: wifiFooter

    Component.onCompleted: {
        Wifi.setScanning(Wifi.enabled);
    }

    Component.onDestruction: {
        Wifi.setScanning(false);
    }

    Connections {
        target: Wifi

        function onEnabledChanged() {
            Wifi.setScanning(Wifi.enabled);
        }
    }

    Component {
        id: wifiFooter

        Item {
            implicitHeight: 24

            RowLayout {
                anchors.fill: parent
                spacing: Theme.space8

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    text: networkList.count + " NETWORK"
                        + (networkList.count === 1 ? "" : "S")

                    color: Theme.muted
                    font.family: Theme.fontFamily

                    elide: Text.ElideRight
                }

                Text {
                    id: wifiToggle

                    enabled:
                        Wifi.available
                        && Wifi.hardwareEnabled

                    text: Wifi.enabled
                        ? "WIFI // ON"
                        : "WIFI // OFF"

                    color:
                        wifiToggleMouse.containsMouse
                        && wifiToggle.enabled
                            ? Theme.accent
                            : Theme.muted

                    font.family: Theme.fontFamily

                    MouseArea {
                        id: wifiToggleMouse

                        anchors.fill: parent

                        enabled: wifiToggle.enabled
                        hoverEnabled: true

                        cursorShape: wifiToggle.enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked: {
                            Wifi.setEnabled(!Wifi.enabled);
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationHover
                        }
                    }
                }
            }
        }
    }

    ListView {
        id: networkList

        anchors.fill: parent

        clip: true
        spacing: Theme.space8

        model: Wifi.networks

delegate: Rectangle {
    required property var modelData

    width: networkList.width
    height: 40

    color: "transparent"
    radius: 2

    border.width: 1
    border.color:
        modelData.connected || networkMouse.containsMouse
            ? Theme.accent
            : Theme.line

    RowLayout {
        anchors.fill: parent

        spacing: Theme.space8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space12
                anchors.rightMargin: Theme.space8

                spacing: Theme.space8

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter

                    text: (modelData.connected ? "> " : "  ")
                        + modelData.name
                        + (Wifi.needsPsk(modelData) ? " // LOCK" : "")

                    color: modelData.connected
                        ? Theme.accent
                        : Theme.foreground

                    font.family: Theme.fontFamily

                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                SignalStrength {
                    Layout.alignment: Qt.AlignVCenter

                    strength: modelData.signalStrength

                    activeColor: modelData.connected
                        ? Theme.accent
                        : Theme.foreground
                }
            }

            MouseArea {
                id: networkMouse

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (modelData.connected) {
                        Wifi.disconnectNetwork(modelData);
                        return;
                    }

                    if (Wifi.needsPsk(modelData)) {
                        root.passwordPageRequested(modelData);
                        return;
                    }

                    Wifi.connectNetwork(modelData);
                }
            }
        }

        Rectangle {
            id: forgetButton

            Layout.preferredWidth: 64
            Layout.preferredHeight: 26
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Theme.space8

            visible: modelData.known

            color: forgetMouse.containsMouse
                ? Theme.tile
                : "transparent"

            border.width: 1
            border.color: forgetMouse.containsMouse
                ? Theme.accent
                : Theme.line

            radius: 2

            Text {
                anchors.centerIn: parent

                text: "FORGET"

                color: forgetMouse.containsMouse
                    ? Theme.accent
                    : Theme.muted

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMeta
            }

            MouseArea {
                id: forgetMouse

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    Wifi.forgetNetwork(modelData);
                }
            }
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.durationHover
        }
    }
}
    }
}
