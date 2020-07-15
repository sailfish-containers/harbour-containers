import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent

        Column {
            spacing: Theme.paddingLarge
            width: parent.width
            height: parent.height

            PageHeader {
                id: pageHeader
                title: qsTr("About")

                Rectangle {
                    anchors.fill: parent
                    color: Theme.highlightBackgroundColor
                    opacity: 0.15
                }
            }
            Image {
                source: "../images/harbour-containers.png"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: "<b>harbour-containers</b>"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                text: qsTr("<i> A Linux containers manager for SailfishOS </i>")
                anchors.horizontalCenter: parent.horizontalCenter

            }
            ButtonLayout {

                Button {
                    text: "github"
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/sailfish-containers")
                    }
                }
                Button {
                    text: "wiki"
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/sailfish-containers/lxc-templates-desktop/wiki")
                    }
                }
                Button {
                    text: qsTr("donate")
                    onClicked: {
                        Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MRYB9SATJKZ9N&source=url")
                    }
                }
            }
            Label {
                wrapMode: Label.WordWrap
                //width: parent.width - Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("<i>Inspired by Preflex's (TMO \"Xwayland victory!\") and elros34's (Github \"sailfish_linux_chroot\") awesome work</i>")

            }
            Label {
                text: qsTr("This project is proudly licensed under <b>GNU GPLv3.</b>")
                anchors.horizontalCenter: parent.horizontalCenter

            }
        }
    }
}
