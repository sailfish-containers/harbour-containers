#!/bin/env bash
# Desktop configuration function, called from distro setup scripts
# (not meant to be run directly, it will miss arguments)
function configure_desktop() {
    # Allow user to start X
    printf "allowed_users=anybody" > /etc/X11/Xwrapper.config

    # Edit .xinitrc to expand PATH, allow touch scrolling in Firefox, source .Xressources and start selected WM at launch
    runuser -l $USER_NAME -c "head -n -1 /etc/X11/xinit/xinitrc > /home/$USER_NAME/.xinitrc"
    printf '
# harbour-containers default configuration
export "PATH=/home/%s/.local/bin:$PATH"
export MOZ_USE_XINPUT2=1
xrdb ~/.Xresources
' "$USER_NAME" >> /home/$USER_NAME/.xinitrc
    printf '%s' "$LAUNCHCMD" >> /home/$USER_NAME/.xinitrc

    # Keep polkit from bothering users at each boot
    mkdir -p /etc/polkit-1/localauthority/50-local.d
    rsync -a /mnt/guest/configs/45-allow-colord.pkla /etc/polkit-1/localauthority/50-local.d/

    # Add .xsettingsd (font anti-aliasing)
    rsync -a /mnt/guest/configs/xsettingsd /home/$USER_NAME/.xsettingsd
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xsettingsd

    # Copy wallpapers
    runuser -l $USER_NAME -c "xdg-user-dirs-update 2> /dev/null"
    rsync -a --mkpath /mnt/guest/configs/Wallpapers/ /home/$USER_NAME/Pictures/Wallpapers/
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/Pictures/Wallpapers

    # Beautify urxvt
    rsync -a --mkpath /mnt/guest/configs/urxvt/ /home/$USER_NAME/.urxvt/
    rsync -a /mnt/guest/configs/Xresources /home/$USER_NAME/.Xresources
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.urxvt
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.Xresources

    # Beautify xfce4-terminaĺ and make it use less space
    runuser -l $USER_NAME -c "mkdir -p /home/$USER_NAME/.local/bin/"
    printf '#!/bin/env bash
TERMBIN --hide-scrollbar --hide-menubar --color-bg=#222222 --zoom=-1 $@\n' > /home/$USER_NAME/.local/bin/xfce4-terminal
    TERMBIN=$(which xfce4-terminal)
    sed -i "s#TERMBIN#$TERMBIN#g" /home/$USER_NAME/.local/bin/xfce4-terminal
    chown $USER_NAME:$USERNAME /home/$USER_NAME/.local/bin/xfce4-terminal
    chmod +x /home/$USER_NAME/.local/bin/xfce4-terminal

    # Start WM-specific configurtation
    case "$REPLY" in
        "i" | "i3")
            # Import i3 configuration files
            mkdir -p /home/$USER_NAME/.config
            rsync -a --mkpath /mnt/guest/configs/config/i3/ /home/$USER_NAME/.config/i3/
            rsync -a --mkpath /mnt/guest/configs/config/i3status/ /home/$USER_NAME/.config/i3status/
            if [ "$1" = "debian" ]; then  # Debian doesn't have i3-gaps so we remove the corresponding config lines
                head -n -12 /home/$USER_NAME/.config/i3/config > /tmp/config 2> /dev/null
                mv /tmp/config /home/$USER_NAME/.config/i3/config 2> /dev/null
            fi
            chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config
            
            # Add font for i3status
            rsync -a --mkpath /mnt/guest/configs/fonts/ /home/$USER_NAME/.fonts/
            chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.fonts
            fc-cache -fv > /dev/null

            # Wallpaper
            if [ "$1" = "debian" ] || [ "$1" = "archarm" ] || [ "$1" = "archlinux" ] || [ "$1" = "kali" ]; then
                sed -i "s/PLACEHOLDER/$1/g" /home/$USER_NAME/.config/i3/config
            else
                sed -i "s/PLACEHOLDER-1/mountains/g" /home/$USER_NAME/.config/i3/config
            fi

            # Onboard
            sed 's/dock-height=200/dock-height=480/g' /mnt/guest/configs/onboard-default.conf > /tmp/onboard-i3.conf
            sed -i 's/dock-height=240/dock-height=500/g' /tmp/onboard-i3.conf
            runuser -l $USER_NAME -c "dbus-launch dconf load /org/onboard/ < /tmp/onboard-i3.conf" 2> /dev/null

            # Sway-launcher-desktop
            mkdir -p /home/$USER_NAME/.config/sway-launcher-desktop/
            wget https://github.com/Biont/sway-launcher-desktop/raw/master/sway-launcher-desktop.sh \
            	-O /home/$USER_NAME/.config/sway-launcher-desktop/sway-launcher-desktop.sh -q --show-progress
            chmod +x /home/$USER_NAME/.config/sway-launcher-desktop/sway-launcher-desktop.sh
            chown -R $USER_NAME:$USER_NAME/.config/sway-launcher-desktop

            # yt-dlp (limit quality and avoid vp9, we have no HW acceleration)
            rsync -a --mkpath /mnt/guest/configs/config/yt-dlp/ /home/$USER_NAME/.config/yt-dlp/

        ;;
        "x" | "xfce" | "xfce4" | "" | *)
            # Xfce4 settings
            rsync -a --mkpath /mnt/guest/configs/config/xfce4/xfconf/xfce-perchannel-xml/ /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/

            # Wallpaper
            if [ "$1" = "debian" ] || [ "$1" = "archarm" ] || [ "$1" = "archlinux" ] || [ "$1" = "kali" ]; then
                sed -i "s/\/usr\/share\/backgrounds\/xfce\/xfce-verticals.png/\/home\/$USER_NAME\/Pictures\/Wallpapers\/$1-2.jpg/g" \
                	/home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
            fi
	    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config

            # Onboard
            runuser -l $USER_NAME -c "dbus-launch dconf load /org/onboard/ < /mnt/guest/configs/onboard-default.conf" 2> /dev/null

            # Mousetweaks (right click emulation)
            # Skip on Debian where it is not installed because it complains about Wayland; somehow works in Arch
            if type mousetweaks > /dev/null; then
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
            fi
        ;;
    esac
}

