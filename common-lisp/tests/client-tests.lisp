;;;; tests/client-tests.lisp -- FiveAM test suite for jrm-code-client.
;;;;
;;;; NOTE: Hunchentoot serves requests on worker threads, but FiveAM's `is`
;;;; assertion macro relies on per-thread state bound by the enclosing
;;;; `test` form. So handlers below never call `is` directly; instead they
;;;; record whatever they want to check into *captured-request* (a plist),
;;;; and the test body asserts on it after the client call returns, back on
;;;; the FiveAM test's own thread.

(in-package #:jrm-code-client/tests)

(def-suite jrm-code-client-suite)
(in-suite jrm-code-client-suite)

(defvar *captured-request* nil
  "Plist populated by a *TEST-HANDLER* with whatever it wants a test to
assert on afterwards, since FiveAM's IS macro cannot safely run on a
Hunchentoot worker thread.")

(defun read-json-body ()
  "Parse the current Hunchentoot request's body as a JSON plist."
  (jonathan:parse (hunchentoot:raw-post-data :force-text t) :as :plist))

(defun respond-json (plist &key (status 200))
  (setf (hunchentoot:return-code*) status)
  (setf (hunchentoot:content-type*) "application/json")
  (jonathan:to-json plist))

(test get-token
  (setf *captured-request* nil)
  (with-test-server
      (client
       :handler (lambda ()
                  (setf *captured-request*
                        (list :method (hunchentoot:request-method*)
                              :path (hunchentoot:script-name*)
                              :content-type (hunchentoot:header-in* "Content-Type")
                              :body (read-json-body)))
                  (respond-json (list :|access_token| "tok" :|expires_in| 3600 :|token_type| "bearer"))))
    (let ((token (jrm-code-client:get-token client "alice" "secret")))
      (is (eq (getf *captured-request* :method) :post))
      (is (string= (getf *captured-request* :path) "/api/v1/auth/token"))
      (is (string= (getf *captured-request* :content-type) "application/json"))
      (is (string= (getf (getf *captured-request* :body) :|username|) "alice"))
      (is (string= (getf (getf *captured-request* :body) :|api_key|) "secret"))
      (is (string= (jrm-code-client:token-response-access-token token) "tok"))
      (is (= (jrm-code-client:token-response-expires-in token) 3600)))))

(test create-paste-requires-token
  (let ((client (jrm-code-client:make-client :base-url "http://127.0.0.1:1")))
    (signals error (jrm-code-client:create-paste client "hello"))))

(test create-paste-sends-bearer-token
  (setf *captured-request* nil)
  (with-test-server
      (client
       :handler (lambda ()
                  (setf *captured-request*
                        (list :authorization (hunchentoot:header-in* "Authorization")))
                  (respond-json (list :|status| "ok" :|id| "abc123") :status 201)))
    (setf (jrm-code-client:client-token client) "tok")
    (let ((response (jrm-code-client:create-paste client "(print 1)")))
      (is (string= (getf *captured-request* :authorization) "Bearer tok"))
      (is (string= (jrm-code-client:create-paste-response-id response) "abc123")))))

(test get-paste-no-auth-required
  (setf *captured-request* nil)
  (with-test-server
      (client
       :handler (lambda ()
                  (setf *captured-request* (list :id (hunchentoot:parameter "id")))
                  (respond-json (list :|id| "abc123" :|content| "hi"))))
    (let ((paste (jrm-code-client:get-paste client "abc123")))
      (is (string= (getf *captured-request* :id) "abc123"))
      (is (string= (jrm-code-client:paste-content paste) "hi")))))

(test api-error-on-non-2xx
  (with-test-server
      (client
       :handler (lambda ()
                  (setf (hunchentoot:return-code*) 404)
                  "paste not found"))
    (handler-case
        (progn (jrm-code-client:get-paste client "missing")
               (fail "expected API-ERROR to be signalled"))
      (jrm-code-client:api-error (e)
        (is (= (jrm-code-client:api-error-status-code e) 404))))))

(test chef-sends-gemini-header-and-plain-text
  (setf *captured-request* nil)
  (with-test-server
      (client
       :handler (lambda ()
                  (setf *captured-request*
                        (list :gemini-key (hunchentoot:header-in* "x-goog-api-key")
                              :content-type (hunchentoot:header-in* "Content-Type")
                              :body (hunchentoot:raw-post-data :force-text t)))
                  (setf (hunchentoot:content-type*) "text/plain")
                  "This code is an abomination."))
    (setf (jrm-code-client:client-token client) "tok")
    (let ((roast (jrm-code-client:chef client "(print 1)" "gemini-key")))
      (is (string= (getf *captured-request* :gemini-key) "gemini-key"))
      (is (string= (getf *captured-request* :content-type) "text/plain"))
      (is (string= (getf *captured-request* :body) "(print 1)"))
      (is (string= roast "This code is an abomination.")))))

(test ping
  (with-test-server
      (client
       :handler (lambda ()
                  (respond-json (list :|status| "ok" :|user| "alice" :|tier| "paid"))))
    (setf (jrm-code-client:client-token client) "tok")
    (let ((response (jrm-code-client:ping client)))
      (is (string= (jrm-code-client:ping-response-user response) "alice")))))

(test list-pastes
  (with-test-server
      (client
       :handler (lambda ()
                  (setf (hunchentoot:return-code*) 200)
                  (setf (hunchentoot:content-type*) "application/json")
                  (jonathan:to-json
                   (list (list :|id| "a" :|created_at| "2024-01-01T00:00:00Z"
                               :|expires_at| :null :|content_preview| "hi")))))
    (setf (jrm-code-client:client-token client) "tok")
    (let ((pastes (jrm-code-client:list-pastes client)))
      (is (= (length pastes) 1))
      (is (string= (jrm-code-client:paste-summary-id (first pastes)) "a")))))

(test echo
  (setf *captured-request* nil)
  (with-test-server
      (client
       :handler (lambda ()
                  (setf *captured-request* (read-json-body))
                  (respond-json (list :|status| "ok" :|echo| *captured-request*))))
    (setf (jrm-code-client:client-token client) "tok")
    (let ((response (jrm-code-client:echo client (list :|hello| "world"))))
      (is (string= (getf *captured-request* :|hello|) "world"))
      (is (string= (jrm-code-client:echo-response-status response) "ok")))))
