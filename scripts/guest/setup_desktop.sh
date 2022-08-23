#!/bin/bash
# lxc setup desktop 
# run as root inside a container

# get architecture
ARCH=$(uname -m)

# # get username and uid
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

ARCH=$(uname -m)

# get distro name
DISTRO_FILE=$(cat /etc/os-release | grep ^ID=)
DISTRO_VER=${DISTRO_FILE#"ID="}

case $DISTRO_VER in
	"debian" | "kali" | "ubuntu" | "mint" | "devuan")
                DISTRO_VER=debian
	;;

	 "archarm" | "archlinux")
		DISTRO_VER=arch
	;;
esac

# run distro setup script
if [ -f "/mnt/guest/setups/${DISTRO_VER}.sh" ]
then
	echo "[*] Starting ${DISTRO_VER} setup script..."
        bash -c ". /mnt/guest/setups/$DISTRO_VER.sh $USER_NAME $USER_UID"
else
	echo "[!] ${DISTRO_VER} currently not supported by setup scripts."
fi

echo "[+] container is ready!"
