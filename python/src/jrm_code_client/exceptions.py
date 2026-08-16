"""Exceptions raised by the JRM Code Project API client."""

from __future__ import annotations


class ApiError(Exception):
    """Raised when the API responds with a non-2xx status code.

    Attributes:
        status_code: The HTTP status code returned by the server.
        reason: The HTTP reason phrase (e.g. "Not Found").
        body: The raw response body, if any.
    """

    def __init__(self, status_code: int, reason: str, body: str = ""):
        self.status_code = status_code
        self.reason = reason
        self.body = body
        message = f"jrm_code_client: {status_code} {reason}"
        if body:
            message += f": {body}"
        super().__init__(message)
