;;
;;Part of: Vicare Scheme
;;Contents: table of expand-time properties for strings core primitives
;;Date: Tue Dec 22, 2015
;;
;;Abstract
;;
;;
;;
;;Copyright (C) 2015 Marco Maggi <marco.maggi-ipsu@poste.it>
;;
;;This program is free  software: you can redistribute it and/or  modify it under the
;;terms  of  the  GNU General  Public  License  as  published  by the  Free  Software
;;Foundation, either version 3 of the License, or (at your option) any later version.
;;
;;This program  is distributed in the  hope that it  will be useful, but  WITHOUT ANY
;;WARRANTY; without  even the implied  warranty of  MERCHANTABILITY or FITNESS  FOR A
;;PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;;
;;You should have received  a copy of the GNU General Public  License along with this
;;program.  If not, see <http://www.gnu.org/licenses/>.
;;


;;;; core syntactic binding descriptors, typed safe core primitives: strings

(section

;;; predicates

(declare-type-predicate string? <string>)
(declare-string-predicate string-empty?			(replacements $string-empty?))
(declare-string-predicate ascii-encoded-string?		(replacements $ascii-encoded-string?))
(declare-string-predicate latin1-encoded-string?	(replacements $latin1-encoded-string?))
(declare-string-predicate octets-encoded-string?	(replacements $octets-encoded-string?))
(declare-string-predicate uri-encoded-string?		(replacements $uri-encoded-string?))
(declare-string-predicate percent-encoded-string?	(replacements $percent-encoded-string?))

;;; --------------------------------------------------------------------
;;; constructors

(declare-core-primitive string
    (safe)
  (signatures
   (()			=> (<string>))
   (<char>		=> (<string>)))
  ;;Not  foldable because  it must  return a  newly allocated  string, even  when the
  ;;return value is an empty string.
  (attributes
   (()			effect-free result-true)
   (_			effect-free result-true)))

(declare-core-primitive make-string
    (safe)
  (signatures
   ((<non-negative-fixnum>)		=> (<string>))
   ((<non-negative-fixnum> <char>)	=> (<string>)))
  ;;Not  foldable because  it must  return a  newly allocated  string, even  when the
  ;;return value is an empty string.
  (attributes
   ((0)			effect-free result-true)
   ((0 . _)		effect-free result-true)
   (_			effect-free result-true)))

(declare-core-primitive string->symbol
    (safe)
  (signatures
   ((<string>) => (<symbol>))))

;;; --------------------------------------------------------------------

(declare-core-primitive substring
    (safe)
  (signatures
   ((<string> <non-negative-fixnum> <non-negative-fixnum>)	=> (<string>)))
  ;;Not  foldable because  it must  return a  newly allocated  string, even  when the
  ;;return value is an empty string.
  (attributes
   ((_ _ _)				effect-free result-true)))

(declare-core-primitive string-copy
    (safe)
  (signatures
   ((<string>)		=> (<void>)))
  (attributes
   ((_)			effect-free result-true)))

(declare-core-primitive string-copy!
    (safe)
  (signatures
   ((<string> <non-negative-fixnum> <string> <non-negative-fixnum> <non-negative-fixnum>)	=> (<void>)))
  (attributes
   ((_ _)		result-true)))

(declare-core-primitive string-append
    (safe)
  (signatures
   (<string>			=> (<string>)))
  (attributes
   (_				effect-free result-true)))

(declare-core-primitive string-reverse-and-concatenate
    (safe)
  (signatures
   ((<string*>)			=> (<string>)))
  (attributes
   ((_)				effect-free result-true)))

;;; --------------------------------------------------------------------
;;; inspection

(declare-core-primitive string-length
    (safe)
  (signatures
   ((<string>)		=> (<non-negative-fixnum>)))
  (attributes
   ((_)			foldable effect-free result-true))
  (replacements $string-length))

(declare-core-primitive string-for-each
    (safe)
  (signatures
   ((<procedure> <string> . <string>)		=> (<void>)))
  (attributes
   ;;Not foldable and not effect-free because it applies an unknown procedure.
   ((_ _ . _)					result-true)))

;;; --------------------------------------------------------------------
;;; accessors and mutators

;;FIXME  This cannot  have $STRING-REF  as  replacement because  there is  no way  to
;;validate the index with respect to the string.  But in future another primitive can
;;be added that does not validate the  types, but validates the range.  (Marco Maggi;
;;Tue Oct 27, 2015)
(declare-core-primitive string-ref
    (safe)
  (signatures
   ((<string> <non-negative-fixnum>)	=> (<char>)))
  (attributes
   ((_ _)		foldable effect-free result-true)))

;;FIXME This  cannot have  $STRING-SET!  as  replacement because there  is no  way to
;;validate the index with respect to the string.  But in future another primitive can
;;be added that does not validate the  types, but validates the range.  (Marco Maggi;
;;Tue Oct 27, 2015)
(declare-core-primitive string-set!
    (safe)
  (signatures
   ((<string> <non-negative-fixnum> <char>)	=> (<void>)))
  (attributes
   ((_ _ _)		result-true)))

(declare-core-primitive string-fill!
    (safe)
  (signatures
   ((<string> <char>)	=> (<void>)))
  (attributes
   ((_ _)		result-true)))

;;; --------------------------------------------------------------------
;;; comparison

(declare-string-binary/multi-comparison string<=?)

(declare-string-binary/multi-comparison string<?)
(declare-string-binary/multi-comparison string=?)
(declare-string-binary/multi-comparison string>=?)
(declare-string-binary/multi-comparison string>?)

(declare-string-binary/multi-comparison string-ci<=?)
(declare-string-binary/multi-comparison string-ci<?)
(declare-string-binary/multi-comparison string-ci=?)
(declare-string-binary/multi-comparison string-ci>=?)
(declare-string-binary/multi-comparison string-ci>?)

;;; --------------------------------------------------------------------
;;; transformation

(declare-string-unary string-titlecase)
(declare-string-unary string-upcase)
(declare-string-unary string-downcase)
(declare-string-unary string-foldcase)

(declare-string-unary string-normalize-nfc)
(declare-string-unary string-normalize-nfd)
(declare-string-unary string-normalize-nfkc)
(declare-string-unary string-normalize-nfkd)

;;; --------------------------------------------------------------------
;;; conversion

(declare-core-primitive string->flonum
    (safe)
  (signatures
   ((<string>)		=> (<flonum>)))
  (attributes
   ((_)			foldable effect-free result-true)))

(declare-core-primitive string->number
    (safe)
  (signatures
   ;; ((<string>)               => ((or <number> <false>)))
   ;; ((<string> <non-negative-fixnum>)      => ((or <number> <false>)))
   ((<string>)		=> (<top>))
   ((<string> <non-negative-fixnum>)	=> (<top>)))
  (attributes
   ((_)			foldable effect-free)
   ((_ _)		foldable effect-free)))

(declare-core-primitive string->utf8
    (safe)
  (signatures
   ((<string>)			=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector at every application.
   ((_)				effect-free result-true)))

(declare-core-primitive string->utf16
    (safe)
  (signatures
   ((<string>)			=> (<bytevector>))
   ((<string> <symbol>)		=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector at every application.
   ((_ _)			effect-free result-true)))

(declare-core-primitive string->utf32
    (safe)
  (signatures
   ((<string>)			=> (<bytevector>))
   ((<string> <symbol>)		=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector at every application.
   ((_)				effect-free result-true)
   ((_ _)			effect-free result-true)))

(declare-core-primitive string->bytevector
    (safe)
  (signatures
   ((<string> <transcoder>)	=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector at every application.
   ((_ _)			effect-free result-true)))

(let-syntax
    ((declare-string->bytevector-conversion
      (syntax-rules ()
	((_ ?who)
	 (declare-core-primitive ?who
	     (safe)
	   (signatures
	    ((<string>)		=> (<bytevector>)))
	   (attributes
	    ;;Not  foldable  because  it  must  return  a  new  bytevector  at  every
	    ;;application.
	    ((_ )		effect-free result-true))))
	)))
  (declare-string->bytevector-conversion string->ascii)
  (declare-string->bytevector-conversion string->latin1)
  (declare-string->bytevector-conversion string->octets)
  (declare-string->bytevector-conversion string->percent-encoding)
  (declare-string->bytevector-conversion string->uri-encoding)
  (declare-string->bytevector-conversion string->utf16be)
  (declare-string->bytevector-conversion string->utf16le)
  (declare-string->bytevector-conversion string->utf16n)
  (declare-string->bytevector-conversion string-base64->bytevector)
  (declare-string->bytevector-conversion string-hex->bytevector)
  #| end of LET-SYNTAX |# )

;;;

(declare-core-primitive string->symbol
    (safe)
  (signatures
   ((<string>)			=> (<symbol>)))
  (attributes
   ((_)				foldable effect-free result-true)))

(declare-core-primitive string-or-symbol->string
    (safe)
  (signatures
   ((<string>)			=> (<string>))
   ((<symbol>)			=> (<string>)))
  (attributes
   ;;Not foldable because it must return a new string at every application.
   ((_)				effect-free result-true)))

(declare-core-primitive string-or-symbol->symbol
    (safe)
  (signatures
   ((<string>)			=> (<symbol>))
   ((<symbol>)			=> (<symbol>)))
  (attributes
   ((_)				foldable effect-free result-true)))

(declare-core-primitive string->keyword
    (safe)
  (signatures
   ((<string>)			=> (<keyword>)))
  (attributes
   ;;Not foldable because keywords cannot be serialised in fasl files.
   ((_)				effect-free result-true)))

(declare-core-primitive string->list
    (safe)
  (signatures
   ((<string>)			=> (<char*>)))
  (attributes
   ;;Not foldable because it must return a new list at every application.
   ((_)				effect-free result-true)))


;;;; core syntactic binding descriptors, typed unsafe core primitives: strings

;;; predicates

(declare-string-predicate $string-empty?)
(declare-string-predicate $octets-encoded-string?)
(declare-string-predicate $ascii-encoded-string?)
(declare-string-predicate $latin1-encoded-string?)
(declare-string-predicate $uri-encoded-string?)
(declare-string-predicate $percent-encoded-string?)

;;; --------------------------------------------------------------------
;;; constructors

(declare-core-primitive $make-string
    (unsafe)
  (signatures
   ((<non-negative-fixnum>)		=> (<string>)))
  (attributes
   ;;Not foldable because it must return a new string every time.
   ((_)			effect-free result-true)))

(declare-core-primitive $string
    (unsafe)
  (signatures
   (<char>		=> (<string>)))
  (attributes
   ;;Not foldable because it must return a new string every time.
   (_			effect-free result-true)))

(declare-core-primitive $string-concatenate
    (unsafe)
  (signatures
   ((<exact-integer> <string*>)	=> (<string>)))
  (attributes
   ((_ ())			foldable effect-free result-true)
   ;;Not foldable because it must return a new string every time.
   ((_ _)			effect-free result-true)))

(declare-core-primitive $string-reverse-and-concatenate
    (unsafe)
  (signatures
   ((<exact-integer> <string*>)	=> (<string>)))
  (attributes
   ((_ ())			foldable effect-free result-true)
   ;;Not foldable because it must return a new string every time.
   ((_ _)			effect-free result-true)))

;;; --------------------------------------------------------------------
;;; inspection

(declare-core-primitive $string-length
    (unsafe)
  (signatures
   ((<string>)		=> (<non-negative-fixnum>)))
  (attributes
   ((_)			foldable effect-free result-true)))

(declare-core-primitive $string-total-length
    (unsafe)
  (signatures
   ((<exact-integer> <string*>)	=> (<exact-integer>)))
  (attributes
   ((_)				foldable effect-free result-true)))

;;; --------------------------------------------------------------------
;;; accessors and mutators

(declare-core-primitive $string-ref
    (unsafe)
  (signatures
   ((<string> <non-negative-fixnum>)	=> (<char>)))
  (attributes
   ((_ _)		foldable effect-free result-true)))

(declare-core-primitive $string-set!
    (unsafe)
  (signatures
   ((<string> <non-negative-fixnum> <char>)	=> (<void>)))
  (attributes
   ((_ _ _)		result-true)))

;;; --------------------------------------------------------------------
;;; comparison

(declare-string-binary-comparison $string=)

;;; --------------------------------------------------------------------
;;; conversion

(declare-core-primitive $string->ascii
    (unsafe)
  (signatures
   ((<string>)		=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector every time.
   ((_)			effect-free result-true)))

(declare-core-primitive $string->octets
    (unsafe)
  (signatures
   ((<string>)		=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector every time.
   ((_)			effect-free result-true)))

(declare-core-primitive $string->latin1
    (unsafe)
  (signatures
   ((<string>)		=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector every time.
   ((_)			effect-free result-true)))

(declare-core-primitive $string-base64->bytevector
    (unsafe)
  (signatures
   ((<string>)		=> (<bytevector>)))
  (attributes
   ;;Not foldable because it must return a new bytevector every time.
   ((_)			effect-free result-true)))

(declare-core-primitive $string->symbol
    (unsafe)
  (signatures
   ((<string>)		=> (<symbol>)))
  (attributes
   ((_)			foldable effect-free result-true)))

;;; --------------------------------------------------------------------
;;; miscellaneous

(declare-core-primitive $interned-strings
    (unsafe)
  (signatures
   (()			=> (<vector>)))
  (attributes
   ((_)			effect-free result-true)))

/section)


;;;; core syntactic binding descriptors, typed OOP safe core primitives: strings

(section

(declare-core-primitive <string>-for-each
    (safe)
  (signatures
   ((<string> <procedure> . <string>)	=> (<void>))))

/section)

;;; end of file
;; Local Variables:
;; mode: vicare
;; coding: utf-8-unix
;; eval: (put 'declare-core-primitive		'scheme-indent-function 1)
;; End: