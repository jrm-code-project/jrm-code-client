;;; jrm-code-client-pastes.el --- /api/v1/pastes and /api/v1/user/pastes -*- lexical-binding: t; -*-

;; Author: jrm-code-project
;; Package-Requires: ((emacs "27.1") (jrm-code-client "0.1.0"))

;;; Commentary:

;; Paste endpoint bindings for jrm-code-client.

;;; Code:

(require 'cl-lib)
(require 'jrm-code-client)

(cl-defstruct (jrm-code-client-paste
               (:constructor jrm-code-client-paste--make)
               (:copier nil))
  "A paste's full content, as returned by `jrm-code-client-get-paste'."
  id
  content)

(cl-defstruct (jrm-code-client-paste-summary
               (:constructor jrm-code-client-paste-summary--make)
               (:copier nil))
  "A single entry in the authenticated caller's paste list, as returned
by `jrm-code-client-list-pastes'."
  id
  created-at
  expires-at
  content-preview)

(cl-defstruct (jrm-code-client-create-paste-response
               (:constructor jrm-code-client-create-paste-response--make)
               (:copier nil))
  "The response returned by `jrm-code-client-create-paste'."
  status
  id)

(cl-defstruct (jrm-code-client-status-response
               (:constructor jrm-code-client-status-response--make)
               (:copier nil))
  "A generic {\"status\": ...} response, e.g. from
`jrm-code-client-delete-paste'."
  status)

(defun jrm-code-client-create-paste (client content)
  "Create a new paste owned by the authenticated caller via
POST /api/v1/pastes.  Requires CLIENT's token to be set."
  (let ((alist (jrm-code-client--request-json
                client "POST" "/api/v1/pastes"
                :body-alist (list (cons "content" content))
                :authorize t)))
    (jrm-code-client-create-paste-response--make
     :status (cdr (assoc "status" alist))
     :id (cdr (assoc "id" alist)))))

(defun jrm-code-client-get-paste (client id)
  "Retrieve a paste's content by ID via GET /api/v1/pastes.  This
endpoint is publicly readable and requires no authentication."
  (let ((alist (jrm-code-client--request-json
                client "GET" "/api/v1/pastes"
                :query (list (cons "id" id)))))
    (jrm-code-client-paste--make
     :id (cdr (assoc "id" alist))
     :content (cdr (assoc "content" alist)))))

(defun jrm-code-client-delete-paste (client id)
  "Delete a paste owned by the authenticated caller via
DELETE /api/v1/pastes.  Requires CLIENT's token to be set."
  (let ((alist (jrm-code-client--request-json
                client "DELETE" "/api/v1/pastes"
                :query (list (cons "id" id))
                :authorize t)))
    (jrm-code-client-status-response--make :status (cdr (assoc "status" alist)))))

(defun jrm-code-client-list-pastes (client)
  "Return the authenticated caller's non-expired pastes, most recently
created first, as a list of `jrm-code-client-paste-summary', via
GET /api/v1/user/pastes.  Requires CLIENT's token to be set."
  (let ((entries (jrm-code-client--request-json
                  client "GET" "/api/v1/user/pastes"
                  :authorize t)))
    (mapcar (lambda (entry)
              (jrm-code-client-paste-summary--make
               :id (cdr (assoc "id" entry))
               :created-at (cdr (assoc "created_at" entry))
               :expires-at (cdr (assoc "expires_at" entry))
               :content-preview (cdr (assoc "content_preview" entry))))
            entries)))

(provide 'jrm-code-client-pastes)

;;; jrm-code-client-pastes.el ends here
