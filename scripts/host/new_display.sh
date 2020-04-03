#!/bin/bash
# sailfish-containers-dbus : new qxcompositor display

USER_UID=$2
DISPLAY_ID=$1

#export EGL_DRIVER="egl_gallium"
export EGL_PLATFORM="wayland"
export QT_QPA_PLATFORM="wayland"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export PATH="/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/nemo/bin"
export PWD="/usr/share/sailfish-containers/guest"
export QMLSCENE_DEVICE="customcontext"

export XDG_RUNTIME_DIR=/run/user/$USER_UID
export WAYLAND_DISPLAY="../../display/wayland-0"

/usr/bin/qxdisplay --wayland-socket-name "../../display/wayland-container-$DISPLAY_ID"
