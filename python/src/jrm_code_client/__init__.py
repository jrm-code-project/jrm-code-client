"""Python client bindings for the JRM Code Project API
(https://jrm-code-project.com).

Example::

    from jrm_code_client import JrmCodeClient

    client = JrmCodeClient()
    token = client.get_token("alice", "my-api-key")
    client.token = token.access_token

    created = client.create_paste('(print "hello")')
    paste = client.get_paste(created.id)  # public, no auth required
    print(paste.content)
"""

from __future__ import annotations

from .auth import _AuthMixin
from .chef import _ChefMixin
from .client import DEFAULT_BASE_URL, _BaseClient
from .diagnostics import _DiagnosticsMixin
from .exceptions import ApiError
from .models import (
    CreatePasteResponse,
    EchoResponse,
    Paste,
    PasteSummary,
    PingResponse,
    StatusResponse,
    TokenResponse,
)
from .pastes import _PastesMixin


class JrmCodeClient(_AuthMixin, _PastesMixin, _ChefMixin, _DiagnosticsMixin, _BaseClient):
    """A client for the JRM Code Project API.

    Construct with ``JrmCodeClient()`` (defaults to the production API) or
    ``JrmCodeClient(base_url=..., token=...)``. Most methods require
    ``token`` to be set (either at construction, by assigning
    ``client.token = ...``, or from a prior call to :meth:`get_token`).
    """


__all__ = [
    "JrmCodeClient",
    "DEFAULT_BASE_URL",
    "ApiError",
    "TokenResponse",
    "Paste",
    "PasteSummary",
    "CreatePasteResponse",
    "StatusResponse",
    "PingResponse",
    "EchoResponse",
]
