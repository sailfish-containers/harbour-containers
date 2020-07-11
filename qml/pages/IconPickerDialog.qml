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

        Grid {
            columns: parent.width / (Theme.iconSizeExtraLarge*2)
            spacing: 22

            Repeater {
                model: ListModel {
                    ListElement { icon_source: "../icons/aliendalvik.png"; icon_name: "android" }
                    ListElement { icon_source: "../icons/debian.png"; icon_name: "debian" }
                    ListElement { icon_source: "image://theme/icon-m-computer"; icon_name: "default" }

                }
                IconButton {
                    icon.source: icon_source
                    width: icon.width
                    height: icon.height
                    icon.width:  Theme.iconSizeExtraLarge*2
                    icon.height: Theme.iconSizeExtraLarge*2
                    onClicked: {
                        new_icon=icon_source
                        selection_lbl.text="selected: "+icon_name
                    }
                }
            }
        }
    }
}
