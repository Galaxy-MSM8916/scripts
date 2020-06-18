#!/usr/bin/env python3


# map of information pertinent to running automated builds
# map keys are distro short names (see distributions.py)

envvars = {
    #"GITHUB_TOKEN": "",
    "GITHUB_USER": "Galaxy-MSM8916",
    "GITHUB_REPO": "releases",
    "SSH_UPLOAD_USER": "galaxy-msm8916",
    "SSH_PROJECT": "galaxy-msm8916",
    "SSH_UPLOAD_HOST": "frs.sourceforge.net",
    "SSH_UPLOAD_BASE_DIR": "/home/frs/project/galaxy-msm8916"
    #"SSH_UPLOAD_IDENTITY": "",
}

jobs = {
    "lineage": {
        "17.1": {
            "devices": ["j3xprolte", "j5lte", "j5nlte", "j53gxx", "j5ltechn", "j7ltechn"],
            "picks": [],
            "picks_lineage": [],
            "build_variants": ["userdebug"],
            "targets": ["otapackage"],
        },
    },

    "lineage-go": {
        "17.1": {
            "devices": [],
            "picks": ["android-go-17.1"],
            "picks_lineage": [],
            "build_variants": ["userdebug"],
            "targets": ["otapackage"],
        },
    },
}
