#!/bin/bash
# sailfish-containers-dbus : new qxcompositor display

if [ "$#" -ne 3 ]
then
    echo "Usage $0 [display-id] [user_uid] [screen_orientation]"
    echo "Example: $0 4 100000 portrait"
    exit 0
fi

DISPLAY_ID=$1
USER_UID=$2
SCREEN_ORIENTATION=$3

export EGL_PLATFORM="wayland"
export QT_QPA_PLATFORM="wayland"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export PATH="/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/defaultuser/bin"
export PWD="/usr/share/sailfish-containers/guest"
export QMLSCENE_DEVICE="customcontext"

export XDG_RUNTIME_DIR=/run/user/$USER_UID
export WAYLAND_DISPLAY="../../display/wayland-0"

/usr/bin/qxcompositor --wayland-socket-name "../../display/wayland-container-$DISPLAY_ID" -o $SCREEN_ORIENTATION
