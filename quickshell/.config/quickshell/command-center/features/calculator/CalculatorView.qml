import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../core"
import "../../theme"

ColumnLayout {
    spacing: Theme.spaceLg
    Label { text: "Calculator"; font.pixelSize: Theme.fontTitle; font.weight: Theme.fontWeightStrong }
    Label {
        Layout.fillWidth: true
        text: CommandCenterState.query.length ? CommandCenterState.query : "Type an expression in the search field"
        color: CommandCenterState.query.length ? Theme.textPrimary : Theme.textMuted
        font.pixelSize: Theme.fontTitle
    }
    Label { text: "Evaluation will be supplied by CalculatorService."; color: Theme.textMuted }
}
