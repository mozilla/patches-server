import sys
sys.path.insert(0, '../patches_server/patches_server')

import pytest
import requests

from util import stateful


@stateful
def test_handling_valid_sessions():
    session_id = requests.get('http://127.0.0.1:6060?platform=ubuntu:18.04')\
        .json()\
        .get('session', None)

    assert session_id is not None

    vulns = requests.get(f'http://127.0.0.1:6060?session={session_id}')\
        .json()\
        .get('vulnerabilities', None)

    assert vulns is not None