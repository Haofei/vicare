;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;Implementation  of  FXREVERSE-BIT-FIELD from:
;;;
;;;  Original patch by G�ran Weinholt, posted on the Ikarus bug tracker.
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under  the terms of  the GNU General  Public License version  3 as
;;;published by the Free Software Foundation.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.


#!r6rs
(library (ikarus numerics div-and-mod)
  (export
    div			div0
    mod			mod0
    div-and-mod		div0-and-mod0)
  (import (except (vicare)
		  div			div0
		  mod			mod0
		  div-and-mod		div0-and-mod0)
    (vicare system $fx)
    (only (vicare system $flonums)
	  $fl=
	  $flexact)
    #| end of IMPORT |# )


(module (div-and-mod*)

  (define (div-and-mod* n m who)
    (cond ((fixnum? m)
	   (cond (($fx= m 0)
		  (assertion-violation who "division by 0"))
		 ((or (fixnum? n)
		      (bignum? n))
		  (int-div-and-mod n m))
		 ((flonum? n)
		  (if (flnan? n)
		      (values n n)
		    (fldiv-and-mod n (fixnum->flonum m))))
		 ((ratnum? n)
		  (rat-div-and-mod n m))
		 (else
		  (%error-not-a-number who n))))

	  ((bignum? m)
	   (cond ((or (fixnum? n)
		      (bignum? n))
		  (int-div-and-mod n m))
		 ((flonum? n)
		  (if (flnan? n)
		      (values n n)
		    (let ((v ($flexact n)))
		      (receive (a b)
			  (div-and-mod* v m who)
			(values (inexact a) (inexact b))))))
		 ((ratnum? n)
		  (rat-div-and-mod n m))
		 (else
		  (%error-not-a-number who n))))

	  ((ratnum? m)
	   (cond ((or (fixnum? n)
		      (bignum? n)
		      (ratnum? n))
		  (rat-div-and-mod n m))
		 ((flonum? n)
		  (if (flnan? n)
		      (values n n)
		    (let ((v ($flexact n)))
		      (receive (a b)
			  (div-and-mod* v m who)
			(values (inexact a) (inexact b))))))
		 (else
		  (%error-not-a-number who n))))

	  ((flonum? m)
	   (cond (($fl= m 0.0)
		  (assertion-violation who "division by 0.0"))
		 ((flnan? m)
		  (values m m))
		 ((flonum? n)
		  (if (flnan? n)
		      (values n n)
		    (fldiv-and-mod n m)))
		 ((fixnum? n)
		  (fldiv-and-mod (fixnum->flonum n) m))
		 ((or (bignum? n)
		      (ratnum? n))
		  (let ((v ($flexact m)))
		    (let-values (((a b) (div-and-mod* n v who)))
		      (values (inexact a) (inexact b)))))
		 (else
		  (%error-not-a-number who n))))

	  (else
	   (%error-not-a-number who m))))

  (define (int-div-and-mod n m)
    (let* ((d0 (quotient n m))
	   (m0 (- n (* d0 m))))
      (cond ((>= m0 0)
	     (values d0       m0))
	    ((>= m 0)
	     (values (- d0 1) (+ m0 m)))
	    (else
	     (values (+ d0 1) (- m0 m))))))

  (define (rat-div-and-mod n m)
    (let ((x (/ n m)))
      (if  (or (fixnum? x)
	       (bignum? x))
	  (values x 0)
	(let* ((n0 (numerator   x))
	       (d0 (denominator x))
	       (q  (quotient n0 d0))
	       (r  (- n (* q m))))
	  (cond ((>= r 0)
		 (values q       r))
		((> m 0)
		 (values (- q 1) (+ r m)))
		(else
		 (values (+ q 1) (- r m))))))))

  (define (%error-not-a-number who n)
    (assertion-violation who "expected number as argument" n))

  #| end of module: div-and-mod* |# )


(define (div-and-mod n m)
  (div-and-mod* n m 'div-and-mod))

(define* (div n m)
  (import (vicare system $fx))
  (if (and (fixnum? n)
	   (fixnum? m))
      (case m
	((0)
	 (assertion-violation __who__ "division by 0"))
	((-1)
	 ;;Notice  that we  *cannot* use  $fx-  here because  when N  is
	 ;;(least-fixnum)   it  would   result   in   an  overflow:   (-
	 ;;(least-fixnum)) is *not* a fixnum.
	 (- n))
	(else
	 ;;After  the exclusion  of  M=0  and M=-1:  the  result of  the
	 ;;quotient between fixnums is a fixnum.
	 (let ((d0 ($fxquotient n m)))
	   (cond (($fx>= n ($fx* d0 m))
		  d0)
		 (($fx>= m 0)
		  ($fx- d0 1))
		 (else
		  ($fx+ d0 1))))))
    (receive (a b)
	(div-and-mod* n m __who__)
      a)))

(define* (mod n m)
  (import (vicare system $fx))
  (if (and (fixnum? n)
	   (fixnum? m))
      (case m
	((0)
	 (assertion-violation __who__ "division by 0"))
	((-1)
	 0)
	(else
	 ;;After  the exclusion  of  M=0  and M=-1:  the  result of  the
	 ;;quotient between fixnums is a fixnum.
	 (let* ((d0 ($fxquotient n m))
		;;N can  be (least-fixnum), but the  second operand here
		;;cannot be -1.
		(m0 ($fx- n ($fx* d0 m))))
	   (cond (($fx>= m0 0)
		  m0)
		 (($fx>= m 0)
		  ($fx+ m0 m))
		 (else
		  ($fx- m0 m))))))
    (receive (a b)
	(div-and-mod* n m __who__)
      b)))


(define* (div0-and-mod0 x y)
  (receive (d m)
      (div-and-mod* x y __who__)
    (if (> y 0)
	(if (< m (/ y 2))
	    (values d m)
	  (values (+ d 1) (- m y)))
      (if (>= m (/ y -2))
	  (values (- d 1) (+ m y))
	(values d m)))))

(define* (div0 x y)
  (receive (d m)
      (div-and-mod* x y __who__)
    (if (> y 0)
	(if (< m (/ y 2))
	    d
	  (+ d 1))
      (if (>= m (/ y -2))
	  (- d 1)
	d))))

(define* (mod0 x y)
  (receive (d m)
      (div-and-mod* x y __who__)
    (if (> y 0)
	(if (< m (/ y 2))
	    m
	  (- m y))
      (if (>= m (/ y -2))
	  (+ m y)
	m))))


;;;; done

;; #!vicare
;; (define end-of-file-dummy
;;   (foreign-call "ikrt_print_emergency" #ve(ascii "ikarus.numerics.div-and-mod")))

#| end of library |# )

;;; end of file
