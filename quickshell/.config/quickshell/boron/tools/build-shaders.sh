#!/usr/bin/env bash
# Compiles the QML shaders. Qt loads the .qsb files, so run this after editing any .frag.
set -euo pipefail
cd "$(dirname "$0")/.."
QSB=$(command -v qsb || command -v qsb-qt6 || echo /usr/lib64/qt6/bin/qsb)
[ -x "$QSB" ] || [ -x "$(command -v "$QSB")" ] || { echo "qsb not found: install qt6-qtshadertools (Fedora) or qt6-shadertools (Arch)" >&2; exit 1; }
for frag in features/lock/shaders/*.frag; do
  "$QSB" --qt6 -o "$frag.qsb" "$frag"
  echo "built $frag.qsb"
done
