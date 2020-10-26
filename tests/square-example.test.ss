#!/usr/bin/env scheme-script
;; -*- mode: scheme; coding: utf-8 -*- !#
;; Copyright (c) 2020 Julian Herrera
;; SPDX-License-Identifier: MIT


(import (chezscheme) (srfi :64 testing))
(include "./tests/square-example.ss")

(test-begin "Testing squaring function")
(test-assert "returns a number" (number? (my-square 2)))
(test-eq "square of 4 is 16" 16 (my-square 4))
(test-end)
