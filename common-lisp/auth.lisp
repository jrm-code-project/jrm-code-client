;;;; auth.lisp -- POST /api/v1/auth/token

(in-package #:jrm-code-client)

(defstruct token-response
  access-token
  expires-in
  token-type)

(defun get-token (client username api-key)
  "Exchange USERNAME and API-KEY for a short-lived JWT via
POST /api/v1/auth/token. This endpoint does not require prior
authentication. The returned TOKEN-RESPONSE is not automatically stored on
CLIENT; call (SETF (CLIENT-TOKEN client) (token-response-access-token
response)) to do so."
  (let ((response (%request-json client :post "/api/v1/auth/token"
                                  :body-plist (list :|username| username
                                                     :|api_key| api-key))))
    (make-token-response :access-token (getf response :|access_token|)
                          :expires-in (getf response :|expires_in|)
                          :token-type (getf response :|token_type|))))
