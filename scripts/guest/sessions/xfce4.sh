#!/bin/bash
# lxc start xfce desktop on xwayland 
# run as user
if [ "$#" -ne 1 ] 
then
	echo "[+] usage: $0 [wayland-display-id]"
	exit 0
fi

# get user id
USER_ID=`id -u`

# unset sfos variables
unset BROWSER

# set env
export XDG_RUNTIME_DIR=/run/user/$USER_ID
export WAYLAND_DISPLAY="../../display/wayland-container-$1" # connect to qxcompositor wayland socket

export LANG=C
export EGL_PLATFORM=wayland
#export EGL_DRIVER=egl_gallium
export QT_QPA_PLATFORM=xcb # force qt applications backend to Xwayland
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/games:/usr/local/sbin:/sbin

#export CHROMIUM_SCALE=1.5

# qt applications incorrect scaling fix 
export QT_SCALE_FACTOR=0.1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_FONT_DPI=2000

# start dbus session
export $(dbus-launch)

# Start Xwayland window
/opt/bin/Xwayland -nolisten tcp &
sleep 2

# set display to xwayland
export DISPLAY=:0

# start xfce session
startxfce4
