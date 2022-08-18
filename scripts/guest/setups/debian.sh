#!/bin/bash
# lxc setup xfce4 desktop on debian/ubuntu
# run as root inside a container

USER_NAME=$1
USER_UID=$2

# check if user setup is required
if [ ! -d "/home/${USER_NAME}" ]
then
	# add user without interaction
        echo "[+] creating new user '$USER_NAME', please enter user password."
        adduser --disabled-password --gecos "" --uid $USER_UID $USER_NAME
	sleep 1
        passwd $USER_NAME

	# add android group inet for _apt and user
	echo "inet:x:3003:_apt,${USER_NAME}" >> /etc/group
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf

	# add _apt to 3003 group
	usermod -g 3003 _apt

	sleep 1
fi

# build xwayland
# add sources repository
echo "[+] Adding sources repository"
cp /etc/apt/sources.list /etc/apt/sources.list.d/deb-src.list
sed -i 's/deb http/deb-src http/g' /etc/apt/sources.list.d/deb-src.list

apt update
cd /usr/src

# get xwayland and build dependencies
echo "[+] Get Xwayland sources and build dependencies"
apt showsrc xwayland | sed -e '/Build-Depends/!d;s/Build-Depends: \|,\|([^)]*),*\|\[[^]]*\]//g' | grep -v "Build-Depends-Indep:" > /tmp/deplist
apt build-dep -y xwayland
apt source -y xwayland

# patch xwayland
echo "[+] Patching Xwayland sources"
cd /usr/src/xorg-server-1*

patch -p1 hw/xwayland/xwayland-input.c < /mnt/guest/configs/wlseat.patch

# make xwayland
echo "[+] Running configure"
./autogen.sh --prefix=$WLD --disable-docs --disable-devel-docs \
  --enable-xwayland --disable-xorg --disable-xvfb --disable-xnest \
  --disable-xquartz --disable-xwin

echo "[!!!] Xwayland build process starting in 3 seconds"
sleep 3
make -j$(nproc  --all)

echo "[+] Installing Xwayland binary..."
# copy new binary
mkdir -p /opt/bin
cp hw/xwayland/Xwayland /opt/bin/Xwayland

echo "[+] Done."
echo "[+] Cleaning container..."
sleep 3
# Clean system
cd /
apt purge -y `cat /tmp/deplist`
apt autoremove -y
apt clean

rm /etc/apt/sources.list.d/deb-src.list
rm -rf /usr/src/xorg-server-*

apt update

# download latest xwayland binary from the repo if building from sources failed,
# else keep the built one already in /opt/bin/Xwayland (wget won' overwritte it)
ARCH=$(uname -m)
echo "[+] Fetching prebuilt Xwayland in case building above failed..."
wget https://github.com/sailfish-containers/xserver/releases/download/b1/Xwayland.${ARCH}.libc-2.29.bin -O /opt/bin/Xwayland -nc
chmod +x /opt/bin/Xwayland

# install xfce-desktop
echo "[+] Installing xfce4 and Onboard virtual keyboard"
apt install -y sudo xfce4 onboard dbus-x11 dconf-cli # Xephyr # Xephyr allow to run a display manager and rotate the screen from the container however it disable multitouch

# load sensible onboard settings
dconf load /org/onboard/ < /mnt/guest/configs/onboard-default.conf

# mask unused services
systemctl mask lightdm
systemctl mask upower

# add user to sudoers
adduser $USER_NAME sudo

# link scripts
ln -s /mnt/guest/start_desktop.sh /opt/bin/start_desktop.sh
ln -s /mnt/guest/setup_desktop.sh /opt/bin/setup_desktop.sh
ln -s /mnt/guest/start_onboard.sh /opt/bin/start_onboard.sh
ln -s /mnt/guest/kill_xwayland.sh /opt/bin/kill_xwayland.sh

echo "[+] xsession ready"
sleep 4
