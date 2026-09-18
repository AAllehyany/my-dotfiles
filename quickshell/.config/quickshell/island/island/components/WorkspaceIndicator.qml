import QtQuick
import qs.theme

Text {
    text: String(parent && parent.workspaceText !== undefined ? parent.workspaceText : "")
          .replace(" · ", " // ")
          .toUpperCase()
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizePrimary
    font.weight: Theme.fontWeightPrimary
    font.letterSpacing: Theme.letterSpacing
    verticalAlignment: Text.AlignVCenter
}
