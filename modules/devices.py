#!/usr/bin/env python3

from . import config

def get_long_device_name(device):
    """
    Return the long device name of device
    """
    for name in config.devices:
        if device in config.devices[name]:
            return name

    return None

def get_device_model(device):
    """
    Return the model of device
    """
    for name in config.devices:
        if device in config.devices[name]:
            return config.devices[name][device]["model"]

    return None