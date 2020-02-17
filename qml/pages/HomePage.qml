import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Page {
    id: page

    function freeze_all(){
        return true
    }
    function stop_all(){
        return true
    }

    SilicaFlickable{
        anchors.fill:parent

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "Stop all"
                onClicked: stop_all()
            }
            MenuItem {
                text: "Freeze all"
                onClicked: freeze_all()
            }
            MenuItem {
                text: "New container"
                enabled: false
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
                    color: Theme.darkSecondaryColor

                    PageHeader {
                        title: qsTr("Containers")
                    }
                }
            }

            SilicaGridView {
                id: gridView
                width: parent.width //- Theme.paddingLarge
                height: parent.height - pageHeader.height - Theme.paddingLarge
                clip: true
                cellWidth: Theme.itemSizeExtraLarge + Theme.itemSizeSmall + Theme.paddingSmall
                cellHeight: Theme.itemSizeExtraLarge + Theme.itemSizeSmall + Theme.paddingLarge + Theme.paddingSmall

                VerticalScrollDecorator {}

                model: ListModel {
                    id: containersModel
                }
                delegate: Column {

                    IconButton {
                        width: icon.width //+ Theme.paddingLarge //GridView.view.width
                        height: icon.height - Theme.paddingLarge - Theme.paddingLarge

                        icon.source: "image://theme/icon-m-computer"
                        icon.width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall //GridView.view.width
                        icon.height: Theme.itemSizeExtraLarge + Theme.itemSizeSmall

                        onClicked: {
                            // Go to machineView
                            pageStack.push(Qt.resolvedUrl("MachineView.qml"), {container : model} )
                        }
                    }

                    Label {
                        //anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: container_status
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmallBase

                    }
                    Label {
                        //anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: container_name
                    }
                }
            }
        }
    }

    Item {
        DBusInterface {
            id: daemon

            bus: DBus.SystemBus
            service: 'org.sailfishcontainers.daemon'
            iface: 'org.sailfishcontainers.daemon'
            path: '/org/sailfishcontainers/daemon'
        }
        Timer {
            id: refreshTimer
            interval: 20000 // 20 sec
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                daemon.call('get_containers',[], function (result) {
                    //containersModel.clear()
                    var ind = 0
                    for(var item in result){
                        // update containers cache
                        containersModel.set(ind, result[item])
                        ind++
                    }
                    //console.log("cache refreshed")
                });
            }
        }
    }
}

