pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
    property string activeMode: "applications"
    property int navigationDepth: 0
    property string query: ""
    property int selectedIndex: 0

    function open() { visible = true }
    function close() {
        visible = false
        query = ""
        selectedIndex = 0
        navigationDepth = 0
    }
    function toggle() { visible ? close() : open() }
    function selectMode(modeId) {
        activeMode = modeId
        query = ""
        selectedIndex = 0
        navigationDepth = 0
    }
    function enter() { navigationDepth += 1 }
    function handleEscape() {
        if (navigationDepth > 0) navigationDepth -= 1
        else if (query.length > 0) query = ""
        else close()
    }
    function moveSelection(delta, count) {
        if (count <= 0) { selectedIndex = 0; return }
        selectedIndex = (selectedIndex + delta + count) % count
    }
}
