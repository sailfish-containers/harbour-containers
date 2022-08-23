#!/bin/bash
# sailfish-containers-dbus: attach to container
# args: username, cmd

if [ "$#" -ne 2 ]
then
        # set default user
        CMD=""
else
        CMD=$2
fi

export EGL_PLATFORM="wayland"
export QT_QPA_PLATFORM="wayland"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export PATH="/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/defaultuser/bin"
export PWD="/usr/share/sailfish-containers/guest"
export QMLSCENE_DEVICE="customcontext"
export QT_WAYLAND_FORCE_DPI="96"

export XDG_RUNTIME_DIR=/run/user/0
export WAYLAND_DISPLAY="../../display/wayland-0"

mkdir -p /run/user/0

/usr/bin/fingerterm  -e "lxc-attach -n $1 $CMD;"
