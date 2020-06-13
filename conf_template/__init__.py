#!/usr/bin/env python3

# import modules
from . import devices as mod_devices
from . import distributions as mod_distributions
from . import executors as mod_executors
from . import jobs as mod_jobs

# bind module variables to the package
from .devices import devices
from .distributions import distros, versions, targets
from .executors import executors
from .jobs import jobs

envvars = {}
variables = {}

modules = [ "mod_devices", "mod_distributions", "mod_executors", "mod_jobs" ]

# concatenate all targets, envvars, variables
for module in modules:
    module = eval(module)

    if 'envvars' in dir(module):
        envvars.update(module.envvars)

    if 'variables' in dir(module):
        variables.update(module.variables)

__all__ = ["envvars", "variables", "targets", "devices", "distros", "executors", "jobs"]