import QtQuick
import QtQuick.Layouts

import qs.island.components
import qs.theme
import QtQuick.Controls.Basic
IslandPage {
    id: root

    required property var network

    signal connectRequested(var network, string password)

    title: network ? network.name : "Wi-Fi"
    StackView.onActivated: {
        Qt.callLater(function() {
            passwordInput.forceActiveFocus();
        });
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space12

        Text {
            Layout.fillWidth: true

            text: "PSK // PASSWORD"
            color: Theme.muted

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            color: Theme.tile
            border.width: Theme.borderWidth
            border.color: passwordInput.activeFocus
                ? Theme.accent
                : Theme.line

            radius: Theme.radiusControl

            TextInput {
                id: passwordInput

                anchors.fill: parent
                anchors.leftMargin: Theme.space10
                anchors.rightMargin: Theme.space10

                verticalAlignment: TextInput.AlignVCenter

                color: Theme.foreground
                selectionColor: Theme.accent

                font.family: Theme.fontFamily

                echoMode: TextInput.Password
                passwordCharacter: "•"


                Keys.onReturnPressed: {
                    if (text.length > 0)
                        root.connectRequested(root.network, text);
                }
            }
        }

        Text {
            Layout.fillWidth: true

            text: "ENTER // CONNECT"

            color: passwordInput.text.length > 0
                ? Theme.accent
                : Theme.muted

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta

            MouseArea {
                anchors.fill: parent

                enabled: passwordInput.text.length > 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.connectRequested(
                        root.network,
                        passwordInput.text
                    );
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
