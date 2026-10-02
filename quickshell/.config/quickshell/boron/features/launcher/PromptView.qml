import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

FocusScope {
    id: root
    required property var prompt
    signal submitted(var values)
    signal canceled()
    implicitHeight: content.implicitHeight + 32
    function submit() {
        const values = {};
        for (let i = 0; i < fields.count; i++) {
            const item = fields.itemAt(i);
            if (item.modelData.required && !item.value.trim()) { item.focusInput(); return; }
            values[item.modelData.id] = item.value;
        }
        submitted(values);
    }
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 14
        Text { text: root.prompt.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        Text { text: root.prompt.description || ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        Repeater {
            id: fields
            model: root.prompt.fields || []
            delegate: ColumnLayout {
                id: field
                required property var modelData
                required property int index
                Layout.fillWidth: true
                property string value: modelData.type === "select" ? select.currentText : input.text
                function focusInput() { if (modelData.type === "select") select.forceActiveFocus(); else input.forceActiveFocus(); }
                Text { text: field.modelData.label || field.modelData.id; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12 }
                TextField {
                    id: input
                    visible: field.modelData.type !== "select"
                    Layout.fillWidth: true
                    text: field.modelData.value || ""
                    echoMode: field.modelData.type === "password" ? TextInput.Password : TextInput.Normal
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    selectByMouse: true
                    background: Rectangle { color: Theme.raised; border.color: input.activeFocus ? Theme.accent : Theme.border }
                    onAccepted: root.submit()
                    Component.onCompleted: { if (field.index === 0 && visible) forceActiveFocus(); }
                }
                ComboBox {
                    id: select
                    visible: field.modelData.type === "select"
                    Layout.fillWidth: true
                    model: field.modelData.options || []
                    font.family: Theme.font
                    palette.buttonText: Theme.text
                    palette.text: Theme.text
                    palette.button: Theme.raised
                    palette.base: Theme.raised
                    palette.highlight: Theme.selection
                    background: Rectangle { color: Theme.raised; border.color: select.activeFocus ? Theme.accent : Theme.border }
                    Component.onCompleted: { currentIndex = Math.max(0, model.indexOf(field.modelData.value)); if (field.index === 0 && visible) forceActiveFocus(); }
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            ActionButton { text: "Cancel"; onClicked: root.canceled(); Component.onCompleted: { if (!(root.prompt.fields || []).length) forceActiveFocus(); } }
            ActionButton { text: root.prompt.submitLabel || "Confirm"; destructive: !!root.prompt.destructive; visible: !root.prompt.displayOnly; onClicked: root.submit() }
        }
    }
}
