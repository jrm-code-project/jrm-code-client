;;;; diagnostics.lisp -- GET /api/v1/ping and POST /api/v1/echo

(in-package #:jrm-code-client)

(defstruct ping-response
  status
  user
  tier)

(defstruct echo-response
  status
  echo)

(defun ping (client)
  "Perform a trivial JWT-authenticated liveness check via GET /api/v1/ping,
returning the caller's identity and tier as decoded from the bearer token.
Requires CLIENT-TOKEN to be set."
  (let ((response (%request-json client :get "/api/v1/ping" :authorize t)))
    (make-ping-response :status (getf response :|status|)
                         :user (getf response :|user|)
                         :tier (getf response :|tier|))))

(defun echo (client payload-plist)
  "Send PAYLOAD-PLIST (a plist with pipe-quoted lowercase keyword keys) to
POST /api/v1/echo and return it verbatim as decoded by the server, useful
for confirming request encoding and auth header handling end to end.
Requires CLIENT-TOKEN to be set."
  (let ((response (%request-json client :post "/api/v1/echo"
                                  :body-plist payload-plist
                                  :authorize t)))
    (make-echo-response :status (getf response :|status|)
                         :echo (getf response :|echo|))))
