import json
from unittest.mock import MagicMock, Mock

import pytest

from patches_server.cache import Cache


def test_persist_success_case():
    mock_redis = MagicMock()

    mock_redis.hset = Mock(return_value=1)

    cache = Cache()

    cache.cache('test1', [ 'item1', 'item2', 'item3' ])

    assert cache.persist(mock_redis) is None

    mock_redis.hset.assert_called_with(
        'cache_item_counts', 'test1', '3')


def test_persist_failure_case():
    mock_redis = MagicMock()
   
    mock_redis.hset = Mock(side_effect=Exception('test'))

    cache = Cache()

    cache.cache('test1', [ 'testitem1', 'testitem2' ])

    assert cache.persist(mock_redis) is not None


def test_rebuild():
    mock_redis = MagicMock()

    test_buckets = {
        'test1': [ 'item1', 'item2' ],
        'test2': [ 'item01' ],
        'test3': []
    }

    test_counts = {
        'test1': 2,
        'test2': 1,
        'test3': 0
    }

    def determine_bucket(hash_name, _bucket):
        if hash_name == 'cache_buckets':
            return json.dumps(test_buckets)

        return json.dumps(test_counts)


    mock_redis.hkeys = Mock(return_value=[ 'test1', 'test2', 'test3' ])
    mock_redis.hget = Mock(side_effects=determine_bucket)

    cache = Cache().rebuild(mock_redis)

    mock_redis.hkeys.assert_called_once_with('cache_buckets')
    mock_redis.hget.assert_called_with('cache_item_counts', 'test3')

    assert 'test1' in cache.buckets
    assert 'test2' in cache._total_item_counts


def test_cache():
    cache = Cache()

    cache.cache('test', [1,2,3])
    cache.cache('test2', ['hello', 'world'])

    assert cache.size('test') == 3
    assert cache.size('test2') == 2
    assert cache.size('test3') == 0


def test_remove_bucket():
    cache = Cache()

    cache.cache('test', [1,2])

    assert cache.remove_bucket('test').size('test') == 0
    assert cache.remove_bucket('test2').size('test2') == 0


def test_retrieve():
    cache = Cache()

    cache.cache('test', [1,2,3,4,5])

    assert cache.retrieve('test') == [1,2,3,4,5]
    assert cache.retrieve('test2') is None
    assert cache.retrieve('test', offset=3) == [4,5]
    assert cache.retrieve('test', limit=10000) == [1,2,3,4,5]
    assert cache.retrieve('test', offset=2, limit=1) == [3]

    cache.cache('test', [6,7,8,9])

    assert cache.retrieve('test', offset=5) == [6,7,8,9]
    assert cache.retrieve('test', offset=2) == [6,7,8,9]
    assert cache.retrieve('test', offset=8) == [9]


def test_size():
    cache = Cache()

    cache.cache('test', [1,2])
    cache.cache('test', [3,4,5])

    assert cache.size('test') == 5

    assert cache.size('test2') == 0
