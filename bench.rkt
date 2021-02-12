#lang racket/base

(require profile/analyzer
         (prefix-in text: profile/render-text)
         profile/sampler
         racket/async-channel
         web-server/dispatch
         web-server/http
         web-server/http/response
         web-server/web-server)

(define-values (app _)
  (dispatch-rules
   [("plaintext")
    (lambda (_req)
      (response/output
       #:headers (list (make-header #"Content-length" #"13"))
       (lambda (out)
         (write-bytes #"Hello, World!" out))))]))

(define cust (make-custodian))
(define sampler (create-sampler cust 0 #:use-errortrace? #t))
(define (render)
  (sampler 'stop)
  (text:render (analyze-samples (sampler 'get-snapshots))))

(define ch (make-async-channel))
(define stop
  (parameterize ([current-custodian cust])
    (serve
     #:port 8081
     #:dispatch (lambda (conn req)
                  (output-response conn (app req)))
     #:confirmation-channel ch)))
(define maybe-exn (async-channel-get ch))
(when (exn:fail? maybe-exn)
  (raise maybe-exn))

(call-with-output-file "ready"
  #:exists 'truncate/replace
  (lambda (out)
    (displayln "ready" out)))

(with-handlers ([exn:break?
                 (lambda (_e)
                   (stop)
                   (render))])
  (sync never-evt))
