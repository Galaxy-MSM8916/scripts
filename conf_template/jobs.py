#!/usr/bin/env python3


# map of information pertinent to running automated builds
# map keys are distro short names (see distributions.py)

jobs = {
    "lineage": {
        "17.1": {
            "devices": ["gprimelte", "j7ltespr"],
            "picks": [],
            "picks-lineage": [],
            "build_variants": ["eng"],
            "targets": ["otapackage", "recoveryimage"],
        },
    },

    "lineage-go": {
        "17.1": {
            "devices": [],
            "picks": ["android-go"],
            "picks-lineage": [],
            "build_variants": ["eng"],
            "targets": ["otapackage"],
        },
    },

    "rr": {
        "ten": {
            "devices": [],
            "picks": [],
            "picks-lineage": [],
            "build_variants": ["eng"],
            "targets": ["otapackage"],
        },
    },
}
