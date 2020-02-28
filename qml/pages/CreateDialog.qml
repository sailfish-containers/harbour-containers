import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    property string new_name
    property string new_arch
    property string new_distro
    property string new_release
    property bool new_setup : true

    id: mainDialog
    canAccept: false

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
                MenuItem { text: "ubuntu" }
                MenuItem { text: "debian" }
                MenuItem { text: "kali" }
            }
        }

        ComboBox {
            id: releaseBox
            width: parent.width
            label: "Release"

            menu: ContextMenu {
                MenuItem { text: "bionic" }
                MenuItem { text: "cosmic" }
                MenuItem { text: "eon" }
            }
        }

        TextSwitch {
            id: desktopSwitch
            text: "Setup desktop"
            checked: true
            description: "setup container's desktop"
        }
    }

    onOpened: {}

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
