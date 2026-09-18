import QtQuick
import qs.attention

QtObject {
    id: root

    required property var value

    property bool enabled: true

    // Receives the new value and returns an attention event.
    property var eventFactory: value => null

    property bool initialized: false
    property var previousValue: undefined

    function rememberCurrentValue() {
        root.previousValue = root.value;
        root.initialized = true;
    }

    function handleValueChanged() {
        const next = root.value;

        // First observation establishes our baseline.
        //
        // Starting Quickshell should not itself generate
        // an "attention" event.
        if (!root.initialized) {
            root.rememberCurrentValue();
            return;
        }

        if (next === root.previousValue)
            return;

        root.previousValue = next;

        if (!root.enabled)
            return;

        const event = root.eventFactory(next);

        if (event !== null && event !== undefined)
            AttentionCenter.publish(event);
    }

    onValueChanged: {
        root.handleValueChanged();
    }

    onEnabledChanged: {
        // Becoming enabled establishes a fresh baseline.
        // We don't want service startup to look like a user event.
        if (root.enabled)
            root.rememberCurrentValue();
    }

    Component.onCompleted: {
        root.rememberCurrentValue();
    }
}
