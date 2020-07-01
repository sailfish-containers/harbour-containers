import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property var container // container object from dbus
    property var daemon    // sailfish-containers daemon object

    SilicaFlickable {
        anchors.fill: parent

        Column {
            spacing: Theme.paddingLarge
            width: parent.width
            height: parent.height

            PageHeader {
                id: pageHeader
                title: qsTr("Settings: ") + container.container_name

                Rectangle {
                    anchors.fill: parent
                    color: Theme.highlightBackgroundColor
                    opacity: 0.15
                }
            }

            SilicaGridView {
                id: gridView
                width: parent.width //- Theme.paddingLarge
                height: parent.height - pageHeader.height
                clip: true
                cellWidth: page.isLandscape ? parent.width/1.5 : parent.width - Theme.paddingLarge
                //cellHeight: auto

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
                            text: "Change icon"
                            enabled: false
                        }
                    }
                    ButtonLayout {
                        Button {
                            text: "Destroy container"
                            enabled: true
                            color: Theme.errorColor
                            onClicked: {
                                var remorse = Remorse.popupAction(page, Remorse.deletedText, function() {
                                    daemon.call('container_destroy',[container.container_name], function (result){
                                        pageStack.push(Qt.resolvedUrl("HomePage.qml"),{daemon: daemon})
                                    })
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}
