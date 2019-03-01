# -*- coding: utf-8 -*-

import json

from flask import Flask, request

from server import ServerState


APP = Flask('patches_server')
STATE = ServerState()


@APP.route("/", methods=[ 'GET' ])
def api():
    '''The only API endpoint.

    If a `session` query parameter is provided, the associated value will be
    validated against a known list of sessions to determine if new
    vulnerabilities are available for the session.

    If a `platform` query parameter is supplied, then a new session will be
    created.
    '''

    platform = request.args.get('platform', None)
    session = request.args.get('session', None)

    if session is not None:
        return _vulns(session)
    elif platform is not None:
        return _new_session(platform)
    else:
        return _error()


def _vulns(session_id):
    '''Retrieve vulnerabilities available for a scanner with an active session.
    '''

    body = json.dumps({
        'error': None,
        'vulnerabilities': [],
    })
    
    return (body, 200, { 'Content-Type': 'application/json' })


def _new_session(platform):
    '''Create a new session for a scanner running on a particular platform.
    '''

    body = json.dumps({
        'error': None,
        'session': 'testing',
    })
    
    return (body, 200, { 'Content-Type': 'application/json' })


def _error():
    '''Produce an error indicating that expected query parameters were missing.
    '''
    err_msg = 'Requests must contain one of either a `session` or ' +\
        '`platform` parameter'

    body = json.dumps({
        'error': err_msg,
    })

    return (body, 400, { 'Content-Type': 'application/json' })


if __name__ == '__main__':
    config = {
        'maxActiveSessions': 4,
        'maxQueuedSessions': 16,
        'sessionTimeoutSeconds': 10,
        'maxVulnsToServe': 32,
        'sources': {
            'clair': {
                'baseAddress': 'http://127.0.0.1:6060',
                'fetchLimit': 32,
            }
        }
    }

    STATE = STATE.configure(config)

    APP.run(host='0.0.0.0', port=9002)