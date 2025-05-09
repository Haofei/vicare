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


#!vicare
(library (ikarus.symbols)
  (export
    ;; R6RS functions
    symbol->string

    ;; generating symbols
    gensym gensym? gensym->unique-string gensym-prefix
    gensym-count print-gensym

    ;; predicates
    list-of-symbols?

    ;;comparison
    symbol=?			symbol!=?
    symbol<?			symbol<=?
    symbol>?			symbol>=?

    symbol-max			symbol-min

    ;; internal functions
    $unintern-gensym

    ;; object properties
    getprop putprop remprop property-list

    ;; conversion functions
    string-or-symbol->string
    string-or-symbol->symbol

    ;; unsafe operations
    $symbol->string
    $getprop $putprop $remprop $property-list

    $symbol=			$symbol!=
    $symbol<			$symbol<=
    $symbol>			$symbol>=
    $symbol-max			$symbol-min

    ;; internals handling of symbols and special symbols
    unbound-object	unbound-object?
    top-level-value	top-level-bound?	set-top-level-value!
    symbol-value	symbol-bound?		set-symbol-value!
    reset-symbol-proc!)
  (import (except (vicare)
		  ;; R6RS functions
		  symbol->string

		  ;; generating symbols
		  gensym gensym? gensym->unique-string gensym-prefix
		  gensym-count print-gensym

		  ;; predicates
		  list-of-symbols?

		  ;; comparison
		  symbol=?			symbol!=?
		  symbol<?			symbol<=?
		  symbol>?			symbol>=?
		  symbol-max			symbol-min

		  ;; object properties
		  getprop putprop remprop property-list

		  ;; conversion functions
		  string-or-symbol->string
		  string-or-symbol->symbol

		  ;; internals handling of symbols and special symbols
		  unbound-object	unbound-object?
		  symbol-value		symbol-bound?		set-symbol-value!
		  reset-symbol-proc!

		  top-level-value	top-level-bound?	set-top-level-value!

		  ;; internal functions
		  $unintern-gensym)
    ;;NOTE This is a delicate library defining some low level feature like the system
    ;;gensyms.   Let's try  to import  only  the system  libraries, without  creating
    ;;external dependencies.  (Marco Maggi; Mon Apr 14, 2014)
    (vicare system $fx)
    (vicare system $pairs)
    (vicare system $strings)
    (only (vicare system $numerics)
	  $add1-integer)
    (except (vicare system $symbols)
	    $symbol->string
	    $unintern-gensym
	    $getprop
	    $putprop
	    $remprop
	    $property-list
	    $symbol=			$symbol!=
	    $symbol<			$symbol<=
	    $symbol>			$symbol>=
	    $symbol-max			$symbol-min)
    (only (vicare language-extensions syntaxes)
	  define-list-of-type-predicate
	  define-min/max-comparison
	  define-equality/sorting-predicate
	  define-inequality-predicate))


;;;; helpers

(define (string-or-symbol? obj)
  (or (string? obj)
      (symbol? obj)))


(case-define* gensym
  (()
   ;;This form generates a non-interned symbol  with unset strings; it is the fastest
   ;;way of  generating gensyms.  The pretty  string and unique string  are generated
   ;;only if explicitly requested.
   ($make-symbol #f))
  ((s)
   (cond ((string? s)
	  ($make-symbol s))
	 ((symbol? s)
	  ($make-symbol ($symbol-string s)))
	 (else
	  (procedure-argument-violation __who__
	    "expected string or symbol as argument" s)))))

(define (gensym? x)
  (and (symbol? x)
       (let ((s ($symbol-unique-string x)))
	 ;;The  USTRING  field  of  gensyms  is   initialised  to  the  fixnum  0  by
	 ;;$MAKE-SYMBOL.  A non-gensym symbol has false in this field.
	 (and s #t))))

(define* ($unintern-gensym {x symbol?})
  (foreign-call "ikrt_unintern_gensym" x)
  (values))

(define* (gensym->unique-string {x symbol?})
  (let ((us ($symbol-unique-string x)))
    ;;The USTRING field of gensyms is initialised to the fixnum 0 by $MAKE-SYMBOL.  A
    ;;non-gensym symbol has false in this field.
    (cond ((string? us)
	   us)
	  ((not us)
	   (procedure-argument-violation __who__
	     "expected generated symbol as argument" x))
	  (else
	   (let loop ((x x))
	     (let ((id (uuid)))
	       ($set-symbol-unique-string! x id)
	       (if (foreign-call "ikrt_intern_gensym" x)
		   id
		 (loop x))))))))

(define gensym-prefix
  (make-parameter
      "g"
    (lambda (x)
      (if (string? x)
	  x
	(procedure-argument-violation 'gensym-prefix "not a string" x)))))

(define gensym-count
  (make-parameter
      0
    (lambda (x)
      (if (and (fixnum? x) ($fx>= x 0))
	  x
	(procedure-argument-violation 'gensym-count "not a valid count" x)))))

(define print-gensym
  (make-parameter
      #t
    (lambda (x)
      (if (or (boolean? x) (eq? x 'pretty))
	  x
	(procedure-argument-violation 'print-gensym "not in #t|#f|pretty" x)))))


;;;; predicates

(define-list-of-type-predicate list-of-symbols? symbol?)


;;;; comparison

(define-equality/sorting-predicate symbol=?	$symbol=	symbol?)
(define-equality/sorting-predicate symbol<?	$symbol<	symbol?)
(define-equality/sorting-predicate symbol<=?	$symbol<=	symbol?)
(define-equality/sorting-predicate symbol>?	$symbol>	symbol?)
(define-equality/sorting-predicate symbol>=?	$symbol>=	symbol?)
(define-inequality-predicate       symbol!=?	$symbol!=	symbol?)

(define ($symbol= sym1 sym2)
  ($string= ($symbol->string sym1)
	    ($symbol->string sym2)))

(define ($symbol!= sym1 sym2)
  ($string!= ($symbol->string sym1)
	     ($symbol->string sym2)))

(define ($symbol< sym1 sym2)
  ($string< ($symbol->string sym1)
	    ($symbol->string sym2)))

(define ($symbol> sym1 sym2)
  ($string> ($symbol->string sym1)
	    ($symbol->string sym2)))

(define ($symbol<= sym1 sym2)
  ($string<= ($symbol->string sym1)
	     ($symbol->string sym2)))

(define ($symbol>= sym1 sym2)
  ($string>= ($symbol->string sym1)
	     ($symbol->string sym2)))


;;;; min max

(define-min/max-comparison symbol-max $symbol-max symbol?)
(define-min/max-comparison symbol-min $symbol-min symbol?)

(define ($symbol-min str1 str2)
  (if ($symbol< str1 str2) str1 str2))

(define ($symbol-max str1 str2)
  (if ($symbol< str1 str2) str2 str1))


(define (unbound-object? x)
  ($unbound-object? x))

(define (unbound-object)
  (foreign-call "ikrt_unbound_object"))

(define* (top-level-value {loc symbol?})
  ;;Expect the argument to be a loc gensym associated to a binding; extract the value
  ;;from the slot  "value" of the symbol object  and return it.  If the  value is the
  ;;unbound object: raise an exception.
  ;;
  ;;NOTE This primitive function is also implemented as primitive operation!!!
  ;;
  ;;This function has a specific purpose: to  retrieve the value of a binding defined
  ;;in  a  previously   evaluated  expression  in  the  context   of  an  interaction
  ;;environment; we  have to  know the  internals of the  expander to  understand it.
  ;;Let's say we are evaluating expressions at the REPL; first we do:
  ;;
  ;;   vicare> (define a 1)
  ;;
  ;;the expander creates a new top level binding in the interaction environment; such
  ;;interaction environment bindings are special in that they have a single gensym to
  ;;serve both as lex  gensym and loc gensym; the expander  transforms the input form
  ;;into the core language form:
  ;;
  ;;   (set! lex.a 1)
  ;;
  ;;where  "lex.a" is  both the  lex  gensym and  the  loc gensym  associated to  the
  ;;binding; the compiler transforms the core language expression into:
  ;;
  ;;   ($init-symbol-value! lex.a 1)
  ;;
  ;;which, compiled and evaluated,  will store the value in the  "value" field of the
  ;;gensym "lex.a".
  ;;
  ;;Later we do:
  ;;
  ;;   vicare> a
  ;;
  ;;the expander finds the binding in  the interaction environment and transforms the
  ;;variable reference into the core language expression:
  ;;
  ;;   lex.a
  ;;
  ;;the compiler then transforms the core language variable reference into:
  ;;
  ;;   (top-level-value 'lex.a)
  ;;
  ;;which compiled and evaluated will return the binding's value.
  ;;
  ;;The same  processing happens when we  evaluate multiple expressions with  EVAL in
  ;;the context of the same interaction environment.
  ;;
  (receive-and-return (v)
      ($symbol-value loc)
    (when ($unbound-object? v)
      (raise
       (condition (make-undefined-violation)
		  (make-who-condition 'top-level-value)
		  (make-message-condition "unbound variable")
		  (make-irritants-condition (list (string->symbol (symbol->string loc)))))))))

(define* (set-top-level-value! {loc symbol?} v)
  ;;This function can be used to set a new  object in a loc gensym, so that it can be
  ;;later retrieved by  TOP-LEVEL-VALUE.  This function exists  for completeness, but
  ;;it is not really used by the compiler.
  ;;
  ($set-symbol-value! loc v))

(define* (top-level-bound? {x symbol?})
  (not ($unbound-object? ($symbol-value x))))

(define* (symbol-value {x symbol?})
  (receive-and-return (obj)
      ($symbol-value x)
    (when ($unbound-object? obj)
      (procedure-argument-violation __who__
	"expected bound symbol as argument" x))))

(define* (symbol-bound? {x symbol?})
  (not ($unbound-object? ($symbol-value x))))

(define* (set-symbol-value! {x symbol?} v)
  ($set-symbol-value! x v)
  ;;If  V is  not a  procedure: raise  an exception  if the  client code
  ;;attemtps to apply it.
  ($set-symbol-proc!  x (if (procedure? v)
			    v
			  (lambda args
			    (assertion-violation 'apply
			      "not a procedure"
			      `(top-level-value-of-symbol ,x)
			      ($symbol-value x) args)))))

(define* (reset-symbol-proc! {x symbol?})
  ;;X is meant to be a location gensym.   If the value currently in the field "value"
  ;;of X is a closure object: store such value also in the field "proc" of X.
  ;;
  ;;NOTE Whenever binary code performs a call to a global closure object, it does the
  ;;following:
  ;;
  ;;* From the relocation vector of the current code object: retrieve the loc gensym
  ;;  of the procedure to call.
  ;;
  ;;* From the loc gensym: extract the value of the "proc" slot, which is meant to be
  ;;  a closure object.  This is done by accessing the gensym object with a low-level
  ;;  assembly instruction, *not* by using the primitive operation $SYMBOL-PROC.
  ;;
  ;;* Actually call the closure object.
  ;;
  (let ((v ($symbol-value x)))
    ($set-symbol-proc! x (if (procedure? v)
			     v
			   (lambda args
			     (assertion-violation 'apply
			       "not a procedure"
			       `(top-level-value-of-symbol ,x)
			       (top-level-value x) args))))))


(define* (symbol->string {x symbol?})
  ;;Defined by  R6RS.  Return the name  of the symbol X  as an immutable
  ;;string.
  ;;
  ($symbol->string x))

(define ($symbol->string x)
  ;;Return the string name of the symbol X.
  ;;
  (let ((str ($symbol-string x)))
    (or str
	(let ((ct (gensym-count)))
	  (receive-and-return (str)
	      (string-append (gensym-prefix) (number->string ct))
	    ($set-symbol-string! x str)
	    (gensym-count ($add1-integer ct)))))))

(define* (string-or-symbol->string {obj string-or-symbol?})
  ;;Defined by Vicare.  If OBJ is a string return a copy of it; if it is
  ;;a symbol return a new string object equal to its string name.
  ;;
  (let ((str (if (string? obj)
		 obj
	       ($symbol->string obj))))
    (substring str 0 ($string-length str))))

(define* (string-or-symbol->symbol {obj string-or-symbol?})
  ;;Defined by Vicare.  If OBJ is a  symbol return it; if it is a string
  ;;return a symbol having it as string name.
  ;;
  (if (symbol? obj)
      obj
    (string->symbol obj)))


;;;; property lists

(define* (putprop {x symbol?} {k symbol?} v)
  ;;Add a new property K with value V to the property list of the symbol
  ;;X.  K must be a symbol, V can be any value.
  ;;
  ($putprop x k v))

(define ($putprop x k v)
  (let ((p ($symbol-plist x)))
    (cond ((assq k p)
	   => (lambda (x)
		($set-cdr! x v)))
	  (else
	   ($set-symbol-plist! x (cons (cons k v) p)))))
  (values))

(define* (getprop {x symbol?} {k symbol?})
  ;;Return  the value  of the  property K  in the  property list  of the
  ;;symbol X; if K is not set return false.  K must be a symbol.
  ;;
  ($getprop x k))

(define ($getprop x k)
  (let ((p ($symbol-plist x)))
    (cond ((assq k p)
	   => cdr)
	  (else #f))))

(define* (remprop {x symbol?} {k symbol?})
  ;;Remove property K from the list associated to the symbol X.
  ;;
  ($remprop x k))

(define ($remprop x k)
  (let ((plist ($symbol-plist x)))
    (unless (null? plist)
      (let ((a ($car plist)))
	(if (eq? ($car a) k)
	    ($set-symbol-plist! x ($cdr plist))
	  (let loop ((q     plist)
		     (plist ($cdr plist)))
	    (unless (null? plist)
	      (let ((a ($car plist)))
		(if (eq? ($car a) k)
		    ($set-cdr! q ($cdr plist))
		  (loop plist ($cdr plist))))))))))
  (values))

(define* (property-list {x symbol?})
  ;;Return a new association list  representing the property list of the
  ;;symbol X.
  ;;
  ;;NOTE We duplicated the structure of the internl association list, so
  ;;that modifying the returned value does not affect the internal state
  ;;of the property list.
  ;;
  ($property-list x))

(define ($property-list x)
  (let loop ((ls    ($symbol-plist x))
	     (accum '()))
    (if (null? ls)
	accum
      (let ((a ($car ls)))
	(loop ($cdr ls)
	      (cons (cons ($car a) ($cdr a))
		    accum))))))


;;;; done

;; #!vicare
;; (foreign-call "ikrt_print_emergency" #ve(ascii "ikarus.symbols"))

#| end of library |# )

;;; end of file
