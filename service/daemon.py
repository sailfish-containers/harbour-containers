#!/usr/bin/env python3
# Sailifish Containers dbus service

from gi.repository import GLib
from dbus.mainloop.glib import DBusGMainLoop

from libs import lxc, qxcompositor

import dbus
import dbus.service
import pathlib

DBUS_IFACE="org.sailfishcontainers.daemon"
DBUS_PATH ="/org/sailfishcontainers/daemon"

class ContainersService(dbus.service.Object):
    def __init__(self):
        """ sailfish-containers dbus daemon """

        # daemon config
        self.user_name = "nemo"
        self.user_uid  = 100000
        self.current_path = pathlib.Path(__file__).parent.parent.absolute()

        # init dbus
        bus_name = dbus.service.BusName(DBUS_IFACE, bus=dbus.SystemBus())
        dbus.service.Object.__init__(self, bus_name, DBUS_PATH)

        # daemon cache
        self.containers      = {} # available lxc containers
        self.processes       = {} # lxc running processes
        self.templates       = {} # "raw" templates cache
        self.display_counter = 0  # qxcompositor's display sockets


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
                    #'container_mounts'   : dbus.Dictionary(self.containers[container]["container_mounts"], signature='sv'),
                }, signature='sv'))

        return list_out

    def _refresh(self):
        """ refresh cache """

        # get containers
        self.containers = lxc.get_containers()

    def _create_display(self):
        """ create a qxcompositor display """

        self.display_counter +=1
        display = qxcompositor.new(self.user_name, "%d" % self.display_counter, self.user_uid, self.current_path)

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

        def _add_guest_mp(self, name ):
            """ add scripts mountpoint to container """

            return lxc.add_mountpoint(name, "/usr/share/harbour-Containers/scripts/guest","mnt/guest", False)

        @dbus.service.method(DBUS_IFACE)
        def mount_scripts(self, name):
            """ add scripts mountpoint to container, via dbus """
            if name in self.containers:
                self._add_guest_mp(name)

                return True
            return False

    @dbus.service.method(DBUS_IFACE)
    def start_xsession(self, name):
        """ start xwayland desktop session on guest """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            # create a new qxcompositor display
            display = self._create_display()

            # start Xwayland on the new display
            desktop = lxc.start_desktop(name, display)

            return True
        return False

    @dbus.service.method(DBUS_IFACE)
    def get_containers(self):
        """ get containers list """
        self._refresh()

        return self._dbus_dict()

    @dbus.service.method(DBUS_IFACE)
    def start_container(self, name):
        """ start lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "STOPPED":
            lxc.start(name)

            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def stop_container(self, name):
        """ stop lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            lxc.stop(name)

            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def freeze_container(self, name):
        """ freeze lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            lxc.freeze(name)

            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def unfreeze_container(self, name):
        """ unfreeze lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "FROZEN":
            lxc.unfreeze(name)

            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def destroy_container(self, name):
        """ destroy lxc container """
        self._refresh()

        if self.containers[name]["container_status"] == "STOPPED":

            lxc.destroy(name)
            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def snapshot_container(self, name, snapshot_name):
        """ take container's snapshot """
        self._refresh()

        if self.containers[name]["container_status"] == "STOPPED":
            lxc.snapshot(name, snaphost_name)

            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def get_tpl(self):
        """ Get available distributions """
        self.templates = lxc.get_templates() # refresh templates cache

        return self.templates

    @dbus.service.method(DBUS_IFACE)
    def get_tpl_distro(self):
        """ Get available distributions """
        if len(self.templates) < 1:
            self.templates = lxc.get_templates()

        return self._get_templates_names()

    @dbus.service.method(DBUS_IFACE)
    def get_tpl_version(self, tpl):
        """ get available templates """
        if len(self.templates) < 1:
            self.templates = lxc.get_templates()

        return self._get_template_version(tpl)


        @dbus.service.method(DBUS_IFACE)
        def get_mounts(self, name):
            if name in self.containers:
                return lxc.get_mounts(name)

    @dbus.service.method(DBUS_IFACE)
    def create_container(self, name, dist, arch, release):
        """ create containers from template """
        self._refresh()

        if not name in self.containers:
            try:
                # get popen object
                proc = lxc.create(name, dist, arch, release)

                # store popen on running processes
                self.processes[str(proc.pid)] = proc

                return dbus.Dictionary({ "result" : True, "pid": dbus.String(str(proc.pid)) }, signature="sv")

            except:
                return dbus.Dictionary({ "result" : False, "err": dbus.String("lxc-create failed")}, signature="sv")

        return dbus.Dictionary({ "result" : False, "err": dbus.String("container exist") }, signature="sv")

    @dbus.service.method(DBUS_IFACE)
    def setup_container(self, name, environment):
        """ run setup scripts  """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            try:
                # get popen object
                proc = lxc.setup_container(name, self.user_name, self.user_uid, environment)

                # store popen on running processes
                self.processes[str(proc.pid)] = proc

                return dbus.Dictionary({ "result" : True, "pid": str(proc.pid) }, signature="sv")
            except:
                return dbus.Dictionary({ "result" : False, "err": "setup_desktop.sh failed"}, signature="sv")

        return dbus.Dictionary({ "result" : False, "err": "container is not running" }, signature="sv")

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

    @dbus.service.method(DBUS_IFACE)
    def set_flag(self, name, flag):
        """ experimental, set setup flags """
        self._refresh()

        if self.containers[name]["container_status"] == "STARTED":

            lxc.set_flag(name, flag) # lxc.set_flag("test","leste")
            return True

        return False

    @dbus.service.method(DBUS_IFACE)
    def start_shell(self, name):
        """ attach to container shell """
        self._refresh()

        if self.containers[name]["container_status"] == "RUNNING":
            lxc.start_shell(name, self.current_path)

            return True
        return False


if __name__ == "__main__":
    DBusGMainLoop(set_as_default=True)
    myservice = ContainersService()
    loop = GLib.MainLoop()

    loop.run()
