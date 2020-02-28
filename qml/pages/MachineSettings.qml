import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Page {
    id: page

    property var container // container object from dbus

    SilicaFlickable {
        anchors.fill: parent

        RemorseItem { id: remorse }

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
                        title: qsTr("Settings: ") + container.container_name
                    }
                }
            }

            SilicaGridView {
                id: gridView
                width: parent.width //- Theme.paddingLarge
                height: parent.height - pageHeader.height
                clip: true
                cellWidth: page.isLandscape ? parent.width/1.5 : parent.width - Theme.paddingLarge
                cellHeight: page.height *2

                VerticalScrollDecorator {}

                model: ListModel {
                    id:listmodel

                    ListElement{}
                }

                delegate: Column {
                    id: column
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: page.isLandscape ? parent.width/1.5 : parent.width - Theme.paddingLarge
                    spacing: Theme.paddingLarge

                    ButtonLayout {
                        Button {
                            text: "icon"
                            enabled: false
                        }
                    }
                    ButtonLayout {
                        Button {
                            text: "delete container"
                            enabled: true
                            onClicked: daemon.call('destroy_container',[container.container_name], function (result){
                                pageStack.push(Qt.resolvedUrl("HomePage.qml"),{})
                            })
                        }
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
    }
}
