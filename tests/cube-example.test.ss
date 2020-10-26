#!/usr/bin/env scheme-script
;; -*- mode: scheme; coding: utf-8 -*- !#
;; Copyright (c) 2020 Julian Herrera
;; SPDX-License-Identifier: MIT


(import (chezscheme) (srfi :64 testing))
(include "./tests/cube-example.ss")

(test-begin "Testing cube function")
(test-assert "returns a number" (number? (my-cube 2)))
(test-eq "cube of 2 is 8" 8 (my-cube 2))
(test-end)
