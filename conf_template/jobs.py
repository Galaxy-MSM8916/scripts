#!/usr/bin/env python3


# map of information pertinent to running automated builds
# map keys are distro short names (see distributions.py)

jobs = {
    "lineage": {
        "devices": {
            "gprimelte": ["14.1", "15.1"],
            "j7ltespr": ["14.1", "15.1"]
            },
        "picks": [],
        "picks-lineage": [],
        "types": ["eng"],
        },

    "lineage-go": {
        "devices": {},
        "picks": ["android-go"],
        "types": ["eng"],
        },

    "rr": {
        "devices": {
            "gprimelte": ["6.0.0"],
            "j7ltespr": ["6.0.0"]
            },
        "picks": [],
        "types": ["eng"],
        },
}
