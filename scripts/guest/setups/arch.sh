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
        printf "\033[0;36m[+] Creating new user '$USER_NAME', please type new password password.\033[0m\n"
        useradd -m -u $USER_UID $USER_NAME
	sleep 1
        passwd $USER_NAME

	# Add android group inet for user
	echo "inet:x:3003:root,${USER_NAME}" >> /etc/group
	echo "net_raw:x:3004:root,${USER_NAME}" >> /etc/group
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
	sleep 5

	# Make the dns change in resolv.conf permanent
	pacman -Syu --noconfirm --disable-download-timeout resolvconf
	prtinf "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/tail
	resolvconf --enable-updates
	resolvconf -u
fi

# Install base utilities for selected WM and X setup
printf "\033[0;36m[+] Installing selected WM and base utilities…\033[0m\n"

install_packages() {
    # /usr/share/alsa is mounted from the LXC config, so we don't want pacman to try overwriting files during this initial setup
    umount /usr/share/alsa
    #sed -i "s/#IgnorePkg   =/IgnorePkg   = alsa-topology-conf alsa-ucm-conf alsa-lib/g" /etc/pacman.conf

    # Base packages for either WM
    case "$REPLY" in
        "i" | "i3")
            LAUNCHCMD="exec i3"
            pacman -Syu --noconfirm --needed --disable-download-timeout \
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
                pavucontrol \
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
            pacman -Syu --noconfirm --disable-download-timeout xorg-apps || err=1 # --needed has to be dropped for xorg-apps due to a package conflict
            				                                          # that would break the script when run more than once on a container
            ;;
        "x" | "xfce" | "xfce4" | "" | *)
            LAUNCHCMD="exec startxfce4"
            pacman -Syu --noconfirm --needed --disable-download-timeout \
                dconf \
                dmenu \
                exo \
                firefox \
                garcon \
                libbsd \
                mpv \
                mousetweaks \
                pavucontrol \
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
            pacman -Syu --noconfirm --disable-download-timeout xorg-apps || err=1 # --needed has to be dropped for xorg-apps due to a package conflict
            				                                          # that would break the script when run more than once on a container
            ;;
    esac

    if [[ "$err" -eq "1" ]]; then
        printf "\033[0;33m\n[!] Error(s) encountered when installing base packages. This may be caused by an unstable Internet connection. [R]etry or [c]ontinue anyway? (default=c) \033[0m" && read -r RETRY
        
        case "$RETRY" in
            "r" | "R" | "retry" | "Retry" | "RETRY")
                printf "Retrying to install base packages…\n"
                sleep 2
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
	-O /opt/bin/Xwayland -nc -q --show-progress || err=xwayland
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
            printf "\033[0;33mAborting desktop reconfiguration…\033[0m\n"
        ;;
    esac
else
    configure_desktop $3
    printf "\033[0;32mDone.\033[0m\n"
fi

# Generate locales
printf "\033[0;36m[+] Generating en_GB.UTF-8 locale…\033[0m\n"
sed -i "s/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g" /etc/locale.gen
sed -i "s/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g" /etc/locale.gen
printf '
LANG=en_GB.utf8
LC_CTYPE="en_GB.utf8"
LC_NUMERIC="en_GB.utf8"
LC_TIME="en_GB.utf8"
LC_COLLATE="en_GB.utf8"
LC_MONETARY="en_GB.utf8"
LC_MESSAGES="en_GB.utf8"
LC_PAPER="en_GB.utf8"
LC_NAME="en_GB.utf8"
LC_ADDRESS="en_GB.utf8"
LC_TELEPHONE="en_GB.utf8"
LC_MEASUREMENT="en_GB.utf8"
LC_IDENTIFICATION="en_GB.utf8"
LC_ALL=
' > /etc/locale.conf
locale-gen

# Compile from AUR the extra packages required for Xwayland
ls /usr/lib/libselinux.so.1 &> /dev/null || err=2
ls /usr/lib/libdbus-1.so &> /dev/null || err=2

if [[ "$err" -eq "2" ]]; then
    printf "\033[1;32m[?] Xwayland depends on extra packages that have to be compiled on Arch. This will take a long time but is necessary only once per container. [C]ontinue or [s]kip (default=c)? \033[0m" && read -r SKIP
else
    printf "\033[1;32m[?] Xwayland dependencies have already been compiled for this container. Continuing will upgrade and recompile them, but will take a long time and may not be necessary. [C]ontinue or [s]kip (default=c)? \033[0m" && read -r SKIP
fi

compile_aur() {
    case "$SKIP" in
        "s" | "skip" | "S" | "Skip" | "SKIP")
            printf '\033[0;32mSkipping.\033[0m\n'
        ;;
        "c" | "C" | "continue" | "Continue" | "CONTINUE" | "" | *)
            printf "\033[0;32mCompiling dbus-x11, libsepol and libselinux from AUR. Now is a good time to brew some coffee…\033[0m\n"

            # Add user to sudoers, temporarily with no password to avoid password prompts for makepkg below
            usermod -aG wheel $USER_NAME
            sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

            # Compile and install dbus-x11, libsepol and libselinux from AUR
            pacman -Syu --needed --noconfirm --disable-download-timeout git autoconf automake binutils make pkgconf bison fakeroot gcc flex patch || err=2
            rm -rf /tmp/dbus-x11 2> /dev/null
            rm -rf /tmp/libsepol 2> /dev/null
            rm -rf /tmp/libselinux 2> /dev/null
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/dbus-x11.git /tmp/dbus-x11"
            runuser -l $USER_NAME -c "cd /tmp/dbus-x11 && yes | makepkg -AsiL --skippgpcheck --needed"
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/libsepol.git /tmp/libsepol"
            runuser -l $USER_NAME -c "cd /tmp/libsepol && makepkg -siL --noconfirm --skippgpcheck --needed"
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/libselinux.git /tmp/libselinux"
            runuser -l $USER_NAME -c "cd /tmp/libselinux && makepkg -siL --noconfirm --skippgpcheck --needed"

	    err=0
	    ls /usr/lib/libselinux.so.1 &> /dev/null || err=2
            ls /usr/lib/libdbus-1.so &> /dev/null || err=2

            if [[ "$err" -eq "2" ]]; then
                printf "\033[0;31m[!] Error(s) encountered. Please check your Internet connection. If errors persist and you cannot start X when ignoring them, then please open an issue on Github with the above logs. [R]etry or [c]ontinue anyway (default=r)? \033[0m" && read -r RETRY2

                case "$RETRY2" in
                    "r" | "R" | "retry" | "Retry" | "RETRY")
                        printf "Retrying…\n"
                        sleep 2
                        compile_aur
                    ;;
                    "c" | "C" | "continue" | "Continue" | "CONTINUE" | "" | *)
                        printf "\033[0;33mIgnoring compile error(s)…\033[0m\n"
                        sleep 2
                    ;;
                esac
            fi
        ;;
    esac

}

compile_aur

# Make audio work within container
printf "\033[0;36m[+] Setting up audio…\033[0m\n"
usermod -aG audio $USER_NAME

# Change /etc/sudoers to prompt user for password on sudo again
sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

# Wrap up
printf "\033[1;32m[✔] Setup complete. Press [Return] to close this terminal window. If everything went well, you should be able to start X from the GUI.\033[0m\n"
read -r _

# Reboot the container
shutdown -h now
