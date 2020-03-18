import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property var container // container object from dbus
    property var daemon    // sailfish-containers daemon object

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: "New snapshot"
                enabled: false
                onClicked: {

                }
            }
        }

        Column {
            spacing: Theme.paddingLarge
            width: parent.width
            height: parent.height

            PageHeader {
                id: pageHeader

                Rectangle {
                    anchors.fill: parent
                    color: Theme._wallpaperOverlayColor

                    PageHeader {
                        title: qsTr("Snapshots: ") + container.container_name
                    }
                }
            }

            SilicaListView {
                width: page.isLandscape ? parent.width/1.5 : parent.width - Theme.paddingLarge
                height: parent.height - pageHeader.height
                anchors.horizontalCenter: parent.horizontalCenter

                model: ListModel {
                    ListElement { snap: "snap1" }
                    ListElement { snap: "snap0" }
                    ListElement { snap: "snap2" }
                    ListElement { snap: "snap3" }
                    ListElement { snap: "test" }
                }
                delegate: BackgroundItem {
                    width: ListView.view.width
                    height: Theme.itemSizeSmall

                    Label {
                        text: snap
                    }
                }
            }
        }
    }
}
