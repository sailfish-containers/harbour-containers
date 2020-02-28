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
TARGET = harbour-Containers

CONFIG += sailfishapp

SOURCES += src/harbour-Containers.cpp

DISTFILES += qml/harbour-Containers.qml \
    qml/cover/CoverPage.qml \
    qml/pages/CreateDialog.qml \
    qml/pages/HomePage.qml \
    qml/pages/MachineSettings.qml \
    qml/pages/MachineView.qml \
    rpm/harbour-Containers.changes.in \
    rpm/harbour-Containers.changes.run.in \
    rpm/harbour-Containers.spec \
    rpm/harbour-Containers.yaml \
    translations/*.ts \
    harbour-Containers.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-Containers-de.ts
