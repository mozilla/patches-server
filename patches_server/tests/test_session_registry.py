from datetime import datetime
import time
from unittest.mock import MagicMock, Mock

import pytest

from session_registry import\
    ActivityState, SessionRegistry, SessionState


def test_persist_success_case():
    mock_redis = MagicMock()
    
    mock_redis.set = Mock(return_value=1)
    mock_redis.hset = Mock(return_value=1)

    registry = SessionRegistry(1, 3)

    registry.queue('test_id', 'ubuntu:18.04')

    registry.persist(mock_redis)
    mock_redis.set.assert_called_with(
        'session_registry_max_queued_sessions', 3)
    mock_redis.hset.assert_called_once()


def test_persist_failure_case():
    mock_redis = MagicMock()

    mock_redis.set = Mock(return_value=1)
    mock_redis.hset = Mock(side_effects=Exception('test'))

    registry = SessionRegistry(1, 3)

    registry.queue('test_id', 'ubuntu:18.04')

    registry.persist(mock_redis)
    mock_redis.hset.assert_called_once()


def test_rebuild_success_case():
    mock_redis = MagicMock()

    test_ids = [ 'test1' ]

    test_session = SessionState(
        'ubuntu:18.04',
        ActivityState.ACTIVE,
        datetime.utcnow(),
        datetime.utcnow(),
        12
    ).to_json()

    mock_redis.get = Mock(return_value=None)
    mock_redis.hkeys = Mock(return_value=test_ids)
    mock_redis.hget = Mock(return_value=test_session)

    registry = SessionRegistry(1, 3).rebuild(mock_redis)

    mock_redis.get.assert_called_with('session_registry_max_queued_sessions')
    mock_redis.hkeys.assert_called_once()
    mock_redis.hget.asset_called_once_with('session_registry', 'test1')

    assert registry.lookup('test1') is not None


def test_rebuild_failure_case():
    mock_redis = MagicMock()

    mock_redis.get = Mock(side_effects=Exception('not found'))

    registry = SessionRegistry(1, 3).rebuild(mock_redis)

    assert registry.lookup('test1') is None


def test_timed_out():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')
    registry.queue('test2', 'ubuntu:18.04')

    time.sleep(1.5)

    assert registry.timed_out(1) == [ 'test1', 'test2' ]


def test_notify_activity():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')

    assert registry.notify_activity('test1')
    assert not registry.notify_activity('test2')


def test_active():
    registry = SessionRegistry(2, 3)

    registry.queue('test1', 'ubuntu:18.04')
    registry.queue('test2', 'alpine:3.4')
    registry.queue('test3', 'alpine:3.4')

    registry.activate_sessions()

    registry.notify_activity('test1', read_vulns=10)
    registry.notify_activity('test2', read_vulns=5)

    print(registry._registry)
    assert registry.active(read_at_least=5, platform='ubuntu:18.04') == [ 'test1' ]
    assert registry.active(read_at_least=10, platform='ubuntu:18.04') == [ 'test1' ]
    assert registry.active(read_at_least=3, platform='alpine:3.4') == [ 'test2' ]
    assert registry.active(read_at_least=10, platform='alpine:3.4') == []


def test_queue():
    registry = SessionRegistry(1, 3)

    assert registry.queue('test1', 'ubuntu:18.04')
    assert not registry.queue('test1', 'ubuntu:18.04')
    assert registry.queue('test2', 'ubuntu:18.04')
    assert registry.queue('test3', 'ubuntu:18.04')
    assert not registry.queue('test4', 'ubuntu:18.04')


def test_activate_sessions():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')
    registry.queue('test2', 'ubuntu:18.04')

    assert registry.activate_sessions() == [ 'test1' ]
    assert registry.activate_sessions() == []

    registry.terminate('test1')

    registry.queue('test1', 'alpine3.4') 

    assert registry.activate_sessions() == [ 'test2' ]


def test_terminate():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')

    assert registry.terminate('test1')
    assert not registry.terminate('test2')
