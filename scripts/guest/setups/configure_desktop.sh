#!/bin/env bash
# Desktop configuration function, called from distro setup scripts
# (not meant to be run directly, it will miss arguments)
function configure_desktop() {
    case "$REPLY" in
        "i" | "i3")
           # Onboard
            sed 's/dock-height=200/dock-height=480/g' /mnt/guest/configs/onboard-default.conf > /tmp/onboard-i3.conf
            sed -i 's/dock-height=240/dock-height=500/g' /tmp/onboard-i3.conf
            runuser -l $USER_NAME -c "dbus-launch dconf load /org/onboard/ < /tmp/onboard-i3.conf" 2> /dev/null

           # Nitrogen
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
file=/home/%s/Pictures/Wallpapers/PLACEHOLDER-1.jpg
mode=5
bgcolor=#000000
' "$USER_NAME" > /home/$USER_NAME/.config/nitrogen/bg-saved.cfg
            if [ "$1" = "debian" ] || [ "$1" = "archarm" ] || [ "$1" = "archlinux" ] || [ "$1" = "kali" ]; then
                sed -i "s/PLACEHOLDER/$1/g" /home/$USER_NAME/.config/nitrogen/bg-saved.cfg
            else
                sed -i "s/PLACEHOLDER-1/mountains/g" /home/$USER_NAME/.config/nitrogen/bg-saved.cfg
            fi
            chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config

           # i3
           mkdir -p /home/$USER_NAME/.config/i3/
           head -n -11 /etc/i3/config > /home/$USER_NAME/.config/i3/config
           sed -i "11a\set \$mod Mod1\n" /home/$USER_NAME/.config/i3/config
           printf '########## harbour-containers default styling ##########
# Wallpaper
exec_always --no-startup-id "sleep 2; nitrogen --restore"

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
            if [ "$1" = "debian" ]; then
                head -n -6 /home/$USER_NAME/.config/i3/config > /tmp/config 2> /dev/null
                mv /tmp/config /home/$USER_NAME/.config/i3/config 2> /dev/null
            fi
            chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/i3
            ;;
        "x" | "xfce" | "xfce4" | "" | *)
            # Xfce4 settings
            mkdir -p /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml
            cp -a /mnt/guest/configs/xfce4/xfconf/xfce-perchannel-xml/. /home/$USER_NAME/.config/xfce4/xfconf/xfce-perchannel-xml/

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

    # Copy wallpapers
    runuser -l $USER_NAME -c "xdg-user-dirs-update 2> /dev/null"
    cp -r /mnt/guest/configs/Wallpapers /home/$USER_NAME/Pictures/
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/Pictures/Wallpapers

    # Beautify xfce4-terminaĺ and make it use less space
    runuser -l $USER_NAME -c "mkdir -p /home/$USER_NAME/.local/bin/"
    printf '#!/bin/env bash
TERMBIN --hide-scrollbar --hide-menubar --color-bg=#222222 --zoom=-1 $@\n' > /home/$USER_NAME/.local/bin/xfce4-terminal
    TERMBIN=$(which xfce4-terminal)
    sed -i "s#TERMBIN#$TERMBIN#g" /home/$USER_NAME/.local/bin/xfce4-terminal
    chown $USER_NAME:$USERNAME /home/$USER_NAME/.local/bin/xfce4-terminal
    chmod +x /home/$USER_NAME/.local/bin/xfce4-terminal
}

