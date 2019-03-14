import pytest

from api import api


@pytest.fixture
def client():
    api.config['TESTING'] = True

    yield api.test_client()


def test_session_registration(client):
    response = client.get('/?platform=ubuntu:18.04').json

    session_id = response.get('session')

    assert isinstance(session_id, str)
    assert len(session_id) > 0
