;;; -*- coding: utf-8-unix -*-
;;;
;;;Ikarus Scheme -- A compiler for R6RS Scheme.
;;;Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
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
;;;


#!vicare
(library (ikarus bytevectors)
  (export
    make-bytevector				bytevector-length
    bytevector-empty?
    bytevector-copy!				bytevector-fill!
    bytevector-copy				bytevector-append
    native-endianness
    bytevector-concatenate			bytevector-reverse-and-concatenate

    bytevector=?				bytevector!=?
    bytevector-u8<?				bytevector-u8>?
    bytevector-u8<=?				bytevector-u8>=?
    bytevector-u8-min				bytevector-u8-max
    bytevector-s8<?				bytevector-s8>?
    bytevector-s8<=?				bytevector-s8>=?
    bytevector-s8-min				bytevector-s8-max

    ;; validation predicates
    list-of-bytevectors?
    bytevector-length?				bytevector-index?
    bytevector-word-size?			bytevector-word-count?
    bytevector-index-for-word?
    bytevector-index-for-word8?
    bytevector-index-for-word16?
    bytevector-index-for-word32?
    bytevector-index-for-word64?
    bytevector-index-for-single-flonum?
    bytevector-index-for-double-flonum?
    bytevector-start-index-and-count-for-word?
    bytevector-start-index-and-count-for-word8?
    bytevector-start-index-and-count-for-word16?
    bytevector-start-index-and-count-for-word32?
    bytevector-start-index-and-count-for-word64?

    bytevector-s8-ref				bytevector-s8-set!
    bytevector-u8-ref				bytevector-u8-set!

    bytevector-u16-native-ref			bytevector-u16-native-set!
    bytevector-s16-native-ref			bytevector-s16-native-set!
    bytevector-u32-native-ref			bytevector-u32-native-set!
    bytevector-s32-native-ref			bytevector-s32-native-set!
    bytevector-u64-native-ref			bytevector-u64-native-set!
    bytevector-s64-native-ref			bytevector-s64-native-set!

    bytevector-u16-ref				bytevector-u16-set!
    bytevector-s16-ref				bytevector-s16-set!
    bytevector-u32-ref				bytevector-u32-set!
    bytevector-s32-ref				bytevector-s32-set!
    bytevector-u64-ref				bytevector-u64-set!
    bytevector-s64-ref				bytevector-s64-set!

    bytevector-uint-ref				bytevector-uint-set!
    bytevector-sint-ref				bytevector-sint-set!

    bytevector-ieee-double-native-ref		bytevector-ieee-double-native-set!
    bytevector-ieee-single-native-ref		bytevector-ieee-single-native-set!
    bytevector-ieee-double-ref			bytevector-ieee-double-set!
    bytevector-ieee-single-ref			bytevector-ieee-single-set!

    uint-list->bytevector			bytevector->uint-list
    sint-list->bytevector			bytevector->sint-list

    u8-list->bytevector				bytevector->u8-list
    s8-list->bytevector				bytevector->s8-list

    u16l-list->bytevector			bytevector->u16l-list
    u16b-list->bytevector			bytevector->u16b-list
    u16n-list->bytevector			bytevector->u16n-list
    s16l-list->bytevector			bytevector->s16l-list
    s16b-list->bytevector			bytevector->s16b-list
    s16n-list->bytevector			bytevector->s16n-list

    u32l-list->bytevector			bytevector->u32l-list
    u32b-list->bytevector			bytevector->u32b-list
    u32n-list->bytevector			bytevector->u32n-list
    s32l-list->bytevector			bytevector->s32l-list
    s32b-list->bytevector			bytevector->s32b-list
    s32n-list->bytevector			bytevector->s32n-list

    u64l-list->bytevector			bytevector->u64l-list
    u64b-list->bytevector			bytevector->u64b-list
    u64n-list->bytevector			bytevector->u64n-list
    s64l-list->bytevector			bytevector->s64l-list
    s64b-list->bytevector			bytevector->s64b-list
    s64n-list->bytevector			bytevector->s64n-list

    f4l-list->bytevector			bytevector->f4l-list
    f4b-list->bytevector			bytevector->f4b-list
    f4n-list->bytevector			bytevector->f4n-list
    f8l-list->bytevector			bytevector->f8l-list
    f8b-list->bytevector			bytevector->f8b-list
    f8n-list->bytevector			bytevector->f8n-list

    c4l-list->bytevector			bytevector->c4l-list
    c4b-list->bytevector			bytevector->c4b-list
    c4n-list->bytevector			bytevector->c4n-list
    c8l-list->bytevector			bytevector->c8l-list
    c8b-list->bytevector			bytevector->c8b-list
    c8n-list->bytevector			bytevector->c8n-list

    subbytevector-u8				subbytevector-u8/count
    subbytevector-s8				subbytevector-s8/count

    ;; unsafe bindings, to be exported by (vicare system $bytevectors)
    $bytevector=				$bytevector!=
    $bytevector-u8<				$bytevector-u8>
    $bytevector-u8<=				$bytevector-u8>=
    $bytevector-u8-min				$bytevector-u8-max
    $bytevector-s8<				$bytevector-s8>
    $bytevector-s8<=				$bytevector-s8>=
    $bytevector-s8-min				$bytevector-s8-max

    $bytevector-u8-set!				$bytevector-s8-set!

    $bytevector-u16l-ref			$bytevector-u16l-set!
    $bytevector-u16b-ref			$bytevector-u16b-set!
    $bytevector-u16n-ref			$bytevector-u16n-set!
    $bytevector-s16l-ref			$bytevector-s16l-set!
    $bytevector-s16b-ref			$bytevector-s16b-set!
    $bytevector-s16n-ref			$bytevector-s16n-set!
    $bytevector-u16-ref				$bytevector-u16-set!
    $bytevector-s16-ref				$bytevector-s16-set!

    $bytevector-u32b-ref			$bytevector-u32b-set!
    $bytevector-u32l-ref			$bytevector-u32l-set!
    $bytevector-s32b-ref			$bytevector-s32b-set!
    $bytevector-s32l-ref			$bytevector-s32l-set!
    $bytevector-u32n-ref			$bytevector-u32n-set!
    $bytevector-s32n-ref			$bytevector-s32n-set!
    $bytevector-u32-ref				$bytevector-u32-set!
    $bytevector-s32-ref				$bytevector-s32-set!

    $bytevector-u64b-ref			$bytevector-u64b-set!
    $bytevector-u64l-ref			$bytevector-u64l-set!
    $bytevector-s64b-ref			$bytevector-s64b-set!
    $bytevector-s64l-ref			$bytevector-s64l-set!
    $bytevector-u64n-ref			$bytevector-u64n-set!
    $bytevector-s64n-ref			$bytevector-s64n-set!
    $bytevector-u64-ref				$bytevector-u64-set!
    $bytevector-s64-ref				$bytevector-s64-set!

    $bytevector-ieee-double-big-ref		$bytevector-ieee-double-big-set!
    $bytevector-ieee-double-little-ref		$bytevector-ieee-double-little-set!
    $bytevector-ieee-double-ref			$bytevector-ieee-double-set!

    $bytevector-ieee-single-big-ref		$bytevector-ieee-single-big-set!
    $bytevector-ieee-single-little-ref		$bytevector-ieee-single-little-set!
    $bytevector-ieee-single-ref			$bytevector-ieee-single-set!

    $subbytevector-u8				$subbytevector-u8/count
    $subbytevector-s8				$subbytevector-s8/count

    $bytevector-empty?				$bytevector-total-length
    $bytevector-copy				$bytevector-copy!
    $bytevector-concatenate			$bytevector-reverse-and-concatenate
    $bytevector-copy!/count
    $bytevector-self-copy-forwards!/count	$bytevector-self-copy-backwards!/count
    $bytevector-fill!)
  (import (except (vicare)
		  make-bytevector			bytevector-length
		  bytevector-empty?
		  bytevector-copy!			bytevector-fill!
		  bytevector-copy			bytevector-append
		  native-endianness
		  bytevector-concatenate		bytevector-reverse-and-concatenate

		  bytevector=?				bytevector!=?
		  bytevector-u8<?			bytevector-u8>?
		  bytevector-u8<=?			bytevector-u8>=?
		  bytevector-u8-min			bytevector-u8-max
		  bytevector-s8<?			bytevector-s8>?
		  bytevector-s8<=?			bytevector-s8>=?
		  bytevector-s8-min			bytevector-s8-max

		  list-of-bytevectors?
		  bytevector-length?			bytevector-index?
		  bytevector-word-size?			bytevector-word-count?
		  bytevector-index-for-word?
		  bytevector-index-for-word8?
		  bytevector-index-for-word16?
		  bytevector-index-for-word32?
		  bytevector-index-for-word64?
		  bytevector-index-for-single-flonum?
		  bytevector-index-for-double-flonum?
		  bytevector-start-index-and-count-for-word?
		  bytevector-start-index-and-count-for-word8?
		  bytevector-start-index-and-count-for-word16?
		  bytevector-start-index-and-count-for-word32?
		  bytevector-start-index-and-count-for-word64?

		  bytevector-s8-ref			bytevector-s8-set!
		  bytevector-u8-ref			bytevector-u8-set!

		  bytevector-u16-native-ref		bytevector-u16-native-set!
		  bytevector-s16-native-ref		bytevector-s16-native-set!
		  bytevector-u32-native-ref		bytevector-u32-native-set!
		  bytevector-s32-native-ref		bytevector-s32-native-set!
		  bytevector-u64-native-ref		bytevector-u64-native-set!
		  bytevector-s64-native-ref		bytevector-s64-native-set!

		  bytevector-u16-ref			bytevector-u16-set!
		  bytevector-s16-ref			bytevector-s16-set!
		  bytevector-u32-ref			bytevector-u32-set!
		  bytevector-s32-ref			bytevector-s32-set!
		  bytevector-u64-ref			bytevector-u64-set!
		  bytevector-s64-ref			bytevector-s64-set!

		  bytevector-uint-ref			bytevector-uint-set!
		  bytevector-sint-ref			bytevector-sint-set!

		  bytevector-ieee-double-native-ref	bytevector-ieee-double-native-set!
		  bytevector-ieee-single-native-ref	bytevector-ieee-single-native-set!
		  bytevector-ieee-double-ref		bytevector-ieee-double-set!
		  bytevector-ieee-single-ref		bytevector-ieee-single-set!

		  uint-list->bytevector			bytevector->uint-list
		  sint-list->bytevector			bytevector->sint-list

		  u8-list->bytevector			bytevector->u8-list
		  s8-list->bytevector			bytevector->s8-list

		  u16l-list->bytevector			bytevector->u16l-list
		  u16b-list->bytevector			bytevector->u16b-list
		  u16n-list->bytevector			bytevector->u16n-list
		  s16l-list->bytevector			bytevector->s16l-list
		  s16b-list->bytevector			bytevector->s16b-list
		  s16n-list->bytevector			bytevector->s16n-list

		  u32l-list->bytevector			bytevector->u32l-list
		  u32b-list->bytevector			bytevector->u32b-list
		  u32n-list->bytevector			bytevector->u32n-list
		  s32l-list->bytevector			bytevector->s32l-list
		  s32b-list->bytevector			bytevector->s32b-list
		  s32n-list->bytevector			bytevector->s32n-list

		  u64l-list->bytevector			bytevector->u64l-list
		  u64b-list->bytevector			bytevector->u64b-list
		  u64n-list->bytevector			bytevector->u64n-list
		  s64l-list->bytevector			bytevector->s64l-list
		  s64b-list->bytevector			bytevector->s64b-list
		  s64n-list->bytevector			bytevector->s64n-list

		  f4l-list->bytevector			bytevector->f4l-list
		  f4b-list->bytevector			bytevector->f4b-list
		  f4n-list->bytevector			bytevector->f4n-list
		  f8l-list->bytevector			bytevector->f8l-list
		  f8b-list->bytevector			bytevector->f8b-list
		  f8n-list->bytevector			bytevector->f8n-list

		  c4l-list->bytevector			bytevector->c4l-list
		  c4b-list->bytevector			bytevector->c4b-list
		  c4n-list->bytevector			bytevector->c4n-list
		  c8l-list->bytevector			bytevector->c8l-list
		  c8b-list->bytevector			bytevector->c8b-list
		  c8n-list->bytevector			bytevector->c8n-list

		  subbytevector-u8			subbytevector-u8/count
		  subbytevector-s8			subbytevector-s8/count)
    (vicare system $fx)
    (vicare system $pairs)
    (vicare system $flonums)
    (only (vicare system $bytevectors)
	  $make-bytevector
	  $bytevector-length
	  $bytevector-s8-ref
	  $bytevector-u8-ref
	  $bytevector-set!
	  $bytevector-ieee-double-native-ref
	  $bytevector-ieee-double-native-set!
	  $bytevector-ieee-double-nonnative-ref
	  $bytevector-ieee-double-nonnative-set!
	  $bytevector-ieee-single-native-ref
	  $bytevector-ieee-single-native-set!
	  $bytevector-ieee-single-nonnative-ref
	  $bytevector-ieee-single-nonnative-set!)
    (prefix (vicare platform words) words.)
    (only (ikarus conditions)
	  preconditions)
    (only (vicare language-extensions syntaxes)
	  define-list-of-type-predicate
	  define-min/max-comparison
	  define-equality/sorting-predicate
	  define-inequality-predicate))


;;;; helpers

(define (%implementation-violation who msg . irritants)
  (raise (condition
	  (make-assertion-violation)
	  (make-implementation-restriction-violation)
	  (make-who-condition who)
	  (make-message-condition msg)
	  (make-irritants-condition irritants))))

;;; --------------------------------------------------------------------

(define-syntax (%case-endianness stx)
  (module (platform-endianness)
    (include "ikarus.config.scm" #t))
  (syntax-case stx (big little)
    ((_ ((big) ?big-stuff) ((little) ?little-stuff))
     (case platform-endianness
       ((big)		#'?big-stuff)
       ((little)	#'?little-stuff)))
    ))

(define-syntax define-cased-accessor
  (syntax-rules ()
    ((_ ?who ?big-who ?little-who)
     (define (?who bv index)
       (%case-endianness
	((big)		(?big-who     bv index))
	((little)	(?little-who  bv index)))))
    ))

(define-syntax define-cased-mutator
  (syntax-rules ()
    ((_ ?who ?big-who ?little-who)
     (define (?who bv index value)
       (%case-endianness
	((big)		(?big-who    bv index value))
	((little)	(?little-who bv index value)))))
    ))

(define-syntax define-generic-cased-accessor
  (syntax-rules ()
    ((_ ?who ?big-who ?little-who ?native-who)
     (define (?who bv index endianness)
       (case endianness
	 ((big)		(?big-who    bv index))
	 ((little)	(?little-who bv index))
	 (else		(?native-who bv index)))))
    ))

(define-syntax define-generic-cased-mutator
  (syntax-rules ()
    ((_ ?who ?big-who ?little-who ?native-who)
     (define (?who bv index value endianness)
       (case endianness
	 ((big)		(?big-who    bv index value))
	 ((little)	(?little-who bv index value))
	 (else		(?native-who bv index value)))))
    ))

;;; --------------------------------------------------------------------

(define-syntax $fixnum-ior
  (syntax-rules ()
    ((_ ?op1)
     ?op1)
    ((_ ?op1 ?op2)
     ($fxlogor ?op1 ?op2))
    ((_ ?op1 ?op2 . ?ops)
     ($fxlogor ?op1 ($fixnum-ior ?op2 . ?ops)))))

;;; --------------------------------------------------------------------

(define (bytevector-byte-filler? obj)
  ;;Return  #t if  OBJ  is valid  as byte  filler  for new  bytevectors;
  ;;otherwise return #f.
  ;;
  (and (fixnum? obj)
       ($fx>= obj -128)
       ($fx<= obj 255)))

;;; --------------------------------------------------------------------

(define (bytevector-flonum-single-le-set! bv i x)
  (bytevector-ieee-single-set! bv i x (endianness little)))

(define (bytevector-flonum-single-be-set! bv i x)
  (bytevector-ieee-single-set! bv i x (endianness big)))

(define (bytevector-flonum-single-ne-set! bv i x)
  (bytevector-ieee-single-native-set! bv i x))

(define (bytevector-flonum-double-le-set! bv i x)
  (bytevector-ieee-double-set! bv i x (endianness little)))

(define (bytevector-flonum-double-be-set! bv i x)
  (bytevector-ieee-double-set! bv i x (endianness big)))

(define (bytevector-flonum-double-ne-set! bv i x)
  (bytevector-ieee-double-native-set! bv i x))

;;; --------------------------------------------------------------------

(define (bytevector-flonum-single-le-ref bv i)
  (bytevector-ieee-single-ref bv i (endianness little)))

(define (bytevector-flonum-single-be-ref bv i)
  (bytevector-ieee-single-ref bv i (endianness big)))

(define (bytevector-flonum-single-ne-ref bv i)
  (bytevector-ieee-single-native-ref bv i))

(define (bytevector-flonum-double-le-ref bv i)
  (bytevector-ieee-double-ref bv i (endianness little)))

(define (bytevector-flonum-double-be-ref bv i)
  (bytevector-ieee-double-ref bv i (endianness big)))

(define (bytevector-flonum-double-ne-ref bv i)
  (bytevector-ieee-double-native-ref bv i))

;;; --------------------------------------------------------------------

(define (bytevector-cflonum-single-le-set! bv i x)
  (bytevector-ieee-single-set! bv i          (real-part x) (endianness little))
  (bytevector-ieee-single-set! bv ($fx+ 4 i) (imag-part x) (endianness little)))

(define (bytevector-cflonum-single-be-set! bv i x)
  (bytevector-ieee-single-set! bv i          (real-part x) (endianness big))
  (bytevector-ieee-single-set! bv ($fx+ 4 i) (imag-part x) (endianness big)))

(define (bytevector-cflonum-single-ne-set! bv i x)
  (bytevector-ieee-single-native-set! bv i          (real-part x))
  (bytevector-ieee-single-native-set! bv ($fx+ 4 i) (imag-part x)))

(define (bytevector-cflonum-double-le-set! bv i x)
  (bytevector-ieee-double-set! bv i          (real-part x) (endianness little))
  (bytevector-ieee-double-set! bv ($fx+ 8 i) (imag-part x) (endianness little)))

(define (bytevector-cflonum-double-be-set! bv i x)
  (bytevector-ieee-double-set! bv i          (real-part x) (endianness big))
  (bytevector-ieee-double-set! bv ($fx+ 8 i) (imag-part x) (endianness big)))

(define (bytevector-cflonum-double-ne-set! bv i x)
  (bytevector-ieee-double-native-set! bv i          (real-part x))
  (bytevector-ieee-double-native-set! bv ($fx+ 8 i) (imag-part x)))

;;; --------------------------------------------------------------------

(define (bytevector-cflonum-single-le-ref bv i)
  (make-rectangular
    (bytevector-ieee-single-ref bv i          (endianness little))
    (bytevector-ieee-single-ref bv ($fx+ 4 i) (endianness little))))

(define (bytevector-cflonum-single-be-ref bv i)
  (make-rectangular
    (bytevector-ieee-single-ref bv i          (endianness big))
    (bytevector-ieee-single-ref bv ($fx+ 4 i) (endianness big))))

(define (bytevector-cflonum-single-ne-ref bv i)
  (make-rectangular
    (bytevector-ieee-single-native-ref bv i)
    (bytevector-ieee-single-native-ref bv ($fx+ 4 i))))

(define (bytevector-cflonum-double-le-ref bv i)
  (make-rectangular
    (bytevector-ieee-double-ref bv i          (endianness little))
    (bytevector-ieee-double-ref bv ($fx+ 8 i) (endianness little))))

(define (bytevector-cflonum-double-be-ref bv i)
  (make-rectangular
    (bytevector-ieee-double-ref bv i          (endianness big))
    (bytevector-ieee-double-ref bv ($fx+ 8 i) (endianness big))))

(define (bytevector-cflonum-double-ne-ref bv i)
  (make-rectangular
    (bytevector-ieee-double-native-ref bv i)
    (bytevector-ieee-double-native-ref bv ($fx+ 8 i))))


;;;; preconditions syntax and arguments validation

(define-syntax (assert-total-string-length stx)
  (syntax-case stx ()
    ((_ ?len)
     (identifier? #'?len)
     #'(unless (bytevector-length? ?len)
	 (procedure-arguments-consistency-violation __who__
	   "total resulting bytevector length out of range, expected non-negative fixnum"
	   ?len)))
    ))


;;;; endianness dispatching

(define-auxiliary-syntaxes big little)

(define-syntax (case-endianness stx)
  ;;We  want  this  syntax  to   raise  a  "&procedure-argument-violation"  when  the
  ;;endianness is wrong.
  ;;
  (syntax-case stx (big little)
    ((_ (?who ?endianness)
	((little)	. ?lit-body)
	((big)		. ?big-body))
     (and (identifier? #'?who)
	  (identifier? #'?endianness))
     #'(case-endianness (?who ?endianness)
	 ((big)		. ?big-body)
	 ((little)	. ?lit-body)))

    ((_ (?who ?endianness)
	((big)		. ?big-body)
	((little)	. ?lit-body))
     (and (identifier? #'?who)
	  (identifier? #'?endianness))
     #'(case ?endianness
	 ((big)		. ?big-body)
	 ((little)	. ?lit-body)
	 (else
	  (procedure-signature-argument-violation ?who
	    "expected endianness symbol as argument"
	    #f 'endianness? ?endianness))))
    ))


;;;; validation predicates

;;Defined  by Vicare.   Return #t  if LEN  is valid  as bytevector  length, otherwise
;;return #f.
(define bytevector-length? non-negative-fixnum?)

;;Defined by Vicare.  Return #t if OBJ is valid as bytevector index; otherwise return
;;#f.  OBJ must be further validated for  the specific bytevector with which it is to
;;be used.
(define bytevector-index? non-negative-fixnum?)

;;Defined by Vicare.   Return true if OBJ is  valid as word size to be  accessed in a
;;bytevector; otherwise return  false.  OBJ must be further validated  for a specific
;;bytevector word start offset.
(define bytevector-word-size? positive-fixnum?)

;;Define by Vicare.   Return #t if OBJ  is valid as word count  for bytevector items,
;;either a byte count, 16-bit words  count, 32-bit words count, ...; otherwise return
;;#f.  OBJ must be  further validated for the specific bytevector  and word size with
;;which it is to be used.
(define bytevector-word-count?  non-negative-fixnum?)

;;; --------------------------------------------------------------------

(define (bytevector-index-for-word? bv idx word-size-in-bytes)
  ;;Defined by  Vicare.  Return true  if: BV is a  bytevector, IDX is  a non-negative
  ;;fixnum, WORD-SIZE-IN-BYTES is  a non-negative fixnum, IDX is a  valid index in BV
  ;;to reference  a word  whose size is  WORD-SIZE-IN-BYTES; otherwise  return false.
  ;;This validation is for getter and setter indexes.
  ;;
  (and (bytevector? bv)
       (bytevector-index? idx)
       (bytevector-word-size? word-size-in-bytes)
       ;;We  want  this  operation to  return  a  boolean  even  if it  overflows  or
       ;;underflows the range of fixnums.
       (let ((end (- ($bytevector-length bv) word-size-in-bytes)))
	 (and (fixnum? end)
	      ($fx<= idx end)))))

(define (bytevector-index-for-word8? bv idx)
  (bytevector-index-for-word? bv idx 1))

(define (bytevector-index-for-word16? bv idx)
  (bytevector-index-for-word? bv idx 2))

(define (bytevector-index-for-word32? bv idx)
  (bytevector-index-for-word? bv idx 4))

(define (bytevector-index-for-word64? bv idx)
  (bytevector-index-for-word? bv idx 8))

(define (bytevector-index-for-single-flonum? bv idx)
  (bytevector-index-for-word? bv idx 4))

(define (bytevector-index-for-double-flonum? bv idx)
  (bytevector-index-for-word? bv idx 8))

;;; --------------------------------------------------------------------

(define* (bytevector-start-index-and-count-for-word? bv idx word-size-in-bytes count)
  ;;Defined by  Vicare.  Return true  if: BV is a  bytevector, IDX is  a non-negative
  ;;fixnum,  COUNT is  a non-negative  fixnum, WORD-SIZE-IN-BYTES  is a  non-negative
  ;;fixnum,  IDX is  a valid  index in  BV  to reference  COUNT words  whose size  is
  ;;WORD-SIZE-IN-BYTES; otherwise return false.  Notice that  if COUNT is zero: it is
  ;;fine for IDX to be equal to the  length of BV.  This validation is for getter and
  ;;setter indexes.
  ;;
  (and (bytevector? bv)
       (bytevector-index? idx)
       ($fx<= idx ($bytevector-length bv))
       (bytevector-word-size? word-size-in-bytes)
       ;;We want this operation to return a boolean even if it overflows
       ;;or underflows the range of fixnums.
       (let ((data-size (* count word-size-in-bytes)))
	 (and (fixnum? data-size)
	      (let ((past (+ idx data-size)))
		(and (fixnum? past)
		     ($fx<= past ($bytevector-length bv))))))))

(define (bytevector-start-index-and-count-for-word8? bv idx count)
  (bytevector-start-index-and-count-for-word? bv idx 1 count))

(define (bytevector-start-index-and-count-for-word16? bv idx count)
  (bytevector-start-index-and-count-for-word? bv idx 2 count))

(define (bytevector-start-index-and-count-for-word32? bv idx count)
  (bytevector-start-index-and-count-for-word? bv idx 4 count))

(define (bytevector-start-index-and-count-for-word64? bv idx count)
  (bytevector-start-index-and-count-for-word? bv idx 8 count))

;;; --------------------------------------------------------------------

(define (bytevector-start-past-indexes? bv start past)
  ;;Defined by Vicare.  Return  true if: BV is a bytevector,  START is a non-negative
  ;;fixnum, PAST  is a non-negative  fixnum, START and PAST  are valid indexes  for a
  ;;range of bytes in BV; otherwise return false.
  ;;
  (and (bytevector? bv)
       (bytevector-index? start)
       (bytevector-index? past)
       ($fx<= past ($bytevector-length bv))
       ($fx<= start past)))

;;; --------------------------------------------------------------------

(define (bytevector-index-aligned-to-2? idx)
  ;;Return  true if  IDX is  a  fixnum exact  multiple of  2,  which can  be used  to
  ;;reference 16-bit words in bytevectors.
  ;;
  (words.fixnum-aligned-to-2? idx))

(define (bytevector-index-aligned-to-4? idx)
  ;;Return  true if  IDX is  a  fixnum exact  multiple of  4,  which can  be used  to
  ;;reference 32-bit words in bytevectors.
  ;;
  (words.fixnum-aligned-to-4? idx))

(define (bytevector-index-aligned-to-8? idx)
  ;;Return  true if  IDX is  a  fixnum exact  multiple of  8,  which can  be used  to
  ;;reference 64-bit words in bytevectors.
  ;;
  (words.fixnum-aligned-to-8? idx))


;;;; predicates

(define-list-of-type-predicate list-of-bytevectors? bytevector?)


;;;; comparison

(define-equality/sorting-predicate bytevector=?		$bytevector=	bytevector?)
(define-inequality-predicate       bytevector!=?	$bytevector!=	bytevector?)

(define-equality/sorting-predicate bytevector-u8<?	$bytevector-u8<		bytevector?)
(define-equality/sorting-predicate bytevector-u8<=?	$bytevector-u8<=	bytevector?)
(define-equality/sorting-predicate bytevector-u8>?	$bytevector-u8>		bytevector?)
(define-equality/sorting-predicate bytevector-u8>=?	$bytevector-u8>=	bytevector?)

(define-equality/sorting-predicate bytevector-s8<?	$bytevector-s8<		bytevector?)
(define-equality/sorting-predicate bytevector-s8<=?	$bytevector-s8<=	bytevector?)
(define-equality/sorting-predicate bytevector-s8>?	$bytevector-s8>		bytevector?)
(define-equality/sorting-predicate bytevector-s8>=?	$bytevector-s8>=	bytevector?)

;;; --------------------------------------------------------------------

(define ($bytevector= bv1 bv2)
  (or (eq? bv1 bv2)
      (let ((bv1.len ($bytevector-length bv1)))
	(and ($fx= bv1.len ($bytevector-length bv2))
	     (let loop ((i 0) (len bv1.len))
	       (or ($fx= i len)
		   (and ($fx= ($bytevector-u8-ref bv1 i)
			      ($bytevector-u8-ref bv2 i))
			(loop ($fxadd1 i) len))))))))

(define ($bytevector!= bv1 bv2)
  (not ($bytevector= bv1 bv2)))

;;; --------------------------------------------------------------------

(define ($bytevector-u8< bv1 bv2)
  (if (eq? bv1 bv2)
      #f
    (let ((len1 ($bytevector-length bv1))
	  (len2 ($bytevector-length bv2)))
      (if ($fx< len1 len2)
	  (let next-octet ((idx  0)
			   (len1 len1)
			   (bv1 bv1)
			   (bv2 bv2))
	    (or ($fx= idx len1)
		(let ((ch1 ($bytevector-u8-ref bv1 idx))
		      (ch2 ($bytevector-u8-ref bv2 idx)))
		  (or ($fx< ch1 ch2)
		      (if ($fx= ch1 ch2)
			  (next-octet ($fxadd1 idx) len1 bv1 bv2)
			#f)))))
	(let next-octet ((idx  0)
			 (len2 len2)
			 (bv1 bv1)
			 (bv2 bv2))
	  (if ($fx= idx len2)
	      #f
	    (let ((ch1 ($bytevector-u8-ref bv1 idx))
		  (ch2 ($bytevector-u8-ref bv2 idx)))
	      (or ($fx< ch1 ch2)
		  (if ($fx= ch1 ch2)
		      (next-octet ($fxadd1 idx) len2 bv1 bv2)
		    #f)))))))))

(define ($bytevector-u8<= bv1 bv2)
  (or (eq? bv1 bv2)
      (let ((len1 ($bytevector-length bv1))
	    (len2 ($bytevector-length bv2)))
	(if ($fx<= len1 len2)
	    (let next-octet ((idx  0)
			     (len1 len1)
			     (bv1 bv1)
			     (bv2 bv2))
	      (or ($fx= idx len1)
		  (let ((ch1 ($bytevector-u8-ref bv1 idx))
			(ch2 ($bytevector-u8-ref bv2 idx)))
		    (or ($fx< ch1 ch2)
			(if ($fx= ch1 ch2)
			    (next-octet ($fxadd1 idx) len1 bv1 bv2)
			  #f)))))
	  (let next-octet ((idx  0)
			   (len2 len2)
			   (bv1 bv1)
			   (bv2 bv2))
	    (if ($fx= idx len2)
		#f
	      (let ((ch1 ($bytevector-u8-ref bv1 idx))
		    (ch2 ($bytevector-u8-ref bv2 idx)))
		(or ($fx< ch1 ch2)
		    (if ($fx= ch1 ch2)
			(next-octet ($fxadd1 idx) len2 bv1 bv2)
		      #f)))))))))

(define ($bytevector-u8> bv1 bv2)
  ($bytevector-u8< bv2 bv1))

(define ($bytevector-u8>= bv1 bv2)
  ($bytevector-u8<= bv2 bv1))

;;; --------------------------------------------------------------------

(define ($bytevector-s8< bv1 bv2)
  (if (eq? bv1 bv2)
      #f
    (let ((len1 ($bytevector-length bv1))
	  (len2 ($bytevector-length bv2)))
      (if ($fx< len1 len2)
	  (let next-byte ((idx  0)
			  (len1 len1)
			  (bv1 bv1)
			  (bv2 bv2))
	    (or ($fx= idx len1)
		(let ((ch1 ($bytevector-s8-ref bv1 idx))
		      (ch2 ($bytevector-s8-ref bv2 idx)))
		  (or ($fx< ch1 ch2)
		      (if ($fx= ch1 ch2)
			  (next-byte ($fxadd1 idx) len1 bv1 bv2)
			#f)))))
	(let next-byte ((idx  0)
			(len2 len2)
			(bv1 bv1)
			(bv2 bv2))
	  (if ($fx= idx len2)
	      #f
	    (let ((ch1 ($bytevector-s8-ref bv1 idx))
		  (ch2 ($bytevector-s8-ref bv2 idx)))
	      (or ($fx< ch1 ch2)
		  (if ($fx= ch1 ch2)
		      (next-byte ($fxadd1 idx) len2 bv1 bv2)
		    #f)))))))))

(define ($bytevector-s8<= bv1 bv2)
  (or (eq? bv1 bv2)
      (let ((len1 ($bytevector-length bv1))
	    (len2 ($bytevector-length bv2)))
	(if ($fx<= len1 len2)
	    (let next-byte ((idx  0)
			    (len1 len1)
			    (bv1 bv1)
			    (bv2 bv2))
	      (or ($fx= idx len1)
		  (let ((ch1 ($bytevector-s8-ref bv1 idx))
			(ch2 ($bytevector-s8-ref bv2 idx)))
		    (or ($fx< ch1 ch2)
			(if ($fx= ch1 ch2)
			    (next-byte ($fxadd1 idx) len1 bv1 bv2)
			  #f)))))
	  (let next-byte ((idx  0)
			  (len2 len2)
			  (bv1 bv1)
			  (bv2 bv2))
	    (if ($fx= idx len2)
		#f
	      (let ((ch1 ($bytevector-s8-ref bv1 idx))
		    (ch2 ($bytevector-s8-ref bv2 idx)))
		(or ($fx< ch1 ch2)
		    (if ($fx= ch1 ch2)
			(next-byte ($fxadd1 idx) len2 bv1 bv2)
		      #f)))))))))

(define ($bytevector-s8> bv1 bv2)
  ($bytevector-s8< bv2 bv1))

(define ($bytevector-s8>= bv1 bv2)
  ($bytevector-s8<= bv2 bv1))


;;;; min max

(define-min/max-comparison bytevector-u8-max $bytevector-u8-max bytevector?)
(define-min/max-comparison bytevector-u8-min $bytevector-u8-min bytevector?)

(define ($bytevector-u8-min bv1 bv2)
  (if ($bytevector-u8< bv1 bv2) bv1 bv2))

(define ($bytevector-u8-max bv1 bv2)
  (if ($bytevector-u8< bv1 bv2) bv2 bv1))

;;; --------------------------------------------------------------------

(define-min/max-comparison bytevector-s8-max $bytevector-s8-max bytevector?)
(define-min/max-comparison bytevector-s8-min $bytevector-s8-min bytevector?)

(define ($bytevector-s8-min bv1 bv2)
  (if ($bytevector-s8< bv1 bv2) bv1 bv2))

(define ($bytevector-s8-max bv1 bv2)
  (if ($bytevector-s8< bv1 bv2) bv2 bv1))


;;;; main bytevector handling functions

(define (native-endianness)
  ;;Defined  by  R6RS.   Return  the endianness  symbol  associated  implementation's
  ;;preferred endianness (usually that of the underlying machine architecture).  This
  ;;may be any endianness symbol, including a symbol other than "big" and "little".
  ;;
  (module (platform-endianness)
    (include "ikarus.config.scm" #t))
  platform-endianness)

(case-define* make-bytevector
  ;;Defined by  R6RS.  Return a newly  allocated bytevector of BV.LEN  bytes.  If the
  ;;FILL argument  is missing, the  initial contents  of the returned  bytevector are
  ;;unspecified.  If the FILL argument is present, it must be an exact integer object
  ;;in the interval [-128, 255] that specifies the initial value for the bytes of the
  ;;bytevector:  if FILL  is  positive, it  is  interpreted  as an  octet;  if it  is
  ;;negative, it is interpreted as a byte.
  ;;
  (({bv.len bytevector-length?})
   ($make-bytevector bv.len))
  (({bv.len bytevector-length?} {fill bytevector-byte-filler?})
   ($bytevector-fill! ($make-bytevector bv.len) 0 bv.len fill)))

;;; --------------------------------------------------------------------

(define* (bytevector-length {bv bytevector?})
  ;;Defined by R6RS.  Return, as an exact integer object, the number of bytes in BV.
  ;;
  ($bytevector-length bv))

;;; --------------------------------------------------------------------

(define* (bytevector-empty? {bv bytevector?})
  ;;Defined by Vicare.  Return true if BV is empty, otherwise return false.
  ;;
  ($bytevector-empty? bv))

(define ($bytevector-empty? bv)
  ($fxzero? ($bytevector-length bv)))


;;;; copying

(define* (bytevector-copy {src.bv bytevector?})
  ;;Defined by R6RS.  Return a newly allocated copy of SRC.BV.
  ;;
  ($bytevector-copy src.bv))

(define ($bytevector-copy src.bv)
  (receive-and-return (dst.bv)
      ($make-bytevector ($bytevector-length src.bv))
    ($bytevector-copy! src.bv 0
		       dst.bv 0
		       ($bytevector-length src.bv))))

;;; --------------------------------------------------------------------

(define* (bytevector-copy! {src.bv bytevector?} {src.start bytevector-index?}
			   {dst.bv bytevector?} {dst.start bytevector-index?}
			   {byte-count non-negative-fixnum?})
  ;;Defined by  R6RS.  SRC and  DST must  be bytevectors.  SRC.START,  DST.START, and
  ;;BYTE-COUNT must be non-negative exact integer objects that satisfy:
  ;;
  ;;   0 <= SRC.START <= SRC.START + BYTE-COUNT <= SRC.LEN
  ;;   0 <= DST.START <= DST.START + BYTE-COUNT <= DST.LEN
  ;;
  ;;where SRC.LEN is the length of SRC and DST.LEN is the length of DST.
  ;;
  ;;The BYTEVECTOR-COPY! procedure copies the bytes from SRC at indices:
  ;;
  ;;   SRC.START, ..., SRC.START + BYTE-COUNT - 1
  ;;
  ;;to consecutive indices in DST starting at index DST.START.
  ;;
  ;;This must work even if the memory  regions for the source and the target overlap,
  ;;i.e., the bytes at the target location after  the copy must be equal to the bytes
  ;;at the source location before the copy.
  ;;
  ;;Return unspecified values.
  ;;
  (preconditions
   (bytevector-start-index-and-count-for-word8? src.bv src.start byte-count)
   (bytevector-start-index-and-count-for-word8? dst.bv dst.start byte-count))
  ($bytevector-copy!/count src.bv src.start dst.bv dst.start byte-count))

;;; --------------------------------------------------------------------

(define ($bytevector-copy! src.bv src.start dst.bv dst.start src.end)
  ;;Copy the characters of SRC.BV from  SRC.START inclusive to SRC.END exclusive, to
  ;;DST.BV starting at DST.START inclusive.
  ;;
  (cond (($fx= src.start src.end)
	 (void))
	((eq? src.bv dst.bv)
	 (cond (($fx< dst.start src.start)
		($bytevector-copy-forwards!  src.bv src.start dst.bv dst.start src.end))
	       (($fx> dst.start src.start)
		($bytevector-copy-backwards! src.bv src.start dst.bv dst.start src.end))
	       (else (void))))
	(else
	 ($bytevector-copy-forwards!  src.bv src.start dst.bv dst.start src.end))))

(define ($bytevector-copy-forwards! src.bv src.start dst.bv dst.start src.end)
  ;;Copy characters  of STR.BV  from SRC.START inclusive  to SRC.END  exclusive into
  ;;DST.BV itself starting at DST.START inclusive.  The copy happens forwards, so if
  ;;SRC.BV  and DST.BV  are the  same:  it is  suitable  for the  case SRC.START  >
  ;;DST.START.
  ;;
  (unless ($fx= src.start src.end)
    ($bytevector-set! dst.bv dst.start ($bytevector-u8-ref src.bv src.start))
    ($bytevector-copy-forwards! src.bv ($fxadd1 src.start) dst.bv ($fxadd1 dst.start) src.end)))

(define ($bytevector-copy-backwards! src.bv src.start dst.bv dst.start src.end)
  ;;Copy characters  of STR.BV  from SRC.START inclusive  to SRC.END  exclusive into
  ;;DST.BV itself starting  at DST.START inclusive.  The copy  happens backwards, so
  ;;if SRC.BV  and DST.BV are  the same:  it is suitable  for the case  SRC.START <
  ;;DST.START.
  ;;
  (define count ($fx- src.end src.start))
  (let loop ((src.end   src.end)
	     (dst.end	($fx+ dst.start count)))
    (unless ($fx= src.start src.end)
      (let ((src.end ($fxsub1 src.end))
	    (dst.end ($fxsub1 dst.end)))
	($bytevector-set! dst.bv dst.end ($bytevector-u8-ref src.bv src.end))
	(loop src.end dst.end)))))

;;; --------------------------------------------------------------------

(define ($bytevector-copy!/count src.bv src.start dst.bv dst.start count)
  ;;Copy COUNT  characters from  SRC.BV starting at  SRC.START inclusive  to DST.BV
  ;;starting at DST.START inclusive.
  ;;
  (cond (($fxzero? count)
	 (void))
	((eq? src.bv dst.bv)
	 (cond (($fx< dst.start src.start)
		($bytevector-self-copy-forwards!/count  src.bv src.start dst.start count))
	       (($fx> dst.start src.start)
		($bytevector-self-copy-backwards!/count src.bv src.start dst.start count))
	       (else (void))))
	(else
	 (let ((src.end ($fx+ src.start count)))
	   ($bytevector-copy-forwards! src.bv src.start dst.bv dst.start src.end)))))

(define ($bytevector-self-copy-forwards!/count str src.start dst.start count)
  ;;Copy COUNT characters  of STR from SRC.START inclusive to  STR itself starting at
  ;;DST.START inclusive.  The  copy happens forwards, so it is  suitable for the case
  ;;SRC.START > DST.START.
  ;;
  (let loop ((str	str)
	     (src.start	src.start)
	     (dst.start	dst.start)
	     (src.end	($fx+ src.start count)))
    (unless ($fx= src.start src.end)
      ($bytevector-set! str dst.start ($bytevector-u8-ref str src.start))
      (loop str ($fxadd1 src.start) ($fxadd1 dst.start) src.end))))

(define ($bytevector-self-copy-backwards!/count str src.start dst.start count)
  ;;Copy COUNT characters  of STR from SRC.START inclusive to  STR itself starting at
  ;;DST.START inclusive.  The copy happens backwards,  so it is suitable for the case
  ;;SRC.START < DST.START.
  ;;
  (let loop ((str	str)
	     (src.start	($fx+ src.start count))
	     (dst.start	($fx+ dst.start count))
	     (src.end	src.start))
    (unless ($fx= src.start src.end)
      (let ((src.start ($fxsub1 src.start))
	    (dst.start ($fxsub1 dst.start)))
	($bytevector-set! str dst.start ($bytevector-u8-ref str src.start))
	(loop str src.start dst.start src.end)))))





;;;; filling

(define* (bytevector-fill! {bv bytevector?} {fill bytevector-byte-filler?})
  ;;Defined  by  R6RS.    The  FILL  argument  is  as  in   the  description  of  the
  ;;MAKE-BYTEVECTOR procedure.  The BYTEVECTOR-FILL!   procedure stores FILL in every
  ;;element of BV and returns unspecified values.
  ;;
  ($bytevector-fill! bv 0 ($bytevector-length bv) fill))

(define ($bytevector-fill! bv index end fill)
  ;;Fill the positions in BV from INDEX inclusive to END exclusive with FILL.
  ;;
  (if ($fx< index end)
      (begin
	($bytevector-set! bv index fill)
	($bytevector-fill! bv ($fxadd1 index) end fill))
    bv))


;;;; subbytevectors, bytes

(case-define* subbytevector-u8
  ;;Defined by Vicare.  Build and return a new bytevector holding the bytes in SRC.BV
  ;;from index SRC.START (inclusive) to index SRC.END (exclusive).  The start and end
  ;;indexes must be such that:
  ;;
  ;;   0 <= SRC.START <= src.END <= (bytevector-length SRC.BV)
  ;;
  (({src.bv bytevector?} {src.start bytevector-index?})
   (let ((src.end ($bytevector-length src.bv)))
     (preconditions
       (bytevector-start-past-indexes? src.bv src.start src.end))
     ($subbytevector-u8 src.bv src.start src.end)))
  (({src.bv bytevector?} {src.start bytevector-index?} {src.end bytevector-index?})
   (preconditions
     (bytevector-start-past-indexes? src.bv src.start src.end))
   ($subbytevector-u8 src.bv src.start src.end)))

(define ($subbytevector-u8 src.bv src.start src.end)
  ($subbytevector-u8/count src.bv src.start (fx- src.end src.start)))

;;; --------------------------------------------------------------------

(define* (subbytevector-u8/count {src.bv bytevector?} {src.start bytevector-index?} {dst.len bytevector-length?})
  ;;Defined by  Vicare.  Build and return  a new bytevector holding  DST.LEN bytes in
  ;;SRC.BV from index SRC.START (inclusive).  The start index and the byte count must
  ;;be such that:
  ;;
  ;;   0 <= SRC.START <= SRC.START + DST.LEN <= (bytevector-length SRC.BV)
  ;;
  (preconditions
    (bytevector-start-index-and-count-for-word8? src.bv src.start dst.len))
  ($subbytevector-u8/count src.bv src.start dst.len))

(define ($subbytevector-u8/count src.bv src.start dst.len)
  (do ((dst.bv ($make-bytevector dst.len))
       (dst.index 0         ($fxadd1 dst.index))
       (src.index src.start ($fxadd1 src.index)))
      (($fx= dst.index dst.len)
       dst.bv)
    ($bytevector-u8-set! dst.bv dst.index ($bytevector-u8-ref src.bv src.index))))

;;; --------------------------------------------------------------------

(case-define* subbytevector-s8
  ;;Defined by Vicare.  Build and return a new bytevector holding the bytes in SRC.BV
  ;;from index SRC.START (inclusive) to index SRC.END (exclusive).  The start and end
  ;;indexes must be such that:
  ;;
  ;;   0 <= SRC.START <= src.END <= (bytevector-length SRC.BV)
  ;;
  (({src.bv bytevector?} {src.start bytevector-index?})
   (let ((src.end ($bytevector-length src.bv)))
     (preconditions
       (bytevector-start-past-indexes? src.bv src.start src.end))
     ($subbytevector-s8 src.bv src.start src.end))>)
  (({src.bv bytevector?} {src.start bytevector-index?} {src.end bytevector-index?})
   (preconditions
     (bytevector-start-past-indexes? src.bv src.start src.end))
   ($subbytevector-s8 src.bv src.start src.end)))

(define ($subbytevector-s8 src.bv src.start src.end)
  ($subbytevector-s8/count src.bv src.start (fx- src.end src.start)))

;;; --------------------------------------------------------------------

(define* (subbytevector-s8/count {src.bv bytevector?} {src.start bytevector-index?} {dst.len bytevector-length?})
  ;;Defined by  Vicare.  Build and return  a new bytevector holding  DST.LEN bytes in
  ;;SRC.BV from index SRC.START (inclusive).  The start index and the byte count must
  ;;be such that:
  ;;
  ;;   0 <= SRC.START <= SRC.START + DST.LEN <= (bytevector-length SRC.BV)
  ;;
  (preconditions
    (bytevector-start-index-and-count-for-word8? src.bv src.start dst.len))
  ($subbytevector-s8/count src.bv src.start dst.len))

(define ($subbytevector-s8/count src.bv src.start dst.len)
  (do ((dst.bv ($make-bytevector dst.len))
       (dst.index 0         ($fxadd1 dst.index))
       (src.index src.start ($fxadd1 src.index)))
      (($fx= dst.index dst.len)
       dst.bv)
    ($bytevector-s8-set! dst.bv dst.index ($bytevector-s8-ref src.bv src.index))))


;;;; appending and concatenating

(define* (bytevector-append . {bv* bytevector?})
  ;;Defined by Vicare.   Concatenate the bytevector arguments and  return the result.
  ;;If no arguments are given: return the empty bytevector.
  ;;
  (let ((total-length ($bytevector-total-length 0 bv*)))
    (assert-total-string-length total-length)
    ($bytevector-concatenate total-length bv*)))

;;; --------------------------------------------------------------------

(define* (bytevector-concatenate {bv* list-of-bytevectors?})
  ;;Defined by Vicare.   Concatenate the bytevector arguments and  return the result.
  ;;If no arguments are given: return the empty bytevector.
  ;;
  (let ((total-length ($bytevector-total-length 0 bv*)))
    (assert-total-string-length total-length)
    ($bytevector-concatenate total-length bv*)))

(define ($bytevector-concatenate total-length bv*)
  ;;Concatenate the bytevectors in BV*,  return the result.  The resulting bytevector
  ;;must have length TOTAL-LENGTH.  Assume the arguments have been already validated.
  ;;
  ;;IMPLEMENTATION  RESTRICTION The  bytevectors must  have a  fixnum length  and the
  ;;whole bytevector must at maximum have a fixnum length.
  ;;
  (let loop ((dst.bv	($make-bytevector total-length))
	     (dst.start	0)
	     (bvs	bv*))
    (if (null? bvs)
	dst.bv
      (let* ((src.bv   ($car bvs))
	     (src.len  ($bytevector-length src.bv)))
	($bytevector-copy!/count src.bv 0 dst.bv dst.start src.len)
	(loop dst.bv ($fx+ dst.start src.len) ($cdr bvs))))))

;;; --------------------------------------------------------------------

(define* (bytevector-reverse-and-concatenate {bv* list-of-bytevectors?})
  ;;Defined by  Vicare.  Reverse the BV*,  concatenate them and return  the resulting
  ;;bytevector.  It is  an error if the sum  of the bytevector lengths is  not in the
  ;;range of the maximum bytevector length.
  ;;
  (let ((total-length ($bytevector-total-length 0 bv*)))
    (assert-total-string-length total-length)
    ($bytevector-reverse-and-concatenate total-length bv*)))

(define ($bytevector-reverse-and-concatenate total-length bv*)
  ;;Reverse  BV*  and concatenate  its  bytevector  items;  return the  result.   The
  ;;resulting bytevector  must have length  TOTAL-LENGTH.  Assume the  arguments have
  ;;been already validated.
  ;;
  ;;IMPLEMENTATION  RESTRICTION The  bytevectors must  have a  fixnum length  and the
  ;;whole bytevector must at maximum have a fixnum length.
  ;;
  (let loop ((dst.bv	($make-bytevector total-length))
	     (dst.start	total-length)
	     (bvs	bv*))
    (if (null? bvs)
	dst.bv
      (let* ((src.bv    ($car bvs))
	     (src.len   ($bytevector-length src.bv))
	     (dst.start ($fx- dst.start src.len)))
	($bytevector-copy!/count src.bv 0 dst.bv dst.start src.len)
	(loop dst.bv dst.start ($cdr bvs))))))

;;; --------------------------------------------------------------------

(define ($bytevector-total-length total-len bv*)
  ;;Given the BV*: compute  the total length of the bytevectors,  add it to TOTAL-LEN
  ;;and return  the result.  If  TOTAL-LEN is zero: the  returned value is  the total
  ;;length of the bytevectors.  The returned value may  or may not be in the range of
  ;;the maximum bytevector size.
  ;;
  (if (null? bv*)
      total-len
    ($bytevector-total-length (+ total-len ($bytevector-length ($car bv*)))
			      ($cdr bv*))))


;;;; 8-bit setters and getters

(define* (bytevector-s8-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (bytevector-index-for-word8? bv index))
  ($bytevector-s8-ref bv index))

(define* (bytevector-u8-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (bytevector-index-for-word8? bv index))
  ($bytevector-u8-ref bv index))

(define* (bytevector-s8-set! {bv bytevector?} {index bytevector-index?} {byte words.word-s8?})
  (preconditions
    (bytevector-index-for-word8? bv index))
  ($bytevector-s8-set! bv index byte))

(define* (bytevector-u8-set! {bv bytevector?} {index bytevector-index?} {octet words.word-u8?})
  (preconditions
    (bytevector-index-for-word8? bv index))
  ($bytevector-u8-set! bv index octet))

;;; --------------------------------------------------------------------

;;FIXME This should be a proper primitive operation.  (Marco Maggi; Sun Mar 22, 2015)
(define ($bytevector-u8-set! bv idx val)
  ($bytevector-set! bv idx val))

;;FIXME This should be a proper primitive operation.  (Marco Maggi; Sun Mar 22, 2015)
(define ($bytevector-s8-set! bv idx val)
  ($bytevector-set! bv idx val))


;;;; 16-bit setters and getters

(define* (bytevector-u16-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-word16? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-u16b-ref bv index))
    ((little)
     ($bytevector-u16l-ref bv index))))

(define* (bytevector-u16-set! {bv bytevector?} {index bytevector-index?} {word words.word-u16?} endianness)
  (preconditions
    (bytevector-index-for-word16? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-u16b-set! bv index word))
    ((little)
     ($bytevector-u16l-set! bv index word))))

;;; --------------------------------------------------------------------

(define* (bytevector-s16-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-word16? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-s16b-ref bv index))
    ((little)
     ($bytevector-s16l-ref bv index))))

(define* (bytevector-s16-set! {bv bytevector?} {index bytevector-index?} {word words.word-s16?} endianness)
  (preconditions
    (bytevector-index-for-word16? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-s16b-set! bv index word))
    ((little)
     ($bytevector-s16l-set! bv index word))))

;;; --------------------------------------------------------------------

(define* (bytevector-u16-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (words.fixnum-aligned-to-2? index)
    (bytevector-index-for-word16? bv index))
  ($bytevector-u16n-ref bv index))

(define* (bytevector-u16-native-set! {bv bytevector?} {index bytevector-index?} {word words.word-u16?})
  (preconditions
    (words.fixnum-aligned-to-2? index)
    (bytevector-index-for-word16? bv index))
  ($bytevector-u16n-set! bv index word))

;;; --------------------------------------------------------------------

(define* (bytevector-s16-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (words.fixnum-aligned-to-2? index)
    (bytevector-index-for-word16? bv index))
  ($bytevector-s16n-ref bv index))

(define* (bytevector-s16-native-set! {bv bytevector?} {index bytevector-index?} {word words.word-s16?})
  (preconditions
    (words.fixnum-aligned-to-2? index)
    (bytevector-index-for-word16? bv index))
  ($bytevector-s16n-set! bv index word))


;;;; 32-bit setters and getters

(define* (bytevector-u32-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-word32? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-u32b-ref bv index))
    ((little)
     ($bytevector-u32l-ref bv index))))

(define* (bytevector-u32-set! {bv bytevector?} {index bytevector-index?} {word words.word-u32?} endianness)
  (preconditions
    (bytevector-index-for-word32? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-u32b-set! bv index word))
    ((little)
     ($bytevector-u32l-set! bv index word))))

;;; --------------------------------------------------------------------

(define* (bytevector-s32-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-word32? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-s32b-ref bv index))
    ((little)
     ($bytevector-s32l-ref bv index))))

(define* (bytevector-s32-set! {bv bytevector?} {index bytevector-index?} {word words.word-s32?} endianness)
  (preconditions
    (bytevector-index-for-word32? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-s32b-set! bv index word))
    ((little)
     ($bytevector-s32l-set! bv index word))))

;;; --------------------------------------------------------------------

(define* (bytevector-u32-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (words.fixnum-aligned-to-4? index)
    (bytevector-index-for-word32? bv index))
  ($bytevector-u32n-ref bv index))

(define* (bytevector-u32-native-set! {bv bytevector?} {index bytevector-index?} {word words.word-u32?})
  (preconditions
    (words.fixnum-aligned-to-4? index)
    (bytevector-index-for-word32? bv index))
  ($bytevector-u32n-set! bv index word))

;;; --------------------------------------------------------------------

(define* (bytevector-s32-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (words.fixnum-aligned-to-4? index)
    (bytevector-index-for-word32? bv index))
  ($bytevector-s32n-ref bv index))

(define* (bytevector-s32-native-set! {bv bytevector?} {index bytevector-index?} {word words.word-s32?})
  (preconditions
    (words.fixnum-aligned-to-4? index)
    (bytevector-index-for-word32? bv index))
  ($bytevector-s32n-set! bv index word))


;;;; 64-bit setters and getters

(define* (bytevector-u64-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-word64? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-u64b-ref bv index))
    ((little)
     ($bytevector-u64l-ref bv index))))

(define* (bytevector-u64-set! {bv bytevector?} {index bytevector-index?} {word words.word-u64?} endianness)
  (preconditions
    (bytevector-index-for-word64? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-u64b-set! bv index word))
    ((little)
     ($bytevector-u64l-set! bv index word))))

;;; --------------------------------------------------------------------

(define* (bytevector-s64-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-word64? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-s64b-ref bv index))
    ((little)
     ($bytevector-s64l-ref bv index))))

(define* (bytevector-s64-set! {bv bytevector?} {index bytevector-index?} {word words.word-s64?} endianness)
  (preconditions
    (bytevector-index-for-word64? bv index))
  (case-endianness (__who__ endianness)
    ((big)
     ($bytevector-s64b-set! bv index word))
    ((little)
     ($bytevector-s64l-set! bv index word))))

;;; --------------------------------------------------------------------

(define* (bytevector-u64-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (words.fixnum-aligned-to-8? index)
    (bytevector-index-for-word64? bv index))
  ($bytevector-u64n-ref bv index))

(define* (bytevector-u64-native-set! {bv bytevector?} {index bytevector-index?} {word words.word-u64?})
  (preconditions
    (words.fixnum-aligned-to-8? index)
    (bytevector-index-for-word64? bv index))
  ($bytevector-u64n-set! bv index word))

;;; --------------------------------------------------------------------

(define* (bytevector-s64-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (words.fixnum-aligned-to-8? index)
    (bytevector-index-for-word64? bv index))
  ($bytevector-s64n-ref bv index))

(define* (bytevector-s64-native-set! {bv bytevector?} {index bytevector-index?} {word words.word-s64?})
  (preconditions
    (words.fixnum-aligned-to-8? index)
    (bytevector-index-for-word64? bv index))
  ($bytevector-s64n-set! bv index word))


;;;; double-precision flonum bytevector functions

(define* (bytevector-ieee-double-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-double-flonum? bv index))
  (if (words.fixnum-aligned-to-8? index)
      (case-endianness (__who__ endianness)
	((little)
	 ($bytevector-ieee-double-native-ref    bv index))
	((big)
	 ($bytevector-ieee-double-nonnative-ref bv index)))
    (case-endianness (__who__ endianness)
      ((little)
       ($bytevector-ieee-double-little-ref bv index))
      ((big)
       ($bytevector-ieee-double-big-ref bv index)))))

(define* (bytevector-ieee-double-set! {bv bytevector?} {index bytevector-index?} {X flonum?} endianness)
  (preconditions
    (bytevector-index-for-double-flonum? bv index))
  (if (words.fixnum-aligned-to-8? index)
      (case-endianness (__who__ endianness)
	((little)
	 ($bytevector-ieee-double-native-set! bv index X))
	((big)
	 ($bytevector-ieee-double-nonnative-set! bv index X)))
    (case endianness
      ((little)
       ($bytevector-ieee-double-little-set! bv index X))
      ((big)
       ($bytevector-ieee-double-big-set! bv index X)))))

;;; --------------------------------------------------------------------

(define* (bytevector-ieee-double-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (bytevector-index-for-double-flonum? bv index)
    (bytevector-index-aligned-to-8? index))
  ($bytevector-ieee-double-native-ref bv index))

(define* (bytevector-ieee-double-native-set! {bv bytevector?} {index bytevector-index?} {X flonum?})
  (preconditions
    (bytevector-index-for-double-flonum? bv index)
    (bytevector-index-aligned-to-8? index))
  ($bytevector-ieee-double-native-set! bv index X))


;;;; single-precision flonum bytevector functions

(define* (bytevector-ieee-single-ref {bv bytevector?} {index bytevector-index?} endianness)
  (preconditions
    (bytevector-index-for-single-flonum? bv index))
  (if (words.fixnum-aligned-to-4? index)
      (case-endianness (__who__ endianness)
	((little)
	 ($bytevector-ieee-single-native-ref bv index))
	((big)
	 ($bytevector-ieee-single-nonnative-ref bv index)))
    (case-endianness (__who__ endianness)
      ((little)
       ($bytevector-ieee-single-little-ref bv index))
      ((big)
       ($bytevector-ieee-single-big-ref bv index)))))

(define* (bytevector-ieee-single-set! {bv bytevector?} {index bytevector-index?}
				      {X flonum?} endianness)
  (preconditions
    (bytevector-index-for-single-flonum? bv index))
  (if (words.fixnum-aligned-to-4? index)
      (case-endianness (__who__ endianness)
	((little)
	 ($bytevector-ieee-single-native-set! bv index X))
	((big)
	 ($bytevector-ieee-single-nonnative-set! bv index X)))
    (case-endianness (__who__ endianness)
      ((little)
       ($bytevector-ieee-single-little-set! bv index X))
      ((big)
       ($bytevector-ieee-single-big-set! bv index X)))))

;;; --------------------------------------------------------------------

(define* (bytevector-ieee-single-native-ref {bv bytevector?} {index bytevector-index?})
  (preconditions
    (bytevector-index-for-single-flonum? bv index)
    (bytevector-index-aligned-to-4? index))
  ($bytevector-ieee-single-native-ref bv index))

(define* (bytevector-ieee-single-native-set! {bv bytevector?} {index bytevector-index?} {X flonum?})
  (preconditions
    (bytevector-index-for-single-flonum? bv index)
    (bytevector-index-aligned-to-4? index))
  ($bytevector-ieee-single-native-set! bv index X))


;;;; unsafe 16-bit setters and getters
;;
;;            |            | lowest memory | highest memory
;; endianness |    word    | location      | location
;; -----------+------------+---------------+--------------
;;   little   |   #xHHLL   |     LL        |     HH
;;    big     |   #xHHLL   |     HH        |     LL
;;
;;NOTE Remember that $BYTEVECTOR-SET! takes care  of storing in memory only the least
;;significant byte of its value argument.
;;

(define ($bytevector-u16l-ref bv index)
  ($fxlogor
   ;; highest memory location -> most significant byte
   ($fxsll ($bytevector-u8-ref bv ($fxadd1 index)) 8)
   ;; lowest memory location -> least significant byte
   ($bytevector-u8-ref bv index)))

(define ($bytevector-u16l-set! bv index word)
  ;; lowest memory location -> least significant byte
  ($bytevector-set! bv index word)
  ;; highest memory location -> most significant byte
  ($bytevector-set! bv ($fxadd1 index) (fxsra word 8)))

;;; --------------------------------------------------------------------

(define ($bytevector-u16b-ref bv index)
  ($fxlogor
   ;; lowest memory location -> most significant byte
   ($fxsll ($bytevector-u8-ref bv index) 8)
   ;; highest memory location -> least significant byte
   ($bytevector-u8-ref bv ($fxadd1 index))))

(define ($bytevector-u16b-set! bv index word)
  ;; lowest memory location -> most significant byte
  ($bytevector-set! bv index ($fxsra word 8))
  ;; highest memory location -> least significant byte
  ($bytevector-set! bv ($fxadd1 index) word))

;;; --------------------------------------------------------------------

(define ($bytevector-s16l-ref bv index)
  ($fxlogor
   ;; highest memory location -> most significant byte
   ($fxsll ($bytevector-s8-ref bv ($fxadd1 index)) 8)
   ;; lowest memory location -> least significant byte
   ($bytevector-u8-ref bv index)))

(define ($bytevector-s16l-set! bv index word)
  ;; lowest memory location -> least significant byte
  ($bytevector-set! bv index word)
  ;; highest memory location -> most significant byte
  ($bytevector-set! bv ($fxadd1 index) (fxsra word 8)))

;;; --------------------------------------------------------------------

(define ($bytevector-s16b-ref bv index)
  ($fxlogor
   ;; lowest memory location -> most significant byte
   ($fxsll ($bytevector-s8-ref bv index) 8)
   ;; highest memory location -> least significant byte
   ($bytevector-u8-ref bv ($fxadd1 index))))

(define ($bytevector-s16b-set! bv index word)
  ;; lowest memory location -> most significant byte
  ($bytevector-set! bv index ($fxsra word 8))
  ;; highest memory location -> least significant byte
  ($bytevector-set! bv ($fxadd1 index) word))

;;; --------------------------------------------------------------------

(define-cased-accessor $bytevector-u16n-ref
  $bytevector-u16b-ref
  $bytevector-u16l-ref)

(define-cased-mutator $bytevector-u16n-set!
  $bytevector-u16b-set!
  $bytevector-u16l-set!)

;;; --------------------------------------------------------------------

(define-cased-accessor $bytevector-s16n-ref
  $bytevector-s16b-ref
  $bytevector-s16l-ref)

(define-cased-mutator $bytevector-s16n-set!
  $bytevector-s16b-set!
  $bytevector-s16l-set!)

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-u16-ref
  $bytevector-u16b-ref
  $bytevector-u16l-ref
  $bytevector-u16n-ref)

(define-generic-cased-mutator $bytevector-u16-set!
  $bytevector-u16b-set!
  $bytevector-u16l-set!
  $bytevector-u16n-set!)

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-s16-ref
  $bytevector-s16b-ref
  $bytevector-s16l-ref
  $bytevector-s16n-ref)

(define-generic-cased-mutator $bytevector-s16-set!
  $bytevector-s16b-set!
  $bytevector-s16l-set!
  $bytevector-s16n-set!)


;;;; unsafe 32-bit setters and getters
;;
;;                           lowest memory ------------> highest memory
;; endianness |    word    | 1st byte | 2nd byte | 3rd byte | 4th byte
;; -----------+------------+----------+----------+----------+----------
;;   little   | #xAABBCCDD |   DD     |    CC    |    BB    |    AA
;;    big     | #xAABBCCDD |   AA     |    BB    |    CC    |    DD
;; bit offset |            |    0     |     8    |    16    |    24
;;
;;NOTE Remember that $BYTEVECTOR-SET! takes care  of storing in memory only the least
;;significant byte of its value argument.
;;

(define ($bytevector-u32b-ref bv index)
  (+ (sll ($bytevector-u8-ref bv index) 24)
     ($fixnum-ior
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index)) 16)
      ($fxsll ($bytevector-u8-ref bv ($fx+ index 2))  8)
      ($bytevector-u8-ref bv ($fx+ index 3)))))

(define ($bytevector-u32b-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv index ($fxsra b 8))
    ($bytevector-set! bv ($fxadd1 index) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fx+ index 2) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 3) b)))

;;; --------------------------------------------------------------------

(define ($bytevector-u32l-ref bv index)
  (+ (sll ($bytevector-u8-ref bv ($fx+ index 3)) 24)
     ($fixnum-ior
      ($fxsll ($bytevector-u8-ref bv ($fx+ index 2)) 16)
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index)) 8)
      ($bytevector-u8-ref bv index))))

(define ($bytevector-u32l-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv ($fx+ index 3) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 2) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fxadd1 index) ($fxsra b 8))
    ($bytevector-set! bv index b)))

;;; --------------------------------------------------------------------

(define ($bytevector-s32b-ref bv index)
  (+ (sll ($bytevector-s8-ref bv index) 24)
     ($fixnum-ior
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index))   16)
      ($fxsll ($bytevector-u8-ref bv ($fx+    index 2))  8)
      ($bytevector-u8-ref bv ($fx+ index 3)))))

(define ($bytevector-s32b-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv index ($fxsra b 8))
    ($bytevector-set! bv ($fxadd1 index) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fx+ index 2) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 3) b)))

;;; --------------------------------------------------------------------

(define ($bytevector-s32l-ref bv index)
  (+ (sll ($bytevector-s8-ref bv ($fx+ index 3)) 24)
     ($fixnum-ior
      ($fxsll ($bytevector-u8-ref bv ($fx+    index 2)) 16)
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index))    8)
      ($bytevector-u8-ref bv index))))

(define ($bytevector-s32l-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv ($fx+ index 3) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 2) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fxadd1 index) ($fxsra b 8))
    ($bytevector-set! bv index b)))

;;; --------------------------------------------------------------------

(define-cased-accessor $bytevector-u32n-ref
  $bytevector-u32b-ref
  $bytevector-u32l-ref)

(define-cased-mutator $bytevector-u32n-set!
  $bytevector-u32b-set!
  $bytevector-u32l-set!)

;;; --------------------------------------------------------------------

(define-cased-accessor $bytevector-s32n-ref
  $bytevector-s32b-ref
  $bytevector-s32l-ref)

(define-cased-mutator $bytevector-s32n-set!
  $bytevector-s32b-set!
  $bytevector-s32l-set!)

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-u32-ref
  $bytevector-u32b-ref
  $bytevector-u32l-ref
  $bytevector-u32n-ref)

(define-generic-cased-mutator $bytevector-u32-set!
  $bytevector-u32b-set!
  $bytevector-u32l-set!
  $bytevector-u32n-set!)

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-s32-ref
  $bytevector-s32b-ref
  $bytevector-s32l-ref
  $bytevector-s32n-ref)

(define-generic-cased-mutator $bytevector-s32-set!
  $bytevector-s32b-set!
  $bytevector-s32l-set!
  $bytevector-s32n-set!)


;;;; unsafe 64-bit setters and getters
;;
;;                                      lowest memory ------------> highest memory
;; endianness |         word        | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th | 8th
;; -----------+---------------------+-----+-----+-----+-----+-----+-----+-----+-----
;;   little   | #xAABBCCDD EEFFGGHH | HH  | GG  | FF  | EE  | DD  | CC  | BB  | AA
;;    big     | #xAABBCCDD EEFFGGHH | AA  | BB  | CC  | DD  | EE  | FF  | GG  | HH
;; bit offset |                     |  0  |  8  | 16  | 24  | 32  | 40  | 48  | 56
;;
;;NOTE Remember that $BYTEVECTOR-SET! takes care  of storing in memory only the least
;;significant byte of its value argument.
;;

(define ($bytevector-u64b-ref ?bv ?index)
  (let ((index ?index))
    (let next-byte ((bv     ?bv)
		    (index  index)
		    (end    ($fx+ index 7))
		    (word   0))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxadd1 index) end (sll word 8)))))))

(define ($bytevector-u64b-set! ?bv ?index ?word)
  (let ((index  ?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  ($fx+ 7 index))
		    (end    index)
		    (word   word))
      ($bytevector-set! bv index (bitwise-and word #xFF))
      (unless ($fx= index end)
	(next-byte bv ($fxsub1 index) end (sra word 8))))))

;;; --------------------------------------------------------------------

(define ($bytevector-u64l-ref ?bv ?end)
  (let ((end ?end))
    (let next-byte ((bv     ?bv)
		    (index  ($fx+ 7 end))
		    (word   0))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxsub1 index) (sll word 8)))))))

(define ($bytevector-u64l-set! ?bv ?index ?word)
  (let ((index	?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  index)
		    (end    ($fx+ 7 index))
		    (word   word))
      ($bytevector-set! bv index (bitwise-and word #xFF))
      (unless ($fx= index end)
	(next-byte bv ($fxadd1 index) end (sra word 8))))))

;;; --------------------------------------------------------------------

(define ($bytevector-s64b-ref ?bv ?index)
  (let ((bv	?bv)
	(index	?index))
    (let next-byte ((bv     bv)
		    (index  ($fxadd1 index))
		    (end    ($fx+ index 7))
		    (word   (sll ($bytevector-s8-ref bv index) 8)))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxadd1 index) end (sll word 8)))))))

(define ($bytevector-s64b-set! ?bv ?index ?word)
  (let ((index	?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  ($fx+ 7 index))
		    (end    index)
		    (word   word))
      (if ($fx= index end)
	  ($bytevector-set! bv index (bitwise-and word #xFF))
	(begin
	  ($bytevector-set! bv index (bitwise-and word #xFF))
	  (next-byte bv ($fxsub1 index) end (sra word 8)))))))

;;; --------------------------------------------------------------------

(define ($bytevector-s64l-ref ?bv ?end)
  (let ((bv	?bv)
	(end	?end))
    (let next-byte ((bv     bv)
		    (index  ($fx+ 6 end))
		    (word   (sll ($bytevector-s8-ref bv ($fx+ 7 end)) 8)))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxsub1 index) (sll word 8)))))))

(define ($bytevector-s64l-set! ?bv ?index ?word)
  (let ((index	?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  index)
		    (end    ($fx+ 7 index))
		    (word   word))
      (if ($fx= index end)
	  ($bytevector-set! bv index (bitwise-and word #xFF))
	(begin
	  ($bytevector-set! bv index (bitwise-and word #xFF))
	  (next-byte bv ($fxadd1 index) end (sra word 8)))))))

;;; --------------------------------------------------------------------

(define-cased-accessor $bytevector-u64n-ref
  $bytevector-u64b-ref
  $bytevector-u64l-ref)

(define-cased-mutator $bytevector-u64n-set!
  $bytevector-u64b-set!
  $bytevector-u64l-set!)

;;; --------------------------------------------------------------------

(define-cased-accessor $bytevector-s64n-ref
  $bytevector-s64b-ref
  $bytevector-s64l-ref)

(define-cased-mutator $bytevector-s64n-set!
  $bytevector-s64b-set!
  $bytevector-s64l-set!)

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-u64-ref
  $bytevector-u64b-ref
  $bytevector-u64l-ref
  $bytevector-u64n-ref)

(define-generic-cased-mutator $bytevector-u64-set!
  $bytevector-u64b-set!
  $bytevector-u64l-set!
  $bytevector-u64n-set!)

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-s64-ref
  $bytevector-s64b-ref
  $bytevector-s64l-ref
  $bytevector-s64n-ref)

(define-generic-cased-mutator $bytevector-s64-set!
  $bytevector-s64b-set!
  $bytevector-s64l-set!
  $bytevector-s64n-set!)


;;;; unsafe flonum setters and getters: double-precision IEEE flonums
;;
;;As defined by IEEE 754: single-precision flonums are 4 bytes long, double-precision
;;flonums are  8 bytes long.   Vicare's flonums are double-precision.   On big-endian
;;platforms the order of bytes is the same in a flonum data area and the bytevector.
;;

(define ($bytevector-ieee-double-big-ref x i)
  (receive-and-return (y)
      ($make-flonum)
    ($flonum-set! y 0 ($bytevector-u8-ref x i))
    ($flonum-set! y 1 ($bytevector-u8-ref x ($fx+ i 1)))
    ($flonum-set! y 2 ($bytevector-u8-ref x ($fx+ i 2)))
    ($flonum-set! y 3 ($bytevector-u8-ref x ($fx+ i 3)))
    ($flonum-set! y 4 ($bytevector-u8-ref x ($fx+ i 4)))
    ($flonum-set! y 5 ($bytevector-u8-ref x ($fx+ i 5)))
    ($flonum-set! y 6 ($bytevector-u8-ref x ($fx+ i 6)))
    ($flonum-set! y 7 ($bytevector-u8-ref x ($fx+ i 7)))))

(define ($bytevector-ieee-double-big-set! x i y)
  ($bytevector-set! x i          ($flonum-u8-ref y 0))
  ($bytevector-set! x ($fx+ i 1) ($flonum-u8-ref y 1))
  ($bytevector-set! x ($fx+ i 2) ($flonum-u8-ref y 2))
  ($bytevector-set! x ($fx+ i 3) ($flonum-u8-ref y 3))
  ($bytevector-set! x ($fx+ i 4) ($flonum-u8-ref y 4))
  ($bytevector-set! x ($fx+ i 5) ($flonum-u8-ref y 5))
  ($bytevector-set! x ($fx+ i 6) ($flonum-u8-ref y 6))
  ($bytevector-set! x ($fx+ i 7) ($flonum-u8-ref y 7)))

;;; --------------------------------------------------------------------

(define ($bytevector-ieee-double-little-ref x i)
  (receive-and-return (y)
      ($make-flonum)
    ($flonum-set! y 7 ($bytevector-u8-ref x i))
    ($flonum-set! y 6 ($bytevector-u8-ref x ($fx+ i 1)))
    ($flonum-set! y 5 ($bytevector-u8-ref x ($fx+ i 2)))
    ($flonum-set! y 4 ($bytevector-u8-ref x ($fx+ i 3)))
    ($flonum-set! y 3 ($bytevector-u8-ref x ($fx+ i 4)))
    ($flonum-set! y 2 ($bytevector-u8-ref x ($fx+ i 5)))
    ($flonum-set! y 1 ($bytevector-u8-ref x ($fx+ i 6)))
    ($flonum-set! y 0 ($bytevector-u8-ref x ($fx+ i 7)))))

(define ($bytevector-ieee-double-little-set! x i y)
  ($bytevector-set! x i          ($flonum-u8-ref y 7))
  ($bytevector-set! x ($fx+ i 1) ($flonum-u8-ref y 6))
  ($bytevector-set! x ($fx+ i 2) ($flonum-u8-ref y 5))
  ($bytevector-set! x ($fx+ i 3) ($flonum-u8-ref y 4))
  ($bytevector-set! x ($fx+ i 4) ($flonum-u8-ref y 3))
  ($bytevector-set! x ($fx+ i 5) ($flonum-u8-ref y 2))
  ($bytevector-set! x ($fx+ i 6) ($flonum-u8-ref y 1))
  ($bytevector-set! x ($fx+ i 7) ($flonum-u8-ref y 0)))

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-ieee-double-ref
  $bytevector-ieee-double-big-ref
  $bytevector-ieee-double-little-ref
  $bytevector-ieee-double-native-ref)

(define-generic-cased-mutator $bytevector-ieee-double-set!
  $bytevector-ieee-double-big-set!
  $bytevector-ieee-double-little-set!
  $bytevector-ieee-double-native-set!)


;;;; unsafe flonum setters and getters: single-precision IEEE flonums
;;
;;As defined by IEEE 754: single-precision flonums are 4 bytes long, double-precision
;;flonums are  8 bytes long.   Vicare's flonums are double-precision.   On big-endian
;;platforms the order of bytes is the same in a flonum data area and the bytevector.
;;

(define ($bytevector-ieee-single-little-ref x i)
  (let ((bv (make-bytevector 4)))
    ($bytevector-set! bv 0 ($bytevector-u8-ref x i))
    ($bytevector-set! bv 1 ($bytevector-u8-ref x ($fx+ i 1)))
    ($bytevector-set! bv 2 ($bytevector-u8-ref x ($fx+ i 2)))
    ($bytevector-set! bv 3 ($bytevector-u8-ref x ($fx+ i 3)))
    ($bytevector-ieee-single-native-ref bv 0)))

(define ($bytevector-ieee-single-big-ref x i)
  (let ((bv (make-bytevector 4)))
    ($bytevector-set! bv 3 ($bytevector-u8-ref x i))
    ($bytevector-set! bv 2 ($bytevector-u8-ref x ($fx+ i 1)))
    ($bytevector-set! bv 1 ($bytevector-u8-ref x ($fx+ i 2)))
    ($bytevector-set! bv 0 ($bytevector-u8-ref x ($fx+ i 3)))
    ($bytevector-ieee-single-native-ref bv 0)))

;;; --------------------------------------------------------------------

(define ($bytevector-ieee-single-little-set! x i v)
  (let ((bv (make-bytevector 4)))
    ($bytevector-ieee-single-native-set! bv 0 v)
    ($bytevector-set! x i          ($bytevector-u8-ref bv 0))
    ($bytevector-set! x ($fx+ i 1) ($bytevector-u8-ref bv 1))
    ($bytevector-set! x ($fx+ i 2) ($bytevector-u8-ref bv 2))
    ($bytevector-set! x ($fx+ i 3) ($bytevector-u8-ref bv 3))))

(define ($bytevector-ieee-single-big-set! x i v)
  (let ((bv (make-bytevector 4)))
    ($bytevector-ieee-single-native-set! bv 0 v)
    ($bytevector-set! x i          ($bytevector-u8-ref bv 3))
    ($bytevector-set! x ($fx+ i 1) ($bytevector-u8-ref bv 2))
    ($bytevector-set! x ($fx+ i 2) ($bytevector-u8-ref bv 1))
    ($bytevector-set! x ($fx+ i 3) ($bytevector-u8-ref bv 0))))

;;; --------------------------------------------------------------------

(define-generic-cased-accessor $bytevector-ieee-single-ref
  $bytevector-ieee-single-big-ref
  $bytevector-ieee-single-little-ref
  $bytevector-ieee-single-native-ref)

(define-generic-cased-mutator $bytevector-ieee-single-set!
  $bytevector-ieee-single-big-set!
  $bytevector-ieee-single-little-set!
  $bytevector-ieee-single-native-set!)


;;;; any integer getters, bytevector to any integer list conversion

(module (bytevector-uint-ref
	 bytevector-sint-ref
	 bytevector->uint-list
	 bytevector->sint-list)

  (define-syntax-rule ($fxsll8 ?fx)
    ($fxsll ?fx 8))

  ;;NOTE The  arguments IB and  IL are  byte indexes in  the bytevector.
  ;;
  ;;                 word
  ;;        |.................|
  ;;   --|--|--|--|--|--|--|--|--|--
  ;;         ^                 ^
  ;;         ib                il
  ;;

  (define (uref-big x ib il) ;; ib included, il excluded
    (if ($fx= il ib)
	0
      (let ((b ($bytevector-u8-ref x ib)))
	(if ($fxzero? b)
	    (uref-big x ($fxadd1 ib) il)
	  (case ($fx- il ib)
	    ((1) b)
	    ((2) ($fx+ ($fxsll8 b) ($bytevector-u8-ref x ($fxsub1 il))))
	    ((3) ($fx+ ($fxsll8 ($fx+ ($fxsll8 b) ($bytevector-u8-ref x ($fxadd1 ib))))
		       ($bytevector-u8-ref x ($fxsub1 il))))
	    (else
	     (let ((im ($fxsra ($fx+ il ib) 1)))
	       (+ (uref-big x im il)
		  (* (uref-big x ib im)
		     (expt 256 ($fx- il im)))))))))))

  (define (uref-little x il ib) ;; il included, ib excluded
    (if ($fx= il ib)
	0
      (let ((ib^ ($fxsub1 ib)))
	(let ((b ($bytevector-u8-ref x ib^)))
	  (if ($fxzero? b)
	      (uref-little x il ib^)
	    (case ($fx- ib il)
	      ((1) b)
	      ((2) ($fx+ ($fxsll8 b) ($bytevector-u8-ref x il)))
	      ((3) ($fx+ ($fxsll8 ($fx+ ($fxsll8 b) ($bytevector-u8-ref x ($fxadd1 il))))
			 ($bytevector-u8-ref x il)))
	      (else
	       (let ((im ($fxsra ($fx+ il ib) 1)))
		 (+ (uref-little x il im)
		    (* (uref-little x im ib)
		       (expt 256 ($fx- im il))))))))))))

  (define (sref-big x ib il) ;; ib included, il excluded
    (if ($fx= il ib)
	-1
      (let ((b ($bytevector-u8-ref x ib)))
	(cond (($fxzero? b)
	       (uref-big x ($fxadd1 ib) il))
	      (($fx= b 255)
	       (sref-big-neg x ($fxadd1 ib) il))
	      (($fx< b 128)
	       (uref-big x ib il))
	      (else
	       (- (uref-big x ib il) (expt 256 ($fx- il ib))))))))

  (define (sref-big-neg x ib il) ;; ib included, il excluded
    (if ($fx= il ib)
	-1
      (let ((b ($bytevector-u8-ref x ib)))
	(if ($fx= b 255)
	    (sref-big-neg x ($fxadd1 ib) il)
	  (- (uref-big x ib il) (expt 256 ($fx- il ib)))))))

  (define (sref-little x il ib) ;; il included, ib excluded
    (if ($fx= il ib)
	-1
      (let* ((ib^ ($fxsub1 ib))
	     (b   ($bytevector-u8-ref x ib^)))
	(cond (($fxzero? b)	(uref-little x il ib^))
	      (($fx= b 255)	(sref-little-neg x il ib^))
	      (($fx< b 128)	(uref-little x il ib))
	      (else
	       (- (uref-little x il ib) (expt 256 ($fx- ib il))))))))

  (define (sref-little-neg x il ib) ;; il included, ib excluded
    (if ($fx= il ib)
	-1
      (let* ((ib^ ($fxsub1 ib))
	     (b   ($bytevector-u8-ref x ib^)))
	(if ($fx= b 255)
	    (sref-little-neg x il ib^)
	  (- (uref-little x il ib) (expt 256 ($fx- ib il)))))))

;;;

  (define* (bytevector-sint-ref {bv bytevector?} {idx.start bytevector-index?} endianness {size bytevector-word-size?})
    (preconditions
      (bytevector-index-for-word? bv idx.start size))
    (let ((idx.past ($fx+ idx.start size)))
      (case-endianness (__who__ endianness)
	((little)	(sref-little bv idx.start idx.past))
	((big)		(sref-big    bv idx.start idx.past)))))

  (define* (bytevector-uint-ref {bv bytevector?} {idx.start bytevector-index?} endianness {size bytevector-word-size?})
    (preconditions
      (bytevector-index-for-word? bv idx.start size))
    (let ((idx.past ($fx+ idx.start size)))
      (case-endianness (__who__ endianness)
	((little)	(uref-little bv idx.start idx.past))
	((big)		(uref-big    bv idx.start idx.past)))))

  (module (bytevector->uint-list
	   bytevector->sint-list)

    (define* (bytevector->uint-list {bv bytevector?} endianness {size bytevector-word-size?})
      (case-endianness (__who__ endianness)
	((little)
	 ($bytevector->some-list bv size ($bytevector-length bv) '() uref-little __who__))
	((big)
	 ($bytevector->some-list bv size ($bytevector-length bv) '() uref-big    __who__))))

    (define* (bytevector->sint-list {bv bytevector?} endianness {size bytevector-word-size?})
      (case-endianness (__who__ endianness)
	((little)
	 ($bytevector->some-list bv size ($bytevector-length bv) '() sref-little __who__))
	((big)
	 ($bytevector->some-list bv size ($bytevector-length bv) '() sref-big    __who__))))

    (define ($bytevector->some-list bv word-size idx.past ls proc who)
      (if ($fxzero? idx.past)
	  ls
	(let ((idx.start ($fx- idx.past word-size)))
	  (if ($fxnonnegative? idx.start)
	      ($bytevector->some-list bv word-size idx.start
				      (cons (proc bv idx.start idx.past) ls)
				      proc who)
	    (procedure-argument-violation who "invalid word size" word-size)))))

    #| end of module |# )

  #| end of module |# )


;;;; any integer setters

(define* (bytevector-uint-set! bv idx n endianness size)
  (bytevector-uint-set!/who bv idx n endianness size __who__))

(define* (bytevector-uint-set!/who {bv bytevector?} {idx bytevector-index?}
				   {word non-negative-exact-integer?}
				   endianness
				   {word-size bytevector-word-size?} who)
  (preconditions
    (bytevector-index-for-word? bv idx word-size))
  (let ((nbits (bitwise-length word)))
    (when (< (* word-size 8) nbits)
      (procedure-argument-violation who
	(format "number does not fit in ~a byte~a" word-size (if (= word-size 1) "" "s"))
	word)))
  (case-endianness (who endianness)
    ((little)
     (let loop ((bv bv) (i0 idx) (i1 (fx+ idx word-size)) (n word))
       (unless ($fx= i0 i1)
	 ($bytevector-set! bv i0 (bitwise-and n 255))
	 (loop bv ($fx+ i0 1) i1 (sra n 8)))))
    ((big)
     (let loop ((bv bv) (i0 idx) (i1 (fx+ idx word-size)) (n word))
       (unless ($fx= i0 i1)
	 (let ((i1 ($fxsub1 i1)))
	   ($bytevector-set! bv i1 (bitwise-and n 255))
	   (loop bv i0 i1 (sra n 8))))))))

;;; --------------------------------------------------------------------

(define* (bytevector-sint-set! bv idx n endianness size)
  (bytevector-sint-set!/who bv idx n endianness size __who__))

(define* (bytevector-sint-set!/who {bv bytevector?} {idx bytevector-index?}
				   {word exact-integer?} endianness
				   {word-size bytevector-word-size?} who)
  (preconditions
   (bytevector-index-for-word? bv idx word-size))
  (let ((nbits (add1 (bitwise-length word))))
    (when (< (* word-size 8) nbits)
      (procedure-argument-violation who
	(format "number does not fit in ~a byte~a" word-size (if (= word-size 1) "" "s"))
	word)))
  (case-endianness (who endianness)
    ((little)
     (let loop ((bv bv) (i0 idx) (i1 (fx+ idx word-size)) (n word))
       (unless ($fx= i0 i1)
	 ($bytevector-set! bv i0 (bitwise-and n 255))
	 (loop bv ($fxadd1 i0) i1 (sra n 8)))))
    ((big)
     (let loop ((bv bv) (i0 idx) (i1 (fx+ idx word-size)) (n word))
       (unless ($fx= i0 i1)
	 (let ((i1 ($fx- i1 1)))
	   ($bytevector-set! bv i1 (bitwise-and n 255))
	   (loop bv i0 i1 (sra n 8))))))))


;;;; bytevector to fixed-length word list conversion

(define-syntax define-bytevector-to-byte-list
  (syntax-rules ()
    ((_ ?who ?bytevector-ref)
     (define* (?who {bv bytevector?})
       (let loop ((bv	    bv)
		  (index  ($bytevector-length bv))
		  (accum  '()))
	 (if ($fxzero? index)
	     accum
	   (let ((j ($fxsub1 index)))
	     (loop bv j (cons (?bytevector-ref bv j) accum)))))))
    ))

(define-bytevector-to-byte-list bytevector->u8-list $bytevector-u8-ref)
(define-bytevector-to-byte-list bytevector->s8-list $bytevector-s8-ref)

;;; --------------------------------------------------------------------

(define-syntax define-bytevector-to-word-list
  (syntax-rules ()
    ((_ ?who ?tag ?bytes-in-word ?bytevector-ref)
     (define* (?who {bv bytevector?})
       (let ((bv.len ($bytevector-length bv)))
	 (unless (fxzero? (fxmod bv.len ?bytes-in-word))
	   (procedure-arguments-consistency-violation (quote ?who)
	     "invalid bytevector size, not an exact multiple of word size"
	     bv ?bytes-in-word bv.len))
	 (let loop ((bv		bv)
		    (i		bv.len)
		    (accum	'()))
	   (if ($fxzero? i)
	       accum
	     (let ((j ($fx- i ?bytes-in-word)))
	       (loop bv j (cons (?bytevector-ref bv j) accum))))))))
    ))

(define-bytevector-to-word-list bytevector->u16l-list vu16l 2 $bytevector-u16l-ref)
(define-bytevector-to-word-list bytevector->u16b-list vu16b 2 $bytevector-u16b-ref)
(define-bytevector-to-word-list bytevector->u16n-list vu16n 2 $bytevector-u16n-ref)
(define-bytevector-to-word-list bytevector->s16l-list vs16l 2 $bytevector-s16l-ref)
(define-bytevector-to-word-list bytevector->s16b-list vs16b 2 $bytevector-s16b-ref)
(define-bytevector-to-word-list bytevector->s16n-list vs16n 2 $bytevector-s16n-ref)

(define-bytevector-to-word-list bytevector->u32l-list vu32l 4 $bytevector-u32l-ref)
(define-bytevector-to-word-list bytevector->u32b-list vu32b 4 $bytevector-u32b-ref)
(define-bytevector-to-word-list bytevector->u32n-list vu32n 4 $bytevector-u32n-ref)
(define-bytevector-to-word-list bytevector->s32l-list vs32l 4 $bytevector-s32l-ref)
(define-bytevector-to-word-list bytevector->s32b-list vs32b 4 $bytevector-s32b-ref)
(define-bytevector-to-word-list bytevector->s32n-list vs32n 4 $bytevector-s32n-ref)

(define-bytevector-to-word-list bytevector->u64l-list vu64l 8 $bytevector-u64l-ref)
(define-bytevector-to-word-list bytevector->u64b-list vu64b 8 $bytevector-u64b-ref)
(define-bytevector-to-word-list bytevector->u64n-list vu64n 8 $bytevector-u64n-ref)
(define-bytevector-to-word-list bytevector->s64l-list vs64l 8 $bytevector-s64l-ref)
(define-bytevector-to-word-list bytevector->s64b-list vs64b 8 $bytevector-s64b-ref)
(define-bytevector-to-word-list bytevector->s64n-list vs64n 8 $bytevector-s64n-ref)

(define-bytevector-to-word-list bytevector->f4l-list  vf4l  4 bytevector-flonum-single-le-ref)
(define-bytevector-to-word-list bytevector->f4b-list  vf4b  4 bytevector-flonum-single-be-ref)
(define-bytevector-to-word-list bytevector->f4n-list  vf4n  4 bytevector-flonum-single-ne-ref)
(define-bytevector-to-word-list bytevector->f8l-list  vf8l  8 bytevector-flonum-double-le-ref)
(define-bytevector-to-word-list bytevector->f8b-list  vf8b  8 bytevector-flonum-double-be-ref)
(define-bytevector-to-word-list bytevector->f8n-list  vf8n  8 bytevector-flonum-double-ne-ref)

(define-bytevector-to-word-list bytevector->c4l-list  vc4l  8 bytevector-cflonum-single-le-ref)
(define-bytevector-to-word-list bytevector->c4b-list  vc4b  8 bytevector-cflonum-single-be-ref)
(define-bytevector-to-word-list bytevector->c4n-list  vc4n  8 bytevector-cflonum-single-ne-ref)
(define-bytevector-to-word-list bytevector->c8l-list  vc8l 16 bytevector-cflonum-double-le-ref)
(define-bytevector-to-word-list bytevector->c8b-list  vc8b 16 bytevector-cflonum-double-be-ref)
(define-bytevector-to-word-list bytevector->c8n-list  vc8n 16 bytevector-cflonum-double-ne-ref)


;;;; fixed-length word list to bytevector conversion

(define-syntax define-byte-list-to-bytevector
  (syntax-rules ()
    ((_ ?who ?tag ?valid-number-pred ?bytevector-set!)
     (define* (?who ls)
       (define (race h t ls n)
	 (if (pair? h)
	     (let ((h ($cdr h)))
	       (if (pair? h)
		   (if (not (eq? h t))
		       (race ($cdr h) ($cdr t) ls ($fx+ n 2))
		     (procedure-argument-violation (quote ?who) "circular list" ls))
		 (if (null? h)
		     ($fxadd1 n)
		   (procedure-argument-violation (quote ?who) "not a proper list" ls))))
	   (if (null? h)
	       n
	     (procedure-argument-violation (quote ?who) "not a proper list" ls))))

       (define (fill s i ls)
	 (if (null? ls)
	     s
	   (let ((c ($car ls)))
	     (unless (?valid-number-pred c)
	       (procedure-argument-violation (quote ?who) "not an octet" c))
	     ($bytevector-set! s i c)
	     (fill s ($fxadd1 i) (cdr ls)))))

       (let* ((n (race ls ls ls 0))
	      (s ($make-bytevector n)))
	 (fill s 0 ls))))))

(define-byte-list-to-bytevector u8-list->bytevector
  vu8 words.word-u8? $bytevector-set!)
(define-byte-list-to-bytevector s8-list->bytevector
  vs8 words.word-s8? $bytevector-set!)

;;; --------------------------------------------------------------------

(define-syntax define-word-list-to-bytevector
  (syntax-rules ()
    ((_ ?who ?tag ?valid-number-pred ?bytes-in-word ?bytevector-set!)
     (define* (?who ls)
       (define (%race h t ls n)
	 (cond ((pair? h)
		(let ((h ($cdr h)))
		  (if (pair? h)
		      (if (not (eq? h t))
			  (%race ($cdr h) ($cdr t) ls (+ n 2))
			(procedure-argument-violation (quote ?who) "circular list" ls))
		    (if (null? h)
			(+ n 1)
		      (procedure-argument-violation (quote ?who) "not a proper list" ls)))))
	       ((null? h)
		n)
	       (else
		(procedure-argument-violation (quote ?who) "not a proper list" ls))))

       (define (%fill s i ls)
	 (if (null? ls)
	     s
	   (let ((c ($car ls)))
	     (unless (?valid-number-pred c)
	       (procedure-argument-violation (quote ?who) "invalid element for requested bytevector type" c))
	     (?bytevector-set! s i c)
	     (%fill s ($fx+ ?bytes-in-word i) (cdr ls)))))

       (let* ((number-of-words (%race ls ls ls 0))
	      (bv.len	       (* ?bytes-in-word number-of-words)))
	 (unless (fixnum? bv.len)
	   (%implementation-violation (quote ?who) "resulting bytevector size must be a fixnum" (list bv.len)))
	 (%fill ($make-bytevector bv.len) 0 ls)))
     )))

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector u16l-list->bytevector
  'vu16l		       ;tag
  words.word-u16?	       ;to validate numbers
  2			       ;number of bytes in word
  $bytevector-u16l-set!) ;setter

(define-word-list-to-bytevector u16b-list->bytevector
  'vu16b		       ;tag
  words.word-u16?	       ;to validate numbers
  2			       ;number of bytes in word
  $bytevector-u16b-set!) ;setter

(define-word-list-to-bytevector u16n-list->bytevector
  'vu16n		       ;tag
  words.word-u16?	       ;to validate numbers
  2			       ;number of bytes in word
  $bytevector-u16n-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector s16l-list->bytevector
  'vs16l		       ;tag
  words.word-s16?	      ;to validate numbers
  2			       ;number of bytes in word
  $bytevector-s16l-set!) ;setter

(define-word-list-to-bytevector s16b-list->bytevector
  'vs16b		       ;tag
  words.word-s16?	       ;to validate numbers
  2			       ;number of bytes in word
  $bytevector-s16b-set!) ;setter

(define-word-list-to-bytevector s16n-list->bytevector
  'vs16n		       ;tag
  words.word-s16?	       ;to validate numbers
  2			       ;number of bytes in word
  $bytevector-s16n-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector u32l-list->bytevector
  'vu32l		       ;tag
  words.word-u32?	       ;to validate numbers
  4			       ;number of bytes in word
  $bytevector-u32l-set!) ;setter

(define-word-list-to-bytevector u32b-list->bytevector
  'vu32b		       ;tag
  words.word-u32?	       ;to validate numbers
  4			       ;number of bytes in word
  $bytevector-u32b-set!) ;setter

(define-word-list-to-bytevector u32n-list->bytevector
  'vu32n		       ;tag
  words.word-u32?	       ;to validate numbers
  4			       ;number of bytes in word
  $bytevector-u32n-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector s32l-list->bytevector
  'vs32l		       ;tag
  words.word-s32?	       ;to validate numbers
  4			       ;number of bytes in word
  $bytevector-s32l-set!) ;setter

(define-word-list-to-bytevector s32b-list->bytevector
  'vs32b		       ;tag
  words.word-s32?	       ;to validate numbers
  4			       ;number of bytes in word
  $bytevector-s32b-set!) ;setter

(define-word-list-to-bytevector s32n-list->bytevector
  'vs32n		       ;tag
  words.word-s32?	       ;to validate numbers
  4			       ;number of bytes in word
  $bytevector-s32n-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector u64l-list->bytevector
  'vu64l		       ;tag
  words.word-u64?	       ;to validate numbers
  8			       ;number of bytes in word
  $bytevector-u64l-set!) ;setter

(define-word-list-to-bytevector u64b-list->bytevector
  'vu64b		       ;tag
  words.word-u64?	       ;to validate numbers
  8			       ;number of bytes in word
  $bytevector-u64b-set!) ;setter

(define-word-list-to-bytevector u64n-list->bytevector
  'vu64n		       ;tag
  words.word-u64?	       ;to validate numbers
  8			       ;number of bytes in word
  $bytevector-u64n-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector s64l-list->bytevector
  'vs64l		       ;tag
  words.word-s64?	       ;to validate numbers
  8			       ;number of bytes in word
  $bytevector-s64l-set!) ;setter

(define-word-list-to-bytevector s64b-list->bytevector
  'vs64b		       ;tag
  words.word-s64?	       ;to validate numbers
  8			       ;number of bytes in word
  $bytevector-s64b-set!) ;setter

(define-word-list-to-bytevector s64n-list->bytevector
  'vs64n		       ;tag
  words.word-s64?	       ;to validate numbers
  8			       ;number of bytes in word
  $bytevector-s64n-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector f4l-list->bytevector
  'vf4l				    ;tag
  flonum?			    ;to validate numbers
  4				    ;number of bytes in word
  bytevector-flonum-single-le-set!) ;setter

(define-word-list-to-bytevector f4b-list->bytevector
  'vf4b				    ;tag
  flonum?			    ;to validate numbers
  4				    ;number of bytes in word
  bytevector-flonum-single-be-set!) ;setter

(define-word-list-to-bytevector f4n-list->bytevector
  'vf4n				    ;tag
  flonum?			    ;to validate numbers
  4				    ;number of bytes in word
  bytevector-flonum-single-ne-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector f8l-list->bytevector
  'vf8l				    ;tag
  flonum?			    ;to validate numbers
  8				    ;number of bytes in word
  bytevector-flonum-double-le-set!) ;setter

(define-word-list-to-bytevector f8b-list->bytevector
  'vf8b				    ;tag
  flonum?			    ;to validate numbers
  8				    ;number of bytes in word
  bytevector-flonum-double-be-set!) ;setter

(define-word-list-to-bytevector f8n-list->bytevector
  'vf8n				    ;tag
  flonum?			    ;to validate numbers
  8				    ;number of bytes in word
  bytevector-flonum-double-ne-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector c4l-list->bytevector
  'vc4l				     ;tag
  cflonum?			     ;to validate numbers
  8				     ;number of bytes in word
  bytevector-cflonum-single-le-set!) ;setter

(define-word-list-to-bytevector c4b-list->bytevector
  'vc4b				     ;tag
  cflonum?			     ;to validate numbers
  8				     ;number of bytes in word
  bytevector-cflonum-single-be-set!) ;setter

(define-word-list-to-bytevector c4n-list->bytevector
  'vc4n				     ;tag
  cflonum?			     ;to validate numbers
  8				     ;number of bytes in word
  bytevector-cflonum-single-ne-set!) ;setter

;;; --------------------------------------------------------------------

(define-word-list-to-bytevector c8l-list->bytevector
  'vc8l				     ;tag
  cflonum?			     ;to validate numbers
  16				     ;number of bytes in word
  bytevector-cflonum-double-le-set!) ;setter

(define-word-list-to-bytevector c8b-list->bytevector
  'vc8b				     ;tag
  cflonum?			     ;to validate numbers
  16				     ;number of bytes in word
  bytevector-cflonum-double-be-set!) ;setter

(define-word-list-to-bytevector c8n-list->bytevector
  'vc8n				     ;tag
  cflonum?			     ;to validate numbers
  16				     ;number of bytes in word
  bytevector-cflonum-double-ne-set!) ;setter


;;;; any integer list to bytevector functions

(define (%make-xint-list->bytevector who bv-set!)
  (define (race h t ls idx endianness size)
    (if (pair? h)
	(let ((h ($cdr h)) (a ($car h)))
	  (if (pair? h)
	      (if (not (eq? h t))
		  (let ((bv (race ($cdr h) ($cdr t) ls
				  ($fx+ idx ($fx+ size size))
				  endianness size)))
		    (bv-set! bv idx a endianness size who)
		    (bv-set! bv ($fx+ idx size) ($car h) endianness size who)
		    bv)
		(procedure-argument-violation who "circular list" ls))
	    (if (null? h)
		(let ((bv (make-bytevector ($fx+ idx size))))
		  (bv-set! bv idx a endianness size who)
		  bv)
	      (procedure-argument-violation who "not a proper list" ls))))
      (if (null? h)
	  (make-bytevector idx)
	(procedure-argument-violation who "not a proper list" ls))))
  (lambda (ls endianness size)
    (if (positive-fixnum? size)
	(race ls ls ls 0 endianness size)
      (procedure-argument-violation who "size must be a positive integer" size))))

(define uint-list->bytevector
  (%make-xint-list->bytevector 'uint-list->bytevector bytevector-uint-set!/who))

(define sint-list->bytevector
  (%make-xint-list->bytevector 'sint-list->bytevector bytevector-sint-set!/who))



#| end of library |#  )


(library (vicare system bytevectors)
  (export $make-bytevector $bytevector-length
	  $bytevector-u8-ref $bytevector-set!)
  (import (vicare))
  (define ($bytevector-set! dst.bv dst.index N)
    (if (<= 0 N)
	(bytevector-u8-set! dst.bv dst.index N)
      (bytevector-s8-set! dst.bv dst.index N)))
  (define $bytevector-u8-ref bytevector-u8-ref)
  (define $bytevector-length bytevector-length)
  (define $make-bytevector   make-bytevector))

;;; end of file
;;Local Variables:
;;eval: (put '%implementation-violation	'scheme-indent-function 1)
;;eval: (put 'case-endianness		'scheme-indent-function 1)
;;End:
