import json
import os

from flask import Flask, g, request
from redis import Redis


DEFAULT_CONFIG_FILE = 'patches-server/patches_server/config/default.py'


api = Flask('patches_server')

if os.environ.get('CONFIG_FILE', None) is None:
    os.environ['CONFIG_FILE'] = DEFAULT_CONFIG_FILE

api.config.from_envvar('CONFIG_FILE')


@api.route('/', methods=[ 'GET' ])
def root():
    '''
    '''

    redis = connect_redis()

    hits = redis.get('hits')

    if hits is None:
        hits = 1
    else:
        hits = int(hits) + 1

    redis.set('hits', hits)

    body = json.dumps({
        'hits': int(hits)
    })

    print(f'Sending body {body}')

    headers = { 'Content-Type': 'application/json' }

    return ( body, 200, headers )


def connect_redis(**kwargs):
    '''Create a connection to a Redis server.
    '''
  
    conn = getattr(g, 'redis_connection', None)

    if conn is None:
        password = kwargs.get(
            'password',
            api.config.get('REDIS_PASSWORD', None))

        arguments = {
            'host': kwargs.get('host', api.config['REDIS_HOST']),
            'port': kwargs.get('port', api.config['REDIS_PORT']),
            'password': password
        }

        g.redis_connection = conn = Redis(**arguments)

    return conn


@api.teardown_appcontext
def disconnect_redis(_error=None):
    '''
    '''

    conn = getattr(g, 'redis_connection', None)

    if conn is None:
        return

    conn.connection_pool.disconnect()


if __name__ == '__main__':
    api.run(
        host=api.config['SERVER_HOST'],
        port=api.config['SERVER_PORT'],
    )
