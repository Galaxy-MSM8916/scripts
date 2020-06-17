#!/usr/bin/env python3

# targets
targets = [ "otapackage", "recoveryimage", "bootimage" ]

envvars = {
    "LINEAGE_BUILDTYPE": "NIGHTLY",
    "USE_CCACHE": "1",
    "CCACHE_MAXSIZE": "100G",
    "CCACHE_COMPRESS": "1",
    }

# name: Distro name
# versions: for use with repo init
# url: repo init url
# init_prefix: branch prefixes for repo init, e.g "lineage-" for lineage (e.g "lineage-" + "15.1")
distros = {
    "lineage" : {
        "name": "LineageOS",
        "versions": ["16.0", "17.1"],
        "url": "git://github.com/LineageOS/android.git",
        "init_prefix": ["lineage-"],
        "variants": {
            "lineage-go" : {
                "name": "LineageOS Go",
                "versions": ["16.0", "17.1"],
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
