#!/usr/bin/env scheme-script
;; -*- mode: scheme; coding: utf-8 -*- !#
;; Copyright (c) 2020 Julian Herrera
;; SPDX-License-Identifier: MIT


(import (chezscheme) (srfi :64 testing))
(include "./job.ss")

(test-begin "Scheme Filetype Detection Tests")
(let ([sls-path "./this-is-a-test-path.sls"]
      [ss-path "./this-is-a-test-path.ss"]
      [sps-path "./this-is-a-test-path.sps"])
  (test-assert ".sls files are recognized as scheme files" (scheme-file? sls-path))
  (test-assert ".sps files are recognized as scheme files" (scheme-file? sls-path))
  (test-assert ".ss files are recognized as scheme files" (scheme-file? sls-path)))
(test-end)

(test-begin "Scheme Test Finding Tests")
(let ([src-path "./job.ss"]
      [test-path "./tests/job.test.ss"])
  (test-assert "A matching test is found" (find-test src-path))
  (test-assert "A test file is identified as its own test" (find-test test-path)))
(test-end)
  
;; (exit (if (zero? (test-runner-fail-count (test-runner-get))) 0 1))
