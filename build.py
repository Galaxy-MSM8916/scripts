#!/usr/bin/env python3

import getopt
import os
import sys

try:
    import conf
except ImportError:
    import conf_template as conf

import modules

def init():
    os.environ.update(conf.envvars)

if __name__ == "__main__":
    modules.parse_args()
    init()
