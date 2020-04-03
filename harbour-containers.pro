# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-containers

CONFIG += sailfishapp

SOURCES += src/harbour-containers.cpp

scripts-dir.path = /usr/share/harbour-containers/scripts

scripts-dir-guest.path = /usr/share/harbour-containers/scripts/guest
scripts-dir-guest.files = scripts/guest/*.sh

scripts-dir-guest-sessions.path = /usr/share/harbour-containers/scripts/guest/sessions
scripts-dir-guest-sessions.files = scripts/guest/sessions/*.sh

scripts-dir-guest-setups.path = /usr/share/harbour-containers/scripts/guest/setups
scripts-dir-guest-setups.files = scripts/guest/setups/*.sh

scripts-dir-host.path = /usr/share/harbour-containers/scripts/host
scripts-dir-host.files = scripts/host/*.sh

systemd-dbus.path = /usr/share/dbus-1/system-services
systemd-dbus.files = systemd/org.sailfishcontainers.daemon.service

systemd-config.path = /etc/dbus-1/system.d
systemd-config.files = systemd/org.sailfishcontainers.daemon.conf

systemd-main.path = /etc/systemd/system
systemd-main.files = systemd/sailfish-containers.service

service.path = /usr/share/harbour-containers/service
service.files = service/*.py

service-libs.path = /usr/share/harbour-containers/service/libs
service-libs.files = service/libs/*.py

INSTALLS += scripts-dir \
    scripts-dir-guest \
    scripts-dir-guest-sessions \
    scripts-dir-guest-setups \
    scripts-dir-host \
    service \
    service-libs \
    systemd-dbus \
    systemd-config \
    systemd-main

DISTFILES += qml/harbour-containers.qml \
    qml/cover/CoverPage.qml \
    qml/pages/CreateDialog.qml \
    qml/pages/HomePage.qml \
    qml/pages/MachineSettings.qml \
    qml/pages/MachineSnapshots.qml \
    qml/pages/MachineView.qml \
    rpm/harbour-containers.spec \
    rpm/harbour-containers.changes.in \
    rpm/harbour-containers.changes.run.in \
    rpm/harbour-containers.yaml \
    translations/*.ts \
    harbour-containers.desktop \
    service/*.py \
    systemd/* \
    service/libs/*.py \
    scripts/guest/*.sh \
    scripts/guest/*.sh \
    scripts/guest/sessions/*.sh \
    scripts/guest/setups/*.sh \
    scripts/host/*.sh

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-containers-de.ts
