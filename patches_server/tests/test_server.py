import sys
sys.path.insert(0, '../')

import time

import pytest

from patches_server.patches_server.server import ServerState


def test_queue_session():
    config = {
        'maxActiveSessions': 1,
        'maxQueuedSessions': 3,
        'sources': {
            'clair': {
                'baseAddress': '',
            },
        },
    }

    state = ServerState().configure(config)

    assert state.queue_session('not-supported') is None
    assert state.queue_session('ubuntu:18.04') is not None
    assert state.queue_session('alpine:3.4') is not None
    assert state.queue_session('debian:unstable') is not None
    assert state.queue_session('centos:7') is None


def test_retrieve_vulns():
    config = {
        'maxActiveSessions': 1,
        'maxQueuedSessions': 3,
        'sources': {
            'testing': {
                'vulns': 10,
            },
        },
    }

    state = ServerState().configure(config)

    session_id = state.queue_session('__testing_stub__')
    
    assert state.retrieve_vulns(session_id) is None
    assert state.retrieve_vulns('not-valid') is None

    state.update()

    assert len(state.retrieve_vulns(session_id)) == 10
    assert state.retrieve_vulns('not-valid') is None


def test_update():
    config = {
        'maxActiveSessions': 1,
        'maxQueuedSessions': 3,
        'sessionTimeoutSeconds': 1,
        'sources': {
            'testing': {
                'vulns': 10,
            },
        },
    }

    state = ServerState().configure(config)

    session_id = state.queue_session('__testing_stub__')

    session_id_2 = state.queue_session('__testing_stub__')

    state.update()

    # The configured limit of at most one active session should be respected.
    assert len(state._sessions.active()) == 1

    assert len(state._sessions.active(read_at_least=1)) == 0

    state.retrieve_vulns(session_id)
    state.update()
    
    # After reading all of the vulns, a call to update should result in the
    # now-complete active session being removed.
    assert len(state._sessions.active(read_at_least=1)) == 0

    state.update()

    assert len(state._sessions.active()) == 1

    time.sleep(1.5)
    state.update()

    assert len(state._sessions.active()) == 0
