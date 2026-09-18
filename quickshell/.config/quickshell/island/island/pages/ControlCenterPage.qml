import QtQuick
import QtQuick.Layouts

import qs.island.components
import qs.theme
import qs.services


Item {
    id: root

    required property bool expanded

    signal pageRequested(string pageId)

    enabled: root.expanded
    visible: opacity > 0.001

    Column {
        width: parent.width
        spacing: Theme.space12

        Text {
            width: parent.width

            text: "CONNECTIVITY // SYSTEM LINKS"

            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta
        }

        RowLayout {
            width: parent.width
            spacing: Theme.space8

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 54

                ControlTile {
                    anchors.fill: parent

                    title: "Wi-Fi"

                    subtitle: !Wifi.available
                        ? "NO ADAPTER"
                        : !Wifi.enabled
                            ? "OFF"
                            : Wifi.connectedName.length > 0
                                ? Wifi.connectedName
                                : "AVAILABLE"

                    iconText: "NET"
                    enabled: true
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.pageRequested("wifi");
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 54

                ControlTile {
                    anchors.fill: parent

                    title: "Bluetooth"

                    subtitle: !Bluetooth.available
                        ? "NO ADAPTER"
                        : !Bluetooth.enabled
                            ? "OFF"
                            : "AVAILABLE"

                    iconText: "BT"
                    enabled: true
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.pageRequested("bluetooth");
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1

            color: Theme.line
        }

        SliderControl {
            width: parent.width

            label: Audio.currentOutputName
            labelInteractive: Audio.available

            iconText: Audio.muted ? "MUT" : "VOL"

            value: Audio.volume
            interactive: Audio.available

            progressColor: Audio.muted
                ? Theme.accentMuted
                : Theme.accent

            onValueChangedByUser: value => {
                Audio.setVolume(value);
            }

            onIconActivated: {
                Audio.toggleMute();
            }

            onLabelActivated: {
                root.pageRequested("audio");
            }
        }

        SliderControl {
            width: parent.width

            label: "Brightness"
            iconText: "LUX"

            value: 0.55
            interactive: false
        }

        Rectangle {
            width: parent.width
            height: 1

            color: Theme.line
        }

        Rectangle {
            width: parent.width
            height: 42

            radius: Theme.radiusControl

            color: Theme.tile

            border.width: Theme.borderWidth
            border.color: Theme.line

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.space10
                anchors.verticalCenter: parent.verticalCenter

                text: "PWR // BATTERY"

                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSecondary
                font.weight: Theme.fontWeightPrimary
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Theme.space10
                anchors.verticalCenter: parent.verticalCenter

                text: "PHASE 4 // BALANCED"

                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMeta
            }
        }
    }
}
