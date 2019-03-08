import sys
sys.path.insert(0, '../patches_server/patches_server')

import pytest
import requests

from util import needs_patches_server, needs_redis


#@needs_patches_server
def test_handling_valid_sessions():
    print('in test_handling_valid_sessions', file=sys.stderr)
    session_id = requests.get('http://127.0.0.1:9002/?platform=ubuntu:18.04')\
        .json()\
        .get('session', None)

    assert session_id is not None

    print(f'got session_id {session_id}')

    vulns = requests.get(f'http://127.0.0.1:9002/?session={session_id}')\
        .json()\
        .get('vulnerabilities', None)

    assert vulns is not None

    assert False