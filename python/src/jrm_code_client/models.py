"""Response types for the JRM Code Project API client.

All classes are plain, immutable ``dataclasses`` constructed from the JSON
payloads returned by the API.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional


@dataclass(frozen=True)
class TokenResponse:
    access_token: str
    expires_in: int
    token_type: str

    @classmethod
    def _from_json(cls, data: dict) -> "TokenResponse":
        return cls(
            access_token=data.get("access_token"),
            expires_in=data.get("expires_in"),
            token_type=data.get("token_type"),
        )


@dataclass(frozen=True)
class Paste:
    id: str
    content: str

    @classmethod
    def _from_json(cls, data: dict) -> "Paste":
        return cls(id=data.get("id"), content=data.get("content"))


@dataclass(frozen=True)
class PasteSummary:
    id: str
    created_at: str
    expires_at: Optional[str]
    content_preview: str

    @classmethod
    def _from_json(cls, data: dict) -> "PasteSummary":
        return cls(
            id=data.get("id"),
            created_at=data.get("created_at"),
            expires_at=data.get("expires_at"),
            content_preview=data.get("content_preview"),
        )


@dataclass(frozen=True)
class CreatePasteResponse:
    status: str
    id: str

    @classmethod
    def _from_json(cls, data: dict) -> "CreatePasteResponse":
        return cls(status=data.get("status"), id=data.get("id"))


@dataclass(frozen=True)
class StatusResponse:
    status: str

    @classmethod
    def _from_json(cls, data: dict) -> "StatusResponse":
        return cls(status=data.get("status"))


@dataclass(frozen=True)
class PingResponse:
    status: str
    user: str
    tier: str

    @classmethod
    def _from_json(cls, data: dict) -> "PingResponse":
        return cls(status=data.get("status"), user=data.get("user"), tier=data.get("tier"))


@dataclass(frozen=True)
class EchoResponse:
    status: str
    echo: Any

    @classmethod
    def _from_json(cls, data: dict) -> "EchoResponse":
        return cls(status=data.get("status"), echo=data.get("echo"))
