#!/usr/bin/env python3

import getopt
import os
import sys

import modules
import modules.config as config

def init():
    os.environ.update(config.envvars)

    args = modules.args.parse_args()

if __name__ == "__main__":
    init()
