;;;; tests/test-server.lisp -- a minimal Hunchentoot server used as a test
;;;; double for the JRM Code Project API in the jrm-code-client test suite.

(defpackage #:jrm-code-client/tests
  (:use #:cl #:fiveam)
  (:export #:jrm-code-client-suite))

(in-package #:jrm-code-client/tests)

(defvar *test-handler* nil
  "A function of no arguments, called with HUNCHENTOOT:*REQUEST* bound, that
produces the response for the current request. Rebind this per-test.")

(defclass test-acceptor (hunchentoot:easy-acceptor) ()
  (:documentation "Acceptor that dispatches every request to *TEST-HANDLER*."))

(defmethod hunchentoot:acceptor-dispatch-request ((acceptor test-acceptor) request)
  (declare (ignore request))
  (if *test-handler*
      (funcall *test-handler*)
      (progn (setf (hunchentoot:return-code*) 404) "not found")))

(defun start-test-server ()
  "Start a TEST-ACCEPTOR on an OS-assigned ephemeral port and return it."
  (let ((acceptor (make-instance 'test-acceptor
                                  :port 0
                                  :address "127.0.0.1"
                                  :access-log-destination nil
                                  :message-log-destination nil)))
    (hunchentoot:start acceptor)
    acceptor))

(defun stop-test-server (acceptor)
  (hunchentoot:stop acceptor))

(defun test-server-base-url (acceptor)
  (format nil "http://127.0.0.1:~D" (hunchentoot:acceptor-port acceptor)))

(defmacro with-test-server ((client-var &key handler) &body body)
  "Start a test server for the duration of BODY, bind CLIENT-VAR to a
JRM-CODE-CLIENT:CLIENT pointed at it, and set *TEST-HANDLER* to HANDLER (a
zero-argument function or lambda) while BODY runs."
  (let ((acceptor (gensym "ACCEPTOR")))
    `(let ((,acceptor (start-test-server)))
       (unwind-protect
            (progn
              (setf *test-handler* ,handler)
              (let ((,client-var (jrm-code-client:make-client
                                   :base-url (test-server-base-url ,acceptor))))
                ,@body))
         (setf *test-handler* nil)
         (stop-test-server ,acceptor)))))
