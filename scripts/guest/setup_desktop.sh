#!/bin/bash
# LXC setup desktop
# Run as root inside a container

# Get architecture
ARCH=$(uname -m)

# Get username and uid
if [ "$#" -lt 1 ]
then
    	# set default user
        USER_NAME="user"
else
    	USER_NAME=$1
fi
if [ "$#" -ne 2 ]
then
    # set user uid
    USER_UID=100000
else
    USER_UID=$2
fi

# Get distro name
DISTRO_FILE=$(cat /etc/os-release | grep ^ID=)
DISTRO=${DISTRO_FILE#"ID="}

case $DISTRO in
        "debian" | "kali" | "ubuntu" | "mint" | "devuan")
                DISTRO_VER=debian
        ;;

         "archarm" | "archlinux")
	        DISTRO_VER=arch
    	;;
esac

# Run distro setup script
if [ -f "/mnt/guest/setups/${DISTRO_VER}.sh" ]
then
    	echo "[*] Starting ${DISTRO_VER} setup script..."
        bash -c ". /mnt/guest/setups/$DISTRO_VER.sh $USER_NAME $USER_UID $DISTRO"
else
    	echo "[!] ${DISTRO} currently not supported by setup scripts."
fi

echo "[+] Container is ready!"
