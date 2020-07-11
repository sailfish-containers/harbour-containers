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
    Database {
        id: main_db
    }

    initialPage: Component{
        HomePage {
            daemon: dbus_daemon
            db: main_db
        }
    }
    cover: CoverPage {
        daemon: dbus_daemon
    }

    allowedOrientations: defaultAllowedOrientations
}
