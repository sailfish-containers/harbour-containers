#!/bin/bash
# lxc setup desktop 
# run as root inside a container

# get username and uid
if [ "$#" -ne 1 ]
then
	# set default user
	USER_NAME="user"
else
        USER_NAME=$1
fi

# get user uid
USER_UID=`id -u $USER_NAME`

# get arch and libc version for xwayland
ARCH=`arch`

case $ARCH in
	"armv7hl")
		ARCH="armhf"
	;;
esac
if [ $ARCH = "armhf" ]
then
	LIBC_FILE=`ls /lib/arm-linux-gnueabihf/ | grep ^libc-`
else
	LIBC_FILE=`ls /lib/$ARCH-linux-gnu/ | grep ^libc-`
fi

LIBC_VER=${LIBC_FILE%".so"}

# get distro name
DISTRO_FILE=`cat /etc/os-release | grep ^ID=`
DISTRO_VER=${DISTRO_FILE#"ID="}

case $DISTRO_VER in
	"kali"|"ubuntu"|"mint"|"devuan")
                DISTRO_VER="debian"
	;;

	"archarm"|"archlinux")
		DISTRO_VER="arch"
	;;
esac

# run distro setup script
if [ -f "/mnt/guest/setups/${DISTRO_VER}.sh" ]
then
	echo "[*] Starting ${DISTRO_VER} setup script..."
	. /mnt/guest/setups/$DISTRO_VER.sh 
else
	echo "[!] ${DISTRO_VER} currently not supported by setup scripts."
fi

# check for Xwayland binary
if [ ! -f "/opt/bin/Xwayland" ]
then

	echo "[*] Downloading pre-built xwayland binary..."

	# get latest Xwayland blobs from github
	mkdir -p /opt/bin

	curl "https://github.com/sailfish-containers/xserver/releases/download/b1/Xwayland.${ARCH}.${LIBC_VER}.bin" -L --output /opt/bin/Xwayland
	chown $USER_NAME:$USER_NAME -R /opt/bin
	chmod +x /opt/bin/Xwayland
fi

echo "[+] container is ready!"
echo "[+] remember to set a password for the user: ${USER_NAME}"
