#!/usr/bin/env python3

# import modules
from . import devices as mod_devices
from . import distributions as mod_distributions
from . import executors as mod_executors
from . import jobs as mod_jobs

# bind module variables to the package
from .devices import devices
from .distributions import distros, versions
from .executors import executors
from .jobs import jobs

__all__ = [ "mod_devices", "mod_distributions", "mod_executors", "mod_jobs" ]

envvars = {}
targets = []
variables = {}

# concatenate all targets, envvars, variables
for mod in __all__:

    mod = eval(mod)

    if 'envvars' in dir(mod):
        envvars.update(mod.envvars)

    if 'targets' in dir(mod):
        targets.extend(mod.targets)

    if 'variables' in dir(mod):
        variables.update(mod.variables)
