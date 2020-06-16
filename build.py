#!/usr/bin/env python3

import getopt
import os
import sys

def init(parse_args):
    import modules.args
    import modules.config

    os.environ.update(modules.config.envvars)

if __name__ == "__main__":

    import modules.args

    argv = modules.args.parse_config_url()
    parse_args = modules.args.parse_args(argv)

    init(parse_args)
