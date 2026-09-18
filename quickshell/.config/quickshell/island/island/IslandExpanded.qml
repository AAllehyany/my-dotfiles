import QtQuick

import qs.island.navigation
import qs.island.pages
import qs.services

Item {
    id: root

    required property bool expanded

    property var wifiPasswordNetwork: null

    function openPage(pageId: string): void {
        switch (pageId) {
        case "audio":
            navigator.open(audioPage);
            break;

        case "wifi":
            navigator.open(wifiPage);
            break;

        case "bluetooth":
            navigator.open(bluetoothPage);
            break;

        default:
            console.warn("Unknown island page:", pageId);
            break;
        }
    }

    IslandNavigator {
        id: navigator

        anchors.fill: parent

        initialItem: controlCenterPage
    }

    Component {
        id: controlCenterPage

        ControlCenterPage {
            expanded: root.expanded

            onPageRequested: pageId => {
                root.openPage(pageId);
            }
        }
    }

    Component {
        id: audioPage

        AudioPage {
            onBackRequested: {
                navigator.goBack();
            }
        }
    }

    Component {
        id: wifiPage

        WifiPage {
            onBackRequested: {
                navigator.goBack();
            }

            onPasswordPageRequested: network => {
                root.wifiPasswordNetwork = network;
                navigator.open(wifiPasswordPage);
            }
        }
    }

Component {
    id: wifiPasswordPage

    WifiPasswordPage {
        network: root.wifiPasswordNetwork

        onBackRequested: {
            navigator.goBack();
        }

        onConnectRequested: (network, password) => {
            Wifi.connectWithPsk(network, password);
        }

        onConnectionSucceeded: {
            navigator.goBack();
        }
    }
}

    Component {
        id: bluetoothPage

        BluetoothPage {
            onBackRequested: {
                navigator.goBack();
            }
        }
    }

    onExpandedChanged: {
        if (!root.expanded) {
            navigator.reset();
            root.wifiPasswordNetwork = null;
        }
    }
}
