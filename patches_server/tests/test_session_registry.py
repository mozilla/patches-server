import sys
sys.path.append('../')

import time

import pytest

from patches_server.session_registry import \
    ActivityState, SessionState, SessionRegistry


def test_timed_out():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')
    registry.queue('test2', 'ubuntu:18.04')

    time.sleep(1)

    assert registry.timed_out() == [ 'test1', 'test2' ]


def test_notify_activity():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')

    assert registry.notify_activity('test1')
    assert not registry.notify_activity('test2')


def test_queue():
    registry = SessionRegistry(1, 3)

    assert registry.queue('test1', 'ubuntu:18.04')
    assert not registry.queue('test1', 'ubuntu:18.04')
    assert registry.queue('test2', 'ubuntu:18.04')
    assert registry.queue('test3', 'ubuntu:18.04')
    assert not registry.queue('test4', 'ubuntu:18.04')


def test_activate():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')
    registry.queue('test2', 'ubuntu:18.04')

    assert registry.activate() == [ 'test1' ]
    assert registry.activate() == []

    registry.terminate('test1')

    registry.queue('test1') 

    assert registry.activate() == [ 'test2' ]


def test_terminate():
    registry = SessionRegistry(1, 3)

    registry.queue('test1', 'ubuntu:18.04')

    assert registry.terminate('test1')
    assert not registry.terminate('test2')