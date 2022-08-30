#!/bin/bash
# LXC setup xfce4 or i3-gaps in Debian-based distributions
# run as root inside a Debian container, or use harbour-containers' xsession setup button

USER_NAME=$1
USER_UID=$2

# Source the configure_desktop function
source /mnt/guest/setups/configure_desktop.sh

# Choose default WM
sleep 3
printf '\033[1;32m[?] Choose [x]fce4 or [i]3 as window manager for this %s container (default=x): \033[0m' "${3^}" && read -r REPLY

# Check if user setup is required
if [ ! -d "/home/${USER_NAME}" ]
then
	# Add user without interaction
        printf "\033[0;36m[+] Creating new user '$USER_NAME', please type new password password.\033[0m\n"
        adduser --disabled-password --gecos "" --uid $USER_UID $USER_NAME
	sleep 1
        passwd $USER_NAME

	# Add android group inet for _apt and user
	echo "inet:x:3003:_apt,${USER_NAME}" >> /etc/group
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf

	# add _apt to 3003 group
	usermod -g 3003 _apt

	sleep 5
	
        # Add user to sudoers
        adduser $USER_NAME sudo

	# Make the dns change in resolv.conf permanent
	apt update
	apt install -y resolvconf
	echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/tail
	resolvconf --enable-updates
	resolvconf -u
fi

# Install base utilities for selected WM and X setup
printf "\033[0;36m[+] Installing selected WM and base utilities…\033[0m\n"

install_packages() {
    # /usr/share/alsa is mounted from the LXC config, so we don't want pacman to try overwriting files during this initial setup
    umount /usr/share/alsa

case "$REPLY" in
        "i" | "i3")
            LAUNCHCMD="exec i3"
            apt install -y i3-gaps 2> /dev/null # i3-gaps is available in some debian-based distros, but not all
            if ! type i3 > /dev/null; then
                apt install -y i3 || err=1      # Install base i3 only if i3-gaps didn't install above
            fi
            apt install -y \
                dbus-x11 \
                dconf-cli \
                dmenu \
                dunst \
                fonts-noto \
                fzf \
                hsetroot \
                i3blocks \
                i3lock \
                i3status \
                mpv \
                ncurses-term \
                onboard \
                pavucontrol \
                rofi \
                rsync \
                rxvt-unicode \
                sudo \
                thunar \
                thunar-volman \
                tumbler \
                viewnior \
                wget \
                xclip \
                xdg-user-dirs \
                xfce4-terminal \
                xsel \
                xsettingsd \
                yad \
                yt-dlp || err=1
            apt install -y firefox 2> /dev/null # Firefox is not available in Kali and would prevent installing
            		       		        # the other packages if it was inclided in the same list
            if ! type firefox > /dev/null; then
                apt install -y firefox-esr      # Install firefox-esr only if firefox didn't install above
                fi
            ;;
        "x" | "xfce" | "xfce4" | "" | *)
            LAUNCHCMD="exec startxfce4"
            apt install -y \
                dbus-x11 \
                dconf-cli \
                dmenu \
                mpv \
                ncurses-term \
                onboard \
                pavucontrol \
                rsync \
                sudo \
                thunar \
                thunar-volman \
                tumbler \
                viewnior \
                wget \
                xdg-user-dirs \
                xfce4 \
                xfce4-terminal || err=1
            apt install -y firefox 2> /dev/null # Firefox is not available in Kali and would prevent installing
            		       		        # the other packages if it was inclided in the same list
            if ! type firefox > /dev/null; then
                apt install -y firefox-esr      # Install firefox-esr only if firefox didn't install above
                fi
            ;;
    esac

    if [[ "$err" -eq "1" ]]; then
        printf "\033[0;33m\n[!] Error(s) encountered when installing base packages. This may be caused by an unstable Internet connection. [R]etry or [c]ontinue anyway? \033[0m" && read -r RETRY
        
        case "$RETRY" in
            "r" | "R" | "retry" | "Retry" | "RETRY")
                printf "Retrying to install base packages…\n"
                # Redo the above steps for resolv.conf in case they didn't work; sometimes that happens, I have not identified why yet
                echo "nameserver 8.8.8.8" >> /etc/resolv.conf
                sleep 2
        	apt update
        	apt install -y resolvconf
        	echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/tail
        	resolvconf --enable-updates
        	resolvconf -u
                install_packages
            ;;
            "c" | "C" | "continue" | "Continue" | "CONTINUE" | "" | *)
                printf "\033[0;33mIgnoring install error(s) and continuing to next step…\033[0m\n"
                sleep 2
            ;;
        esac
    fi
}

install_packages

# Mask unused services
systemctl mask lightdm
systemctl mask upower

# Download latest Xwayland binary from the sailfish-containers/xserver repo, since current Xwayland does not support XDG_WM_BASE
printf "\033[0;36m[+] Fetching prebuilt Xwayland…\033[0m\n"
ARCH=$(uname -m)
mkdir -p /opt/bin
wget https://github.com/sailfish-containers/xserver/releases/download/b1/Xwayland.${ARCH}.libc-2.29.bin \
	-O /opt/bin/Xwayland -nc -q --show-progress
chmod +x /opt/bin/Xwayland

# Link harbour-containers scripts
ln -s /mnt/guest/start_desktop.sh /opt/bin/start_desktop.sh 2> /dev/null
ln -s /mnt/guest/setup_desktop.sh /opt/bin/setup_desktop.sh 2> /dev/null
ln -s /mnt/guest/start_onboard.sh /opt/bin/start_onboard.sh 2> /dev/null
ln -s /mnt/guest/kill_xwayland.sh /opt/bin/kill_xwayland.sh 2> /dev/null

# Desktop configuration prompt
printf "\033[0;36m[+] Preconfiguring desktop with sane default settings…\033[0m\n"
if [ -e "/home/$USER_NAME/.config/i3/config" ] || [ -e "/home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml" ]; then
    printf "\033[0;33m[!] This container seems to have been configured already (possibly manually). Overwrite with defaults? [y/N] \033[0m" && read -r ANSWER
    case "$ANSWER" in
        "y" | "yes" | "Y" | "Yes" | "Yes")
            configure_desktop $3
            printf "\033[0;32mDefault configuration re-applied.\033[0m\n"
        ;;
        "n" | "no" | "N" | "No" | "NO" | "" | *)
            printf "\033[0;33mAborting desktop reconfiguration…\033[0m"
        ;;
    esac
else
    configure_desktop $3
    printf "\033[0;32mDone.\033[0m\n"
fi

# Make audio work within container
printf "\033[0;36m[+] Setting up audio (this is still work in progress for Debian-based containers, it may not work)…\033[0m\n"
usermod -aG audio $USER_NAME

# Wrap up
printf "\033[1;32m[✔] Setup complete. Press [Return] to close this terminal window. If everything went well, you should be able  to start X from the GUI.\033[0m\n"
read -r _

# Reboot the container
shutdown -h now

# # Compile Xwayland from sources - disabled for now because sources no longer support required XDG_WM_BASE
# # Add sources repository
# echo "[+] Adding sources repository"
# cp /etc/apt/sources.list /etc/apt/sources.list.d/deb-src.list
# sed -i 's/deb http/deb-src http/g' /etc/apt/sources.list.d/deb-src.list
# apt update
# cd /usr/src
# # Get Xwayland and build dependencies
# echo "[+] Get Xwayland sources and build dependencies"
# apt showsrc xwayland | sed -e '/Build-Depends/!d;s/Build-Depends: \|,\|([^)]*),*\|\[[^]]*\]//g' | grep -v "Build-Depends-Indep:" > /tmp/deplist
# apt build-dep -y xwayland
# apt source -y xwayland
# # Patch Xwayland
# echo "[+] Patching Xwayland sources"
# cd /usr/src/xwayland-*
# patch -p1 hw/xwayland/xwayland-input.c < /mnt/guest/configs/wlseat.patch
# # Make Xwayland
# echo "[+] Running configure"
# meson -Ddocs=false -Ddevel-docs=false -Dxvfb=false ../build
# echo "[!] Xwayland build process starting in 3 seconds"
# meson compile -C ../build
# echo "[+] Installing Xwayland binary…"
# meson install -C ../build
# # Copy new binary
# mkdir -p /opt/bin
# mv /usr/local/bin/Xwayland /opt/bin/Xwayland
# echo "[+] Done."
# echo "[+] Cleaning container…"
# sleep 3
# # Clean system
# cd /
# apt purge -y `cat /tmp/deplist`
# apt autoremove -y
# apt clean
# rm /etc/apt/sources.list.d/deb-src.list
# rm -rf /usr/src/*
# apt update
