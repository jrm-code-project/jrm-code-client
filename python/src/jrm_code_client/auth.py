"""POST /api/v1/auth/token"""

from __future__ import annotations

from .client import _BaseClient
from .models import TokenResponse


class _AuthMixin(_BaseClient):
    def get_token(self, username: str, api_key: str) -> TokenResponse:
        """Exchange USERNAME and API_KEY for a short-lived JWT via
        POST /api/v1/auth/token. This endpoint does not require prior
        authentication. The returned token is not automatically stored on
        the client; set ``client.token = response.access_token`` to do so.
        """
        data = self._request_json(
            "POST",
            "/api/v1/auth/token",
            json_body={"username": username, "api_key": api_key},
            content_type="application/json",
        )
        return TokenResponse._from_json(data)
