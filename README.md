# harbour-containers
<p align="center"><img src="https://raw.githubusercontent.com/sailfish-containers/harbour-Containers/master/icons/172x172/harbour-containers.png" width = 96></p>
<p align="center"><i>A Linux containers manager for SailfishOS</i></p>

### Documentation
#### What is it?
`harbour-containers` is a SailfishOS application to create, download, manage and run LXC containers. It currently relies on `XWayland` to run the associated desktop environment inside a new Sailifsh window:

![](https://user-images.githubusercontent.com/7107523/99102454-feeae200-25d5-11eb-935f-b846233e8808.gif)

This makes it possible to run almost any Linux desktop application, as long as there is a version compiled for your architecture. See for instance `rofi` and `Darktable` below:

![](https://user-images.githubusercontent.com/7107523/99102434-fa262e00-25d5-11eb-853f-f203327f9a55.gif)

While LXC containers of desktop Linux distributions are most convenient with a hardware keyboard, you can also use `Onboard` if your smartphone has no hardware keyboard:

![](https://user-images.githubusercontent.com/7107523/99102422-f5fa1080-25d5-11eb-9d74-b7a09c1a9a22.gif)

A video showcasing what LXC containers can do on SailfishOS is available [here](https://youtu.be/-dgD5jci8Dk).

#### How to use it?
Before proceeding, it's important to take a look at LXC kernel requirements:
 - [LXC requirements](https://github.com/sailfish-containers/lxc-templates-desktop/wiki/Requirements)
 - [lxc-templates-desktop's wiki](https://github.com/sailfish-containers/lxc-templates-desktop/wiki)

The application also has dependencies that you can install this way:

```
devel-su zypper in nemo-qml-plugin-dbus-qt5 sailfish-polkit-agent python3-base python3-gobject dbus-python3
```

You will also need to manually download the latest releases of [`lxc-templates-desktop`](https://github.com/sailfish-containers/lxc-templates-desktop) and [`qxdisplay`](https://github.com/sailfish-containers/qxdisplay) and install them either from your Sailfish file manager or using:

```
devel-su zypper in lxc-templates-dekstop-<VERSION>.rpm
devel-su zypper in qxdisplay-<VERSION>.rpm
```

Then install the latest `harbour-containers` release from your Sailfish file manager or using:

```
devel-su zypper in harbour-containers-<VERSION>.rpm`
```

### License

This project is proudly licensed under GNU GPLv3.

### Credits

A big "Thank you" to all the testers and contributors:
 - [g7](https://github.com/g7)
 - [eLtMosen](https://github.com/eLtMosen)
 - [kabouik](https://github.com/Kabouik)
