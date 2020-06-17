#!/usr/bin/env python3

# targets
targets = [ "otapackage", "recoveryimage", "bootimage" ]

envvars = {
    "LINEAGE_BUILDTYPE": "NIGHTLY",
    }

# name: Distro name
# versions: for use with repo init
# url: repo init url
# init_prefix: branch prefixes for repo init, e.g "lineage-" for lineage (e.g "lineage-" + "15.1")
distros = {
    "lineage" : {
        "name": "LineageOS",
        "versions": ["17.1"],
        "url": "git://github.com/LineageOS/android.git",
        "init_prefix": ["lineage-"],
        "variants": {
            "lineage-go" : {
                "name": "LineageOS Go",
                "versions": ["17.1"],
                },
            },
        "build_variants": ["userdebug", "eng"],
        },

    "rr" : {
        "name": "RessurectionRemix",
        "versions": ["pie", "ten"],
        "url" : "https://github.com/ResurrectionRemix/platform_manifest.git",
        "init_prefix": [],
        "build_variants": ["userdebug", "eng"],
        },
}
