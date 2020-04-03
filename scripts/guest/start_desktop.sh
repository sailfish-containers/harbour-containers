#!/bin/bash
# lxc start desktop session on xwayland as user
# run as root
if [ "$#" -ne 1 ] 
then
	echo "[+] usage: $0 [wayland-display-id]"
	exit 0
fi
if [ "$#" -ne 2 ] 
then
	# if not args provided
	# set to sailfish default
	USER_UID=100000
else
	# set custom user uid
	USER_UID=$2
fi
if [ "$#" -ne 3 ] 
then
	# set default user
	USER_NAME="user"
else
	# set custom user uid
	USER_NAME=$3
fi

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

	sleep 2
fi

# start xfce session
su $USER_NAME -c "/opt/bin/startx $1"