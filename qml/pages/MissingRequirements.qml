import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    backNavigation: false
    Column {
        width: parent.width
        //spacing: Theme.paddingMedium
        SectionHeader {
            text: qsTr("error")
        }

        Icon {
            source: "image://theme/icon-l-attention"
            anchors.horizontalCenter: parent.horizontalCenter

        }

        Label {
            text: "<h2>" + qsTr("Oh no! Your device does not meet requirements for LXC.") + "</h2>"
            anchors.horizontalCenter: parent.horizontalCenter
            width: page.isPortrait ? page.width - Theme.paddingMedium : page.width / 1.5
            wrapMode: Label.WordWrap
        }

        Button {
            text: qsTr("Read more")
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {
                Qt.openUrlExternally("https://github.com/sailfish-containers/lxc-templates-desktop/wiki/Requirements")
            }
        }
    }
}
