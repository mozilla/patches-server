import sys
sys.path.insert(0, '../patches_server/patches_server')

import time

import pytest

from session_registry import ActivityState, SessionState, SessionRegistry


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