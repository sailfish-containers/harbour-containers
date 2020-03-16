import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Page {
    id: page
    backNavigation: false

    property string new_container_pid: "0"
    property string new_container_name: ""
    property bool new_container_setup: true

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

        if (container_create_in_progress(container)){
            // for container under creation
            return ""
        }

        if (container === "New container"){
            // create container icon
            return "image://theme/icon-m-add"
        }

        // default container icon
        return "image://theme/icon-m-computer"

    }

    function container_create_in_progress(name){
        // check if container is under creation
        if (name !== new_container_name){
            return false
        }
        return true
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
                delegate: BackgroundItem {
                    //contentHeight: itemColumn.height
                    width:  Theme.itemSizeExtraLarge + Theme.itemSizeSmall + Theme.paddingSmall
                    height:  Theme.itemSizeExtraLarge + Theme.itemSizeSmall + Theme.itemSizeExtraSmall
                    onClicked: {
                        // Go to machineView
                        if (container_name === "New container" && new_container_pid === "0"){
                            // create container dialog
                            var dialog = pageStack.push(Qt.resolvedUrl("CreateDialog.qml"), {daemon : daemon})

                            dialog.accepted.connect(function() {

                                // Create new container
                                daemon.call('create_container',[dialog.new_name,dialog.new_distro,dialog.new_arch,dialog.new_release], function (result) {
                                    if (result["result"]){
                                        // creation process started
                                        new_container_pid = result["pid"]
                                        new_container_name = dialog.new_name
                                        new_container_setup = dialog.new_setup

                                        //containersModel.remove(containersModel.count-1)
                                        containersModel.set(containersModel.count-1,{"container_status":"Creation in progress...","container_name":dialog.new_name})
                                        containersModel.set(containersModel.count,{"container_status":"","container_name":"New container"})

                                    }
                                })
                            })
                        } else {
                            // Go to container page
                            if (new_container_pid == "0"){ // this lock the page until the creation is completed to avoid interferences
                                // no container creation in progress
                                pageStack.push(Qt.resolvedUrl("MachineView.qml"), {container: model, daemon: daemon} )
                            }

                        }
                    }
                    Column {
                        id: itemColumn

                        Item{
                            width: iconitem.width //+ Theme.paddingLarge //GridView.view.width
                            height: Theme.itemSizeExtraLarge + Theme.itemSizeExtraSmall - Theme.paddingLarge

                            Icon {
                                id: iconitem
                                source: get_container_icon(container_name)
                                width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall //GridView.view.width
                                height: Theme.itemSizeExtraLarge + Theme.itemSizeExtraSmall
                            }

                            BusyIndicator {
                                id: busySpin
                                size: BusyIndicatorSize.Large
                                anchors.horizontalCenter: parent.horizontalCenter
                                running: container_create_in_progress(container_name)
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
                            if (new_container_setup){
                                // Setup container's desktop
                                containersModel.set(containersModel.count-2,{"container_status":"Starting container...","container_name":new_container_name})

                                // Start new container
                                daemon.call('start_container',[new_container_name], function (result) {
                                    // Run setup script
                                    daemon.call('setup_container',[new_container_name,"xfce4"], function (result) {
                                        // refresh pid to check on timer
                                        new_container_pid = result["pid"]
                                        new_container_setup = false

                                        // update container's status
                                        containersModel.set(containersModel.count-2,{"container_status":"Installing packages...","container_name":new_container_name})

                                    })
                                })
                            } else {
                                // creation/setup completed
                                new_container_pid = "0"
                                new_container_name = ""
                            }
                        }
                    })
                }

                if (new_container_pid == "0") {
                    // default condition, refresh containers list
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
            }            
        }
    }
}

