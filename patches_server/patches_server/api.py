import os

from flask import Flask, request

import config


api = Flask('patches-server')


@api.route('/', methods=[ 'GET' ])
def root():
    '''
    '''

    body = '{"greeting": "Hello, world!"}'

    headers = { 'Content-Type': 'application/json' }

    return ( body, 200, headers )


if __name__ == '__main__':
    if os.environ.get('CONFIG_FILE', None) is None:
        os.environ['CONFIG_FILE'] = 'patches_server/config/default.py'

    api.config.from_object('config.default')
    api.config.from_envvar('CONFIG_FILE')
    api.run(
        host=api.config['SERVER_HOST'],
        port=api.config['SERVER_PORT'],
    )
