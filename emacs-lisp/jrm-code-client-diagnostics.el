;;; jrm-code-client-diagnostics.el --- GET /api/v1/ping and POST /api/v1/echo -*- lexical-binding: t; -*-

;; Author: jrm-code-project
;; Package-Requires: ((emacs "27.1") (jrm-code-client "0.1.0"))

;;; Commentary:

;; Diagnostic endpoint bindings for jrm-code-client.

;;; Code:

(require 'cl-lib)
(require 'jrm-code-client)

(cl-defstruct (jrm-code-client-ping-response
               (:constructor jrm-code-client-ping-response--make)
               (:copier nil))
  "The response returned by `jrm-code-client-ping'."
  status
  user
  tier)

(cl-defstruct (jrm-code-client-echo-response
               (:constructor jrm-code-client-echo-response--make)
               (:copier nil))
  "The response returned by `jrm-code-client-echo'."
  status
  echo)

(defun jrm-code-client-ping (client)
  "Perform a trivial JWT-authenticated liveness check via
GET /api/v1/ping, returning the caller's identity and tier as decoded
from the bearer token.  Requires CLIENT's token to be set."
  (let ((alist (jrm-code-client--request-json client "GET" "/api/v1/ping" :authorize t)))
    (jrm-code-client-ping-response--make
     :status (cdr (assoc "status" alist))
     :user (cdr (assoc "user" alist))
     :tier (cdr (assoc "tier" alist)))))

(defun jrm-code-client-echo (client payload)
  "Send PAYLOAD (any value `json-encode' can serialize) to
POST /api/v1/echo and return it verbatim as decoded by the server,
useful for confirming request encoding and auth header handling end to
end.  Requires CLIENT's token to be set."
  (let ((alist (jrm-code-client--request-json client "POST" "/api/v1/echo"
                                               :body-alist payload
                                               :authorize t)))
    (jrm-code-client-echo-response--make
     :status (cdr (assoc "status" alist))
     :echo (cdr (assoc "echo" alist)))))

(provide 'jrm-code-client-diagnostics)

;;; jrm-code-client-diagnostics.el ends here
