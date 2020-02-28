import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Page {
    id: page
    backNavigation: false

    property string new_container_pid: "0"

    function freeze_all(){
        for(var i=0;i<containersModel.count;i++){
            if(containersModel.get(i)["container_status"] === "RUNNING" ){
                daemon.call('freeze_container',[containersModel.get(i)["container_name"]], function (result) {
                    containersModel.setProperty(i, "container_status", "FROZEN")
                })
            }
        }

        return true
    }
    function stop_all(){
        for(var i=0;i<containersModel.count;i++){
            if(containersModel.get(i)["container_status"] === "RUNNING" ){
                daemon.call('stop_container',[containersModel.get(i)["container_name"]], function (result) {
                    containersModel.setProperty(i, "container_status", "FROZEN")
                })
            }
        }

        return true
    }

    function get_container_icon(container){
        if (container === "New container"){
            return "image://theme/icon-m-add"
        } else {
            // get container icon
            return "image://theme/icon-m-computer"
        }
    }

    function refresh_containers(){
        /* Refresh containers list */
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

            // "Add new" icon
            containersModel.set(ind, {"container_status":"","container_name":"New container"})

            //console.log("cache refreshed")
        })
    }

    SilicaFlickable{
        anchors.fill:parent

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "About"
                onClicked: {}
                enabled: false
            }
            MenuItem {
                text: "Stop all"
                onClicked: stop_all()
            }
            MenuItem {
                text: "Freeze all"
                onClicked: freeze_all()
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
                        title: qsTr("Containers")
                    }
                    BusyIndicator {
                        id: busySpin
                        size: BusyIndicatorSize.Medium
                       // anchors.centerIn: parent
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 15
                        anchors.topMargin: 10
                        running: false

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

                        icon.source: get_container_icon(container_name)
                        icon.width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall //GridView.view.width
                        icon.height: Theme.itemSizeExtraLarge + Theme.itemSizeSmall

                        onClicked: {
                            // Go to machineView
                            if (container_name === "New container"){
                                // create container dialog
                                var dialog = pageStack.push(Qt.resolvedUrl("CreateDialog.qml"), {name : "test"})

                                dialog.accepted.connect(function() {

                                    // Create new container
                                    daemon.call('create_container',[dialog.new_name,dialog.new_distro,dialog.new_arch,dialog.new_release], function (result) {
                                        if (result["result"]){
                                            // creation process started
                                            new_container_pid = result["pid"]
                                            busySpin.running = true
                                        }
                                    })
                                })
                            } else {
                                // Go to container page
                                pageStack.push(Qt.resolvedUrl("MachineView.qml"), {container : model} )
                            }
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
            interval: 18000 // 18 sec
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                if (new_container_pid != "0") {
                    daemon.call('check_process',[new_container_pid], function (result){
                        // Check container creation
                        if(!result){
                            // LXC create completed
                            busySpin.running = false
                            new_container_pid = "0"
                            refresh_containers()
                        }
                    })
                } else {
                    // default condition, refresh containers list
                    refresh_containers()
                }
            }            
        }
    }
}

