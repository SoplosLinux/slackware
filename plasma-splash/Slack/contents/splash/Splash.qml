/*
 *   Soplos Linux - Slackware Plasma splash screen
 *   Compatible with KDE Plasma 6 / Qt 6
 *   License: GPLv2+
 */

import QtQuick

Image {
    id: root
    source: "images/background.png"
    fillMode: Image.PreserveAspectCrop

    property int stage

    onStageChanged: {
        if (stage === 1) {
            introAnimation.running = true
            contentFade.from = 0
            contentFade.to = 1
            contentFade.running = true
        }
        if (stage === 4) {
            contentFade.from = 1
            contentFade.to = 0
            contentFade.running = true
            pauseTimer.start()
        }
    }

    // Content: logo centrado
    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        NumberAnimation {
            id: contentFade
            target: content
            property: "opacity"
            duration: 500
            easing.type: Easing.InOutQuad
        }

        TextMetrics {
            id: units
            text: "M"
            property int gridUnit: boundingRect.height
        }

        Image {
            id: logo
            property real size: units.gridUnit * 12
            anchors.centerIn: parent
            source: "images/logo.png"
            sourceSize.width: size
            sourceSize.height: size
        }
    }

    // Barra de progreso inferior
    Image {
        id: topRect
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height
        source: "images/rectangle.svg"

        Rectangle {
            y: 232
            radius: 0
            anchors {
                bottom: parent.bottom
                bottomMargin: 50
                horizontalCenter: parent.horizontalCenter
            }
            height: 2
            width: height * 170
            color: "#ffffff"

            Rectangle {
                id: progressBar
                radius: 1
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: (parent.width / 6) * Math.max(0, stage - 0.01)
                color: "#4862ae"
                Behavior on width {
                    PropertyAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    // Animación de entrada del panel
    SequentialAnimation {
        id: introAnimation
        running: false
        PropertyAnimation {
            property: "y"
            target: topRect
            to: ((root.height / 3) * 2) - 170
            duration: 2000
            easing.type: Easing.InOutBack
            easing.overshoot: 1.0
        }
    }

    Timer {
        id: pauseTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: {
            outFade.running = true
        }
    }

    NumberAnimation {
        id: outFade
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: 500
        running: false
    }
}
