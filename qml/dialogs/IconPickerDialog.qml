import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {

    property string new_icon

    canAccept: true

    Column {
        width: parent.width

        DialogHeader {
            title: qsTr("Select an icon: ")
            id: pageHeader
        }
        Label {
            id: selection_lbl
        }

        VerticalScrollDecorator {}

        Grid {
            columns: parent.width / (Theme.iconSizeExtraLarge + Theme.iconSizeMedium)
            spacing: 22

            Repeater {
                model: ListModel {
                    ListElement { icon_source: "../images/container-aliendalvik.png"; icon_name: "android" }
                    ListElement { icon_source: "../images/container-debian.png"; icon_name: "debian" }
                    ListElement { icon_source: "../images/container-archlinux.png"; icon_name: "archlinux" }
                    ListElement { icon_source: "../images/container-gentoo.png"; icon_name: "gentoo" }
                    ListElement { icon_source: "../images/container-ubuntu.png"; icon_name: "ubuntu" }
                    ListElement { icon_source: "../images/container-alpine.png"; icon_name: "alpine" }
                    ListElement { icon_source: "../images/container-kali.png"; icon_name: "kali" }
                    ListElement { icon_source: "../images/container-manjaro.png"; icon_name: "manjaro" }
                    ListElement { icon_source: "../images/container-tux.png"; icon_name: "tux" }
                    ListElement { icon_source: "../images/container-default.png"; icon_name: "default" }

                }
                IconButton {
                    icon.source: icon_source
                    width: icon.width
                    height: icon.height
                    icon.width:  Theme.iconSizeExtraLarge + Theme.iconSizeSmall
                    icon.height: Theme.iconSizeExtraLarge + Theme.iconSizeSmall
                    onClicked: {
                        new_icon=icon_source
                        selection_lbl.text="selected: "+icon_name
                    }

                }
            }
        }
    }
}
