;;;; package.lisp -- package definition for jrm-code-client.

(defpackage #:jrm-code-client
  (:use #:cl)
  (:nicknames #:jrmc)
  (:export
   ;; client
   #:client
   #:make-client
   #:*default-base-url*
   #:client-base-url
   #:client-token
   #:api-error
   #:api-error-status-code
   #:api-error-reason-phrase
   #:api-error-body
   ;; auth
   #:get-token
   #:token-response
   #:token-response-access-token
   #:token-response-expires-in
   #:token-response-token-type
   ;; pastes
   #:create-paste
   #:get-paste
   #:delete-paste
   #:list-pastes
   #:paste
   #:paste-id
   #:paste-content
   #:paste-summary
   #:paste-summary-id
   #:paste-summary-created-at
   #:paste-summary-expires-at
   #:paste-summary-content-preview
   #:create-paste-response
   #:create-paste-response-id
   #:create-paste-response-status
   #:status-response
   #:status-response-status
   ;; chef
   #:chef
   ;; diagnostics
   #:ping
   #:echo
   #:ping-response
   #:ping-response-status
   #:ping-response-user
   #:ping-response-tier
   #:echo-response
   #:echo-response-status
   #:echo-response-echo))
