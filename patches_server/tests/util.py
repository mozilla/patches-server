'''This module exports a function decorator `stateful` that can be used to
mark tests as only being desirable to run when the Patches' web server is
running.
'''

import sys

import requests


_DEFAULT_ADDR = 'http://127.0.0.1:9002'


def stateful(test_fn, server=_DEFAULT_ADDR):
    '''A function decorator that will assert that the Patches-Server is
    responding to requests before invoking the wrapped function.
    '''

    print('Calling stateful', file=sys.stderr)
    print('Calling stateful')
    def wrapper(*args, **kwargs):
        try:
            response = requests.get(server)
            resp_data = response.json()
            if resp_data.get('error', None) is not None:
                print('Calling test fn', file=sys.stderr)
                return test_fn(*args, **kwargs)
        except requests.ConnectionError:
            print('Not calling test function', file=sys.stderr)
            return None
    
    return wrapper