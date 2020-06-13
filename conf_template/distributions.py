#!/usr/bin/env python3

versions = {
    "7.1": [ "N", "Nougat", "nougat", "14.1" ],
    "8.1": [ "O", "Oreo", "oreo", "6.0.0", "15.1" ],
}

# targets
targets = [ "otapackage", "recoveryimage", "bootimage" ]

# name: Distro name
# versions: for use with repo init
# prefix: Jenkins job prefix
# url: repo init url
# init_prefix: branch prefixes for repo init, e.g "lineage-" for lineage (e.g "lineage-" + "15.1")
distros = {
    "lineage" : {
        "name": "LineageOS",
        "versions": ["14.1", "15.1"],
        "prefix": "los",
        "url": "git://github.com/LineageOS/android.git",
        "init_prefix": ["lineage-", "cm-"],
        "variants": {
            "lineage-go" : {
                "name": "LineageOS Go",
                "versions": ["15.1"],
                "prefix": "los-go",
                },
            },
        "types": ["userdebug", "eng"],
        },

    "rr" : {
        "name": "RessurectionRemix",
        "versions": ["oreo"],
        "prefix": "rr",
        "url" : "https://github.com/ResurrectionRemix/platform_manifest.git",
        "init_prefix": [],
        "types": ["userdebug", "eng"],
        },
}
