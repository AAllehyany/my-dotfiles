import QtQuick
import QtQuick.Shapes
import "../../theme"

// The lock, drawn as vectors on a 512×512 grid so it stays sharp at any size.
// `open` lifts and tilts the shackle.
Item {
    id: root
    property color color: Theme.text
    property bool open: false
    implicitWidth: 512
    implicitHeight: 512

    Item {
        width: 512
        height: 512
        scale: root.width / 512
        transformOrigin: Item.TopLeft

        Shape {
            id: shackle
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transform: [
                Rotation { origin.x: 176; origin.y: 240; angle: root.open ? -14 : 0
                    Behavior on angle { NumberAnimation { duration: 220; easing.type: Easing.OutBack } } },
                Translate { y: root.open ? -58 : 0
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack } } }
            ]
            ShapePath {
                strokeColor: root.color
                strokeWidth: 40
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                startX: 176; startY: 240
                PathLine { x: 176; y: 168 }
                PathArc { x: 336; y: 168; radiusX: 80; radiusY: 80; direction: PathArc.Clockwise }
                PathLine { x: 336; y: 240 }
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            // Body with the keyhole cut out (even-odd fill makes the inner contour a hole).
            ShapePath {
                fillColor: root.color
                strokeWidth: -1
                fillRule: ShapePath.OddEvenFill
                PathRectangle { x: 104; y: 224; width: 304; height: 240; radius: 14 }
                PathMove { x: 244; y: 343.5 }
                PathArc { x: 268; y: 343.5; radiusX: 30; radiusY: 30; useLargeArc: true; direction: PathArc.Clockwise }
                PathLine { x: 268; y: 400 }
                PathLine { x: 244; y: 400 }
                PathLine { x: 244; y: 343.5 }
            }
        }
    }
}
