;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: arguments validation syntaxes
;;;Date: Mon Oct  1, 2012
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!r6rs
(library (vicare arguments validation)
  (export
    define-argument-validation
    with-arguments-validation
    with-dangerous-arguments-validation
    arguments-validation-forms

    ;; fixnums
    vicare.argument-validation-for-fixnum
    vicare.argument-validation-for-positive-fixnum
    vicare.argument-validation-for-negative-fixnum
    vicare.argument-validation-for-non-positive-fixnum
    vicare.argument-validation-for-non-negative-fixnum
    vicare.argument-validation-for-fixnum-in-inclusive-range
    vicare.argument-validation-for-fixnum-in-exclusive-range
    vicare.argument-validation-for-even-fixnum
    vicare.argument-validation-for-odd-fixnum

    ;; exact integers
    vicare.argument-validation-for-exact-integer
    vicare.argument-validation-for-positive-exact-integer
    vicare.argument-validation-for-negative-exact-integer
    vicare.argument-validation-for-non-positive-exact-integer
    vicare.argument-validation-for-non-negative-exact-integer
    vicare.argument-validation-for-exact-integer-in-inclusive-range
    vicare.argument-validation-for-exact-integer-in-exclusive-range
    vicare.argument-validation-for-even-exact-integer
    vicare.argument-validation-for-odd-exact-integer

    )
  (import (ikarus)
    (for (prefix (vicare installation-configuration)
		 config.)
	 expand)
    (prefix (vicare words)
	    words.)
    (prefix (vicare unsafe-operations)
	    $))


;;; helpers

(define-syntax define-inline
  (syntax-rules ()
    ((_ (?name ?arg ... . ?rest) ?form0 ?form ...)
     (define-syntax ?name
       (syntax-rules ()
	 ((_ ?arg ... . ?rest)
	  (begin ?form0 ?form ...)))))))


(define-syntax define-argument-validation
  ;;Define a set of macros to  validate arguments, to be used along with
  ;;WITH-ARGUMENTS-VALIDATION.  Transform:
  ;;
  ;;  (define-argument-validation (bytevector who bv)
  ;;    (bytevector? bv)
  ;;    (assertion-violation who "expected a bytevector as argument" bv))
  ;;
  ;;into:
  ;;
  ;;  (define-inline (vicare.argument-validation-for-bytevector who bv . body)
  ;;    (if (vicare.argument-validation-predicate-for-bytevector bv)
  ;;        (begin . body)
  ;;      (vicare.argument-validation-error-for-bytevector who bv)))
  ;;
  ;;  (define-inline (vicare.argument-validation-predicate-for-bytevector bv)
  ;;    (bytevector? bv))
  ;;
  ;;  (define-inline (vicare.argument-validation-error-for-bytevector who bv))
  ;;    (assertion-violation who "expected a bytevector as argument" bv))
  ;;
  ;;If we need to export a validator  from a library: we can export just
  ;;the    identifier   VICARE.ARGUMENT-VALIDATION-FOR-?NAME,    without
  ;;prefixing it.
  ;;
  (lambda (stx)
    (define who 'define-argument-validation)
    (define (main stx)
      (syntax-case stx ()
	((_ (?name ?who ?arg ...) ?predicate ?error-handler)
	 (and (identifier? #'?name)
	      (identifier? #'?who))
	 (let ((ctx  #'?name)
	       (name (symbol->string (syntax->datum #'?name))))
	   (with-syntax
	       ((VALIDATE	(%name ctx name "argument-validation-for-"))
		(PREDICATE	(%name ctx name "argument-validation-predicate-for-"))
		(ERROR	(%name ctx name "argument-validation-error-for-")))
	     #'(begin
		 (define-inline (PREDICATE ?arg ...) ?predicate)
		 (define-inline (ERROR ?who ?arg ...) ?error-handler)
		 (define-inline (VALIDATE ?who ?arg ... . body)
		   (if (PREDICATE ?arg ...)
		       (begin . body)
		     (ERROR ?who ?arg ...)))))))
	(_
	 (%synner "invalid input form" #f))))

    (define (%name ctx name prefix-string)
      (let ((str (string-append "vicare." prefix-string name)))
	(datum->syntax ctx (string->symbol str))))

    (define (%synner msg subform)
      (syntax-violation who msg (syntax->datum stx) (syntax->datum subform)))

    (main stx)))


(define-syntax arguments-validation-forms
  (if config.arguments-validation
      (syntax-rules ()
	((_)
	 (values))
	((_ ?body0 . ?body)
	 (begin ?body0 . ?body)))
    (syntax-rules ()
      ((_)
       (values))
      ((_ ?body0 . ?body)
       (values)))))


(define-syntax with-arguments-validation
  ;;Perform the validation only if enabled at configure time.
  ;;
  (syntax-rules ()
    ((_ . ?args)
     (%with-arguments-validation #f . ?args))))

(define-syntax with-dangerous-arguments-validation
  ;;Dangerous validations are always performed.
  ;;
  (syntax-rules ()
    ((_ . ?args)
     (%with-arguments-validation #t . ?args))))

(define-syntax %with-arguments-validation
  ;;Transform:
  ;;
  ;;  (with-arguments-validation (who)
  ;;       ((fixnum  X)
  ;;        (integer Y))
  ;;    (do-this)
  ;;    (do-that))
  ;;
  ;;into:
  ;;
  ;;  (vicare.argument-validation-for-fixnum who X
  ;;   (vicare.argument-validation-for-integer who Y
  ;;    (do-this)
  ;;    (do-that)))
  ;;
  ;;As a special case:
  ;;
  ;;  (with-arguments-validation (who)
  ;;       ((#t  X))
  ;;    (do-this)
  ;;    (do-that))
  ;;
  ;;expands to:
  ;;
  ;;  (begin
  ;;    (do-this)
  ;;    (do-that))
  ;;
  (lambda (stx)
    (define (main stx)
      (syntax-case stx ()
	((_ ?always-include (?who) ((?validator ?arg ...) ...) . ?body)
	 (and (identifier? #'?who)
	      (for-all identifier? (syntax->list #'(?validator ...))))
	 ;;Whether we  include the arguments  checking or not,  we build
	 ;;the output form validating the input form.
	 (let* ((include?	(syntax->datum #'?always-include))
		(body		#'(begin . ?body))
		(output-form	(%build-output-form #'?who
						    #'(?validator ...)
						    #'((?arg ...) ...)
						    body)))
	   (if (or include? config.arguments-validation)
	       output-form body)))
	(_
	 (%synner "invalid input form" #f))))

    (define (%build-output-form who validators list-of-args body)
      (syntax-case validators ()
	(()
	 #`(let () #,body))
	;;Accept #t as special validator meaning "always valid"; this is
	;;sometimes useful when composing syntax output forms.
	((#t . ?other-validators)
	 (%build-output-form who #'?other-validators list-of-args body))
	((?validator . ?other-validators)
	 (identifier? #'?validator)
	 (let ((str (symbol->string (syntax->datum #'?validator))))
	   (with-syntax
	       ((VALIDATE (%name #'?validator str "argument-validation-for-"))
		(((ARG ...) . OTHER-ARGS) list-of-args))
	     #`(VALIDATE #,who ARG ...
			 #,(%build-output-form who #'?other-validators #'OTHER-ARGS body)))))
	((?validator . ?others)
	 (%synner "invalid argument-validator selector" #'?validator))))

    (define (%name ctx name prefix-string)
      (let ((str (string-append "vicare." prefix-string name)))
	(datum->syntax ctx (string->symbol str))))

    (define syntax->list
      (case-lambda
       ((stx)
	(syntax->list stx '()))
       ((stx tail)
	(syntax-case stx ()
	  ((?car . ?cdr)
	   (cons #'?car (syntax->list #'?cdr tail)))
	  (()
	   tail)))))

    (define (%synner msg subform)
      (syntax-violation 'with-arguments-validation
	msg (syntax->datum stx) (syntax->datum subform)))

    (main stx)))


;;;; fixnums validation

(define-argument-validation (fixnum who obj)
  (fixnum? obj)
  (%invalid-fixnum who obj))

(define (%invalid-fixnum who obj)
  (assertion-violation who "expected fixnum as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (positive-fixnum who obj)
  (and (fixnum? obj)
       ($fx< 0 obj))
  (%invalid-positive-fixnum who obj))

(define (%invalid-positive-fixnum who obj)
  (assertion-violation who "expected positive fixnum as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (negative-fixnum who obj)
  (and (fixnum? obj)
       ($fx> 0 obj))
  (%invalid-negative-fixnum who obj))

(define (%invalid-negative-fixnum who obj)
  (assertion-violation who "expected negative fixnum as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (non-positive-fixnum who obj)
  (and (fixnum? obj)
       ($fx>= 0 obj))
  (%invalid-non-positive-fixnum who obj))

(define (%invalid-non-positive-fixnum who obj)
  (assertion-violation who "expected non-positive fixnum as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (non-negative-fixnum who obj)
  (and (fixnum? obj)
       ($fx<= 0 obj))
  (%invalid-non-negative-fixnum who obj))

(define (%invalid-non-negative-fixnum who obj)
  (assertion-violation who "expected non-negative fixnum as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (fixnum-in-inclusive-range ?who ?obj ?min ?max)
  (and (fixnum? ?obj)
       ($fx>= ?obj ?min)
       ($fx<= ?obj ?max))
  (%invalid-fixnum-in-inclusive-range ?who ?obj ?min ?max))

(define (%invalid-fixnum-in-inclusive-range who obj min max)
  (assertion-violation who
    (string-append "expected fixnum in inclusive range ["
		   (number->string min) ", " (number->string max)
		   "] as argument")
    obj))

;;; --------------------------------------------------------------------

(define-argument-validation (fixnum-in-exclusive-range ?who ?obj ?min ?max)
  (and (fixnum? ?obj)
       ($fx> ?obj ?min)
       ($fx< ?obj ?max))
  (%invalid-fixnum-in-exclusive-range ?who ?obj ?min ?max))

(define (%invalid-fixnum-in-exclusive-range who obj min max)
  (assertion-violation who
    (string-append "expected fixnum in exclusive range ("
		   (number->string min) ", " (number->string max)
		   ") as argument")
    obj))

;;; --------------------------------------------------------------------

(define-argument-validation (even-fixnum who obj)
  (and (fixnum? obj)
       (fxeven? obj))
  (%invalid-even-fixnum who obj))

(define (%invalid-even-fixnum who obj)
  (assertion-violation who "expected even fixnum as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (odd-fixnum who obj)
  (and (fixnum? obj)
       (fxodd? obj))
  (%invalid-odd-fixnum who obj))

(define (%invalid-odd-fixnum who obj)
  (assertion-violation who "expected odd fixnum as argument" obj))


;;;; exact integers validation

(define-inline (exact-integer? obj)
  (and (integer? obj)
       (exact?   obj)))

(define-argument-validation (exact-integer who obj)
  (exact-integer? obj)
  (%invalid-exact-integer who obj))

(define (%invalid-exact-integer who obj)
  (assertion-violation who "expected exact integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (positive-exact-integer who obj)
  (and (exact-integer? obj)
       (< 0 obj))
  (%invalid-positive-exact-integer who obj))

(define (%invalid-positive-exact-integer who obj)
  (assertion-violation who "expected positive exact integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (negative-exact-integer who obj)
  (and (exact-integer? obj)
       (> 0 obj))
  (%invalid-negative-exact-integer who obj))

(define (%invalid-negative-exact-integer who obj)
  (assertion-violation who "expected negative exact integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (non-positive-exact-integer who obj)
  (and (exact-integer? obj)
       (>= 0 obj))
  (%invalid-non-positive-exact-integer who obj))

(define (%invalid-non-positive-exact-integer who obj)
  (assertion-violation who "expected non-positive exact integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (non-negative-exact-integer who obj)
  (and (exact-integer? obj)
       (<= 0 obj))
  (%invalid-non-negative-exact-integer who obj))

(define (%invalid-non-negative-exact-integer who obj)
  (assertion-violation who "expected non-negative exact integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (exact-integer-in-inclusive-range ?who ?obj ?min ?max)
  (and (exact-integer? ?obj)
       (>= ?obj ?min)
       (<= ?obj ?max))
  (%invalid-exact-integer-in-inclusive-range ?who ?obj ?min ?max))

(define (%invalid-exact-integer-in-inclusive-range who obj min max)
  (assertion-violation who
    (string-append "expected exact integer in inclusive range ["
		   (number->string min) ", " (number->string max)
		   "] as argument")
    obj))

;;; --------------------------------------------------------------------

(define-argument-validation (exact-integer-in-exclusive-range ?who ?obj ?min ?max)
  (and (exact-integer? ?obj)
       (> ?obj ?min)
       (< ?obj ?max))
  (%invalid-exact-integer-in-exclusive-range ?who ?obj ?min ?max))

(define (%invalid-exact-integer-in-exclusive-range who obj min max)
  (assertion-violation who
    (string-append "expected exact integer in exclusive range ("
		   (number->string min) ", " (number->string max)
		   ") as argument")
    obj))

;;; --------------------------------------------------------------------

(define-argument-validation (even-exact-integer who obj)
  (and (exact-integer? obj)
       (even? obj))
  (%invalid-even-exact-integer who obj))

(define (%invalid-even-exact-integer who obj)
  (assertion-violation who "expected even exact integer as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (odd-exact-integer who obj)
  (and (exact-integer? obj)
       (odd? obj))
  (%invalid-odd-exact-integer who obj))

(define (%invalid-odd-exact-integer who obj)
  (assertion-violation who "expected odd exact integer as argument" obj))


;;;; done

)

;;; end of file
