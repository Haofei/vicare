;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare
;;;Contents: unsafe operations
;;;Date: Sun Oct 23, 2011
;;;
;;;Abstract
;;;
;;;	This library is both  installed and used when expanding Vicare's
;;;	own source code.  For this  reason it must export only: bindings
;;;	imported  by Vicare itself,  syntaxes whose  expansion reference
;;;	only bindings imported by Vicare itself.
;;;
;;;	  In general: all the syntaxes must be used with arguments which
;;;	can be evaluated  multiple times, in practice it  is safe to use
;;;	the syntaxes only with identifiers or constant values.
;;;
;;;Copyright (C) 2011 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!r6rs
(library (vicare unsafe-operations)
  (export
    (rename ($fxzero?	fxzero?)
	    ($fxadd1	fxadd1)		;increment
	    ($fxsub1	fxsub1)		;decrement
	    ($fxsra	fxsra)		;shift right
	    ($fxsll	fxsll)		;shift left
	    ($fxlogor	fxlogor)	;inclusive logic OR
	    ($fxlogxor	fxlogxor)	;exlusive logic OR
	    ($fxlogand	fxand)		;logic AND
	    ($fx+	fx+)
	    ($fx-	fx-)
	    ($fx*	fx*)
	    ($fx<	fx<)
	    ($fx>	fx>)
	    ($fx>=	fx>=)
	    ($fx<=	fx<=)
	    ($fx=	fx=))

    (rename ($fxior	fxior)		;multiple arguments inclusive OR
	    ($fxxor	fxxor))		;multiple arguments exclusive OR

    (rename ($bignum-positive?		bignum-positive?)
	    ($bignum-byte-ref		bignum-byte-ref)
	    ($bignum-size		bignum-size))

    (rename ($bnbn=			bnbn=)
	    ($bnbn<			bnbn<)
	    ($bnbn>			bnbn>)
	    ($bnbn<=			bnbn<=)
	    ($bnbn>=			bnbn>=))

    (rename ($make-ratnum		make-ratnum)
	    ($ratnum-n			ratnum-n)
	    ($ratnum-d			ratnum-d))

    (rename ($make-flonum		make-flonum)
	    ($flonum-u8-ref		flonum-u8-ref)
	    ($flonum-set!		flonum-set!)
	    ($fixnum->flonum		fixnum->flonum)
	    ($fl+			fl+)
	    ($fl-			fl-)
	    ($fl*			fl*)
	    ($fl/			fl/)
	    ($fl=			fl=)
	    ($fl<			fl<)
	    ($fl>			fl>)
	    ($fl<=			fl<=)
	    ($fl>=			fl>=)
	    ($flonum-sbe		flonum-sbe))

    (rename ($make-cflonum		make-cflonum)
	    ($cflonum-real		cflonum-real)
	    ($cflonum-imag		cflonum-imag)
	    ($make-compnum		make-compnum)
	    ($compnum-real		compnum-real)
	    ($compnum-imag		compnum-imag))

    (rename ($make-bytevector		make-bytevector)
	    ($bytevector-length		bytevector-length)
	    ($bytevector-u8-ref		bytevector-u8-ref)
	    ($bytevector-s8-ref		bytevector-s8-ref)
	    ($bytevector-u8-set!	bytevector-u8-set!)
	    ($bytevector-s8-set!	bytevector-s8-set!)
	    ($bytevector-ieee-double-native-ref		bytevector-ieee-double-native-ref)
	    ($bytevector-ieee-double-nonnative-ref	bytevector-ieee-double-nonnative-ref)
	    ($bytevector-ieee-double-native-set!	bytevector-ieee-double-native-set!)
	    ($bytevector-ieee-single-native-ref		bytevector-ieee-single-native-ref)
	    ($bytevector-ieee-single-native-set!	bytevector-ieee-single-native-set!)
	    ($bytevector-ieee-single-nonnative-ref	bytevector-ieee-single-nonnative-ref)
	    ($bytevector-ieee-double-nonnative-set!	bytevector-ieee-double-nonnative-set!)
	    ($bytevector-ieee-single-nonnative-set!	bytevector-ieee-single-nonnative-set!))

    (rename ($bytevector-u16b-ref	bytevector-u16b-ref)
	    ($bytevector-u16b-set!	bytevector-u16b-set!)
	    ($bytevector-u16l-ref	bytevector-u16l-ref)
	    ($bytevector-u16l-set!	bytevector-u16l-set!)
	    ($bytevector-s16b-ref	bytevector-s16b-ref)
	    ($bytevector-s16b-set!	bytevector-s16b-set!)
	    ($bytevector-s16l-ref	bytevector-s16l-ref)
	    ($bytevector-s16l-set!	bytevector-s16l-set!)
	    ($bytevector-u16n-ref	bytevector-u16n-ref)
	    ($bytevector-u16n-set!	bytevector-u16n-set!)
	    ($bytevector-s16n-ref	bytevector-s16n-ref)
	    ($bytevector-s16n-set!	bytevector-s16n-set!)

	    ($bytevector-u32b-ref	bytevector-u32b-ref)
	    ($bytevector-u32b-set!	bytevector-u32b-set!)
	    ($bytevector-u32l-ref	bytevector-u32l-ref)
	    ($bytevector-u32l-set!	bytevector-u32l-set!)
	    ($bytevector-s32b-ref	bytevector-s32b-ref)
	    ($bytevector-s32b-set!	bytevector-s32b-set!)
	    ($bytevector-s32l-ref	bytevector-s32l-ref)
	    ($bytevector-s32l-set!	bytevector-s32l-set!)
	    ($bytevector-u32n-ref	bytevector-u32n-ref)
	    ($bytevector-u32n-set!	bytevector-u32n-set!)
	    ($bytevector-s32n-ref	bytevector-s32n-ref)
	    ($bytevector-s32n-set!	bytevector-s32n-set!)

	    ($bytevector-u64b-ref	bytevector-u64b-ref)
	    ($bytevector-u64b-set!	bytevector-u64b-set!)
	    ($bytevector-u64l-ref	bytevector-u64l-ref)
	    ($bytevector-u64l-set!	bytevector-u64l-set!)
	    ($bytevector-s64b-ref	bytevector-s64b-ref)
	    ($bytevector-s64b-set!	bytevector-s64b-set!)
	    ($bytevector-s64l-ref	bytevector-s64l-ref)
	    ($bytevector-s64l-set!	bytevector-s64l-set!)
	    ($bytevector-u64n-ref	bytevector-u64n-ref)
	    ($bytevector-u64n-set!	bytevector-u64n-set!)
	    ($bytevector-s64n-ref	bytevector-s64n-ref)
	    ($bytevector-s64n-set!	bytevector-s64n-set!)

	    ($bytevector-fill!		bytevector-fill!)
	    ($bytevector-copy!		bytevector-copy!))

    (rename ($car		car)
	    ($cdr		cdr)
	    ($set-car!		set-car!)
	    ($set-cdr!		set-cdr!))

    (rename ($make-vector	make-vector)
	    ($vector-length	vector-length)
	    ($vector-ref	vector-ref)
	    ($vector-set!	vector-set!))

    (rename ($char=		char=)
	    ($char<		char<)
	    ($char>		char>)
	    ($char>=		char>=)
	    ($char<=		char<=)
	    ($char->fixnum	char->fixnum)
	    ($fixnum->char	fixnum->char))

    (rename ($make-string	make-string)
	    ($string-length	string-length)
	    ($string-ref	string-ref)
	    ($string-set!	string-set!))

    (rename ($string-copy!	string-copy!)
	    ($string-fill!	string-fill!)
	    ($substring		substring))
    )
  (import (ikarus)
    (ikarus system $fx)
    (ikarus system $bignums)
    (ikarus system $ratnums)
    (ikarus system $flonums)
    (ikarus system $compnums)
    (ikarus system $pairs)
    (ikarus system $vectors)
    (rename (ikarus system $bytevectors)
	    ($bytevector-set!	$bytevector-set!)
	    ($bytevector-set!	$bytevector-u8-set!)
	    ($bytevector-set!	$bytevector-s8-set!))
    (ikarus system $chars)
    (ikarus system $strings)
    (only (vicare syntactic-extensions)
	  define-inline)
    (for (prefix (vicare installation-configuration)
		 config.)
	 expand))


;;;; fixnums

(define-syntax $fxior
  (syntax-rules ()
    ((_ ?op1)
     ?op1)
    ((_ ?op1 ?op2)
     ($fxlogor ?op1 ?op2))
    ((_ ?op1 ?op2 . ?ops)
     ($fxlogor ?op1 ($fxior ?op2 . ?ops)))))

(define-syntax $fxxor
  (syntax-rules ()
    ((_ ?op1)
     ?op1)
    ((_ ?op1 ?op2)
     ($fxlogxor ?op1 ?op2))
    ((_ ?op1 ?op2 . ?ops)
     ($fxlogxor ?op1 ($fxxor ?op2 . ?ops)))))


;;;; bignums

(define-inline (%bnbncmp X Y fxcmp)
  (fxcmp (foreign-call "ikrt_bnbncomp" X Y) 0))

(define-inline ($bnbn= X Y)
  (%bnbncmp X Y $fx=))

(define-inline ($bnbn< X Y)
  (%bnbncmp X Y $fx<))

(define-inline ($bnbn> X Y)
  (%bnbncmp X Y $fx>))

(define-inline ($bnbn<= X Y)
  (%bnbncmp X Y $fx<=))

(define-inline ($bnbn>= X Y)
  (%bnbncmp X Y $fx>=))


;;;; heterogeneous and high-level operations

(define-inline (fx+fx X Y)
  (foreign-call "ikrt_fxfxplus" X Y))

(define-inline (fx+bn X Y)
  (foreign-call "ikrt_fxbnplus" X Y))

(define-inline (bn+bn X Y)
  (foreign-call "ikrt_bnbnplus" X Y))

;;; --------------------------------------------------------------------

(define-inline (fx-fx X Y)
  (foreign-call "ikrt_fxfxminus" X Y))

(define-inline (fx-bn X Y)
  (foreign-call "ikrt_fxbnminus" X Y))

(define-inline (bn-bn X Y)
  (foreign-call "ikrt_bnbnminus" X Y))

;;; --------------------------------------------------------------------

(define-inline (fx-and-bn X Y)
  (foreign-call "ikrt_fxbnlogand" X Y))

(define-inline (bn-and-bn X Y)
  (foreign-call "ikrt_bnbnlogand" X Y))

(define-inline (fx-ior-bn X Y)
  (foreign-call "ikrt_fxbnlogor" X Y))

(define-inline (bn-ior-bn X Y)
  (foreign-call "ikrt_bnbnlogor" X Y))


;;;; endianness handling
;;
;;About endianness, according to R6RS:
;;
;;   Endianness  describes  the encoding  of  exact  integer objects  as
;;   several contiguous bytes in a bytevector.
;;
;;   The little-endian encoding places  the least significant byte of an
;;   integer first,  with the other bytes following  in increasing order
;;   of significance.
;;
;;   The  big-endian encoding  places the  most significant  byte  of an
;;   integer first,  with the other bytes following  in decreasing order
;;   of significance.
;;


;;;; unsafe 16-bit setters and getters
;;
;;            |            | lowest memory | highest memory
;; endianness |    word    | location      | location
;; -----------+------------+---------------+--------------
;;   little   |   #xHHLL   |     LL        |     HH
;;    big     |   #xHHLL   |     HH        |      LL
;;
;;
;;NOTE  Remember that  $BYTEVECTOR-SET! takes  care of  storing in
;;memory only the least significant byte of its value argument.
;;

(define-inline ($bytevector-u16l-ref bv index)
  ($fxlogor
   ;; highest memory location -> most significant byte
   ($fxsll ($bytevector-u8-ref bv ($fxadd1 index)) 8)
   ;; lowest memory location -> least significant byte
   ($bytevector-u8-ref bv index)))

(define-inline ($bytevector-u16l-set! bv index word)
  ;; lowest memory location -> least significant byte
  ($bytevector-set! bv index word)
  ;; highest memory location -> most significant byte
  ($bytevector-set! bv ($fxadd1 index) (fxsra word 8)))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-u16b-ref bv index)
  ($fxlogor
   ;; lowest memory location -> most significant byte
   ($fxsll ($bytevector-u8-ref bv index) 8)
   ;; highest memory location -> least significant byte
   ($bytevector-u8-ref bv ($fxadd1 index))))

(define-inline ($bytevector-u16b-set! bv index word)
  ;; lowest memory location -> most significant byte
  ($bytevector-set! bv index ($fxsra word 8))
  ;; highest memory location -> least significant byte
  ($bytevector-set! bv ($fxadd1 index) word))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-s16l-ref bv index)
  ($fxlogor
   ;; highest memory location -> most significant byte
   ($fxsll ($bytevector-s8-ref bv ($fxadd1 index)) 8)
   ;; lowest memory location -> least significant byte
   ($bytevector-u8-ref bv index)))

(define-inline ($bytevector-s16l-set! bv index word)
  ;; lowest memory location -> least significant byte
  ($bytevector-set! bv index word)
  ;; highest memory location -> most significant byte
  ($bytevector-set! bv ($fxadd1 index) (fxsra word 8)))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-s16b-ref bv index)
  ($fxlogor
   ;; lowest memory location -> most significant byte
   ($fxsll ($bytevector-s8-ref bv index) 8)
   ;; highest memory location -> least significant byte
   ($bytevector-u8-ref bv ($fxadd1 index))))

(define-inline ($bytevector-s16b-set! bv index word)
  ;; lowest memory location -> most significant byte
  ($bytevector-set! bv index ($fxsra word 8))
  ;; highest memory location -> least significant byte
  ($bytevector-set! bv ($fxadd1 index) word))

;;; --------------------------------------------------------------------

(define-syntax $bytevector-u16n-ref
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-u16b-ref))
    ((little)
     (identifier-syntax $bytevector-u16l-ref))))

(define-syntax $bytevector-u16n-set!
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-u16b-set!))
    ((little)
     (identifier-syntax $bytevector-u16l-set!))))

;;; --------------------------------------------------------------------

(define-syntax $bytevector-s16n-ref
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-s16b-ref))
    ((little)
     (identifier-syntax $bytevector-s16l-ref))))

(define-syntax $bytevector-s16n-set!
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-s16b-set!))
    ((little)
     (identifier-syntax $bytevector-s16l-set!))))


;;;; unsafe 32-bit setters and getters
;;
;;                           lowest memory ------------> highest memory
;; endianness |    word    | 1st byte | 2nd byte | 3rd byte | 4th byte |
;; -----------+------------+----------+----------+----------+-----------
;;   little   | #xAABBCCDD |   DD     |    CC    |    BB    |    AA
;;    big     | #xAABBCCDD |   AA     |    BB    |    CC    |    DD
;; bit offset |            |    0     |     8    |    16    |    24
;;
;;NOTE  Remember that  $BYTEVECTOR-SET! takes  care of  storing in
;;memory only the least significant byte of its value argument.
;;

(define-inline ($bytevector-u32b-ref bv index)
  (+ (sll ($bytevector-u8-ref bv index) 24)
     ($fxior
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index)) 16)
      ($fxsll ($bytevector-u8-ref bv ($fx+ index 2))  8)
      ($bytevector-u8-ref bv ($fx+ index 3)))))

(define-inline ($bytevector-u32b-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv index ($fxsra b 8))
    ($bytevector-set! bv ($fxadd1 index) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fx+ index 2) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 3) b)))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-u32l-ref bv index)
  (+ (sll ($bytevector-u8-ref bv ($fx+ index 3)) 24)
     ($fxior
      ($fxsll ($bytevector-u8-ref bv ($fx+ index 2)) 16)
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index)) 8)
      ($bytevector-u8-ref bv index))))

(define-inline ($bytevector-u32l-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv ($fx+ index 3) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 2) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fxadd1 index) ($fxsra b 8))
    ($bytevector-set! bv index b)))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-s32b-ref bv index)
  (+ (sll ($bytevector-s8-ref bv index) 24)
     ($fxior
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index))   16)
      ($fxsll ($bytevector-u8-ref bv ($fx+    index 2))  8)
      ($bytevector-u8-ref bv ($fx+ index 3)))))

(define-inline ($bytevector-s32b-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv index ($fxsra b 8))
    ($bytevector-set! bv ($fxadd1 index) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fx+ index 2) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 3) b)))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-s32l-ref bv index)
  (+ (sll ($bytevector-s8-ref bv ($fx+ index 3)) 24)
     ($fxior
      ($fxsll ($bytevector-u8-ref bv ($fx+    index 2)) 16)
      ($fxsll ($bytevector-u8-ref bv ($fxadd1 index))    8)
      ($bytevector-u8-ref bv index))))

(define-inline ($bytevector-s32l-set! bv index word)
  (let ((b (sra word 16)))
    ($bytevector-set! bv ($fx+ index 3) ($fxsra b 8))
    ($bytevector-set! bv ($fx+ index 2) b))
  (let ((b (bitwise-and word #xFFFF)))
    ($bytevector-set! bv ($fxadd1 index) ($fxsra b 8))
    ($bytevector-set! bv index b)))

;;; --------------------------------------------------------------------

(define-syntax $bytevector-u32n-ref
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-u32b-ref))
    ((little)
     (identifier-syntax $bytevector-u32l-ref))))

(define-syntax $bytevector-u32n-set!
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-u32b-set!))
    ((little)
     (identifier-syntax $bytevector-u32l-set!))))

;;; --------------------------------------------------------------------

(define-syntax $bytevector-s32n-ref
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-s32b-ref))
    ((little)
     (identifier-syntax $bytevector-s32l-ref))))

(define-syntax $bytevector-s32n-set!
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-s32b-set!))
    ((little)
     (identifier-syntax $bytevector-s32l-set!))))


;;;; unsafe 64-bit setters and getters
;;
;;                                      lowest memory ------------> highest memory
;; endianness |         word        | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th | 8th |
;; -----------+---------------------+-----+-----+-----+-----+-----+-----+-----+-----|
;;   little   | #xAABBCCDD EEFFGGHH | HH  | GG  | FF  | EE  | DD  | CC  | BB  | AA
;;    big     | #xAABBCCDD EEFFGGHH | AA  | BB  | CC  | DD  | EE  | FF  | GG  | HH
;; bit offset |                     |  0  |  8  | 16  | 24  | 32  | 40  | 48  | 56
;;
;;NOTE  Remember that  $BYTEVECTOR-SET! takes  care of  storing in
;;memory only the least significant byte of its value argument.
;;

(define-inline ($bytevector-u64b-ref ?bv ?index)
  (let ((index ?index))
    (let next-byte ((bv     ?bv)
		    (index  index)
		    (end    ($fx+ index 7))
		    (word   0))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxadd1 index) end (sll word 8)))))))

(define-inline ($bytevector-u64b-set! ?bv ?index ?word)
  (let ((index  ?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  ($fx+ 7 index))
		    (end    index)
		    (word   word))
      ($bytevector-u8-set! bv index (bitwise-and word #xFF))
      (unless ($fx= index end)
	(next-byte bv ($fxsub1 index) end (sra word 8))))))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-u64l-ref ?bv ?end)
  (let ((end ?end))
    (let next-byte ((bv     ?bv)
		    (index  ($fx+ 7 end))
		    (word   0))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxsub1 index) (sll word 8)))))))

(define-inline ($bytevector-u64l-set! ?bv ?index ?word)
  (let ((index	?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  index)
		    (end    ($fx+ 7 index))
		    (word   word))
      ($bytevector-u8-set! bv index (bitwise-and word #xFF))
      (unless ($fx= index end)
	(next-byte bv ($fxadd1 index) end (sra word 8))))))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-s64b-ref ?bv ?index)
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

(define-inline ($bytevector-s64b-set! ?bv ?index ?word)
  (let ((index	?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  ($fx+ 7 index))
		    (end    index)
		    (word   word))
      (if ($fx= index end)
	  ($bytevector-s8-set! bv index (bitwise-and word #xFF))
	(begin
	  ($bytevector-u8-set! bv index (bitwise-and word #xFF))
	  (next-byte bv ($fxsub1 index) end (sra word 8)))))))

;;; --------------------------------------------------------------------

(define-inline ($bytevector-s64l-ref ?bv ?end)
  (let ((bv	?bv)
	(end	?end))
    (let next-byte ((bv     bv)
		    (index  ($fx+ 6 end))
		    (word   (sll ($bytevector-s8-ref bv ($fx+ 7 end)) 8)))
      (let ((word (+ word ($bytevector-u8-ref bv index))))
	(if ($fx= index end)
	    word
	  (next-byte bv ($fxsub1 index) (sll word 8)))))))

(define-inline ($bytevector-s64l-set! ?bv ?index ?word)
  (let ((index	?index)
	(word	?word))
    (let next-byte ((bv     ?bv)
		    (index  index)
		    (end    ($fx+ 7 index))
		    (word   word))
      (if ($fx= index end)
	  ($bytevector-s8-set! bv index (bitwise-and word #xFF))
	(begin
	  ($bytevector-u8-set! bv index (bitwise-and word #xFF))
	  (next-byte bv ($fxadd1 index) end (sra word 8)))))))

;;; --------------------------------------------------------------------

(define-syntax $bytevector-u64n-ref
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-u64b-ref))
    ((little)
     (identifier-syntax $bytevector-u64l-ref))))

(define-syntax $bytevector-u64n-set!
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-u64b-set!))
    ((little)
     (identifier-syntax $bytevector-u64l-set!))))

;;; --------------------------------------------------------------------

(define-syntax $bytevector-s64n-ref
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-s64b-ref))
    ((little)
     (identifier-syntax $bytevector-s64l-ref))))

(define-syntax $bytevector-s64n-set!
  (case config.platform-endianness
    ((big)
     (identifier-syntax $bytevector-s64b-set!))
    ((little)
     (identifier-syntax $bytevector-s64l-set!))))


;;;; miscellaneous bytevector operations

(define-inline ($bytevector-fill! ?bv ?index ?end ?fill)
  (let loop ((bv ?bv) (index ?index) (end ?end) (fill ?fill))
    (if ($fx= index end)
	bv
      (begin
	($bytevector-u8-set! bv index fill)
	(loop bv ($fxadd1 index) end fill)))))

(define-inline ($bytevector-copy! ?src.str ?src.start ?src.end
				  ?dst.str ?dst.start ?dst.end)
  (let loop ((src.str ?src.str) (src.start ?src.start) (src.end ?src.end)
	     (dst.str ?dst.str) (dst.start ?dst.start) (dst.end ?dst.end))
    (if ($fx= src.start dst.start)
	dst.str
      (begin
       ($bytevector-set! dst.str dst.start ($bytevector-u8-ref src.str src.start))
       (loop src.str ($fxadd1 src.start) src.end
	     dst.str ($fxadd1 dst.start) dst.end)))))


;;;; miscellaneous string operations

(define-inline ($string-fill! ?str ?index ?end ?fill)
  (let loop ((str ?str) (index ?index) (end ?end) (fill ?fill))
    (if ($fx= index end)
	str
      (begin
	($string-set! str index fill)
	(loop str ($fxadd1 index) end fill)))))

(define-inline ($string-copy! ?src.str ?src.start ?src.end
			      ?dst.str ?dst.start ?dst.end)
  (let loop ((src.str ?src.str) (src.start ?src.start) (src.end ?src.end)
	     (dst.str ?dst.str) (dst.start ?dst.start) (dst.end ?dst.end))
    (if ($fx= src.start dst.start)
	dst.str
      (begin
       ($string-set! dst.str dst.start ($string-ref src.str src.start))
       (loop src.str ($fxadd1 src.start) src.end
	     dst.str ($fxadd1 dst.start) dst.end)))))

(define-inline ($substring ?str ?start ?end)
  (let ((dst.len ($fx- ?end ?start)))
    (if ($fx< 0 dst.len)
	(let ((dst.str ($make-string dst.len)))
	  ($string-copy! ?str ?start ?end dst.str 0 dst.len)
	  dst.str)
      "")))


;;;; done

)

;;; end of file
