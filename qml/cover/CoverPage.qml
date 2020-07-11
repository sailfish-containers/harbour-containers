import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {

    property var daemon

    function status_color(container_status){
        if (container_status === "RUNNING"){
            return Theme.highlightColor
        } else if (container_status === "STOPPED" ) {
            return Theme.secondaryColor
        }

        return Theme.primaryColor
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Theme.paddingLarge
        id: column

        Label {
            anchors.horizontalCenter: parent.horizontalCenter

            text: qsTr("<b>Containers</b>")
        }

        Repeater{
            model: ListModel {id: containersModel}
            Row {
                Label {
                    id: namelbl
                    text: container_name + " "
                }
                Label {
                    text: " " + container_status
                    horizontalAlignment: Text.AlignRight
                    width: column.width - namelbl.width
                    color: status_color(container_status)
                }
            }
        }
    }

    CoverActionList {
        id: coverAction

        /*CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }*/
    }
    Timer {
        id: slowTimer
        interval: 60000 * 8 // 8 min
        repeat: true
        triggeredOnStart: true
        running: cover.status === Cover.Active && daemon.new_container_pid == "0"
        onTriggered: {
            daemon.call('get_containers',[], function (result) {
                if(containersModel.count > result.length+1){
                    // containers amount changed
                    containersModel.clear()
                }

                var ind = 0
                for(var item in result){
                    // refresh containers
                    containersModel.set(ind, result[item])
                    ind++
                }
            })
        }
    }
}
