;; -*- mode: scheme; coding: utf-8 -*-
;; Copyright (c) 2020 Julian Herrera
;; SPDX-License-Identifier: MIT


(import (chezscheme)
        (srfi :64 testing)
        (only (srfi :13 strings) string-contains)
        (srfi :26 cut))

(define libfswatch (load-shared-object "libfswatch.so"))

(define-syntax define-function
  (syntax-rules ()
    ((_ ret name fpname args)
     (define name
       (foreign-procedure (symbol->string 'fpname) args ret)))))

(define assq-ref (lambda (a k)
                   (let ([x (assq k a)])
                     (and x (cdr x)))))
    
(define-ftype FSW_STATUS int)
(define-ftype FSW_HANDLE void*)
(define-ftype FLAG_ARRAY void*)
(define-ftype fsw_cevent (struct
                          [path (* char)]
                          [evt_time long]
                          [flags (* int)]
                          [flags_num unsigned-int]))

(define-ftype fsw_cevent_array (array 0 fsw_cevent))

(define system_default_monitor_type 0)

(define-function FSW_STATUS init-library fsw_init_library())
(define-function FSW_HANDLE init-session fsw_init_session (int))
(define-function FSW_STATUS set-recursive fsw_set_recursive (FSW_HANDLE int))
(define-function FSW_STATUS add-path fsw_add_path (FSW_HANDLE string))
(define-function FSW_STATUS set-callback fsw_set_callback (FSW_HANDLE void* void*))
(define-function FSW_STATUS start-monitor fsw_start_monitor (FSW_HANDLE))

(define FSW_CREATE_FLAG 2)
(define FSW_UPDATE_FLAG 4)
   
(define custom-test-runner
  (lambda ()
    (define test-on-test-end
      (lambda (runner)
        (let* ([results (test-result-alist runner)]
               [result? (cut assq <> results)]
               [result (cut assq-ref results <>)]
               [result-kind (result 'result-kind)])
          (format #t "~a~a[m - ~a~%"
                  (case result-kind
                    ((pass) "[0;32m")
                    ((fail) "[0;31m")
                    ((skip) "")
                    ((error) ""))
                  (string-upcase (symbol->string (result 'result-kind)))
                  (result 'test-name))
          (if (equal? 'fail (result 'result-kind))
              (begin
                (when (result? 'expected-value)
                  (format #t "expected value: ~a~%" (result 'expected-value)))
                (when (result? 'expected-error)
                  (format #t "expected error: ~a~%" (result 'expected-error)))
                (when (result? 'actual-value)
                  (format #t "value: ~a~%" (result 'actual-value)))))
          (newline))))
    (let ([runner (test-runner-null)])
      (test-runner-on-test-end! runner test-on-test-end)
      runner)))

(define callback
  (lambda(p)
    (let ([code (foreign-callable __collect_safe p (FSW_HANDLE int) FSW_STATUS)])
      (lock-object code)
      (foreign-callable-entry-point code))))

(define scheme-file?
  (lambda (path)
    (let ([ext (path-extension path)])
      (member ext '("sls" "sps" "ss")))))    

(define find-test
  (lambda (path)
    (let ([is-test? (string-contains path ".test.ss")])
      (if is-test? (and (file-exists? path) path)
          (let* ([test-filename (path-last (string-append (path-root path)
                                                          ".test.ss"))]
                 [test-filepath (string-append "./tests/" test-filename)])
            (and (file-exists? test-filepath) test-filepath))))))

(define ESC #\033)
(define CSI (list->string (list ESC #\[ )))
(define CLEAR (string-append CSI "2J"))
     
(define run-test
  (lambda (test-file)
    (test-runner-factory
     (lambda () (custom-test-runner)))
    (guard (x [(error? x) (begin (display CLEAR)
                                 (display "Syntax error - file couldn't be parsed")
                                 (newline))]) (begin
                                 (display CLEAR)
                                 (load test-file)))
    (test-runner-reset (test-runner-current))))
  
(define handle-event
  (lambda (path)
    (if (scheme-file? path)
        (let ([corresponding-test (find-test path)])
          (if corresponding-test
              (begin
                (run-test corresponding-test)))))))
           
(define on-update
  (callback
   (lambda (events-pointer event-num)
     (let ([events (make-ftype-pointer fsw_cevent events-pointer)])
       (let process-event ([i 0])
         (when (< i event-num)
           (let* ([event-time (ftype-ref fsw_cevent (evt_time) events i)]
                  [path (let buildname ([chars '()]
                                        [offset 0])
                          (let ([char (ftype-ref fsw_cevent (path offset) events i)])
                            (if (eq? char #\nul)
                                (list->string (reverse! chars))
                                (buildname (cons char chars) (+ 1 offset)))))]
                  [flags-num (ftype-ref fsw_cevent (flags_num) events i)]
                  [flags-list (let build-flags-list ([fl '()]
                                                     [j 0])
                                (if (< j flags-num)
                                    (build-flags-list
                                     (cons (ftype-ref fsw_cevent (flags j) events i)
                                           fl)
                                     (+ 1 j))
                                    fl))])
             (if (or (memq FSW_UPDATE_FLAG flags-list)
                     (memq FSW_CREATE_FLAG flags-list))
                 (handle-event path))
             (process-event (+ 1 i))))))
     0))) 

(define watch
  (lambda ()
    (init-library)
    (let ([handle (init-session system_default_monitor_type)])
      (set-recursive handle 1)
      (add-path handle ".")
      (set-callback handle on-update (foreign-alloc (foreign-sizeof 'void*)))
      (display CLEAR)
      (newline)
      (start-monitor handle))))
