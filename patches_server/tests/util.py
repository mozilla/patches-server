import sys

import redis
import requests


_DEFAULT_ADDR = 'http://127.0.0.1:9002'


def needs_redis(test_fn, host='127.0.0.1', port=6379, password=None):
    '''A function decorator that will assert that we can connect to Redis
    before running a test.
    '''

    def wrapper(*args, **kwargs):
        try:
            if password is None:
                redis.Redis(host=host, port=port)
            else:
                redis.Redis(host=host, port=port, password=password)
        except Exception:
            return None
        else:
            return test_fn(*args, **kwargs)

    return wrapper


def needs_patches_server(test_fn, scheme='http', host='127.0.0.1', port=9002):
    '''A function decorator that will assert that we can connect to the
    Patches-Server before running a test.
    '''

    print('Calling needs_patches_server', file=sys.stderr)

    def wrapper(*args, **kwargs):
        try:
            resp = requests.get(f'{scheme}://{host}:{port}?platform=none')
            print('request succeeded', file=sys.stderr)
            if resp.json().get('error', None) is not None:
                print('calling test fn', file=sys.stderr)
                return test_fn(*args, **kwargs)
            
            return None
        except Exception:
            print('request failed', file=sys.stderr)
            return None