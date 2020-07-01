import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property var container // container object from dbus
    property var daemon    // sailfish-containers daemon object

    function is_started(){
        // get Boolean for status: on = true, everything else = false
        if (container.container_status === "RUNNING"){
            return true
        } else {
            return false
        }
    }
    function is_frozen(){
        // get Boolean for status: frozen = true, everything else = false
        if (container.container_status === "FROZEN"){
            return true
        } else {
            return false
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "Settings"
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MachineSettings.qml"), {container : container, daemon: daemon} )
                }
            }
            MenuItem {
                text: "Snapshots"
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MachineSnapshots.qml"), {container : container, daemon: daemon} )
                }
            }
            MenuItem {
                text: is_frozen() ? "Unfreeze" : "Freeze"
                enabled: is_frozen() ? true : is_started()
                onClicked: {   
                    daemon.call("container_freeze",[container.container_name], function (result) {
                        if (result){
                            if (is_frozen()){
                                // update model
                                container.container_status = "RUNNING"
                            } else {
                                container.container_status = "FROZEN"
                            }
                        }
                    })
                }
            }
            MenuItem {
                text: is_started() ? "Stop" : "Start"
                enabled: is_frozen() ? false : true
                onClicked: {
                    if (is_started()){
                        daemon.call("container_stop",[container.container_name], function (result) {
                            if (result){
                                // update model
                                container.container_status = "STOPPED"
                            }
                        })
                    }else {
                        daemon.call("container_start",[container.container_name], function (result) {
                            if (result){
                                // update model
                                container.container_status = "RUNNING"
                            }
                        })
                    }
                }
            }
        }

        Column {
            spacing: Theme.paddingLarge
            width: parent.width
            height: parent.height

            PageHeader {
                id: pageHeader
                title: qsTr("Container: ") + container.container_name

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
                cellHeight: contentHeight //column.height //page.height *2
                onContentHeightChanged: cellHeight = contentHeight

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

                    IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: icon.width //+ Theme.paddingLarge //GridView.view.width
                        height: icon.height - Theme.paddingLarge - Theme.paddingLarge

                        icon.source: "image://theme/icon-m-computer"
                        icon.width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall //GridView.view.width
                        icon.height: Theme.itemSizeExtraLarge + Theme.itemSizeSmall

                    }


                    SectionHeader{
                        text: qsTr("Details")
                    }
                    Row {

                        width: parent.width

                        Column {
                            Label {
                                text: "<b>" + qsTr("name:") + "</b> " + container.container_name
                            }
                            Label{
                                text: "<b>" + qsTr("state:") + "</b> " + container.container_status
                            }
                            Label{
                                //  rootfs label, long string
                                text: "<b>" + qsTr("rootfs:") + "</b> " + container.container_rootfs
                            }
                            Label{
                                //  rootfs label, long string
                                text: "<b>" + qsTr("pid:") + "</b> " + container.container_pid
                            }
                            Label {
                                text: "<b>" + qsTr("cpu use:") + "</b> " + container.container_cpu
                            }
                            Label{
                                text: "<b>" + qsTr("memory use:") + "</b> " + container.container_mem
                            }
                            Label{
                                text: "<b>" + qsTr("kmem use:") + "</b> " + container.container_kmem
                            }
                        }
                    }

                    SectionHeader {
                        text: qsTr("Session")
                    }

                    ButtonLayout {
                        enabled: is_started()

                        Button {
                            text: qsTr("attach")
                            enabled: is_started() ? true : false
                            onClicked: {
                                daemon.call("container_attach",[container.container_name], function (result) {
                                    if (result){
                                    // shell started
                                    }
                                });
                            }
                        }
                        Button {
                            text: qsTr("X session")
                            enabled: is_started() ? true : false
                            onClicked: {
                                daemon.call("container_xsession_start",[container.container_name], function (result) {
                                    if (result){
                                    // Desktop started
                                    }
                                });
                            }
                        }
                    }

                    ExpandingSectionGroup {
                        currentIndex: 0

                        ExpandingSection {

                            title: qsTr("mountpoints")

                            content.sourceComponent: Column {
                                width: section.width
                                Repeater{
                                    model: ListModel { id: listmodelrepeater}
                                    Component.onCompleted: {
                                        // get container's mountpoints from daemon
                                        daemon.call('container_get_mounts',[container.container_name], function (result){

                                            var ind = 0
                                            for (var mp in result){
                                                //console.log(container.container_mounts[mp])
                                                listmodelrepeater.set(ind, {"mount_point":result[mp]})
                                                ind++

                                            }
                                            gridView.cellHeight += column.height
                                        })

                                    }

                                    Label {
                                        text: mount_point
                                        Component.onCompleted: gridView.cellHeight += Theme.paddingLarge*1.6
                                    }
                                }
                            }
                        }

                        ExpandingSection {
                            id: section

                            title: qsTr("advanced options")

                            content.sourceComponent: Column {
                                width: section.width

                                ButtonLayout {

                                    Button {
                                        text: qsTr("setup xsession")
                                        enabled: is_started() ? true : false

                                        onClicked: {
                                            daemon.call("container_xsession_setup",[container.container_name,"xfce4"], function (result) {
                                                if (result){
                                                // shell started
                                                }
                                            });
                                        }
                                    }
                                    Button {
                                        text: qsTr("init container config")
                                        enabled: is_started() ? false : true
                                        onClicked: {
                                            daemon.call("container_init_config",[container.container_name], function (result) {
                                                if (result){
                                                // init started
                                                }
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
