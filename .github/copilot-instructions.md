# Copilot Instructions for jrm-code-client

## Purpose

This repository holds one or more **OpenAPI client bindings** for
[jrm-code-project.com](https://jrm-code-project.com). Each binding is
expected to be a client library (likely one per target language/ecosystem)
generated from, or hand-written against, the OpenAPI spec published by
jrm-code-project.

## Project status

The repository contains `README.md`, `LICENSE`, a checked-in snapshot of
the upstream OpenAPI spec at `openapi.json`, a Go client binding in `go/`
(package `jrmclient`, module `github.com/jrm-code-project/jrm-code-client/go`),
a Common Lisp client binding in `common-lisp/` (ASDF system
`jrm-code-client`, package `jrm-code-client`/nickname `jrmc`), a Python
client binding in `python/` (package `jrm_code_client`), and an Emacs Lisp
client binding in `emacs-lisp/` (package `jrm-code-client`).

## Go client (`go/`)

- Build/test: `cd go; go build ./...` and `go test ./...`. Run a single test
  with `go test ./... -run TestName -v`.
- `go vet ./...` and `gofmt -l .` should be clean before committing.
- Layout: one file per concern — `client.go` (Client type, request/auth
  plumbing, `APIError`), `types.go` (response structs), `auth.go`,
  `pastes.go`, `chef.go`, `diagnostics.go` (one file per group of related
  endpoints), `client_test.go` (uses `httptest` — no live network calls in
  tests).
- Conventions: every endpoint is a `(*Client) MethodName(ctx, ...)` method
  returning `(*ResponseType, error)`; auth-required endpoints call
  `doRequest`/`doRequestRaw` with `requestOptions{authorize: true}`, which
  fails fast with a clear error if `Client.SetToken` hasn't been called yet
  (no token is fetched implicitly). Errors from non-2xx responses surface as
  `*APIError` (status code + body) via `errors.As`.
- When the OpenAPI spec gains endpoints/fields, mirror the pattern above:
  add/extend a types.go struct, add a method in the relevant grouped file,
  and add an `httptest`-based test alongside it.

## Common Lisp client (`common-lisp/`)

- No system-wide Common Lisp toolchain may be assumed present. In this
  environment, SBCL is installed at `C:\Program Files\Steel Bank Common
  Lisp\sbcl.exe` with a working Quicklisp already set up under the user
  profile.
- Load via ASDF/Quicklisp: `(push (truename "common-lisp/")
  asdf:*central-registry*)` then `(ql:quickload :jrm-code-client)`.
- Build/test: `(asdf:test-system :jrm-code-client)` (wired via `:in-order-to
  ((asdf:test-op (asdf:test-op "jrm-code-client/tests")))` in
  `jrm-code-client.asd`) loads and runs the full FiveAM suite. Run a single
  test with `(fiveam:run! 'jrm-code-client/tests::test-name)` after loading
  `:jrm-code-client/tests`.
- Dependencies (via Quicklisp): `drakma` (HTTP), `jonathan` (JSON),
  `flexi-streams` (UTF-8 decoding of non-`text/*` responses, since drakma
  only auto-decodes bodies whose Content-Type is in `*text-content-types*`,
  which defaults to `text/*` only — `application/json` bodies come back as
  octet vectors and must be decoded explicitly); tests additionally use
  `hunchentoot` (local test server) and `fiveam`.
- Layout mirrors the Go package: `package.lisp`, `client.lisp` (`client`
  class, `%request`/`%request-json` plumbing, `api-error` condition),
  `auth.lisp`, `pastes.lisp`, `chef.lisp`, `diagnostics.lisp` (one file per
  group of related endpoints), plus `tests/test-server.lisp` (Hunchentoot
  test double) and `tests/client-tests.lisp`.
- Conventions: JSON object bodies/responses are plists keyed by
  **pipe-quoted lowercase keywords** (e.g. `:|access_token|`), not bare
  keywords — `jonathan` upcases bare `:access-token`-style keys on encode,
  and `jonathan:parse`'s plist output uses the exact on-wire case via pipe
  syntax on decode, so both directions must use pipe-quoted keys matching
  the JSON field names verbatim. Every endpoint returns a `defstruct`
  instance (e.g. `token-response`, `paste`, `create-paste-response`).
  Auth-required calls pass `:authorize t` to `%request`/`%request-json`,
  which signals an error immediately (no HTTP call made) if `client-token`
  is unset.
- **Testing gotcha:** Hunchentoot dispatches requests on worker threads, so
  test handlers must never call FiveAM's `is` directly — its pass/fail
  state is thread-local to the `test` form's thread, and a Hunchentoot
  worker thread is a different thread. Instead, handlers stash whatever
  needs checking into the plain (globally `setf`, never `let`-bound)
  special variable `*captured-request*`, and assertions run afterwards back
  on the test's own thread. See `tests/client-tests.lisp` for the pattern.

## Python client (`python/`)

- src-layout package: source under `python/src/jrm_code_client/`, tests
  under `python/tests/`.
- Setup: `pip install -e "./python[test]"` (installs the package plus
  `pytest` and `responses`).
- Test: `cd python; python -m pytest`. Run a single test with
  `python -m pytest -k test_name` or
  `python -m pytest tests/test_client.py::test_name`.
- Dependencies: `requests` (HTTP) at runtime; `responses` (HTTP mocking,
  playing the same role as `httptest`/Hunchentoot in the other bindings)
  and `pytest` for tests only.
- Layout: unlike the Go/CL bindings (functions/methods grouped by file
  directly), Python exposes a single `JrmCodeClient` class assembled from
  mixins — `_BaseClient` (session, token, `_request`/`_request_json`
  plumbing) in `client.py`, and one mixin per endpoint group: `_AuthMixin`
  (`auth.py`), `_PastesMixin` (`pastes.py`), `_ChefMixin` (`chef.py`),
  `_DiagnosticsMixin` (`diagnostics.py`). `__init__.py` combines them into
  the public `JrmCodeClient` and re-exports response dataclasses from
  `models.py` and `ApiError` from `exceptions.py`.
- Conventions: response types are frozen `dataclasses` with a
  `_from_json(dict)` classmethod. Auth-required methods pass
  `authorize=True` to `_request`/`_request_json`, which raises
  `RuntimeError` immediately if `client.token` is unset (no token is
  fetched implicitly). Non-2xx responses raise `ApiError` (status code +
  reason + body).

## Emacs Lisp client (`emacs-lisp/`)

- No package manager dependency: only built-in Emacs libraries are used
  (`url`, `json`, `cl-lib`). No admin rights are assumed in this
  environment; a portable Emacs build works fine (e.g. extract the
  official Windows zip from `https://ftpmirror.gnu.org/emacs/windows/` to
  `%USERPROFILE%\emacs-portable`).
- Build/test: from `emacs-lisp/`,
  `emacs -batch -L . -l jrm-code-client.el -l jrm-code-client-auth.el -l
  jrm-code-client-pastes.el -l jrm-code-client-chef.el -l
  jrm-code-client-diagnostics.el -l jrm-code-client-tests.el -f
  ert-run-tests-batch-and-exit` runs the full ERT suite. Byte-compile
  check: `emacs -batch -L . -f batch-byte-compile *.el` (should produce no
  warnings; `.elc` files are gitignored and safe to delete after).
- Layout mirrors the other bindings: `jrm-code-client.el` (core —
  `jrm-code-client` `cl-defstruct`, `jrm-code-client-create`,
  `jrm-code-client-api-error` condition via `define-error`,
  `jrm-code-client--http-request`/`--request`/`--request-json`
  plumbing), `jrm-code-client-auth.el`, `jrm-code-client-pastes.el`,
  `jrm-code-client-chef.el`, `jrm-code-client-diagnostics.el` (one file per
  group of related endpoints), and `jrm-code-client-tests.el` (ERT suite).
- Conventions: JSON is decoded with `json-object-type 'alist` and
  `json-key-type 'string` so keys match the wire format exactly (no
  case-mangling issues like the Common Lisp binding has). Every endpoint
  returns a `cl-defstruct` instance. Auth-required calls pass `:authorize
  t` through `--request`/`--request-json`, which signals a plain `error`
  immediately (no HTTP call made) if the client's `token` slot is unset.
- **Gotcha:** `jrm-code-client--http-request` intentionally takes plain
  positional arguments `(method url extra-headers data)`, not a
  `cl-defun`-style `&key` lambda list, even though it's the lowest-level
  request function. This is because ERT tests replace it via `cl-letf`
  with plain `lambda` forms to assert on outgoing requests, and plain
  Elisp `lambda` does **not** understand `&key` — that extended
  lambda-list syntax is only parsed by `cl-defun`/`cl-function`/`cl-lambda`.
  Mocking a `cl-defun`-with-`&key` function with a plain `&key` lambda
  fails at call time with `wrong-number-of-arguments`. Higher-level
  functions (`jrm-code-client--request`, `--request-json`) are never
  mocked directly in tests, so they safely use `cl-defun`/`&key` as usual.

## The OpenAPI spec

- Canonical source: `https://jrm-code-project.com/openapi.json` (OpenAPI
  3.0.3). A snapshot is checked into this repo as `openapi.json` — re-fetch
  it from the live URL when starting new work to catch upstream changes,
  and update the checked-in copy if it drifts.
- Auth model: most endpoints require a bearer JWT (`BearerAuth` security
  scheme). Obtain one via `POST /api/v1/auth/token` by exchanging a
  `username`/`api_key` pair; the token is short-lived (`expires_in`).
- Endpoints:
  - `POST /api/v1/auth/token` — exchange API key for JWT (no auth).
  - `POST /api/v1/pastes` — create a paste (auth required).
  - `GET /api/v1/pastes?id=` — retrieve a paste (public, no auth).
  - `DELETE /api/v1/pastes?id=` — delete own paste (auth required).
  - `GET /api/v1/user/pastes` — list caller's own pastes (auth required).
  - `POST /api/v1/chef` — "The Chef" roasts Lisp code; requires JWT **and**
    an `x-goog-api-key` header (caller's own Gemini API key); body is
    `text/plain` Lisp source, 64 lines max.
  - `GET /api/v1/ping` — liveness/auth check, returns identity + tier.
  - `POST /api/v1/echo` — JSON echo diagnostic endpoint (auth required).
- Common constraints across endpoints: JSON request bodies capped at 64KB
  (`413` if exceeded), `Content-Type` must match what's declared per
  endpoint (`application/json` or `text/plain`, else `415`), and endpoints
  are rate-limited (`429`).

## When more language bindings are added

Update this file to include, per new language directory:

- Whether clients are generated (e.g., via `openapi-generator`, `openapi-typescript`,
  `swagger-codegen`) or hand-written, and the exact command to (re)generate them.
- Exact build, lint, and test commands (including how to run a single test).
- Any conventions for versioning/publishing each client package.

Confirm layout/tooling choices with the user before scaffolding a new
language binding.
