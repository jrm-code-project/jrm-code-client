# jrm-code-client

Common Lisp client bindings for the [JRM Code Project](https://jrm-code-project.com) HTTP API.

## Dependencies

Loaded via Quicklisp: `drakma` (HTTP), `jonathan` (JSON), `flexi-streams`
(response decoding). Tests additionally need `hunchentoot` and `fiveam`.

## Loading

```lisp
(push #p"/path/to/jrm-code-client/common-lisp/" asdf:*central-registry*)
(ql:quickload :jrm-code-client)
```

## Usage

```lisp
(let ((client (jrm-code-client:make-client)))
  (let ((token (jrm-code-client:get-token client "alice" "my-api-key")))
    (setf (jrm-code-client:client-token client)
          (jrm-code-client:token-response-access-token token)))

  (let ((created (jrm-code-client:create-paste client "(print \"hello\")")))
    (format t "created paste: ~A~%" (jrm-code-client:create-paste-response-id created))

    ;; GET /api/v1/pastes is public; no token required.
    (let ((paste (jrm-code-client:get-paste client (jrm-code-client:create-paste-response-id created))))
      (format t "~A~%" (jrm-code-client:paste-content paste)))))
```

`jrm-code-client:make-client` defaults `:base-url` to
`jrm-code-client:*default-base-url*` (the production API).

## Errors

Non-2xx responses signal `jrm-code-client:api-error`, a subclass of `error`
carrying `api-error-status-code`, `api-error-reason-phrase`, and
`api-error-body`:

```lisp
(handler-case (jrm-code-client:get-paste client "missing")
  (jrm-code-client:api-error (e)
    (when (= (jrm-code-client:api-error-status-code e) 404)
      ;; handle "not found"
      )))
```

Calling an endpoint that requires authentication (`CLIENT-TOKEN` not yet
set) signals a plain `error` immediately, without making an HTTP request.

## Testing

```lisp
(push #p"/path/to/jrm-code-client/common-lisp/" asdf:*central-registry*)
(asdf:test-system :jrm-code-client)
```

Tests spin up a local Hunchentoot server as a stand-in for the real API —
no network access or live credentials are required.
