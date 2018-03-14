#!/usr/bin/env python3

# host: server's hostname or ip
# ota: indicates whether executor servers otas
# tracker: indicates whether executor serves/tracks torrents
# jobnum: Maximum concurrent job number for builds (make -j jobnum)
# executors: number of Jenkins executors
executors = {
    "skyvm" : {
        "host": "skyvm.msm8916.com",
        "executors": 2,
        "jobnum": 8,
        "tracker": True,
        "ota": True
        },
}

# envvars: key/val pair of variables to set at build time/in executor config
envvars = {
    "CCACHE_MAXSIZE" : "100G",
}
