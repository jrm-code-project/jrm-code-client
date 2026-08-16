;;;; client.lisp -- core CLIENT type and HTTP request plumbing.

(in-package #:jrm-code-client)

(defparameter *default-base-url* "https://jrm-code-project.com"
  "Default base URL for the JRM Code Project API.")

(defclass client ()
  ((base-url :initarg :base-url
             :accessor client-base-url
             :initform *default-base-url*
             :documentation "Base URL of the API, without a trailing slash.")
   (token :initarg :token
          :accessor client-token
          :initform nil
          :documentation "Bearer JWT attached to authenticated requests, or NIL."))
  (:documentation
   "An HTTP client for the JRM Code Project API. Construct with MAKE-CLIENT."))

(defun make-client (&key (base-url *default-base-url*) token)
  "Create a CLIENT for BASE-URL (defaults to the production API). TOKEN, if
given, is a bearer JWT attached to subsequent authenticated requests; it may
also be set later via (SETF CLIENT-TOKEN)."
  (make-instance 'client :base-url base-url :token token))

(define-condition api-error (error)
  ((status-code :initarg :status-code :reader api-error-status-code)
   (reason-phrase :initarg :reason-phrase :reader api-error-reason-phrase)
   (body :initarg :body :reader api-error-body))
  (:report (lambda (condition stream)
             (format stream "jrm-code-client: ~A ~A: ~A"
                     (api-error-status-code condition)
                     (api-error-reason-phrase condition)
                     (api-error-body condition))))
  (:documentation "Signaled when the API responds with a non-2xx status."))

(defun %successp (status-code)
  (<= 200 status-code 299))

(defun %request (client method path
                  &key query body (content-type nil) (authorize nil) extra-headers)
  "Issue an HTTP request against CLIENT's API. BODY, if non-NIL, is sent
verbatim as an octet vector or string. Returns two values: the response
body as a string, and the numeric HTTP status code. Signals API-ERROR on a
non-2xx response."
  (let* ((url (format nil "~A~A" (client-base-url client) path))
         (headers (append extra-headers
                           (when authorize
                             (let ((token (client-token client)))
                               (unless token
                                 (error "jrm-code-client: ~A ~A requires a bearer token; set CLIENT-TOKEN or call GET-TOKEN first."
                                        method path))
                               (list (cons "Authorization" (format nil "Bearer ~A" token))))))))
    (multiple-value-bind (response-body status-code)
        (drakma:http-request url
                              :method method
                              :parameters query
                              :content body
                              :content-type content-type
                              :additional-headers headers
                              :want-stream nil
                              :external-format-out :utf-8
                              :external-format-in :utf-8)
      (let ((response-body (if (typep response-body '(vector (unsigned-byte 8)))
                                (flexi-streams:octets-to-string response-body :external-format :utf-8)
                                response-body)))
        (unless (%successp status-code)
          (error 'api-error
                 :status-code status-code
                 :reason-phrase (drakma-status-reason status-code)
                 :body (or response-body "")))
        (values response-body status-code)))))

(defun drakma-status-reason (status-code)
  "Best-effort human-readable reason phrase for STATUS-CODE."
  (case status-code
    (400 "Bad Request")
    (401 "Unauthorized")
    (403 "Forbidden")
    (404 "Not Found")
    (413 "Payload Too Large")
    (415 "Unsupported Media Type")
    (422 "Unprocessable Entity")
    (429 "Too Many Requests")
    (t "HTTP Error")))

(defun %request-json (client method path &key query body-plist authorize)
  "Like %REQUEST, but BODY-PLIST (a plist with pipe-quoted lowercase keyword
keys, e.g. (:|username| \"alice\")) is encoded as a JSON object request
body, and the JSON response body is decoded into a plist (also with
pipe-quoted lowercase keyword keys) via jonathan."
  (let* ((body (when body-plist
                 (jonathan:to-json body-plist))))
    (multiple-value-bind (response-body status-code)
        (%request client method path
                  :query query
                  :body body
                  :content-type "application/json"
                  :authorize authorize)
      (declare (ignore status-code))
      (if (and response-body (plusp (length response-body)))
          (jonathan:parse response-body :as :plist)
          nil))))
