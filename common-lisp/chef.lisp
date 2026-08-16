;;;; chef.lisp -- POST /api/v1/chef

(in-package #:jrm-code-client)

(defun chef (client lisp-code gemini-api-key)
  "Submit LISP-CODE (64 lines or fewer) to \"The Chef\" for a roast, via
POST /api/v1/chef. Requires CLIENT-TOKEN to be set (paid tier) and
GEMINI-API-KEY, the caller's own Google Gemini API key, sent as the
x-goog-api-key header. Returns the roast as a plain string."
  (%request client :post "/api/v1/chef"
            :body lisp-code
            :content-type "text/plain"
            :authorize t
            :extra-headers (list (cons "x-goog-api-key" gemini-api-key))))
