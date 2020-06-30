import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    // Dbus datemon object
    property var daemon

    // Available distros from LXC repos
    property var distros: []

    // new value from this dialog
    property string new_name
    property string new_arch
    property string new_distro
    property string new_release
    property bool new_setup : true

    id: mainDialog
    canAccept: false

    Component.onCompleted: {
        daemon.call("tpl_get_distro",[], function (result) {

            for (var data in result){
                distroBox_model.append({ distro_name: result[data]})
                distros[data] = result[data]
            }
            daemon.call("tpl_get_version",[distros[data]], function (result) {
                releaseBox_model.clear()

                for (var data in result){
                    releaseBox_model.append({ release_name: result[data]})
                    //console.log(result[data])
                }
            })
        })
    }

    Column {
        width: parent.width

        DialogHeader {
            title: "New container"
        }

        TextField {
            id: nameField
            width: parent.width
            placeholderText: "Container name"
            label: "Name"
            onTextChanged: {
                if (nameField.text.length > 1){
                    // enable accept
                    mainDialog.canAccept = true
                } else {
                    mainDialog.canAccept = false
                }
            }
        }
        ComboBox {
            id: archBox
            width: parent.width
            label: "Architecture"

            menu: ContextMenu {
                MenuItem { text: "arm64" }
                MenuItem { text: "armhf" }
                MenuItem { text: "i386" }
            }
        }

        ComboBox {
            id: distroBox
            width: parent.width
            label: "Distribution"

            menu: ContextMenu {
                Repeater {
                    model: ListModel{
                        id: distroBox_model
                    }

                    MenuItem { text: distro_name }
                }
            }

            onCurrentIndexChanged: {
                daemon.call("tpl_get_version",[distros[currentIndex]], function (result) {
                    releaseBox_model.clear()

                    for (var data in result){
                        releaseBox_model.append({ release_name: result[data]})
                        //console.log(result[data])
                    }
                })
            }
        }

        ComboBox {
            id: releaseBox
            width: parent.width
            label: "Release"

            menu: ContextMenu {
                Repeater{
                    model: ListModel{
                        id: releaseBox_model
                    }
                    MenuItem { text: release_name }
                }
            }
        }

        TextSwitch {
            id: desktopSwitch
            text: "Setup desktop"
            checked: true
            description: qsTr("Setup container's desktop, may take long time. Currently only debian based systems are supported by the scripts. In addition Xwayland may need to be rebuilt based on guest's libc version. Read more: https://github.com/sailfish-containers/lxc-templates-desktop/wiki/Desktop")
        }
    }

    onDone: {
        if (result == DialogResult.Accepted) {
            new_name = nameField.text
            new_distro = distroBox.value
            new_release = releaseBox.value
            new_arch = archBox.value
            new_setup = desktopSwitch.checked
        }
    }
}
