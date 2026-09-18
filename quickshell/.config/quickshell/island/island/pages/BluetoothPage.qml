import QtQuick
import QtQuick.Layouts

import qs.island.components
import qs.services
import qs.theme

IslandPage {
    id: root

    title: "Bluetooth Devices"

    empty:
        !Bluetooth.available
        || !Bluetooth.enabled
        || deviceList.count === 0

    emptyText:
        !Bluetooth.available
            ? "NO BLUETOOTH ADAPTER"
            : !Bluetooth.enabled
                ? "BLUETOOTH OFF"
                : Bluetooth.discovering
                    ? "SCANNING..."
                    : "NO DEVICES FOUND"

    footer: bluetoothFooter

    Component.onDestruction: {
        Bluetooth.setDiscovering(false);
    }

    Component {
        id: bluetoothFooter

        Item {
            implicitHeight: 24

            RowLayout {
                anchors.fill: parent
                spacing: Theme.space8

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    text: deviceList.count + " DEVICE"
                        + (deviceList.count === 1 ? "" : "S")

                    color: Theme.muted
                    font.family: Theme.fontFamily

                    elide: Text.ElideRight
                }

                Text {
                    id: scanButton

                    enabled:
                        Bluetooth.available
                        && Bluetooth.enabled

                    text: Bluetooth.discovering
                        ? "SCAN // STOP"
                        : "SCAN"

                    color:
                        Bluetooth.discovering
                            ? Theme.accent
                            : scanMouse.containsMouse
                                && scanButton.enabled
                                    ? Theme.accent
                                    : Theme.muted

                    font.family: Theme.fontFamily

                    MouseArea {
                        id: scanMouse

                        anchors.fill: parent

                        enabled: scanButton.enabled
                        hoverEnabled: true

                        cursorShape: scanButton.enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked: {
                            Bluetooth.setDiscovering(
                                !Bluetooth.discovering
                            );
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durationHover
                        }
                    }
                }

                Text {
                    id: bluetoothToggle

                    enabled: Bluetooth.available

                    text: Bluetooth.enabled
                        ? "BT // ON"
                        : "BT // OFF"

                    color:
                        bluetoothToggleMouse.containsMouse
                        && bluetoothToggle.enabled
                            ? Theme.accent
                            : Theme.muted

                    font.family: Theme.fontFamily

                    MouseArea {
                        id: bluetoothToggleMouse

                        anchors.fill: parent

                        enabled: bluetoothToggle.enabled
                        hoverEnabled: true

                        cursorShape: bluetoothToggle.enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked: {
                            if (Bluetooth.discovering)
                                Bluetooth.setDiscovering(false);

                            Bluetooth.setEnabled(!Bluetooth.enabled);
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
        id: deviceList

        anchors.fill: parent

        clip: true
        spacing: Theme.space8

        model: Bluetooth.devices

        delegate: Rectangle {
            required property var modelData

            width: deviceList.width
            height: 40

            color: "transparent"
            radius: 2

            border.width: 1
            border.color:
                modelData.connected || deviceMouse.containsMouse
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

                            text:
                                (modelData.connected ? "> " : "  ")
                                + modelData.name

                            color: modelData.connected
                                ? Theme.accent
                                : Theme.foreground

                            font.family: Theme.fontFamily

                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter

                            visible:
                                modelData.paired
                                && !modelData.connected

                            text: "PAIRED"

                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeMeta
                        }
                    }

                    MouseArea {
                        id: deviceMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (modelData.connected) {
                                Bluetooth.disconnectDevice(modelData);
                                return;
                            }

                            if (modelData.paired) {
                                Bluetooth.connectDevice(modelData);
                                return;
                            }

                            Bluetooth.pairDevice(modelData);
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Theme.space8

                    visible: modelData.paired

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
                            Bluetooth.forgetDevice(modelData);
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
