import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import qs.island.components
import qs.theme

IslandPage {
    id: root

    required property var network

    property string eapMethod: "peap"
    property string phase2Auth: "mschapv2"

    signal connectRequested(var network, var settings)

    title: network ? network.name : "Enterprise Wi-Fi"

    StackView.onActivated: {
        Qt.callLater(function() {
            identityInput.forceActiveFocus();
        });
    }

    function cycleEapMethod(): void {
        if (root.eapMethod === "peap") {
            root.eapMethod = "ttls";
            root.phase2Auth = "pap";
        } else {
            root.eapMethod = "peap";
            root.phase2Auth = "mschapv2";
        }
    }

    function cyclePhase2Auth(): void {
        if (root.eapMethod === "peap") {
            root.phase2Auth = "mschapv2";
            return;
        }

        root.phase2Auth =
            root.phase2Auth === "pap"
                ? "mschapv2"
                : "pap";
    }

    function submit(): void {
        if (identityInput.text.length === 0)
            return;

        if (passwordInput.text.length === 0)
            return;

        root.connectRequested(
            root.network,
            {
                eap: root.eapMethod,
                phase2Auth: root.phase2Auth,
                identity: identityInput.text,
                anonymousIdentity: anonymousIdentityInput.text,
                password: passwordInput.text
            }
        );
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space12

        Text {
            Layout.fillWidth: true

            text: "802.1X // ENTERPRISE"

            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8

            Text {
                text: "EAP"

                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMeta
            }

            Text {
                id: eapSelector

                Layout.fillWidth: true

                text: root.eapMethod.toUpperCase()

                color: eapMouse.containsMouse
                    ? Theme.accent
                    : Theme.foreground

                font.family: Theme.fontFamily

                MouseArea {
                    id: eapMouse

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.cycleEapMethod();
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8

            Text {
                text: "INNER"

                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMeta
            }

            Text {
                id: phase2Selector

                Layout.fillWidth: true

                text: root.phase2Auth.toUpperCase()

                color: phase2Mouse.containsMouse
                    ? Theme.accent
                    : Theme.foreground

                font.family: Theme.fontFamily

                MouseArea {
                    id: phase2Mouse

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.cyclePhase2Auth();
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true

            text: "IDENTITY"

            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            color: Theme.tile

            border.width: Theme.borderWidth
            border.color: identityInput.activeFocus
                ? Theme.accent
                : Theme.line

            radius: Theme.radiusControl

            TextInput {
                id: identityInput

                anchors.fill: parent
                anchors.leftMargin: Theme.space10
                anchors.rightMargin: Theme.space10

                verticalAlignment: TextInput.AlignVCenter

                color: Theme.foreground
                selectionColor: Theme.accent

                font.family: Theme.fontFamily
            }
        }

        Text {
            Layout.fillWidth: true

            text: "ANONYMOUS IDENTITY // OPTIONAL"

            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            color: Theme.tile

            border.width: Theme.borderWidth
            border.color: anonymousIdentityInput.activeFocus
                ? Theme.accent
                : Theme.line

            radius: Theme.radiusControl

            TextInput {
                id: anonymousIdentityInput

                anchors.fill: parent
                anchors.leftMargin: Theme.space10
                anchors.rightMargin: Theme.space10

                verticalAlignment: TextInput.AlignVCenter

                color: Theme.foreground
                selectionColor: Theme.accent

                font.family: Theme.fontFamily
            }
        }

        Text {
            Layout.fillWidth: true

            text: "PASSWORD"

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
                    root.submit();
                }
            }
        }

        Text {
            Layout.fillWidth: true

            text: "ENTER // CONNECT"

            color:
                identityInput.text.length > 0
                && passwordInput.text.length > 0
                    ? Theme.accent
                    : Theme.muted

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMeta

            MouseArea {
                anchors.fill: parent

                enabled:
                    identityInput.text.length > 0
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
