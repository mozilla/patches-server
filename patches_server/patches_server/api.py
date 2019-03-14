import json
import os
import sys

from flask import Flask, g, request
from redis import Redis

from session_registry import SessionRegistry


DEFAULT_CONFIG_FILE = 'patches-server/patches_server/config/default.py'


api = Flask('patches_server')

if os.environ.get('CONFIG_FILE', None) is None:
    os.environ['CONFIG_FILE'] = DEFAULT_CONFIG_FILE

api.config.from_envvar('CONFIG_FILE')


@api.route('/', methods=[ 'GET' ])
def root():
    '''
    '''

    state = app_state()

    test_id = 'test_session'

    session = state.lookup(test_id)

    if session is not None:
        print('Session already queued', file=sys.stderr)
    else:
        print('Queueing a new session', file=sys.stderr)
        state.queue(test_id, 'platform')

    body = json.dumps({ 'session': test_id })

    print(f'Sending body {body}', file=sys.stderr)

    headers = { 'Content-Type': 'application/json' }

    return ( body, 200, headers )


def connect_redis():
    '''Obtain a Redis connection.
    '''

    password = api.config.get('REDIS_PASSWORD', None)

    arguments = {
        'host': api.config['REDIS_HOST'],
        'port': api.config['REDIS_PORT'],
        'password': password
    }

    return Redis(**arguments)


def app_state():
    '''Obtain the current application state.
    '''
    
    state = getattr(g, 'application_state', None)

    if state is not None:
        return state

    conn = getattr(g, 'redis_connection', None)

    if conn is None:
        g.redis_connection = conn = connect_redis()

    print('Reconstructing app state', file=sys.stderr)

    g.application_state = state = SessionRegistry(0, 0).rebuild(conn)

    return state



@api.teardown_appcontext
def persist_app_state(_error=None):
    '''Persist the latest copy of the application state to Redis.
    '''

    state = getattr(g, 'application_state', None)

    if state is None:
        return None
    
    conn = getattr(g, 'redis_connection', None)

    if conn is None:
        conn = connect_redis()

    print('Persisting app state', file=sys.stderr)
    result = state.persist(conn)

    conn.connection_pool.disconnect()

    return result


if __name__ == '__main__':
    api.run(
        host=api.config['SERVER_HOST'],
        port=api.config['SERVER_PORT'],
    )
