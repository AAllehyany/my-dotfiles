import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import qs.island.components
import qs.theme

IslandPage {
    id: root

    required property var network

    property bool connecting: false
    property string errorText: ""

    signal connectRequested(var network, string password)
    signal connectionSucceeded()

    title: network ? network.name : "Wi-Fi"

    StackView.onActivated: {
        Qt.callLater(function() {
            passwordInput.forceActiveFocus();
        });
    }

    Connections {
        target: root.network
        enabled: root.network !== null

        function onConnectionFailed(reason) {
            root.connecting = false;
            root.errorText = "CONNECTION FAILED";

            passwordInput.selectAll();

            Qt.callLater(function() {
                passwordInput.forceActiveFocus();
            });
        }

        function onConnectedChanged() {
            if (!root.network || !root.network.connected)
                return;

            root.connecting = false;
            root.errorText = "";
            root.connectionSucceeded();
        }
    }

    function submit(): void {
        if (root.connecting || passwordInput.text.length === 0)
            return;

        root.errorText = "";
        root.connecting = true;

        root.connectRequested(
            root.network,
            passwordInput.text
        );
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
            border.color:
                root.errorText.length > 0
                    ? Theme.accent
                    : passwordInput.activeFocus
                        ? Theme.accent
                        : Theme.line

            radius: Theme.radiusControl

            TextInput {
                id: passwordInput

                anchors.fill: parent
                anchors.leftMargin: Theme.space10
                anchors.rightMargin: Theme.space10

                enabled: !root.connecting

                verticalAlignment: TextInput.AlignVCenter

                color: Theme.foreground
                selectionColor: Theme.accent

                font.family: Theme.fontFamily

                echoMode: TextInput.Password
                passwordCharacter: "•"

                Keys.onReturnPressed: {
                    root.submit();
                }
            }
        }

        Text {
            Layout.fillWidth: true

            visible: root.errorText.length > 0

            text: root.errorText

            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta
        }

        Text {
            Layout.fillWidth: true

            text: root.connecting
                ? "CONNECTING..."
                : "ENTER // CONNECT"

            color:
                root.connecting
                    ? Theme.muted
                    : passwordInput.text.length > 0
                        ? Theme.accent
                        : Theme.muted

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta

            MouseArea {
                anchors.fill: parent

                enabled:
                    !root.connecting
                    && passwordInput.text.length > 0

                hoverEnabled: true

                cursorShape: enabled
                    ? Qt.PointingHandCursor
                    : Qt.ArrowCursor

                onClicked: {
                    root.submit();
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
