from . import helpers
from .helpers import conf

import requests 

manifest_repo_url = "https://raw.githubusercontent.com/Galaxy-MSM8916/local_manifests/master"

def get_manifest(distro, version):
    """
    Get manifest for distro
    """
    manifest_name = distro + "-" + version + ".xml"

    r = requests.get(manifest_repo_url + "/" + manifest_name)

    if (r.status_code != 200):
        return None

    return r.text


    