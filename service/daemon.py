#!/usr/bin/env python3
# Sailifish Containers dbus service

from gi.repository import GLib
from dbus.mainloop.glib import DBusGMainLoop

from libs import lxc, qxcompositor

import dbus
import dbus.service
import pathlib
import os

DBUS_IFACE="org.sailfishcontainers.daemon"

class ContainersService(dbus.service.Object):
    def __init__(self, conn=None, object_path=None, bus_name=None):
        """ sailfish-containers dbus daemon """

        # init dbus
        dbus.service.Object.__init__(self, conn, object_path, bus_name)

        # daemon config
        self.user_name = os.getlogin()
        self.user_uid  = 100000
        self.current_path = pathlib.Path(__file__).parent.parent.absolute()

        # daemon cache
        self.containers      = {} # available lxc containers
        self.processes       = {} # lxc running processes
        self.templates       = {} # "raw" templates cache
        self.display_counter = 0  # qxcompositor's display sockets

        # polkit auth
        self.dbus_info = None
        self.polkit    = None


    def _check_polkit_privilege(self, sender, conn, privilege):
        # Get Peer PID
        if self.dbus_info is None:
            # Get DBus Interface and get info thru that
            self.dbus_info = dbus.Interface(conn.get_object(
                    "org.freedesktop.DBus",
                    "/org/freedesktop/DBus/Bus",
                    False
                ),
                "org.freedesktop.DBus"
            )
        pid = self.dbus_info.GetConnectionUnixProcessID(sender)

        # Query polkit
        if self.polkit is None:
            self.polkit = dbus.Interface(dbus.SystemBus().get_object(
                    "org.freedesktop.PolicyKit1",
                    "/org/freedesktop/PolicyKit1/Authority",
                    False
                ),
                "org.freedesktop.PolicyKit1.Authority"
            )

        # Check auth against polkit; if it times out, try again
        try:
            auth_response = self.polkit.CheckAuthorization(
                ("unix-process", {
                    "pid": dbus.UInt32(pid, variant_level=1),
                    "start-time": dbus.UInt64(0, variant_level=1)
                }),
                privilege,
                {"AllowUserInteraction": "true"},
                dbus.UInt32(1),
                "",
                timeout=600
                )

            #print(auth_response)
            (is_auth, _, details) = auth_response

        except dbus.DBusException as e:
            if e._dbus_error_name == "org.freedesktop.DBus.Error.ServiceUnknown":
                # polkitd timeout, retry
                self.polkit = None
                return self._check_polkit_privilege(sender, conn, privilege)
            else:
                # it's another error, propagate it
                raise

        if not is_auth:
            # not authorized
            return False
        return True

    def _dbus_dict(self):
        """ Fix dictionary for dbus """
        list_out = []

        for container in self.containers:
            list_out.append(dbus.Dictionary({
                    'container_name'     : self.containers[container]["container_name"],
                    'container_status'   : self.containers[container]["container_status"],
                    'container_pid'      : self.containers[container]["container_pid"],
                    'container_cpu'      : self.containers[container]["container_cpu"],
                    'container_mem'      : self.containers[container]["container_mem"],
                    'container_kmem'     : self.containers[container]["container_kmem"],
                    'container_rootfs'   : self.containers[container]["container_rootfs"],
                }, signature='sv'))

        return list_out

    def _refresh(self):
        """ refresh cache """

        # get containers
        self.containers = lxc.get_containers()

    def _create_display(self, screen_orientation):
        """ create a qxcompositor display """

        self.display_counter +=1
        display = qxcompositor.new(self.user_name, "%d" % self.display_counter, self.user_uid, self.current_path, screen_orientation)

        return "%d" % self.display_counter

    def _get_templates_names(self):
        """ Get templates name from cache """

        self.templates = lxc.get_templates()
        dist = []

        for template in self.templates:
            dist.append(template["dist"])

        unique = list(set(dist)) # return unique list
        return unique

    def _get_template_version(self, tpl):
        """ Get template version from cache """

        if len(self.templates) < 1:
            self.templates = lxc.get_templates() # init cache

        versions = []

        for template in self.templates:
            if template["dist"] == tpl:
                versions.append(template["release"])

        unique = list(set(versions)) # return unique versions list
        return unique

    def _add_guest_mp(self, name):
        """ add scripts mountpoint to container """

        return lxc.add_mountpoint(name, "%s/scripts/guest" % self.current_path, "mnt/guest", False)

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_init_config(self, name, sender=None, conn=None):
        """ add required mountpoints on container's config """
        if self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE):
            # user authenticated
           if self._add_guest_mp(name):

                return True
        return False

    @dbus.service.method(DBUS_IFACE)
    def container_start(self, name):
        """ start lxc container """
        self._refresh()

        #if self.containers[name]["container_status"] == "STOPPED": # fix for new containers
        try:
            lxc.start(name)

            return True
        except: pass

        return False

    @dbus.service.method(DBUS_IFACE)
    def container_stop(self, name):
        """ stop lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            lxc.stop(name)

            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def container_freeze(self, name):
        """ freeze/unfreeze lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            # freeze container
            lxc.freeze(name)

            return True

        elif self.containers[name]["container_status"] == "FROZEN":
            # unfreeze
            lxc.unfreeze(name)

            return True

        return False

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_destroy(self, name, sender=None, conn=None):
        """ destroy lxc container """
        if self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "STOPPED":

                lxc.destroy(name)
                return True

        return False

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="a{sv}",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_snapshot_new(self, name, sender=None, conn=None):
        """ take container's snapshot """
        if self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "STOPPED":
                try:
                    # get popen object
                    proc = lxc.take_snapshot(name)

                    # store popen on running processes
                    self.processes[str(proc.pid)] = proc

                    return dbus.Dictionary({ "result" : True, "pid": dbus.String(str(proc.pid)) }, signature="sv")
                except:
                    return dbus.Dictionary({ "result" : False, "err": dbus.String("snapshot failed")}, signature="sv")

            return dbus.Dictionary({ "result" : False, "err": dbus.String("container running") }, signature="sv")
        return dbus.Dictionary({ "result" : False, "err": "auth failed." }, signature="sv")

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_snapshot_delete(self, name, snapshot_name, sender=None, conn=None):
        """ delete container's snapshot """
        if self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "STOPPED":
                lxc.delete_snapshot(name, snapshot_name)

                return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def container_get_mounts(self, name):
        """ get container's mountpoints """
        if name in self.containers:
            return lxc.get_mounts(name)

    @dbus.service.method(DBUS_IFACE)
    def container_get_snapshots(self, name):
        """ get container's snapshots """
        if name in self.containers:
            snapshots = lxc.get_snapshots(name)

            if len(snapshots) < 1:
                return false

            return snapshots

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="a{sv}",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_create(self, name, dist, arch, release, sender=None, conn=None):
        """ create containers from template """
        if self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE):
            # user authenticated
            self._refresh()

            # check if selected template exist
            ct_found = False

            for tpl in self.templates:
                if tpl["dist"] == dist and tpl["arch"] == arch and tpl["release"] == release:
                    ct_found = True

            # check if container exits
            if not name in self.containers and ct_found:
                try:
                    # get popen object
                    proc = lxc.create(name, dist, arch, release)

                    # store popen on running processes
                    self.processes[str(proc.pid)] = proc

                    return dbus.Dictionary({ "result" : True, "pid": dbus.String(str(proc.pid)) }, signature="sv")
                except:
                    return dbus.Dictionary({ "result" : False, "err": dbus.String("lxc-create failed")}, signature="sv")

            return dbus.Dictionary({ "result" : False, "err": dbus.String("container exist") }, signature="sv")
        return dbus.Dictionary({ "result" : False, "err": "auth failed." }, signature="sv")

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_xsession_start(self, name, screen_orientation, sender=None, conn=None):
        """ start xwayland desktop session on guest """
        if(self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE)):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "RUNNING":
                # create a new qxcompositor display
                display = self._create_display(screen_orientation)

                # start Xwayland on the new display
                desktop = lxc.start_desktop(name, display)

                return True
        return False

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_xsession_kill(self, name, sender=None, conn=None):
        """ start xwayland desktop session on guest """
        if(self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE)):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "RUNNING":
                lxc.kill_xwayland(name)

                return True
        return False

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_xsession_setup(self, name, environment, sender=None, conn=None):
        """ run setup scripts  """

        if(self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE)):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "RUNNING":
                lxc.start_shell(name, self.current_path, "/mnt/guest/setup_desktop.sh")

                return True
        return False

    @dbus.service.method(DBUS_IFACE)
    def container_xsession_onboard(self, name):
        """ Start onboard sw keyboard on container's xsession """

        return lxc.start_onboard(name)

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def container_attach(self, name, sender=None, conn=None):
        """ attach to container shell """

        # check user privilges
        if(self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE)):
            # user authenticated
            self._refresh()

            if self.containers[name]["container_status"] == "RUNNING":
                lxc.start_shell(name, self.current_path, " ")

                return True
        return False

    @dbus.service.method(DBUS_IFACE)
    def tpl_get(self):
        """ Get available distributions """
        self.templates = lxc.get_templates() # refresh templates cache

        return self.templates

    @dbus.service.method(DBUS_IFACE)
    def tpl_get_distro(self):
        """ Get available distributions """
        if len(self.templates) < 1:
            self.templates = lxc.get_templates()

        return self._get_templates_names()

    @dbus.service.method(DBUS_IFACE)
    def tpl_get_version(self, tpl):
        """ get available templates """
        if len(self.templates) < 1:
            self.templates = lxc.get_templates()

        return self._get_template_version(tpl)

    @dbus.service.method(DBUS_IFACE)
    def check_process(self, pid):
        """ check if process is running """

        if pid in self.processes:
            poll = self.processes[str(pid)].poll()
            if poll == None:
                # p.subprocess is alive
                return True
            else:
                # subprocess completed, remove from processes
                self.processes[pid].wait()
                del self.processes[pid]

        return False

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="aa{ss}",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def get_containers(self, sender=None, conn=None):
        """ get containers list """

        self._refresh()
        return self._dbus_dict()

    @dbus.service.method(
        dbus_interface=DBUS_IFACE,
        in_signature="",
        out_signature="b",
        sender_keyword="sender",
        connection_keyword="conn"
    )
    def preauth(self, sender=None, conn=None):
        """ destroy lxc container """
        if(self._check_polkit_privilege(sender, conn, "%s.auth" % DBUS_IFACE)):
            return True
        return False

    @dbus.service.method(DBUS_IFACE)
    def check_lxc_support(self):
        """ check if CONFIG_DEVPTS_MULTIPLE_INSTANCES option is enabled in kernel """
        return lxc.check_kernel()


if __name__ == "__main__":
    DBusGMainLoop(set_as_default=True)

    bus        = dbus.SystemBus()
    name       = dbus.service.BusName("org.sailfishcontainers.daemon", bus)
    sc_service = ContainersService(bus, "/org/sailfishcontainers/daemon")

    loop = GLib.MainLoop()
    loop.run()
