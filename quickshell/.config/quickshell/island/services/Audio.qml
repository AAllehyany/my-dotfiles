pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink

  readonly property bool available: 
    root.sink !== null && root.sink.ready && root.sink.audio !== null

  readonly property real volume: root.available ? root.sink.audio.volume : 0.0

  readonly property bool muted: root.available ? root.sink.audio.muted : false
  readonly property var outputs: outputModel

  readonly property string currentOutputName:
  root.nodeLabel(root.sink)
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }
  ScriptModel {
      id: outputModel

      values: Pipewire.nodes.values.filter(node =>
          node.audio !== null
          && node.isSink
          && !node.isStream
      )
  }
  function nodeLabel(node): string {
      if (!node)
          return "";

      if (node.description && node.description.length > 0)
          return node.description;

      if (node.nickname && node.nickname.length > 0)
          return node.nickname;

      return node.name;
  }

  function isDefaultOutput(node): bool {
      if (!node || !Pipewire.defaultAudioSink)
          return false;

      return node.id === Pipewire.defaultAudioSink.id;
  }

  function setDefaultOutput(node): void {
      if (!node)
          return;

      Pipewire.preferredDefaultAudioSink = node;
  }
  function setVolume(value: real): void {

    if(!root.available) {
      return;
    }

    const clamped = Math.max(0.0, Math.min(1.0, value));
    root.sink.audio.volume = clamped;
  }

  function toggleMute(): void {
    if(!root.available) return;

    root.sink.audio.muted = !root.sink.audio.muted;
  }
}
