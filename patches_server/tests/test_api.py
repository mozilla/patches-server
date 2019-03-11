import pytest

from patches_server.api import api


@pytest.fixture
def client():
    api.config['TESTING'] = True

    yield api.test_client()


def test_hello(client):
    response = client.get('/').json
    assert response.get('hits') > 0
