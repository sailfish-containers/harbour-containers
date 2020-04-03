#!/bin/bash
# sailfish-containers-dbus: attach to container

#export EGL_DRIVER="egl_gallium"
export EGL_PLATFORM="wayland"
export QT_QPA_PLATFORM="wayland"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export PATH="/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/nemo/bin"
export PWD="/usr/share/sailfish-containers/guest"
export QMLSCENE_DEVICE="customcontext"
export QT_WAYLAND_FORCE_DPI="96"

export XDG_RUNTIME_DIR=/run/user/0
export WAYLAND_DISPLAY="../../display/wayland-0"

mkdir -p /run/user/0

su nemo -c "/usr/bin/fingerterm -e 'echo \"lxc-attach: $1\"; echo \"Enter developer mode password\";devel-su lxc-attach -n $1 /bin/bash;'"
