#!/usr/bin/env python3
try:
    import conf
except ImportError:
    import conf_template as conf

def get_targets():
    try:
        targets = conf.targets
    except:
        targets = []

    return targets

def get_devices():

    devices = []

    try:
        for i in conf.devices.values():
            devices.extend(i)
    except:
        pass

    return devices
