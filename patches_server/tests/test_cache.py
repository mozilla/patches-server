import sys
sys.path.insert(0, '../')

import pytest

from patches_server.patches_server.cache import Cache


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
