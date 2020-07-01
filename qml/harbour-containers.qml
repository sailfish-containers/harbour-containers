import QtQuick 2.0
import Sailfish.Silica 1.0

import "pages"
import "cover"
import "components"

ApplicationWindow
{
    Daemon {
        id: dbus_daemon
    }

    initialPage: Component{
        HomePage {
            daemon: dbus_daemon
        }
    }
    cover: CoverPage {
        daemon: dbus_daemon
    }

    allowedOrientations: defaultAllowedOrientations
}
