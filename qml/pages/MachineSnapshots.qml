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
                Component.onCompleted: {
                    daemon.call('get_snapshots',[container.container_name], function (result){
                        if (result !== false){
                            for (var snap in result){
                                snapshostsListModel.append(result)
                            }
                        }
                    })
                }

                model: ListModel {
                    id : snapshostsListModel

                }
                delegate: BackgroundItem {
                    width: ListView.view.width
                    height: Theme.itemSizeSmall

                    Label {
                        text: "<b>" + snap_name + "</b> " + snap_ts
                    }
                }
            }
        }
    }
}
