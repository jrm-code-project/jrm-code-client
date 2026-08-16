"""POST /api/v1/chef"""

from __future__ import annotations

from .client import _BaseClient


class _ChefMixin(_BaseClient):
    def chef(self, lisp_code: str, gemini_api_key: str) -> str:
        """Submit LISP_CODE (64 lines or fewer) to "The Chef" for a roast,
        via POST /api/v1/chef. Requires ``client.token`` to be set (paid
        tier) and GEMINI_API_KEY, the caller's own Google Gemini API key,
        sent as the x-goog-api-key header. Returns the roast as plain text.
        """
        response = self._request(
            "POST",
            "/api/v1/chef",
            data=lisp_code.encode("utf-8"),
            content_type="text/plain",
            authorize=True,
            extra_headers={"x-goog-api-key": gemini_api_key},
        )
        return response.text
