#!/usr/bin/env python3
# Sailifish Containers lxc wrapper

import os
import subprocess

def _get_rootfs(name):
    """ get container's rootfs path from config """

    out = subprocess.check_output(["lxc-info","--config","lxc.rootfs.path","-n",name])
    return out.decode().split()[2]

def get_mounts(name):
    """ get container's mountpoint from config """

    out = subprocess.check_output(["lxc-info","--config","lxc.mount.entry","-n",name]).decode()
    res = {}

    mp  = out.replace("lxc.mount.entry = ","").split("\n")

    for line in mp:
        if line != "":
            title = line.split()[0]
            res[title] = line

    return res

def get_containers():
    """ Get available containers """
    out = subprocess.check_output(['lxc-ls']).decode()
    res = {}

    for container in out.split():

        # get container status
        cmd_out = subprocess.check_output(['lxc-info', '-n', container,'-p','-s','-S']).decode().split("\n")

        if len(cmd_out) > 2:
            # container is running
            container_status = cmd_out[0].split()[1]
            container_pid    = cmd_out[1].split()[1]
            container_cpu    = cmd_out[2].split()[2]
            container_mem    = cmd_out[3].split()[2]
            container_kmem   = cmd_out[4].split()[2]
        else:
            # container stopped
            container_status = cmd_out[0].split()[1]
            container_pid    = ""
            container_cpu    = ""
            container_mem    = ""
            container_kmem   = ""

        # get mountpoints
                #mp = _get_mounts(container)

        # get rootfs path
        rootfs = _get_rootfs(container)

        res[container] = {
            "container_name"      : container,
            "container_status"    : container_status,
            "container_pid"       : container_pid,
            "container_cpu"       : container_cpu,
            "container_mem"       : container_mem,
            "container_kmem"      : container_kmem,
            "container_rootfs"    : rootfs,
                        #"container_mounts"    : mp,
         }

    return res


def get_templates(meta_index="https://images.linuxcontainers.org/meta/1.0/index-system"):
    """ Get available templates from sfos-download """

    tpl = []
    res = subprocess.check_output(["curl", meta_index, "-L"]).decode()

    for line in res.split('\n'):

        # split line
        cell = line.split(';')

        # remove blank line
        if not "default" in line: continue
        if len(cell) < 3: continue

        # add line to templates dictionary
        tpl.append( { "dist":cell[0] , "release" : cell[1], "arch" : cell[2] } )

    return tpl

def create(name, dist, arch, release, template="sfos-download"):
    """ Create a container """
    FNULL = open(os.devnull, 'w') # fix for session hang

    out = subprocess.Popen(['lxc-create', '-n', name, '-t', template, '--', '--arch', arch, '--dist', dist, '--release', release], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    return out

def start(name):
    """ Start a lxc container from name """
    out = subprocess.check_output(['lxc-start', '-n', name])

    if out != "":
        # error starting container
        return False

    # container started
    return True

def stop(name):
    """ Stop a lxc container from name FIXME: sometimes call go in timeout"""
    out = subprocess.check_output(['lxc-stop', '-n', name])

    if out != "":
        # error stopping container
        return False

    return True

def kill(name):
    """ Kill a lxc container from name """
    out = subprocess.check_output(['lxc-stop', '-W', '-n', name, '-k'])

    if out != "":
        # error killing container
        return False

    return True

def freeze(name):
    """ Freeze a lxc container from name """
    out = subprocess.check_output(['lxc-freeze', '-n', name])

    if out != "":
        # error freezing container
        return False

    return True

def unfreeze(name):
    """ Unfreeze a lxc container from name """
    out = subprocess.check_output(['lxc-unfreeze', '-n', name])

    if out != "":
        # error unfreezing container
        return False

    return True

def destroy(name, rootfs=""):
    """ Destroy a lxc container from name """
    out = subprocess.check_output(['lxc-destroy', '-n', name])

    if out != "":
        # error destroying container
        return False

    return True

def get_snapshots(name):
    """ Get snapshots of lxc container from name """
    out = subprocess.check_output(['lxc-snapshot', '-n', name, '-L']).decode()
    res = []

    for line in out.split("\n"):
        try:
            title = line.split(" (")[0]
            date  = line.split(") ")[1]

            res.append({ "snap_name": title, "snap_ts": date })
        except:
            pass

    return res

def take_snapshot(name, snapshot_name):
    """ Take a snapshot of lxc container from name """
    FNULL = open(os.devnull, 'w') # fix for session hang

    snap_process = subprocess.Popen(['lxc-snapshot', '-n', name, snapshot_name], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    # desktop started
    return snap_process

def restore_snapshot(name, snapshot_name):
    """ restore a snapshot of lxc container from name """
    FNULL = open(os.devnull, 'w') # fix for session hang

    restore_process = subprocess.Popen(['lxc-snapshot', '-n', name, '-r', snapshot_name], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    # desktop started
    return restore_process

def restore_create_snapshot(name, snapshot_name, new_name):
    """ create a container from a snapshot """
    FNULL = open(os.devnull, 'w') # fix for session hang

    restore_process = subprocess.Popen(['lxc-snapshot', '-n', name, '-r', snapshot_name, '-N', new_name], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    # desktop started
    return restore_process

def setup_container(name, user_name, session):
    """ setup container x session """
    FNULL = open(os.devnull, 'w') # fix for session hang

    setup_process = subprocess.Popen(['lxc-attach', '-n', name, '/mnt/guest/setup_desktop.sh','%s' % user_name], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    # desktop started
    return setup_process

def start_desktop(name, display_id, user_name="user"): #fixme
    """ start desktop guestsscript """
    FNULL = open(os.devnull, 'w') # fix for session hang

    desktop_session = subprocess.Popen(['lxc-attach', '-n', name, '/mnt/guest/start_desktop.sh', '%s' % display_id, '%s' % user_name ], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    # desktop started
    return True

def start_shell(name, path):
    """ start fingerterm bash session on container """
    scripts_path = "%s/scripts" % str(path)
    FNULL = open(os.devnull, 'w') # fix for session hang

    shell = subprocess.Popen(['%s/host/attach.sh' % scripts_path, name], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    return shell

def add_mountpoint(name, source, dest, rw=False):
    """ add a mountpoint to container """
    read = "rw"
    if not rw:
        read = "ro"

    mp_line = 'lxc.mount.entry = %s %s none bind,create=dir,%s 0 0\n' % (source, dest, read)

    with open('/var/lib/lxc/%s/config' % name, 'r') as f:
        for line in f.readlines():
            if line == mp_line:
                return False

    with open('/var/lib/lxc/%s/config' % name, 'a') as file:
        file.write(mp_line)

    return True
