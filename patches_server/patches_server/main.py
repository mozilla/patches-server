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

    STATE.update()

    if session is not None:
        return _vulns(session)
    elif platform is not None:
        return _new_session(platform)
    else:
        return _error()


def _vulns(session_id):
    '''Retrieve vulnerabilities available for a scanner with an active session.
    '''

    vulns = STATE.retrieve_vulns(session_id)

    if vulns is None:
        body = json.dumps({
            'error': 'There are no vulnerabilities available for you at this'\
                ' time. Check that your session ID is correct and try again'\
                ' later.'
        })

        return ( body, 400, { 'Content-Type': 'application/json' } )

    body = json.dumps({
        'error': None,
        'vulnerabilities': vulns,
    })
    
    return ( body, 200, { 'Content-Type': 'application/json' } )


def _new_session(platform):
    '''Create a new session for a scanner running on a particular platform.
    '''

    session_id = STATE.queue_session(platform)

    if session_id is None:
        body = json.dumps({
            'error': 'Could not create session. Check that your' \
                ' platform is supported and try again later'
        })

        return ( body, 400, { 'Content-Type': 'application/json' } )

    body = json.dumps({
        'error': None,
        'session': session_id,
    })
    
    return ( body, 200, { 'Content-Type': 'application/json' } )


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

    STATE.configure(config)

    APP.run(host='0.0.0.0', port=9002)