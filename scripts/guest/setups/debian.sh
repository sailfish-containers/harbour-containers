#!/bin/bash
# lxc setup xfce4 desktop on debian/ubuntu
# run as root inside a container

# check if user setup is required
if [ ! -d "/home/${USER_NAME}" ]
then
	# add user without interaction
	adduser --disabled-password --gecos "" --uid $USER_UID $USER_NAME
	sleep 1

	# add android group inet for _apt and user
	echo "inet:x:3003:_apt,${USER_NAME}" >> /etc/group
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf

	# add _apt to 3003 group
	usermod -g 3003 _apt

	sleep 1
fi

# update repos
apt update

# install xfce-desktop
apt install -y sudo xfce4 curl

# add user to sudoers
adduser user sudo
