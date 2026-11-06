import QtQuick
import Quickshell.Io
import "../../core/Frecency.js" as Frecency

// Launch counts for frecency ranking. An empty path keeps history in memory only (tests).
Item {
    id: root
    property string path: ""
    property var history: ({})
    FileView {
        id: file
        path: root.path
        printErrors: false
        onLoaded: root.history = Frecency.parse(text())
    }
    function record(id) { history = Frecency.record(history, id, Date.now()); save(); }
    function forget(id) { history = Frecency.forget(history, id); save(); }
    function save() { if (path) file.setText(JSON.stringify(history)); }
}
