;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare
;;;Contents: utility functions for fixed-size words
;;;Date: Sun Oct 23, 2011
;;;
;;;Abstract
;;;
;;;	This library is both  installed and used when expanding Vicare's
;;;	own source code.  For this  reason it must export only: bindings
;;;	imported  by Vicare itself,  syntaxes whose  expansion reference
;;;	only bindings imported by Vicare itself.
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
(library (vicare words)
  (export
    ;; predicates
    word?
    word-u8?		word-s8?
    word-u16?		word-s16?
    word-u32?		word-s32?
    word-u64?		word-s64?

    ;; inclusive limits
    greatest-u8		least-u8
    greatest-s8		least-s8
    greatest-u16	least-u16
    greatest-s16	least-s16
    greatest-u32	least-u32
    greatest-s32	least-s32
    greatest-u64	least-u64
    greatest-s64	least-s64

    ;; exclusive limits
    greatest-u8*	least-u8*
    greatest-s8*	least-s8*
    greatest-u16*	least-u16*
    greatest-s16*	least-s16*
    greatest-u32*	least-u32*
    greatest-s32*	least-s32*
    greatest-u64*	least-u64*
    greatest-s64*	least-s64*)
  (import (ikarus)
    (ikarus system $fx)
    (ikarus system $bignums)
    (only (vicare syntactic-extensions)
	  define-inline
	  define-inline-constant
	  case-word-size))


;;;; constants

(define-inline-constant U8MAX		255)
(define-inline-constant U8MIN		0)
(define-inline-constant S8MAX		+127)
(define-inline-constant S8MIN		-128)

(define-inline-constant U16MAX		65535)		#;(- (expt 2 16) 1)
(define-inline-constant U16MIN		0)
(define-inline-constant S16MAX		+32767)		#;(- (expt 2 15) 1)
(define-inline-constant S16MIN		-32768)		#;(- (expt 2 15))

(define-inline-constant U32MAX		4294967295)	#;(- (expt 2 32) 1)
(define-inline-constant U32MIN		0)
(define-inline-constant S32MAX		+2147483647)	#;(- (expt 2 31) 1)
(define-inline-constant S32MIN		-2147483648)	#;(- (expt 2 31))

(define-inline-constant U64MAX		18446744073709551615)	#;(- (expt 2 64) 1)
(define-inline-constant U64MIN		0)
(define-inline-constant S64MAX		+9223372036854775807)	#;(- (expt 2 63) 1)
(define-inline-constant S64MIN		-9223372036854775808)	#;(- (expt 2 63))

;;; --------------------------------------------------------------------

(define-inline-constant U8MAX*		256)
(define-inline-constant U8MIN*		-1)
(define-inline-constant S8MAX*		+128)
(define-inline-constant S8MIN*		-129)

(define-inline-constant U16MAX*		65536)
(define-inline-constant U16MIN*		-1)
(define-inline-constant S16MAX*		+32768)
(define-inline-constant S16MIN*		-32769)

(define-inline-constant U32MAX*		4294967296)
(define-inline-constant U32MIN*		-1)
(define-inline-constant S32MAX*		+2147483648)
(define-inline-constant S32MIN*		-2147483649)

(define-inline-constant U64MAX*		18446744073709551616)
(define-inline-constant U64MIN*		-1)
(define-inline-constant S64MAX*		+9223372036854775808)
(define-inline-constant S64MIN*		-9223372036854775809)


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


;;;; limits

(define-inline (greatest-u8)		U8MAX)
(define-inline (greatest-s8)		S8MAX)
(define-inline (least-u8)		U8MIN)
(define-inline (least-s8)		S8MIN)

(define-inline (greatest-u16)		U16MAX)
(define-inline (greatest-s16)		S16MAX)
(define-inline (least-u16)		U16MIN)
(define-inline (least-s16)		S16MIN)

(define-inline (greatest-u32)		U32MAX)
(define-inline (greatest-s32)		S32MAX)
(define-inline (least-u32)		U32MIN)
(define-inline (least-s32)		S32MIN)

(define-inline (greatest-u64)		U64MAX)
(define-inline (greatest-s64)		S64MAX)
(define-inline (least-u64)		U64MIN)
(define-inline (least-s64)		S64MIN)

;;; --------------------------------------------------------------------

(define-inline (greatest-u8*)		U8MAX*)
(define-inline (greatest-s8*)		S8MAX*)
(define-inline (least-u8*)		U8MIN*)
(define-inline (least-s8*)		S8MIN*)

(define-inline (greatest-u16*)		U16MAX*)
(define-inline (greatest-s16*)		S16MAX*)
(define-inline (least-u16*)		U16MIN*)
(define-inline (least-s16*)		S16MIN*)

(define-inline (greatest-u32*)		U32MAX*)
(define-inline (greatest-s32*)		S32MAX*)
(define-inline (least-u32*)		U32MIN*)
(define-inline (least-s32*)		S32MIN*)

(define-inline (greatest-u64*)		U64MAX*)
(define-inline (greatest-s64*)		S64MAX*)
(define-inline (least-u64*)		U64MIN*)
(define-inline (least-s64*)		S64MIN*)


;;;; predicates

(define-inline (word? N)
  (or (fixnum? N) (bignum? N)))

(define-inline (word-u8? N)
  (and (fixnum? N)
       ($fx>= N U8MIN)
       ($fx<= N U8MAX)))

(define-inline (word-s8? N)
  (and (fixnum? N)
       ($fx>= N S8MIN)
       ($fx<= N S8MAX)))

;;; --------------------------------------------------------------------

(define-inline (word-u16? N)
  (and (fixnum? N)
       ($fx>= N 0)
       ($fx<= N U16MAX)))

(define-inline (word-s16? N)
  (and (fixnum? N)
       ($fx>= N S16MIN)
       ($fx<= N S16MAX)))

;;; --------------------------------------------------------------------

(define-inline (word-u32? N)
  (case-word-size
   ((32) (if (fixnum? N)
	     ($fx<= 0 N)
	   (and (bignum? N)
		($bignum-positive? N)
		($bnbn<= N U32MAX))))
   ((64) (and (fixnum? N)
	      ($fx>= N 0)
	      ($fx<= N U32MAX)))))


(define-inline (word-s32? N)
  (case-word-size
   ((32) (or (fixnum? N)
	     (and (bignum? N)
		  ($bnbn>= N S32MIN)
		  ($bnbn<= N S32MAX))))
   ((64) (and (fixnum? N)
	      ($fx>= N S32MIN)
	      ($fx<= N S32MAX)))))

;;; --------------------------------------------------------------------

(define-inline (word-u64? N)
  (if (fixnum? N)
      ($fx<= 0 N)
    (and (bignum? N)
	 ($bignum-positive? N)
	 ($bnbn<= N U64MAX))))

(define-inline (word-s64? N)
  (or (fixnum? N)
      (and (bignum? N)
	   ($bnbn>= N S64MIN)
	   ($bnbn<= N S64MAX))))


;;;; done

)

;;; end of file
