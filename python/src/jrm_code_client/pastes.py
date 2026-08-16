"""/api/v1/pastes and /api/v1/user/pastes"""

from __future__ import annotations

from typing import List

from .client import _BaseClient
from .models import CreatePasteResponse, Paste, PasteSummary, StatusResponse


class _PastesMixin(_BaseClient):
    def create_paste(self, content: str) -> CreatePasteResponse:
        """Create a new paste owned by the authenticated caller via
        POST /api/v1/pastes. Requires ``client.token`` to be set."""
        data = self._request_json(
            "POST",
            "/api/v1/pastes",
            json_body={"content": content},
            content_type="application/json",
            authorize=True,
        )
        return CreatePasteResponse._from_json(data)

    def get_paste(self, paste_id: str) -> Paste:
        """Retrieve a paste's content by id via GET /api/v1/pastes. This
        endpoint is publicly readable and requires no authentication."""
        data = self._request_json("GET", "/api/v1/pastes", params={"id": paste_id})
        return Paste._from_json(data)

    def delete_paste(self, paste_id: str) -> StatusResponse:
        """Delete a paste owned by the authenticated caller via
        DELETE /api/v1/pastes. Requires ``client.token`` to be set."""
        data = self._request_json(
            "DELETE", "/api/v1/pastes", params={"id": paste_id}, authorize=True
        )
        return StatusResponse._from_json(data)

    def list_pastes(self) -> List[PasteSummary]:
        """Return the authenticated caller's non-expired pastes, most
        recently created first, via GET /api/v1/user/pastes. Requires
        ``client.token`` to be set."""
        data = self._request_json("GET", "/api/v1/user/pastes", authorize=True)
        return [PasteSummary._from_json(entry) for entry in data]
