'''When a Patches-Scanner requests to start a session to receive information
about vulnerabilities affecting packages built for a specific platform, they
must indicate which platform they are scanning.  This module provides a means
of setting up sources of vulnerability data given an identifier that we will
call the 'platform'.

Each source object constructed given a platform and configuration dictionary
is a generator.  The configuration dictionary provided is expected to be
structured like:

```python
{
    "sources": {
        "clair": {
            "configOption": "value",
            "other": "value2"
        },
        "othersource": {
            "option": "value"
        }
    }
}
```
'''

import patches_server.clair.client as clair_client
from patches_server.patches_server.vulnerability import \
    Package, Severity, Vulnerability


def init(platform, config):
    '''Initialize a generator that will produce vulnerabilities for the
    requested platform.  If the platform specified is not supported, this
    function will return None.
    '''

    if platform == '__testing_stub__':
        return _init_stub(platform, config)

    init_fn = _SUPPORTED_PLATFORMS.get(platform, _none)

    return init_fn(platform, config)


def is_supported(platform):
    '''Returns True if there is a source capable of serving vulnerabilities
    for the platform in question or else False.
    '''

    return platform in _SUPPORTED_PLATFORMS or platform == '__testing_stub__'


def _init_clair(platform, config):
    clair = clair_client.new(platform, config['clair'])

    while clair.has_vulns():
        for vuln in clair.retrieve_vulns():
            yield vuln


def _init_stub(platform, config):
    total_to_serve = config['testing']['vulns']

    served = 0

    package = Package('testpackage', '1.2.3')
    
    vuln = Vulnerability(
      'testvuln', '__testing_stub__', '', Severity.LOW, [ package ]
    )

    while served < total_to_serve:
        served += 1
        
        yield vuln


def _none(_platform, _config):
    return None


_SUPPORTED_PLATFORMS = {
    'ubuntu:18.04': _init_clair,
    'alpine:3.4': _init_clair,
    'debian:unstable': _init_clair,
}
