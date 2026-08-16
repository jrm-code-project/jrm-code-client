;;;; pastes.lisp -- /api/v1/pastes and /api/v1/user/pastes

(in-package #:jrm-code-client)

(defstruct paste
  id
  content)

(defstruct paste-summary
  id
  created-at
  expires-at
  content-preview)

(defstruct create-paste-response
  status
  id)

(defstruct status-response
  status)

(defun create-paste (client content)
  "Create a new paste owned by the authenticated caller via
POST /api/v1/pastes. Requires CLIENT-TOKEN to be set."
  (let ((response (%request-json client :post "/api/v1/pastes"
                                  :body-plist (list :|content| content)
                                  :authorize t)))
    (make-create-paste-response :status (getf response :|status|)
                                 :id (getf response :|id|))))

(defun get-paste (client id)
  "Retrieve a paste's content by ID via GET /api/v1/pastes. This endpoint is
publicly readable and requires no authentication."
  (let ((response (%request-json client :get "/api/v1/pastes"
                                  :query (list (cons "id" id)))))
    (make-paste :id (getf response :|id|)
                :content (getf response :|content|))))

(defun delete-paste (client id)
  "Delete a paste owned by the authenticated caller via
DELETE /api/v1/pastes. Requires CLIENT-TOKEN to be set."
  (let ((response (%request-json client :delete "/api/v1/pastes"
                                  :query (list (cons "id" id))
                                  :authorize t)))
    (make-status-response :status (getf response :|status|))))

(defun list-pastes (client)
  "Return the authenticated caller's non-expired pastes, most recently
created first, as a list of PASTE-SUMMARY, via GET /api/v1/user/pastes.
Requires CLIENT-TOKEN to be set."
  (let ((response (%request-json client :get "/api/v1/user/pastes"
                                  :authorize t)))
    (mapcar (lambda (entry)
              (make-paste-summary :id (getf entry :|id|)
                                   :created-at (getf entry :|created_at|)
                                   :expires-at (getf entry :|expires_at|)
                                   :content-preview (getf entry :|content_preview|)))
            response)))
