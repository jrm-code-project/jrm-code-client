# jrm-code-client (Emacs Lisp)

Emacs Lisp client bindings for the [JRM Code Project](https://jrm-code-project.com) HTTP API.

## Install

No package manager required. Add this directory to your `load-path` and
require the files you need:

```elisp
(add-to-list 'load-path "/path/to/jrm-code-client/emacs-lisp")
(require 'jrm-code-client)
(require 'jrm-code-client-auth)
(require 'jrm-code-client-pastes)
(require 'jrm-code-client-chef)
(require 'jrm-code-client-diagnostics)
```

Only built-in Emacs libraries are used (`url`, `json`, `cl-lib`) — there are
no external package dependencies.

## Usage

```elisp
(let ((client (jrm-code-client-create))) ; defaults to https://jrm-code-project.com
  (let ((token (jrm-code-client-get-token client "alice" "my-api-key")))
    (setf (jrm-code-client-token client)
          (jrm-code-client-token-response-access-token token)))

  (let* ((created (jrm-code-client-create-paste client "(print \"hello\")"))
         (id (jrm-code-client-create-paste-response-id created)))
    (message "created paste: %s" id)
    ;; Public endpoint, no auth required.
    (jrm-code-client-paste-content (jrm-code-client-get-paste client id))))
```

## Errors

Non-2xx responses signal `jrm-code-client-api-error`, a condition defined
with `define-error` that carries `status-code`, `reason`, and `body` (via
`jrm-code-client-api-error-status-code` etc., extracted from the error
data):

```elisp
(condition-case err
    (jrm-code-client-get-paste client "missing")
  (jrm-code-client-api-error
   (when (= (jrm-code-client-api-error-status-code err) 404)
     ;; handle "not found"
     )))
```

Calling a method that requires authentication before the client's `token`
slot is set signals a plain `error` immediately, without making an HTTP
request.

## Testing

Tests use ERT and never touch the network: `jrm-code-client--http-request`
is the only function that calls into `url.el`, and every test replaces it
with `cl-letf` to assert on the outgoing request and return a canned
response.

Using a portable Emacs build (or any Emacs 27.1+) from the `emacs-lisp`
directory:

```
emacs -batch -L . \
  -l jrm-code-client.el -l jrm-code-client-auth.el \
  -l jrm-code-client-pastes.el -l jrm-code-client-chef.el \
  -l jrm-code-client-diagnostics.el -l jrm-code-client-tests.el \
  -f ert-run-tests-batch-and-exit
```

To check for byte-compile warnings:

```
emacs -batch -L . -f batch-byte-compile *.el
```

### Gotcha: `&key` in mocked lambdas

`jrm-code-client--http-request` takes plain positional arguments
`(method url extra-headers data)` rather than `cl-defun`'s `&key` extended
lambda list. This is deliberate: tests replace it via `cl-letf` with plain
`lambda` forms, and plain Elisp `lambda` does **not** understand `&key`
(that syntax is only parsed by `cl-defun`/`cl-function`/`cl-lambda`).
Mocking a `cl-defun`-with-`&key` function with a plain `&key` lambda fails
at call time with `wrong-number-of-arguments`. Higher-level functions
(`jrm-code-client--request`, `jrm-code-client--request-json`) are never
mocked directly, so they're free to use `cl-defun`/`&key` as usual.
