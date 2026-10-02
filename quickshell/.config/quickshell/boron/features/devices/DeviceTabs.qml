import QtQuick
import QtQuick.Controls
import "../../theme"

TabBar {
    id: root
    required property var sections
    required property string activeSection
    readonly property int activeIndex: Math.max(0, sections.findIndex(tab => tab.id === activeSection))
    signal sectionRequested(string section)
    signal searchRequested()
    signal resultsRequested()
    signal textEntered(string text)

    implicitHeight: 34
    implicitWidth: contentWidth
    spacing: 6
    background: Item {}
    currentIndex: activeIndex

    function focusSelected(reason) {
        const selectedTab = buttons.itemAt(activeIndex);
        if (selectedTab) selectedTab.forceActiveFocus(reason === undefined ? Qt.ShortcutFocusReason : reason);
    }
    function hasTabFocus() {
        const selectedTab = buttons.itemAt(activeIndex);
        return selectedTab !== null && selectedTab.activeFocus;
    }
    function select(index) {
        if (!enabled || !sections.length) return;
        const next = (index + sections.length) % sections.length;
        sectionRequested(sections[next].id);
        focusSelected();
    }
    Repeater {
        id: buttons
        model: root.sections
        TabButton {
            id: button
            required property var modelData
            required property int index
            objectName: "deviceTab-" + modelData.id
            text: modelData.label
            width: Math.max(90, label.implicitWidth + 28)
            height: root.implicitHeight
            checked: index === root.activeIndex
            // One tab stop for the strip; arrows move within it.
            focusPolicy: checked ? Qt.StrongFocus : Qt.ClickFocus
            onClicked: root.select(index)
            contentItem: Text {
                id: label
                text: button.text
                font.family: Theme.font
                font.pixelSize: Theme.small
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: button.checked ? Theme.accent : Theme.text
            }
            background: Rectangle {
                color: button.checked || button.hovered ? Theme.selection : Theme.raised
                border.color: button.activeFocus ? Theme.accent : Theme.border
                border.width: button.activeFocus ? 2 : 1
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 2
                    color: Theme.accent
                    visible: button.checked
                }
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (event.modifiers !== Qt.NoModifier && event.modifiers !== Qt.ShiftModifier) return;
                switch (event.key) {
                case Qt.Key_Left: root.select(root.activeIndex - 1); break;
                case Qt.Key_Right: root.select(root.activeIndex + 1); break;
                case Qt.Key_Home: root.select(0); break;
                case Qt.Key_End: root.select(root.sections.length - 1); break;
                case Qt.Key_Backtab: root.searchRequested(); break;
                case Qt.Key_Tab:
                    if (event.modifiers & Qt.ShiftModifier) root.searchRequested(); else root.resultsRequested();
                    break;
                case Qt.Key_Up: root.searchRequested(); break;
                case Qt.Key_Down: case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                    root.resultsRequested(); break;
                default:
                    if (!event.text || event.text.charCodeAt(0) < 32) return;
                    root.textEntered(event.text);
                }
                event.accepted = true;
            }
        }
    }
}
