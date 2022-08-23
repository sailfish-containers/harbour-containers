#!/bin/env bash
# LXC setup xfce4 or i3-gaps in Arch-based distributions
# run as root inside a Arch container, or use harbour-containers' xsession setup button

USER_NAME=$1
USER_UID=$2

# Choose default WM
printf "\033[1;32m[?] Choose default window manager for the container: [x]fce4, [i]3-gaps (default=x): \033[0m" && read -r REPLY

# Check if user setup is required
if [ ! -d "/home/${USER_NAME}" ]
then
	# Add user without interaction
        printf "\033[1;36m\n[+] Creating new user '$USER_NAME', please enter user password.\033[0m\n"
        useradd -m -u $USER_UID $USER_NAME
	sleep 1
        passwd $USER_NAME

	# Add android group inet for user
	printf "inet:x:3003:root,${USER_NAME}" >> /etc/group
	printf "net_raw:x:3004:root,${USER_NAME}" >> /etc/group
	printf "nameserver 8.8.8.8" >> /etc/resolv.conf
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
    "i" | "i3" | "i3gaps" | "i3-gaps")
        LAUNCHCMD="exec i3"
        pacman -Syu --noconfirm --needed \
            dconf \
            dmenu \
            firefox \
            i3blocks \
            i3-gaps \
            i3lock \
            i3status \
            libbsd \
            mousetweaks \
            nitrogen \
            onboard \
            rofi \
            sudo \
            thunar \
            thunar-volman \
            tumbler \
            viewnior \
            wget \
            xdg-user-dirs \
            xfce4-terminal \
            xorg-server \
            xorg-xinit
        pacman -Syu --noconfirm xorg-apps # --needed has to be dropped for xorg-apps due to a package conflict
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
            mousetweaks \
            onboard \
            rofi \
            sudo \
            thunar \
            thunar-volman \
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
            xorg-xinit
        pacman -Syu --noconfirm xorg-apps # --needed has to be dropped for xorg-apps due to a package conflict
        				  # that would break the script when run more than once on a container
        ;;
esac

# Mask unused services
systemctl mask lightdm
systemctl mask upower

# Download latest Xwayland binary from the sailfish-containers/xserver repo,
# since current Xwayland does not support XDG_WM_BASE
ARCH=$(uname -m)
printf "\033[0;36m[+] Fetching prebuilt Xwayland…\033[0m\n"
mkdir -p /opt/bin
wget https://github.com/sailfish-containers/xserver/releases/download/b1/Xwayland.${ARCH}.libc-2.29.bin \
	-O /opt/bin/Xwayland -nc -q --show-progress
chmod +x /opt/bin/Xwayland

# Link harbour-containers scripts
ln -s /mnt/guest/start_desktop.sh /opt/bin/start_desktop.sh
ln -s /mnt/guest/setup_desktop.sh /opt/bin/setup_desktop.sh
ln -s /mnt/guest/start_onboard.sh /opt/bin/start_onboard.sh
ln -s /mnt/guest/kill_xwayland.sh /opt/bin/kill_xwayland.sh

# Desktop configuration
configure_desktop() {
    case "$REPLY" in
        "i" | "i3" | "i3gaps" | "i3-gaps")
           # onboard
            sed 's/dock-height=200/dock-height=480/g' /mnt/guest/configs/onboard-default.conf > /tmp/onboard-i3.conf
            sed -i 's/dock-height=240/dock-height=500/g' /tmp/onboard-i3.conf
            runuser -l $USER_NAME -c "dbus-launch dconf load /org/onboard/ < /tmp/onboard-i3.conf"

           # nitrogen
            mkdir -p /home/$USER_NAME/.config/nitrogen
            printf '[geometry]
posx=-1
posy=-1
sizex=400
sizey=400

[nitrogen]
view=icon
recurse=true
sort=alpha
icon_caps=false
dirs=/home/%s/Pictures/Wallpapers;
' "$USER_NAME" > /home/$USER_NAME/.config/nitrogen/nitrogen.cfg
            printf '[xin_-1]
file=/home/%s/Pictures/Wallpapers/arch_wallpaper.jpg
mode=4
bgcolor=#000000
' "$USER_NAME" > /home/$USER_NAME/.config/nitrogen/bg-saved.cfg
            chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/nitrogen

            # xfce4-terminaĺ
            runuser -l $USER_NAME -c "mkdir -p /home/$USER_NAME/.local/bin/"
            printf '#!/bin/env bash
/sbin/xfce4-terminal --hide-scrollbar --hide-menubar\n' > /home/$USER_NAME/.local/bin/xfce4-terminal
            chown $USER_NAME:$USERNAME /home/$USER_NAME/.local/bin/xfce4-terminal
            chmod +x /home/$USER_NAME/.local/bin/xfce4-terminal

           # i3-gaps
           mkdir -p /home/$USER_NAME/.config/i3/
           head -n -11 /etc/i3/config > /home/$USER_NAME/.config/i3/config
           sed -i "11a\set \$mod Mod1\n" /home/$USER_NAME/.config/i3/config
           printf '########## harbour-containers default styling ##########
# Wallpaper
exec_always --no-startup-id "sleep 3; nitrogen --restore"

# mousetweaks (enable long press to emulate right click)
exec_always --no-startup-id "mousetweaks --ssc --ssc-time=0.5 --threshold=30 --daemonize"

# Windows
# class                 border  backgr. text    indicator child_border
client.focused          #404552 #404552 #fafafa #ff5757 #5294E2
client.focused_inactive #666666 #404552 #eeeeee #666666 #262626
client.unfocused        #404552 #484b52 #eeeeee #ff5757 #262626
client.urgent           #ff5757 #404552 #ffffff #555757 #EFEDEC
client.background       #404552
new_window 1pixel
smart_borders no_gaps
smart_gaps on
gaps outer 0
gaps inner 10
set $gaps_inner 10
set $gaps_variation 4
' >> /home/$USER_NAME/.config/i3/config
	    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/i3
            ;;
        "x" | "xfce" | "xfce4" | "" | *)
            # xfce4 settings
            mkdir -p /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml
            cp -a /mnt/guest/configs/xfce4/xfconf/xfce-perchannel-xml/. /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/
            sed -i 's/\/usr\/share\/backgrounds\/xfce\/xfce-verticals.png/\/home\/$USER_NAME\/Pictures\/Wallpapers\/arch_wallpaper.jpg/g' \
            	/home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
	    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/xfce4

            # onboard
            runuser -l $USER_NAME -c "dbus-launch dconf load /org/onboard/ < /mnt/guest/configs/onboard-default.conf"

            # mousetweaks (right click emulation)
            mkdir -p /home/$USER_NAME/.config/autostart
            printf '[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=mousetweaks
Comment=Enable long press to emulate right click
Exec=mousetweaks --ssc --ssc-time=0.5 --threshold=30 --daemonize
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
' > /home/$USER_NAME/.config/autostart/mousetweaks.desktop
	    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/autostart
        ;;
    esac

    # Allow user to start X
    printf "allowed_users=anybody" > /etc/X11/Xwrapper.config

    # Edit .xinitrc to expand PATH, allow touch scrolling in Firefox, and start selected WM at launch
    runuser -l $USER_NAME -c "head -n -1 /etc/X11/xinit/xinitrc > /home/$USER_NAME/.xinitrc"
    printf '
# harbour-containers default configuration
export "PATH=/home/%s/.local/bin:$PATH"
export MOZ_USE_XINPUT2=1
' "$USER_NAME" >> /home/$USER_NAME/.xinitrc
    printf '%s' "$LAUNCHCMD" >> /home/$USER_NAME/.xinitrc

    # .Xdefaults
    printf '
Xft.dpi: 180
xterm*font:     *-fixed-*-*-*-20-*
Sxiv.background: #222222
Sxiv.foreground: #ffffff
Sxiv.font: mono-10;
' > /home/$USER_NAME/.Xdefaults
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.Xdefaults

    # Keep polkit from bothering users at each boot
    mkdir -p /etc/polkit-1/localauthority/50-local.d
    cp /mnt/guest/configs/45-allow-colord.pkla /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla

    # Move wallpaper
    runuser -l $USER_NAME -c "xdg-user-dirs-update 2> /dev/null"
    runuser -l $USER_NAME -c "mkdir -p /home/$USER_NAME/Pictures/Wallpapers"
    cp /mnt/guest/configs/wallpapers/arch_wallpaper.jpg /home/$USER_NAME/Pictures/Wallpapers/
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/Pictures/Wallpapers
}

# Configuration prompt
printf "\033[0;36m[+] Preconfiguring desktop with sane default settings…\033[0m\n"
if [ -e "/home/$USER_NAME/.config/nitrogen/bg-saved.cfg" ] || [ -e "/home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml" ]; then
    printf "\033[0;33m[!] This container seems to have been configured already (possibly manually). Overwrite with defaults? [y/N] \033[0m" && read -r ANSWER
    case "$ANSWER" in
        "y" | "yes" | "Y" | "Yes" | "Yes")
            configure_desktop
            printf "\033[0;32mDefault configuration re-applied.\033[0m\n"
        ;;
        "n" | "no" | "N" | "No" | "NO" | "" | *)
            printf "Aborting desktop reconfiguration…\n"
        ;;
    esac
else
    configure_desktop
    printf "\033[0;32mDone.\033[0m\n"
fi

# Compile from AUR the extra packages required for Xwayland
printf "\033[1;32m[?] Extra packages Xwayland depends on have to be compiled. This will take a long time but should only
    be done once per container. If this one has already been set up to launch X, this step can be skipped.
    Skip? [y/N] \033[0m" && read -r SKIP

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
            runuser -l $USER_NAME -c "cd /tmp/dbus-x11 && yes | makepkg -AsiL --skippgpcheck --needed"
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/libsepol.git /tmp/libsepol"
            runuser -l $USER_NAME -c "cd /tmp/libsepol && makepkg -siL --noconfirm --skippgpcheck --needed"
            runuser -l $USER_NAME -c "git clone https://aur.archlinux.org/libselinux.git /tmp/libselinux"
            runuser -l $USER_NAME -c "cd /tmp/libselinux && makepkg -siL --noconfirm --skippgpcheck --needed"
        ;;
    esac

    # Change /etc/sudoers to prompt user for password on sudo again
    sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

# Wrap up
printf "\033[1;32m[Success] Xsession ready. Press [Return] to close this terminal window.
          You will then be able to start X from the GUI.\033[0m\n"
read -r _

# Reboot the container
shutdown -h now
