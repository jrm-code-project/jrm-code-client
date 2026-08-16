"""GET /api/v1/ping and POST /api/v1/echo"""

from __future__ import annotations

from typing import Any

from .client import _BaseClient
from .models import EchoResponse, PingResponse


class _DiagnosticsMixin(_BaseClient):
    def ping(self) -> PingResponse:
        """Perform a trivial JWT-authenticated liveness check via
        GET /api/v1/ping, returning the caller's identity and tier as
        decoded from the bearer token. Requires ``client.token`` to be
        set."""
        data = self._request_json("GET", "/api/v1/ping", authorize=True)
        return PingResponse._from_json(data)

    def echo(self, payload: Any) -> EchoResponse:
        """Send PAYLOAD (any JSON-serializable value) to POST /api/v1/echo
        and return it verbatim as decoded by the server, useful for
        confirming request encoding and auth header handling end to end.
        Requires ``client.token`` to be set."""
        data = self._request_json(
            "POST",
            "/api/v1/echo",
            json_body=payload,
            content_type="application/json",
            authorize=True,
        )
        return EchoResponse._from_json(data)
