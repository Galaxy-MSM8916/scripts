#!/usr/bin/env python3

import getopt
import os
import sys

def init():
    import modules.args
    import modules.config

    os.environ.update(modules.config.envvars)
    args = modules.args.parse_args()

if __name__ == "__main__":

    import modules.args

    modules.args.parse_config_url()
    init()
