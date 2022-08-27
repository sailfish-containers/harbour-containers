#!/bin/env bash
# LXC setup xfce4 or i3-gaps in Arch-based distributions
# run as root inside a Arch container, or use harbour-containers' xsession setup button

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
        printf "\033[1;36m\n[+] Creating new user '$USER_NAME', please enter user password.\033[0m\n"
        useradd -m -u $USER_UID $USER_NAME
	sleep 1
        passwd $USER_NAME

	# Add android group inet for user
	echo "inet:x:3003:root,${USER_NAME}" >> /etc/group
	echo "net_raw:x:3004:root,${USER_NAME}" >> /etc/group
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
	sleep 5

	# Make the dns change in resolv.conf permanent
	pacman -Syu --noconfirm resolvconf
	prtinf "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/tail
	resolvconf --enable-updates
	resolvconf -u
fi

# Install base utilities for selected WM and X setup
printf "\033[0;36m[+] Installing selected WM and base utilities…\033[0m\n"
case "$REPLY" in
    "i" | "i3")
        LAUNCHCMD="exec i3"
        pacman -Syu --noconfirm --needed \
            dconf \
            dmenu \
            dunst \
            firefox \
            fzf \
            hsetroot \
            i3blocks \
            i3-gaps \
            i3lock \
            i3status \
            libbsd \
            mpv \
            mousetweaks \
            noto-fonts \
            onboard \
            rofi \
            rsync \
            rxvt-unicode \
            sudo \
            thunar \
            thunar-volman \
            ttf-dejavu \
            tumbler \
            viewnior \
            wget \
            xclip \
            xdg-user-dirs \
            xfce4-terminal \
            xsel \
            xsettingsd \
            xorg-server \
            xorg-xinit \
            yad \
            yt-dlp || err=1
        pacman -Syu --noconfirm xorg-apps || err=1 # --needed has to be dropped for xorg-apps due to a package conflict
        				           # that would break the script when run more than once on a container
        ;;
    "x" | "xfce" | "xfce4" | "" | *)
        LAUNCHCMD="exec startxfce4"
        pacman -Syu --noconfirm --needed \
            dconf \
            dmenu \
            exo \
            firefox \
            garcon \
            libbsd \
            mpv \
            mousetweaks \
            onboard \
            rsync \
            rxvt-unicode \
            sudo \
            thunar \
            thunar-volman \
            ttf-dejavu \
            tumbler \
            viewnior \
            wget \
            xdg-user-dirs \
            xfce4-appfinder \
            xfce4-panel \
            xfce4-power-manager \
            xfce4-session \
            xfce4-settings \
            xfce4-terminal \
            xfconf \
            xfdesktop \
            xfwm4 \
            xfwm4-themes \
            xorg-server \
            xorg-xinit || err=1
        pacman -Syu --noconfirm xorg-apps || err=1 # --needed has to be dropped for xorg-apps due to a package conflict
        				           # that would break the script when run more than once on a container
        ;;
esac

if [[ "$err" -eq "1" ]]; then
    sep="\n---\n"
    printf "\033[0;33m\n[!] Some errors have been encountered when installing packages. They are not necessarily critical, you may proceed to the next step. If however the container does not work properly at the end, please check that your Internet connection is stable, try again, and open an issue on Github with the above logs. Continue? [Y/n] \033[0m" && read -r CONTINUE1
    
    case "$CONTINUE1" in
        "n" | "no" | "N" | "No" | "NO")
            printf "Aborting setup…\n"
            sleep 3
            exit
        ;;
        "y" | "yes" | "Y" | "Yes" | "Yes" | "" | *)
            printf "\033[0;33mIgnoring the install error(s)…\033[0m\n"
        ;;
    esac
fi 

# Mask unused services
systemctl mask lightdm
systemctl mask upower

# Download latest Xwayland binary from the sailfish-containers/xserver repo,
# since current Xwayland does not support XDG_WM_BASE
ARCH=$(uname -m)
printf "\033[0;36m[+] Fetching prebuilt Xwayland…\033[0m\n"
mkdir -p /opt/bin
wget https://github.com/sailfish-containers/xserver/releases/download/b1/Xwayland.${ARCH}.libc-2.29.bin \
	-O /opt/bin/Xwayland -nc -q --show-progress || err=xwayland
chmod +x /opt/bin/Xwayland

# Link harbour-containers scripts
ln -s /mnt/guest/start_desktop.sh /opt/bin/start_desktop.sh
ln -s /mnt/guest/setup_desktop.sh /opt/bin/setup_desktop.sh
ln -s /mnt/guest/start_onboard.sh /opt/bin/start_onboard.sh
ln -s /mnt/guest/kill_xwayland.sh /opt/bin/kill_xwayland.sh

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
            printf "Aborting desktop reconfiguration…\n"
        ;;
    esac
else
    configure_desktop $3
    printf "\033[0;32mDone.\033[0m\n"
fi

# Compile from AUR the extra packages required for Xwayland
printf "\033[1;32m[?] Extra packages Xwayland depends on have to be compiled. This will take a long time but should only be necessary once per container. If this one has already been set up to launch X (even another WM), then this step can be skipped. Skip? [y/N] \033[0m" && read -r SKIP

    # Add user to sudoers, temporarily with no password to avoid password prompts for makepkg below
    usermod -aG wheel $USER_NAME
    sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

    case "$SKIP" in
        "y" | "yes" | "Y" | "Yes" | "Yes")
            printf '\033[0;32mSkipping.\033[0m\n'
        ;;
        "n" | "no" | "N" | "No" | "NO" | "" | *)
            printf "\033[0;32mCompiling dbus-x11, libsepol and libselinux from AUR. A good time to brew some coffee…\033[0m\n"
            # Compile and install dbus-x11, libsepol and libselinux from AUR
            pacman -Syu --needed --noconfirm git autoconf automake binutils make pkgconf bison fakeroot gcc flex patch
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/dbus-x11.git /tmp/dbus-x11"
            runuser -l $USER_NAME -c "cd /tmp/dbus-x11 && yes | makepkg -AsiL --skippgpcheck --needed" || err=2
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/libsepol.git /tmp/libsepol"
            runuser -l $USER_NAME -c "cd /tmp/libsepol && makepkg -siL --noconfirm --skippgpcheck --needed" || err=2
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/libselinux.git /tmp/libselinux"
            runuser -l $USER_NAME -c "cd /tmp/libselinux && makepkg -siL --noconfirm --skippgpcheck --needed" || err=2

            if [[ "$err" -eq "2" ]]; then
                sep="\n---\n"
                printf "\033[0;31m[!] Failed to compile and install dependencies for Xwayland, check your Internet connection and retry. If the error persists and you cannot start X, then please open an issue on Github with the above logs. Continue anyway? [y/N] \033[0m" && read -r CONTINUE2

                case "$CONTINUE2" in
                    "y" | "yes" | "Y" | "Yes" | "Yes")
                        printf "\033[0;33mIgnoring the error(s)…\033[0m\n"
                    ;;
                    "n" | "no" | "N" | "No" | "NO" | "" | *)
                        printf "Aborting setup…\n"
                        sleep 3
                        exit
                    ;;
                esac
            fi
        ;;
    esac

    # Change /etc/sudoers to prompt user for password on sudo again
    sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

# Wrap up
printf "\033[1;32m[Success] Xsession ready. Press [Return] to close this terminal window. You will then be able to start X from the GUI.\033[0m\n"
read -r _

# Reboot the container
shutdown -h now
