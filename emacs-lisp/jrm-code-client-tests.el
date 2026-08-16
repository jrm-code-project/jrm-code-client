;;; jrm-code-client-tests.el --- ERT test suite for jrm-code-client -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with:
;;   emacs -batch -L . \
;;     -l jrm-code-client.el -l jrm-code-client-auth.el \
;;     -l jrm-code-client-pastes.el -l jrm-code-client-chef.el \
;;     -l jrm-code-client-diagnostics.el -l jrm-code-client-tests.el \
;;     -f ert-run-tests-batch-and-exit
;;
;; Tests never touch the network: `jrm-code-client--http-request' is the
;; only function that calls into `url.el', so every test replaces it with
;; `cl-letf' to assert on the outgoing request and return a canned
;; response.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'json)
(require 'jrm-code-client)
(require 'jrm-code-client-auth)
(require 'jrm-code-client-pastes)
(require 'jrm-code-client-chef)
(require 'jrm-code-client-diagnostics)

(defun jrm-code-client-tests--json-response (status-code alist)
  (list :status-code status-code
        :body (json-encode alist)))

(ert-deftest jrm-code-client-test-get-token ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (method url extra-headers data)
               (should (equal method "POST"))
               (should (equal url "https://example.test/api/v1/auth/token"))
               (should (equal (cdr (assoc "Content-Type" extra-headers)) "application/json"))
               (let* ((json-object-type 'alist)
                      (json-key-type 'string)
                      (body (json-read-from-string (decode-coding-string data 'utf-8))))
                 (should (equal (cdr (assoc "username" body)) "alice"))
                 (should (equal (cdr (assoc "api_key" body)) "secret")))
               (jrm-code-client-tests--json-response
                200 (list (cons "access_token" "tok")
                          (cons "expires_in" 3600)
                          (cons "token_type" "bearer"))))))
    (let* ((client (jrm-code-client-create :base-url "https://example.test"))
           (token (jrm-code-client-get-token client "alice" "secret")))
      (should (equal (jrm-code-client-token-response-access-token token) "tok"))
      (should (equal (jrm-code-client-token-response-expires-in token) 3600)))))

(ert-deftest jrm-code-client-test-create-paste-requires-token ()
  (let ((client (jrm-code-client-create :base-url "https://example.test")))
    (should-error (jrm-code-client-create-paste client "hello"))))

(ert-deftest jrm-code-client-test-create-paste-sends-bearer-token ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (_method _url extra-headers _data)
               (should (equal (cdr (assoc "Authorization" extra-headers)) "Bearer tok"))
               (jrm-code-client-tests--json-response
                201 (list (cons "status" "ok") (cons "id" "abc123"))))))
    (let ((client (jrm-code-client-create :base-url "https://example.test" :token "tok")))
      (let ((response (jrm-code-client-create-paste client "(print 1)")))
        (should (equal (jrm-code-client-create-paste-response-id response) "abc123"))))))

(ert-deftest jrm-code-client-test-get-paste-no-auth-required ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (method url _extra-headers _data)
               (should (equal method "GET"))
               (should (equal url "https://example.test/api/v1/pastes?id=abc123"))
               (jrm-code-client-tests--json-response
                200 (list (cons "id" "abc123") (cons "content" "hi"))))))
    (let* ((client (jrm-code-client-create :base-url "https://example.test"))
           (paste (jrm-code-client-get-paste client "abc123")))
      (should (equal (jrm-code-client-paste-content paste) "hi")))))

(ert-deftest jrm-code-client-test-api-error-on-non-2xx ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (_method _url _extra-headers _data)
               (list :status-code 404 :body "paste not found"))))
    (let ((client (jrm-code-client-create :base-url "https://example.test")))
      (let ((err (should-error (jrm-code-client-get-paste client "missing")
                                :type 'jrm-code-client-api-error)))
        (should (equal (jrm-code-client-api-error-status-code err) 404))))))

(ert-deftest jrm-code-client-test-chef-sends-gemini-header-and-plain-text ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (_method _url extra-headers data)
               (should (equal (cdr (assoc "x-goog-api-key" extra-headers)) "gemini-key"))
               (should (equal (cdr (assoc "Content-Type" extra-headers)) "text/plain"))
               (should (equal (decode-coding-string data 'utf-8) "(print 1)"))
               (list :status-code 200 :body "This code is an abomination."))))
    (let ((client (jrm-code-client-create :base-url "https://example.test" :token "tok")))
      (let ((roast (jrm-code-client-chef client "(print 1)" "gemini-key")))
        (should (equal roast "This code is an abomination."))))))

(ert-deftest jrm-code-client-test-ping ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (_method _url _extra-headers _data)
               (jrm-code-client-tests--json-response
                200 (list (cons "status" "ok") (cons "user" "alice") (cons "tier" "paid"))))))
    (let ((client (jrm-code-client-create :base-url "https://example.test" :token "tok")))
      (let ((response (jrm-code-client-ping client)))
        (should (equal (jrm-code-client-ping-response-user response) "alice"))))))

(ert-deftest jrm-code-client-test-list-pastes ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (_method _url _extra-headers _data)
               (list :status-code 200
                     :body (json-encode
                            (list (list (cons "id" "a")
                                        (cons "created_at" "2024-01-01T00:00:00Z")
                                        (cons "expires_at" nil)
                                        (cons "content_preview" "hi"))))))))
    (let ((client (jrm-code-client-create :base-url "https://example.test" :token "tok")))
      (let ((pastes (jrm-code-client-list-pastes client)))
        (should (= (length pastes) 1))
        (should (equal (jrm-code-client-paste-summary-id (car pastes)) "a"))))))

(ert-deftest jrm-code-client-test-echo ()
  (cl-letf (((symbol-function 'jrm-code-client--http-request)
             (lambda (_method _url _extra-headers data)
               (let* ((json-object-type 'alist)
                      (json-key-type 'string)
                      (body (json-read-from-string (decode-coding-string data 'utf-8))))
                 (jrm-code-client-tests--json-response
                  200 (list (cons "status" "ok") (cons "echo" body)))))))
    (let ((client (jrm-code-client-create :base-url "https://example.test" :token "tok")))
      (let ((response (jrm-code-client-echo client (list (cons "hello" "world")))))
        (should (equal (jrm-code-client-echo-response-status response) "ok"))))))

(provide 'jrm-code-client-tests)

;;; jrm-code-client-tests.el ends here

