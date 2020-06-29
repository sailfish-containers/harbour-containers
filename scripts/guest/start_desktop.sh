#!/bin/bash
# lxc start desktop session on xwayland as user
# run as root
if [ "$#" -lt 1 ]
then
        echo "[+] usage: $0 [display-socket-id] [user]"
        exit 0
fi

if [ "$#" -ne 2 ]
then
        # set default user
        USER_NAME="user"
else
        USER_NAME=$2
fi

# get user uid
USER_UID=`id -u $USER_NAME`

if [ ! -d "/run/user/$USER_UID" ]
then
        # create xdg runtime directory for user
        mkdir -p /run/$USER_NAME/$USER_UID
        sleep 1

        # give user permissions on xdg runtime dir
        chown $USER_NAME:$USER_NAME /run/$USER_NAME/$USER_UID

        # create pulse socket mountpoint
        mkdir /run/$USER_NAME/$USER_UID/pulse
        chown -R $USER_NAME:$USER_NAME /run/$USER_NAME/$USER_UID

        # bind mount pulse socket
        mount --bind /mnt/pulse /run/$USER_NAME/$USER_UID/pulse

        # symlink wayland display
        ln -s /mnt/display /run/display

        # replace Xorg with Xwayland in xserverrc
        cp /mnt/guest/configs/xserverrc /etc/X11/xinit/xserverrc

        sleep 2
fi

# start x session
# unset sfos variables
unset BROWSER

# set env
export XDG_RUNTIME_DIR=/run/user/$USER_UID
export WAYLAND_DISPLAY="../../display/wayland-container-$1" # connect to qxcompositor wayland socket

export LANG=C
export EGL_PLATFORM=wayland
export QT_QPA_PLATFORM=xcb # force qt applications backend to Xwayland
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/games:/usr/local/sbin:/sbin

# qt applications incorrect scaling fix
export QT_SCALE_FACTOR=0.1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_FONT_DPI=2000

# start dbus session
#export $(dbus-launch)

#sleep 2
su $USER_NAME -c startx

#
## Xwayland -> Xephyr/Xnest -> lightdm testing
# set display to xwayland and start Xephyr on :1
#export DISPLAY=:0
#Xephyr -fullscreen -nolisten tcp -ac -2button -host-cursor :1 &
#sleep 3

# set display to Xephyr and start display manager
#export DISPLAY=:1 (not required)
#/bin/systemctl restart lightdm
