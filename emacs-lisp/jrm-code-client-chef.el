;;; jrm-code-client-chef.el --- POST /api/v1/chef -*- lexical-binding: t; -*-

;; Author: jrm-code-project
;; Package-Requires: ((emacs "27.1") (jrm-code-client "0.1.0"))

;;; Commentary:

;; "The Chef" endpoint bindings for jrm-code-client.

;;; Code:

(require 'jrm-code-client)

(defun jrm-code-client-chef (client lisp-code gemini-api-key)
  "Submit LISP-CODE (64 lines or fewer) to \"The Chef\" for a roast, via
POST /api/v1/chef.  Requires CLIENT's token to be set (paid tier) and
GEMINI-API-KEY, the caller's own Google Gemini API key, sent as the
x-goog-api-key header.  Returns the roast as a plain string."
  (jrm-code-client--request client "POST" "/api/v1/chef"
                             :body (encode-coding-string lisp-code 'utf-8)
                             :content-type "text/plain"
                             :authorize t
                             :extra-headers (list (cons "x-goog-api-key" gemini-api-key))))

(provide 'jrm-code-client-chef)

;;; jrm-code-client-chef.el ends here
