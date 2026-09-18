import QtQuick

import qs.island.components
import qs.services
import qs.theme

IslandPage {
    id: root

    title: "Audio Output"

    empty: outputList.count === 0
    emptyText: "NO AUDIO OUTPUTS"

    footer: outputFooter

    Component {
        id: outputFooter

        Item {

          implicitHeight: 24
          Text {

              text: outputList.count + " OUTPUT"
                  + (outputList.count === 1 ? "" : "S")

              color: Theme.muted
              font.family: Theme.fontFamily

              verticalAlignment: Text.AlignVCenter
          }
        }
    }

    ListView {
        id: outputList

        anchors.fill: parent

        clip: true
        spacing: Theme.space8

        model: Audio.outputs

        delegate: SelectionRow {
            required property var modelData

            width: outputList.width

            title: Audio.nodeLabel(modelData)
            selected: Audio.isDefaultOutput(modelData)
            subtitle: selected ? "DEFAULT" : ""

            onActivated: {
                Audio.setDefaultOutput(modelData);
            }
        }
    }
}
