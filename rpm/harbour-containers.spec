# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.27
# 

Name:       harbour-containers

# >> macros
# << macros

Summary:    sailfish-containers LXC Silica UI
Version:    0.5
Release:    1
Group:      Qt/Qt
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-containers.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   lxc-templates-desktop
Requires:   python3-gobject
Requires:   dbus-python3
Requires:   nemo-qml-plugin-dbus-qt5
Requires:   qxcompositor
Requires:   sailfish-polkit-agent
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

%description
Containers is an application to create, download, manage and run LXC containers. It relies on Xwayland to run the associated desktop environment inside a new Sailifsh window.
# This description section includes metadata for SailfishOS:Chum, see
# https://github.com/sailfishos-chum/main/blob/main/Metadata.md
%if "%{?vendor}" == "chum"
PackageName: Containers
Type: desktop-application
DeveloperName: r3vn
Categories:
 - Development
 - Utilities
 - Other
Custom:
  Repo: https://github.com/kabouik/harbour-containers
Icon: https://raw.githubusercontent.com/Kabouik/harbour-containers/master/icons/harbour-containers.svg
Screenshots:
 - https://user-images.githubusercontent.com/7107523/99102454-feeae200-25d5-11eb-935f-b846233e8808.gif
 - https://user-images.githubusercontent.com/7107523/99102434-fa262e00-25d5-11eb-853f-f203327f9a55.gif
 - https://user-images.githubusercontent.com/7107523/99102422-f5fa1080-25d5-11eb-9d74-b7a09c1a9a22.gif
Url:
  Homepage: https://github.com/kabouik/harbour-containers
  Help: https://github.com/sailfish-containers/lxc-templates-desktop/wiki
  Bugtracker: https://github.com/sailfish-containers/harbour-containers/issues
%endif

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre

# << install pre
%qmake5_install

# >> install post
chmod +x  %{buildroot}/usr/share/%{name}/service/daemon.py
chmod +x  %{buildroot}/usr/share/%{name}/scripts/host/*.sh
chmod +x  %{buildroot}/usr/share/%{name}/scripts/guest/*.sh
chmod +x  %{buildroot}/usr/share/%{name}/scripts/guest/setups/*.sh

# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/icons/hicolor/*/apps/%{name}.png
/etc/dbus-1/system.d/org.sailfishcontainers.daemon.conf
/usr/share/dbus-1/system-services/org.sailfishcontainers.daemon.service
/etc/systemd/system/sailfish-containers.service
/usr/share/polkit-1/actions/org.sailfishcontainers.daemon.policy
# >> files
# << files
