"""Core HTTP client for the JRM Code Project API.

This module defines :class:`_BaseClient`, which owns the ``requests``
session, bearer-token state, and shared request plumbing used by the
per-endpoint mixins in ``auth.py``, ``pastes.py``, ``chef.py``, and
``diagnostics.py``. The public :class:`JrmCodeClient` (see
``jrm_code_client/__init__.py``... actually defined at the bottom of this
module) composes all of them.
"""

from __future__ import annotations

from typing import Any, Optional

import requests

from .exceptions import ApiError

DEFAULT_BASE_URL = "https://jrm-code-project.com"


class _BaseClient:
    """Shared state and request plumbing for the JRM Code Project API."""

    def __init__(
        self,
        base_url: str = DEFAULT_BASE_URL,
        *,
        token: Optional[str] = None,
        session: Optional[requests.Session] = None,
        timeout: float = 30.0,
    ):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout
        self._session = session or requests.Session()

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[dict] = None,
        json_body: Optional[Any] = None,
        data: Optional[Any] = None,
        content_type: Optional[str] = None,
        authorize: bool = False,
        extra_headers: Optional[dict] = None,
    ) -> requests.Response:
        """Issue an HTTP request against the API and raise ApiError on a
        non-2xx response. JSON bodies should be passed via ``json_body``;
        raw bodies (e.g. text/plain) via ``data``.
        """
        headers = dict(extra_headers or {})
        if content_type:
            headers["Content-Type"] = content_type
        if authorize:
            if not self.token:
                raise RuntimeError(
                    f"jrm_code_client: {method} {path} requires a bearer token; "
                    "set client.token or call get_token() first."
                )
            headers["Authorization"] = f"Bearer {self.token}"

        response = self._session.request(
            method,
            f"{self.base_url}{path}",
            params=params,
            json=json_body,
            data=data,
            headers=headers,
            timeout=self.timeout,
        )
        if not (200 <= response.status_code < 300):
            raise ApiError(response.status_code, response.reason, response.text)
        return response

    def _request_json(self, method: str, path: str, **kwargs) -> Any:
        """Like :meth:`_request`, but decodes and returns the JSON response
        body (or ``None`` if the body is empty)."""
        response = self._request(method, path, **kwargs)
        if not response.content:
            return None
        return response.json()
