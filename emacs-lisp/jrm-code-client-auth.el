;;; jrm-code-client-auth.el --- POST /api/v1/auth/token -*- lexical-binding: t; -*-

;; Author: jrm-code-project
;; Package-Requires: ((emacs "27.1") (jrm-code-client "0.1.0"))

;;; Commentary:

;; Authentication endpoint bindings for jrm-code-client.

;;; Code:

(require 'cl-lib)
(require 'jrm-code-client)

(cl-defstruct (jrm-code-client-token-response
               (:constructor jrm-code-client-token-response--make)
               (:copier nil))
  "The response returned by `jrm-code-client-get-token'."
  access-token
  expires-in
  token-type)

(defun jrm-code-client-token-response--from-alist (alist)
  (jrm-code-client-token-response--make
   :access-token (cdr (assoc "access_token" alist))
   :expires-in (cdr (assoc "expires_in" alist))
   :token-type (cdr (assoc "token_type" alist))))

(defun jrm-code-client-get-token (client username api-key)
  "Exchange USERNAME and API-KEY for a short-lived JWT via
POST /api/v1/auth/token.  This endpoint does not require prior
authentication.  The returned token is not automatically stored on
CLIENT; call `(setf (jrm-code-client-token client) (... access-token))'
to do so."
  (jrm-code-client-token-response--from-alist
   (jrm-code-client--request-json client "POST" "/api/v1/auth/token"
                                   :body-alist (list (cons "username" username)
                                                      (cons "api_key" api-key)))))

(provide 'jrm-code-client-auth)

;;; jrm-code-client-auth.el ends here
