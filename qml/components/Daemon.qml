import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

DBusInterface {

    property string new_container_pid:   "0"
    property string new_container_name:  ""
    property bool   new_container_setup: true

    bus: DBus.SystemBus
    service: 'org.sailfishcontainers.daemon'
    iface: 'org.sailfishcontainers.daemon'
    path: '/org/sailfishcontainers/daemon'

}
