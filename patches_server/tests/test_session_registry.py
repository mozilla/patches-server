from unittest.mock import MagicMock, Mock

import pytest

from patches_server.session_registry import\
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
    mock_redis.hset = Mock(side_effect=Exception('test'))

    registry = SessionRegistry(1, 3)

    registry.queue('test_id', 'ubuntu:18.04')

    registry.persist(mock_redis)
    mock_redis.hset.assert_called_once()
