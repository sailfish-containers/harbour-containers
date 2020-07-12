import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    backNavigation: false

    property var daemon
    property var db

    function freeze_all(){
        for(var i=0;i<containersModel.count;i++){
            if(containersModel.get(i)["container_status"] === "RUNNING" ){
                daemon.call('container_freeze',[containersModel.get(i)["container_name"]], function (result) {
                    containersModel.setProperty(i, "container_status", "FROZEN")
                })
            }
        }

        return true
    }
    function stop_all(){
        for(var i=0;i<containersModel.count;i++){
            if(containersModel.get(i)["container_status"] === "RUNNING" ){
                daemon.call('container_stop',[containersModel.get(i)["container_name"]], function (result) {
                    containersModel.setProperty(i, "container_status", "FROZEN")
                })
            }
        }

        return true
    }

    function setup_container_xsession(name){

        daemon.call('container_init_config',[name], function(out){
            if (out){
                // guest mountpoint added to container config file
                // Start new container
                daemon.call('container_start',[name], function (result) {
                    if (result){
                        // Container started
                        // Run setup script
                        daemon.call('container_xsession_setup',[name,"xfce4"], function (result) {})
                    }
                })
            }
        })
    }

    function get_container_icon(container){

        if (container_create_in_progress(container)){
            // for container under creation
            return ""
        }

        if (container === " "){
            // create container icon
            return "../images/icon-m-add.png"
        } else {

            var stored_icon = db.get_icon(container)

            if (stored_icon !== ""){
                return stored_icon
            }
        }

        // default container icon
        return "../images/container-default.png"
    }

    function container_create_in_progress(name){
        // check if container is under creation
        if (name !== daemon.new_container_name){
            return false
        }
        return true
    }

    SilicaFlickable{
        anchors.fill:parent

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"), {})
            }
            MenuItem {
                text: qsTr("Stop all")
                onClicked: stop_all()
            }
            MenuItem {
                text: qsTr("Freeze all")
                onClicked: freeze_all()
            }
        }

        Column {
            spacing: Theme.paddingLarge
            width: parent.width
            height: parent.height

            PageHeader {
                id: pageHeader
                title: qsTr("Containers")

                Rectangle {
                    anchors.fill: parent
                    color: Theme.highlightBackgroundColor
                    opacity: 0.15
                }
            }

            SilicaGridView {
                id: gridView
                width: parent.width
                height: parent.height - pageHeader.height - Theme.paddingLarge
                clip: true
                cellWidth: Theme.itemSizeExtraLarge + Theme.itemSizeSmall + Theme.paddingSmall
                cellHeight: Theme.itemSizeExtraLarge*2 + Theme.paddingLarge

                VerticalScrollDecorator {}

                model: ListModel {
                    id: containersModel
                }
                delegate: BackgroundItem {
                    //contentHeight: itemColumn.height
                    width:  Theme.itemSizeExtraLarge + Theme.itemSizeSmall + Theme.paddingSmall
                    height:  Theme.itemSizeExtraLarge*2 + Theme.paddingLarge
                    onClicked: {
                        // Go to machineView
                        if (container_name === " " && daemon.new_container_pid === "0"){
                            // create container dialog
                            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/CreateDialog.qml"), {daemon : daemon})

                            dialog.accepted.connect(function() {

                                // Create new container
                                daemon.call('container_create',[dialog.new_name,dialog.new_distro,dialog.new_arch,dialog.new_release], function (result) {
                                    if (result["result"]){
                                        // creation process started
                                        daemon.new_container_pid = result["pid"]
                                        daemon.new_container_name = dialog.new_name
                                        daemon.new_container_setup = dialog.new_setup

                                        //containersModel.remove(containersModel.count-1)
                                        containersModel.set(containersModel.count-1,{"container_status":"Creation in progress...","container_name":dialog.new_name})
                                        containersModel.set(containersModel.count,{"container_status":"","container_name":" "})

                                    }
                                })
                            })
                        } else {
                            // Go to container page
                            //if (daemon.new_container_pid == "0"){ // this lock the page until the creation is completed to avoid interferences
                                // no container creation in progress
                            pageStack.push(Qt.resolvedUrl("ContainerView.qml"), {container: model, daemon: daemon, icon: icon_distro_logo, db: db} )
                            //}

                        }
                    }
                    Column {
                        id: itemColumn

                        Item{
                            width: iconitem.width
                            height: iconitem.height - Theme.paddingSmall

                            Icon {
                                id: iconitem
                                source: (container_name != " " && !container_create_in_progress(container_name) ) ? "../images/container-empty.png" : null
                                width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall
                                height: Theme.itemSizeExtraLarge + Theme.itemSizeSmall

                                Image {
                                    id: icon_distro_logo
                                    source: get_container_icon(container_name)
                                    width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall
                                    height: Theme.itemSizeExtraLarge + Theme.itemSizeSmall

                                }
                            }

                            BusyIndicator {
                                id: busySpin
                                size: BusyIndicatorSize.Large
                                anchors.horizontalCenter: parent.horizontalCenter
                                running: container_create_in_progress(container_name)
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Theme.paddingLarge

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

    Timer {
        id: refreshTimer
        interval: 15000 // 15 sec
        repeat: true
        running: (Qt.application.state == Qt.ApplicationActive && daemon.new_container_pid == "0") || daemon.new_container_pid !== "0"
        triggeredOnStart: true
        onTriggered: {
            if (daemon.new_container_pid != "0") {
                daemon.call('check_process',[daemon.new_container_pid], function (result){
                    // Check container creation
                    if(!result){
                        if (daemon.new_container_setup){
                            // Setup container's desktop
                            // user selection
                            containersModel.set(containersModel.count-2,{"container_status":"Starting setup...","container_name":daemon.new_container_name})
                            // add guest mountpoint to container
                            setup_container_xsession(daemon.new_container_name)

                        }
                        // LXC create completed
                        // creation/setup completed
                        daemon.new_container_pid = "0"
                        daemon.new_container_name = ""
                    }
                })
            } else {

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
                    containersModel.set(ind, {"container_status":"","container_name":" "})
                })
            }
        }
    }
}

