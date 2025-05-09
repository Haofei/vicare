;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for bitvectors on top of vectors of fixnums
;;;Date: Mon Aug  8, 2011
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2011, 2013, 2014, 2016 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software: you can  redistribute it and/or modify it under the
;;;terms  of  the GNU  General  Public  License as  published  by  the Free  Software
;;;Foundation,  either version  3  of the  License,  or (at  your  option) any  later
;;;version.
;;;
;;;This program is  distributed in the hope  that it will be useful,  but WITHOUT ANY
;;;WARRANTY; without  even the implied warranty  of MERCHANTABILITY or FITNESS  FOR A
;;;PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;;;
;;;You should have received a copy of  the GNU General Public License along with this
;;;program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!vicare
(program (test-vicare-containers-bitvectors)
  (options typed-language)
  (import (vicare)
    (vicare containers bitvectors)
    (vicare checks)
    (prefix (vicare platform words)
	    words::))

(check-set-mode! 'report-failed)
(check-display "*** testing Vicare libraries: bitvector containers\n")


;;;; helpers

(define (%bits->list {O <bitvector>})
  (let loop ((result '())
	     (i 0))
    (if (= i (.length O))
	result
      (loop (cons (.bit-ref O i) result) (+ 1 i)))))


(parametrise ((check-test-name	'constructor))

  (check
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.vector O))
    => '#(#f #f #f #f  #f #f #f #f))
;;;        0  1  2  3   4  5  6  7

  (check
      (let (({O <bitvector>} (new <bitvector> 17)))
	(.vector O))
    => '#( ;;
	  #f #f #f #f  #f #f #f #f
	  #f #f #f #f  #f #f #f #f
	  #f))

  (check
      (let (({O <bitvector>} (new <bitvector> (+ 16 16 8))))
	(.vector O))
    => '#( ;;
	  #f #f #f #f  #f #f #f #f    #f #f #f #f  #f #f #f #f
	  #f #f #f #f  #f #f #f #f    #f #f #f #f  #f #f #f #f
	  #f #f #f #f  #f #f #f #f))

  (check
      (let (({O <bitvector>} (new <bitvector> 1234)))
	(.vector O))
    => (make-vector 1234 #f))

  (check
      (let (({O <bitvector>} (new <bitvector> 1024)))
	(.bit-set! O 100 #t)
	(.bit-set! O 200 #t)
	(.bit-set! O 500 #t)
	(.bit-set! O 1023 #t)
	(.vector O))
    => (receive-and-return (V)
	   (make-vector 1024 #f)
	 (vector-set! V 100 #t)
	 (vector-set! V 200 #t)
	 (vector-set! V 500 #t)
	 (vector-set! V 1023 #t)
	 V))

  (void))


(parametrise ((check-test-name	'printer))

  (check
      (let ((O (new <bitvector> 8)))
	(with-output-to-string
	  (lambda ()
	    (display O))))
    => "#[<bitvector> length=8]")

  (void))


(parametrise ((check-test-name	'comparison))

  (define compar
    (comparison-procedure <bitvector>))

  (define-syntax doit
    (syntax-rules (=>)
      ((_ ?A ?B => ?result)
       (check
	   (compar (list->bitvector (quote ?A))
		   (list->bitvector (quote ?B)))
	 => ?result))
      ))

;;; --------------------------------------------------------------------

  (doit (#t #t) (#t #t)	=> 0)
  (doit (#f #t) (#t #t)	=> -1)
  (doit (#t #t) (#f #t)	=> +1)

  (void))


(parametrise ((check-test-name	'equality))

  (check
      (let* ((L			'(#t #f #f #t))
	     ({a <bitvector>}	(list->bitvector L))
	     ({b <bitvector>}	(list->bitvector L)))
	(equal? a b))
    => #t)

  (check
      (let (({a <bitvector>} (list->bitvector '(#t #f #f #t)))
	    ({b <bitvector>} (list->bitvector '(#t #f #t #t))))
	(equal? a b))
    => #f)

  (check-for-true
   (equal? (non-negative-exact-integer->bitvector (least-positive-bignum))
	   (non-negative-exact-integer->bitvector (least-positive-bignum))))

  (check-for-true
   (let ((N (bitwise-arithmetic-shift-left (greatest-fixnum) 22)))
     (equal? (non-negative-exact-integer->bitvector N)
	     (non-negative-exact-integer->bitvector N))))

  (check-for-false
   (let ((N (bitwise-arithmetic-shift-left (greatest-fixnum) 22))
	 (M (bitwise-arithmetic-shift-left (greatest-fixnum) 23)))
     (equal? (non-negative-exact-integer->bitvector N)
	     (non-negative-exact-integer->bitvector M))))

  #t)


(parametrise ((check-test-name	'length))

  (define-syntax doit
    (syntax-rules ()
      ((_ ?len)
       (check
	   (.length (new <bitvector> ?len))
	 => ?len))
      ))

;;; --------------------------------------------------------------------

  (doit	1)
  (doit	2)
  (doit	3)
  (doit	4)
  (doit	5)
  (doit	6)
  (doit	7)
  (doit	8)
  (doit	9)

  (doit	10)
  (doit	11)
  (doit	12)
  (doit	13)
  (doit	14)
  (doit	15)
  (doit	16)
  (doit	17)
  (doit	18)
  (doit	19)

  (doit	30)
  (doit	31)
  (doit	32)
  (doit	33)
  (doit	34)
  (doit	35)
  (doit	36)
  (doit	37)
  (doit	38)
  (doit	39)

  (doit	60)
  (doit	61)
  (doit	62)
  (doit	63)
  (doit	64)
  (doit	65)
  (doit	66)
  (doit	67)
  (doit	68)
  (doit	69)

  (doit	110)
  (doit	111)
  (doit	112)
  (doit	113)
  (doit	114)
  (doit	115)
  (doit	116)
  (doit	117)
  (doit	118)
  (doit	119)

  (void))


(parametrise ((check-test-name	'setter-getter))

;;; 8 bits

  (check
      (let (({O <bitvector>} (new <bitvector> 8)))
	(%bits->list O))
    => '(#f #f #f #f  #f #f #f #f))
;;;       0  1  2  3   4  5  6  7

  (check
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.bit-set! O 0 #t)
	(.bit-set! O 3 #t)
	(.bit-set! O 5 #t)
	(%bits->list O))
    => '(#f #f #t #f  #t #f #f #t))
;;;       0  1  2  3   4  5  6  7

;;; --------------------------------------------------------------------
;;; 19 bits

  (check
      (let (({O <bitvector>} (new <bitvector> 19)))
	(%bits->list O))
    => '( ;;
	 #f #f #f
;;;      18 17 16
	 #f #f #f #f  #f #f #f #f
;;;      15 14 13 12  11 10  9  8
	 #f #f #f #f  #f #f #f #f))
;;;       7  6  5  4   3  2  1  0

  (check
      (let (({O <bitvector>} (new <bitvector> 19)))
	(.bit-set! O  0 #t) (.bit-set! O  3 #t)
	(.bit-set! O  5 #t) (.bit-set! O  9 #t)
	(.bit-set! O 13 #t) (.bit-set! O 17 #t)
	(%bits->list O))
    => '( ;;
	 #f #t #f
;;;      18 17 16
	 #f #f #t #f  #f #f #t #f
;;;      15 14 13 12  11 10  9  8
	 #f #f #t #f  #t #f #f #t))
;;;       7  6  5  4   3  2  1  0

  #t)


(parametrise ((check-test-name	'compound-conversion))

;;; 8 bits

  (check
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.bit-set! O 0 #t)
	(.bit-set! O 3 #t)
	(.bit-set! O 5 #t)
	(.list O))
    => '(#t #f #f #t  #f #t #f #f))
;;;       0  1  2  3   4  5  6  7

  (check
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.bit-set! O 0 #t)
	(.bit-set! O 3 #t)
	(.bit-set! O 5 #t)
	(.vector O))
    => '#(#t #f #f #t  #f #t #f #f))
;;;        0  1  2  3   4  5  6  7

;;; --------------------------------------------------------------------
;;; 19 bits

  (check
      (let (({O <bitvector>} (new <bitvector> 19)))
	(.bit-set! O  0 #t) (.bit-set! O  3 #t)
	(.bit-set! O  5 #t) (.bit-set! O  9 #t)
	(.bit-set! O 13 #t) (.bit-set! O 17 #t)
	(.list O))
    => '( ;;
	 #t #f #f #t  #f #t #f #f
;;;       0  1  2  3   4  5  6  7
	 #f #t #f #f  #f #t #f #f
;;;       8  9 10 11  12 13 14 15
	 #f #t #f))
;;;      16 17 18

  (check
      (let (({O <bitvector>} (new <bitvector> 19)))
	(.bit-set! O  0 #t) (.bit-set! O  3 #t)
	(.bit-set! O  5 #t) (.bit-set! O  9 #t)
	(.bit-set! O 13 #t) (.bit-set! O 17 #t)
	(.vector O))
    => '#( ;;
	  #t #f #f #t  #f #t #f #f
;;;        0  1  2  3   4  5  6  7
	  #f #t #f #f  #f #t #f #f
;;;        8  9 10 11  12 13 14 15
	  #f #t #f))
;;;       16 17 18

;;; --------------------------------------------------------------------

  (let ((ell '(#t #f #f #t  #f #t #f #f)))
    (check
	(let (({O <bitvector>} (list->bitvector ell)))
	  (.list O))
      => ell))

  (let ((V '#(#t #f #f #t  #f #t #f #f)))
    (check
	(let (({O <bitvector>} (vector->bitvector V)))
	  (.vector O))
      => V))

  #t)


(parametrise ((check-test-name	'number-conversion))

  (module (exact-integer->fixnums fixnums->exact-integer)
    (import (only (vicare platform words)
		  case-word-size))

    (define (exact-integer->fixnums {N <non-negative-exact-integer>})
      (if (zero? N)
	  '()
	(let ((fx (bitwise-and N BITS-IN-FIXNUM-MASK))
	      (N  (bitwise-arithmetic-shift-right N NUMBER-OF-PAYLOAD-BITS-IN-FIXNUM)))
	  (cons fx (exact-integer->fixnums N)))))

    (define (fixnums->exact-integer {fxs (list-of <non-negative-fixnum>)})
      (let loop ((N 0) (fxs (reverse fxs)))
	(if (null? fxs)
	    N
	  (let* ((fx (car fxs))
		 (N  (bitwise-arithmetic-shift-left N NUMBER-OF-PAYLOAD-BITS-IN-FIXNUM))
		 (N  (bitwise-ior N fx)))
	    (loop N (cdr fxs))))))

    (define-constant NUMBER-OF-PAYLOAD-BITS-IN-FIXNUM
      (case-word-size
       ((32)	29)
       ((64)	60)))

    (define-constant BITS-IN-FIXNUM-MASK
      (greatest-fixnum))

    #| end of module: EXACT-INTEGER->FIXNUMS |# )

;;; --------------------------------------------------------------------

  (check (exact-integer->fixnums 0)				=> '())
  (check (exact-integer->fixnums 1)				=> '(1))
  (check (exact-integer->fixnums 234)				=> '(234))
  (check (exact-integer->fixnums (greatest-fixnum))		=> (list (greatest-fixnum)))
  (check (exact-integer->fixnums (least-positive-bignum))	=> (list 0 1))
  (check (exact-integer->fixnums (+ 2 (least-positive-bignum)))	=> (list 2 1))
  (check (exact-integer->fixnums (* 2 (least-positive-bignum)))	=> (list 0 2))

  (check
      (exact-integer->fixnums (bitwise-arithmetic-shift-left (least-positive-bignum) 1234))
    => (words::case-word-size
	((32)
	 '(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 65536))
	((64)
	 '(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 17179869184))))

;;; --------------------------------------------------------------------

  (check (fixnums->exact-integer '())				=> 0)
  (check (fixnums->exact-integer '(1))				=> 1)
  (check (fixnums->exact-integer '(234))			=> 234)
  (check (fixnums->exact-integer (list (greatest-fixnum)))	=> (greatest-fixnum))
  (check (fixnums->exact-integer (list 0 1))			=> (least-positive-bignum))
  (check (fixnums->exact-integer (list 2 1))			=> (+ 2 (least-positive-bignum)))
  (check (fixnums->exact-integer '(0 2))			=> (* 2 (least-positive-bignum)))

  (check
      (words::case-word-size
       ((32)
	(fixnums->exact-integer '(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 65536)))
       ((64)
	(fixnums->exact-integer '(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 17179869184))))
    => (bitwise-arithmetic-shift-left (least-positive-bignum) 1234))

;;; --------------------------------------------------------------------

  (check
      (let ((O (non-negative-exact-integer->bitvector 1)))
	(.list O))
    => '(#t))

  (check
      (let ((O (non-negative-exact-integer->bitvector 4)))
	(.list O))
    => '(#f #f #t))

;;; --------------------------------------------------------------------

  (check
      (let ((O (non-negative-exact-integer->bitvector 1)))
	(.non-negative-exact-integer O))
    => 1)

  (check
      (let ((O (non-negative-exact-integer->bitvector 4)))
	(.non-negative-exact-integer O))
    => 4)

  (check
      (let ((O (non-negative-exact-integer->bitvector 234)))
	(.non-negative-exact-integer O))
    => 234)

  (check
      (let ((O (non-negative-exact-integer->bitvector (greatest-fixnum))))
	(.non-negative-exact-integer O))
    => (greatest-fixnum))

  (check
      (let ((O (non-negative-exact-integer->bitvector (least-positive-bignum))))
	(.non-negative-exact-integer O))
    => (least-positive-bignum))

  (check
      (let ((O (non-negative-exact-integer->bitvector (bitwise-arithmetic-shift-left (least-positive-bignum) 1234))))
	(.non-negative-exact-integer O))
    => (bitwise-arithmetic-shift-left (least-positive-bignum) 1234))

  #t)


(parametrise ((check-test-name	'bit-ops))

  (check
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.toggle! O 0)
	(.toggle! O 3)
	(.toggle! O 5)
	(.list O))
    => '(#t #f #f #t  #f #t #f #f))
;;;       0  1  2  3   4  5  6  7

;;; --------------------------------------------------------------------

  (check	;not
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.bit-set! O 0 #t)
	(.bit-set! O 3 #t)
	(.bit-set! O 5 #t)
	(let (({r <bitvector>} (.not O)))
	  (list (.list O) (.list r))))
    => '((#t #f #f #t  #f #t #f #f)
	 (#f #t #t #f  #t #f #t #t)))
;;;        0  1  2  3   4  5  6  7

  (check	;not!
      (let (({O <bitvector>} (new <bitvector> 8)))
	(.bit-set! O 0 #t)
	(.bit-set! O 3 #t)
	(.bit-set! O 5 #t)
	(let ((L (.list O)))
	  (.not! O)
	  (list L (.list O))))
    => '((#t #f #f #t  #f #t #f #f)
	 (#f #t #t #f  #t #f #t #t)))
;;;        0  1  2  3   4  5  6  7

;;; --------------------------------------------------------------------

  (check	;and
      (let* (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	     (b			(list->bitvector '(#t #t #f #f)))
	     ({r <bitvector>}	(.and a b)))
	(.list r))
    => '(#t #f #f #f))

  (check	;and!
      (let (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	    (b			(list->bitvector '(#t #t #f #f))))
	(.and! a b)
	(.list a))
    => '(#t #f #f #f))

;;; --------------------------------------------------------------------

  (check	;ior
      (let* (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	     (b			(list->bitvector '(#t #t #f #f)))
	     ({r <bitvector>}	(.ior a b)))
	(.list r))
    => '(#t #t #f #t))

  (check	;ior!
      (let (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	    (b			(list->bitvector '(#t #t #f #f))))
	(.ior! a b)
	(.list a))
    => '(#t #t #f #t))

;;; --------------------------------------------------------------------

  (check	;xor
      (let* (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	     (b			(list->bitvector '(#t #t #f #f)))
	     ({r <bitvector>}	(.xor a b)))
	(.list r))
    => '(#f #t #f #t))

  (check	;xor!
      (let* (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	     (b			(list->bitvector '(#t #t #f #f))))
	(.xor! a b)
	(.list a))
    => '(#f #t #f #t))

;;; --------------------------------------------------------------------
;;; bit count

  (check
      (let (({O <bitvector>}	(list->bitvector '(#t #f #f #t))))
	(.bit-count O))
    => 2)

  (check
      (let (({O <bitvector>}	(list->bitvector '(#t #f #f #t  #f #t #t #f))))
	(.bit-count O))
    => 4)

  (check
      (let (({O <bitvector>}	(list->bitvector '( ;;
				      #t #f #f #t  #f #t #t #f
				      #t #f #f #t  #f #t #t #f
				      #t #f #f #t  #f #t #t #f))))
	(.bit-count O))
    => 12)

;;; --------------------------------------------------------------------
;;; first bit set

  (check
      (let (({O <bitvector>}	(list->bitvector '(#t #f #f #t))))
	(.first-bit-set O))
    => 0)

  (check
      (let (({O <bitvector>}	(list->bitvector '(#f #t #f #t))))
	(.first-bit-set O))
    => 1)

  (check
      (let (({O <bitvector>}	(list->bitvector '(#f #f #t #t))))
	(.first-bit-set O))
    => 2)

  (check
      (let (({O <bitvector>}	(list->bitvector '(#f #f #f #t))))
	(.first-bit-set O))
    => 3)

  (check
      (let (({O <bitvector>}	(list->bitvector '(#f #f #f #f  #f #f #f #t))))
	(.first-bit-set O))
    => 7)

  (check
      (let (({O <bitvector>}	(list->bitvector '(#f #f #f #f  #f #f #f #f))))
	(.first-bit-set O))
    => -1)

  (check
      (let (({O <bitvector>}	(list->bitvector '( ;;
				      #f #f #f #f  #f #f #f #f
				      #f #f #f #f  #f #f #f #f
				      #f #f #f #f  #f #f #t #f))))
	(.first-bit-set O))
    => 22)

  #t)


(parametrise ((check-test-name	'other-ops))

  (check	;clone
      (let* (({a <bitvector>}	(list->bitvector '(#t #f #f #t)))
	     ({r <bitvector>}	(.clone a)))
	(.list r))
    => '(#t #f #f #t))

  (check	;set-all!
      (let (({O <bitvector>} (list->bitvector '(#t #f #f #t))))
	(.set-all! O)
	(.list O))
    => '(#t #t #t #t))

  (check	;clear-all!
      (let (({O <bitvector>} (list->bitvector '(#t #f #f #t))))
	(.clear-all! O)
	(.list O))
    => '(#f #f #f #f))

  #t)


;;;; done

(check-report)

#| end of program |# )

;;; end of file
