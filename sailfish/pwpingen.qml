// -*- css -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.2

ApplicationWindow {
    cover: Component {
        CoverBackground {
            Label {
                anchors.centerIn: parent
                text: "Password\nand\nPin\nGenerator"
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    initialPage: Component { // the only page !
        Page {
            PageHeader {
               id: header
               width: parent.width
               title: "Password and Pin Generator"
            }
            PasswordField {
                id: input
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                label: ""
                placeholderText: "•••••••••••• ↲"
                //font.family: "Courier New"
                //font.pixelSize: 40 // FIXME
                focus: true
                inputMethodHints: Qt.ImhNoPredictiveText|Qt.ImhNoAutoUppercase
                passwordEchoMode: TextInput.Password
                showEchoModeToggle: true
                maximumLength: 99
                acceptableInput: text.length >= 4
                EnterKey.enabled: text.length >= 4
                EnterKey.onClicked: python.pwpingen_call(text)
                //softwareInputPanelEnabled: true
                //Keys.onPressed: {
                //    if (event.key == Qt.Key_Return ||
                //        event.key == Qt.Key_Enter) {
                //        python.pwpingen_call(text)
                //    }
                //}
                // v.v quite a few internet searches and trial & errors v.v //
                onFocusChanged: { Qt.inputMethod.show(); focus = true }
                //FocusChanged: { console.log(focus); forceActiveFocus() }
            }
            Label {
                id: passwd
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.left: parent.left
                anchors.top: input.bottom
                text: ""
                font.family: "Courier New"
                font.pixelSize: 40 // FIXME
            }
            Label {
                id: p3wd
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.left: parent.left
                anchors.top: passwd.bottom
                anchors.topMargin: 10
                text: ""
                font.family: "Courier New"
                font.pixelSize: 40 // FIXME
            }
            Label {
                id: p2wd
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.left: parent.left
                anchors.top: p3wd.bottom
                anchors.topMargin: 10
                text: ""
                font.family: "Courier New"
                font.pixelSize: 40 // FIXME
            }
            Label {
                id: pin
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.left: parent.left
                anchors.top: p2wd.bottom
                anchors.topMargin: 10
                text: ""
                font.family: "Courier New"
                font.pixelSize: 40 // FIXME
            }
            Button {
                text: "Clear"
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                //width: parent.width / 3
                preferredWidth: Theme.buttonWidthExtraSmall
                //onReleased: { focus = false }
                onClicked: {
                    input.text = ""
                    passwd.text = pin.text = p2wd.text = p3wd.text = ""
                    //input.forceActiveFocus()
                    //input.focus = true
                }
            }
            Python {
                id: python
                Component.onCompleted: {
                    addImportPath(Qt.resolvedUrl('.'));
                    setHandler('update', function(pws, p3s, p2s, pins) {
                        passwd.text = pws
                        p3wd.text = p3s
                        p2wd.text = p2s
                        pin.text = pins
                    })
                    importNames('pwpingen', [ 'pwpingen_call' ], function() {})
                }
                function pwpingen_call(text) {
                    call('pwpingen_call', [ text ], function() {});
                }
            }
        }
    }
}
