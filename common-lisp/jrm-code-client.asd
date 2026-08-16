;;;; jrm-code-client.asd -- ASDF system definitions for the Common Lisp
;;;; bindings to the JRM Code Project API (https://jrm-code-project.com).

(asdf:defsystem "jrm-code-client"
  :description "Common Lisp client bindings for the JRM Code Project API."
  :author "jrm-code-project"
  :license "MIT"
  :version "0.1.0"
  :depends-on ("drakma" "jonathan" "flexi-streams")
  :serial t
  :in-order-to ((asdf:test-op (asdf:test-op "jrm-code-client/tests")))
  :components ((:file "package")
               (:file "client")
               (:file "auth")
               (:file "pastes")
               (:file "chef")
               (:file "diagnostics")))

(asdf:defsystem "jrm-code-client/tests"
  :description "Test suite for jrm-code-client."
  :depends-on ("jrm-code-client" "hunchentoot" "fiveam")
  :serial t
  :components ((:file "tests/test-server")
               (:file "tests/client-tests"))
  :perform (asdf:test-op (op c)
             (uiop:symbol-call :fiveam :run! (uiop:find-symbol* :jrm-code-client-suite
                                                                  :jrm-code-client/tests))))
