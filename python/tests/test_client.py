"""Tests for jrm_code_client, mocking HTTP via the `responses` library."""

import json

import pytest
import responses

from jrm_code_client import ApiError, JrmCodeClient

BASE_URL = "https://example.test"


@pytest.fixture
def client():
    return JrmCodeClient(base_url=BASE_URL)


@responses.activate
def test_get_token(client):
    def callback(request):
        assert request.headers["Content-Type"] == "application/json"
        body = json.loads(request.body)
        assert body == {"username": "alice", "api_key": "secret"}
        return (
            200,
            {"Content-Type": "application/json"},
            json.dumps({"access_token": "tok", "expires_in": 3600, "token_type": "bearer"}),
        )

    responses.add_callback(
        responses.POST, f"{BASE_URL}/api/v1/auth/token", callback=callback
    )

    token = client.get_token("alice", "secret")
    assert token.access_token == "tok"
    assert token.expires_in == 3600


def test_create_paste_requires_token(client):
    with pytest.raises(RuntimeError):
        client.create_paste("hello")


@responses.activate
def test_create_paste_sends_bearer_token(client):
    def callback(request):
        assert request.headers["Authorization"] == "Bearer tok"
        return (201, {"Content-Type": "application/json"}, json.dumps({"status": "ok", "id": "abc123"}))

    responses.add_callback(responses.POST, f"{BASE_URL}/api/v1/pastes", callback=callback)

    client.token = "tok"
    response = client.create_paste("(print 1)")
    assert response.id == "abc123"


@responses.activate
def test_get_paste_no_auth_required(client):
    def callback(request):
        assert request.params["id"] == "abc123"
        return (200, {"Content-Type": "application/json"}, json.dumps({"id": "abc123", "content": "hi"}))

    responses.add_callback(responses.GET, f"{BASE_URL}/api/v1/pastes", callback=callback)

    paste = client.get_paste("abc123")
    assert paste.content == "hi"


@responses.activate
def test_api_error_on_non_2xx(client):
    responses.add(responses.GET, f"{BASE_URL}/api/v1/pastes", status=404, body="paste not found")

    with pytest.raises(ApiError) as exc_info:
        client.get_paste("missing")
    assert exc_info.value.status_code == 404


@responses.activate
def test_chef_sends_gemini_header_and_plain_text(client):
    def callback(request):
        assert request.headers["x-goog-api-key"] == "gemini-key"
        assert request.headers["Content-Type"] == "text/plain"
        assert request.body == b"(print 1)"
        return (200, {"Content-Type": "text/plain"}, "This code is an abomination.")

    responses.add_callback(responses.POST, f"{BASE_URL}/api/v1/chef", callback=callback)

    client.token = "tok"
    roast = client.chef("(print 1)", "gemini-key")
    assert roast == "This code is an abomination."


@responses.activate
def test_ping(client):
    responses.add(
        responses.GET,
        f"{BASE_URL}/api/v1/ping",
        json={"status": "ok", "user": "alice", "tier": "paid"},
    )

    client.token = "tok"
    response = client.ping()
    assert response.user == "alice"


@responses.activate
def test_list_pastes(client):
    responses.add(
        responses.GET,
        f"{BASE_URL}/api/v1/user/pastes",
        json=[{"id": "a", "created_at": "2024-01-01T00:00:00Z", "expires_at": None, "content_preview": "hi"}],
    )

    client.token = "tok"
    pastes = client.list_pastes()
    assert len(pastes) == 1
    assert pastes[0].id == "a"


@responses.activate
def test_echo(client):
    def callback(request):
        body = json.loads(request.body)
        assert body == {"hello": "world"}
        return (200, {"Content-Type": "application/json"}, json.dumps({"status": "ok", "echo": body}))

    responses.add_callback(responses.POST, f"{BASE_URL}/api/v1/echo", callback=callback)

    client.token = "tok"
    response = client.echo({"hello": "world"})
    assert response.status == "ok"
    assert response.echo == {"hello": "world"}
