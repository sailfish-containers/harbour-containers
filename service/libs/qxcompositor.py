#!/usr/bin/env python3
# Sailifish Containers qxcompositor wrapper

import os
import subprocess

def new(user, display_id, user_uid, path):
    """ Create qxcompositor's display """
    scripts_path = "%s/scripts" % str(path)
    FNULL = open(os.devnull, 'w') # fix for session hang
    qxcompositor = subprocess.Popen(['su', user, '-c', '%s/host/new_display.sh %s %s' % (scripts_path, display_id, user_uid)], stdout=FNULL, stderr=subprocess.STDOUT, shell=False)

    return True

def kill(qxcompositor_pid):
    """ Kill qxcompositor process """
    os.kill(qxcompositor_pid)

    return True
