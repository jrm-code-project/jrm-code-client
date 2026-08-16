;;; jrm-code-client.el --- Client bindings for the JRM Code Project API -*- lexical-binding: t; -*-

;; Author: jrm-code-project
;; Maintainer: jrm-code-project
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: comm, tools
;; URL: https://github.com/jrm-code-project/jrm-code-client

;; This file is part of the jrm-code-client SDK and is distributed under
;; the same license as the rest of the repository (see LICENSE).

;;; Commentary:

;; Emacs Lisp client bindings for the JRM Code Project API
;; (https://jrm-code-project.com), as described by its OpenAPI 3.0.3
;; specification (see ../openapi.json at the repository root).
;;
;; Most endpoints require a bearer JWT.  Obtain one with
;; `jrm-code-client-get-token' and store it on the client with
;; `jrm-code-client-token' (a `setf'-able accessor), or pass TOKEN to
;; `jrm-code-client-create'.
;;
;; Example:
;;
;;   (let ((client (jrm-code-client-create)))
;;     (let ((token (jrm-code-client-get-token client "alice" "my-api-key")))
;;       (setf (jrm-code-client-token client)
;;             (jrm-code-client-token-response-access-token token)))
;;     (let ((paste (jrm-code-client-create-paste client "(print \"hello\")")))
;;       (jrm-code-client-get-paste client (jrm-code-client-create-paste-response-id paste))))

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'url)
(require 'url-http)

(defvar url-http-response-status)

(defconst jrm-code-client-default-base-url "https://jrm-code-project.com"
  "Default base URL for the JRM Code Project API.")

(cl-defstruct (jrm-code-client
               (:constructor jrm-code-client--make)
               (:copier nil))
  "An HTTP client for the JRM Code Project API.  Construct with
`jrm-code-client-create'."
  (base-url jrm-code-client-default-base-url :read-only nil)
  (token nil :read-only nil))

(cl-defun jrm-code-client-create (&key (base-url jrm-code-client-default-base-url) token)
  "Create a client for BASE-URL (defaults to the production API).
TOKEN, if given, is a bearer JWT attached to subsequent authenticated
requests; it may also be set later via `(setf (jrm-code-client-token
client) ...)'."
  (jrm-code-client--make :base-url (string-remove-suffix "/" base-url)
                          :token token))

(define-error 'jrm-code-client-api-error
  "JRM Code Project API request failed")

(defun jrm-code-client-api-error-status-code (err)
  "Return the HTTP status code carried by ERR, a `jrm-code-client-api-error'."
  (nth 0 (cdr err)))

(defun jrm-code-client-api-error-body (err)
  "Return the response body carried by ERR, a `jrm-code-client-api-error'."
  (nth 1 (cdr err)))

(defun jrm-code-client--build-query-string (params)
  "Build a URL query string from PARAMS, an alist of (NAME . VALUE)."
  (if (null params)
      ""
    (concat "?"
            (mapconcat (lambda (kv)
                         (format "%s=%s"
                                 (url-hexify-string (format "%s" (car kv)))
                                 (url-hexify-string (format "%s" (cdr kv)))))
                       params
                       "&"))))

(defun jrm-code-client--http-request (method url extra-headers data)
  "Perform a synchronous HTTP request.

METHOD is a string like \"GET\" or \"POST\".  URL is the fully-qualified
request URL.  EXTRA-HEADERS is an alist of additional request headers.
DATA, if non-nil, is the raw request body as a unibyte string.

Returns a plist (:status-code CODE :body STRING).  This is the only
function in this file that talks to `url.el' directly, so it is the
natural seam to replace in tests via `cl-letf'."
  (let ((url-request-method method)
        (url-request-extra-headers extra-headers)
        (url-request-data data))
    (let ((buffer (url-retrieve-synchronously url t t)))
      (unwind-protect
          (with-current-buffer buffer
            (goto-char (point-min))
            (let ((status-code url-http-response-status))
              (search-forward "\n\n" nil t)
              (list :status-code status-code
                    :body (buffer-substring-no-properties (point) (point-max)))))
        (when (buffer-live-p buffer)
          (kill-buffer buffer))))))

(cl-defun jrm-code-client--request (client method path
                                            &key query body content-type
                                            (authorize nil) extra-headers)
  "Issue a request against CLIENT's API.

METHOD is a string (\"GET\", \"POST\", \"DELETE\", ...).  PATH is the API
path, e.g. \"/api/v1/pastes\".  QUERY is an alist of query parameters.
BODY, if non-nil, is sent verbatim as the request body.  CONTENT-TYPE,
if non-nil, is sent as the Content-Type header.  If AUTHORIZE is
non-nil, the client's bearer token is required and sent as the
Authorization header.  EXTRA-HEADERS is an alist of additional headers.

Returns the response body as a string.  Signals
`jrm-code-client-api-error' on a non-2xx response, and a plain `error'
if AUTHORIZE is set but the client has no token."
  (let ((headers (append extra-headers
                          (when content-type
                            (list (cons "Content-Type" content-type)))
                          (when authorize
                            (let ((token (jrm-code-client-token client)))
                              (unless token
                                (error "jrm-code-client: %s %s requires a bearer token; set (jrm-code-client-token client) or call jrm-code-client-get-token first"
                                       method path))
                              (list (cons "Authorization" (concat "Bearer " token))))))))
    (let* ((url (concat (jrm-code-client-base-url client) path
                         (jrm-code-client--build-query-string query)))
           (response (jrm-code-client--http-request method url headers body))
           (status-code (plist-get response :status-code))
           (response-body (plist-get response :body)))
      (unless (and status-code (<= 200 status-code) (< status-code 300))
        (signal 'jrm-code-client-api-error (list status-code response-body)))
      response-body)))

(cl-defun jrm-code-client--request-json (client method path
                                                 &key query body-alist (authorize nil))
  "Like `jrm-code-client--request', but BODY-ALIST is encoded as a JSON
object request body, and the JSON response body is decoded into an
alist (see `json-read-from-string')."
  (let ((body (when body-alist
                (encode-coding-string (json-encode body-alist) 'utf-8))))
    (let ((response-body (jrm-code-client--request client method path
                                                     :query query
                                                     :body body
                                                     :content-type "application/json"
                                                     :authorize authorize)))
      (if (and response-body (not (string-empty-p response-body)))
          (let ((json-object-type 'alist)
                (json-array-type 'list)
                (json-key-type 'string))
            (json-read-from-string response-body))
        nil))))

(provide 'jrm-code-client)

;;; jrm-code-client.el ends here
