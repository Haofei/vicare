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

(library (ikarus.reader)
  (export read read-initial read-token comment-handler get-datum
          read-annotated read-script-annotated annotation?
          annotation-expression annotation-source
          annotation-stripped)
  (import (except (ikarus)
		  read-char read read-token comment-handler get-datum
		  read-annotated read-script-annotated annotation?
		  annotation-expression annotation-source annotation-stripped)
    (only (ikarus.string-to-number)
	  define-string->number-parser)
    (ikarus system $chars)
    (ikarus system $fx)
    (ikarus system $pairs)
    (ikarus system $bytevectors)
    (prefix (rename (ikarus system $fx) #;(ikarus fixnums unsafe)
		    ($fxzero?	fxzero?)
		    ($fxadd1	fxadd1)		 ;increment
		    ($fxsub1	fxsub1)		 ;decrement
		    ($fxsra	fxsra)		 ;shift right
		    ($fxsll	fxsll)		 ;shift left
		    ($fxlogor	fxlogor)	 ;inclusive logic OR
		    ($fxlogand	fxand)		 ;logic AND
		    ($fx+	fx+)
		    ($fx-	fx-)
		    ($fx<	fx<)
		    ($fx>	fx>)
		    ($fx>=	fx>=)
		    ($fx<=	fx<=)
		    ($fx=	fx=))
	    unsafe.)
    (prefix (rename (ikarus system $chars) #;(ikarus system chars)
		    ($char=		char=)
		    ($char<		char<)
		    ($char<=		char<=)
		    ($char>		char>)
		    ($char>=		char>=)
		    ($char->fixnum	char->integer)
		    ($fixnum->char	integer->char))
	    unsafe.)
    (prefix (rename (ikarus system $strings) #;(ikarus system strings)
		    ($make-string	make-string)
		    ($string-length	string-length)
		    ($string-ref	string-ref)
		    ($string-set!	string-set!))
	    unsafe.))


;;;; syntax helpers

(define-syntax define-inline
  (syntax-rules ()
    ((_ (?name ?arg ... . ?rest) ?form0 ?form ...)
     (define-syntax ?name
       (syntax-rules ()
	 ((_ ?arg ... . ?rest)
	  (begin ?form0 ?form ...)))))))


;;;; miscellaneous helpers

(define-inline (read-char port)
  ;;Attempt to  read a  character from PORT.   If successful  return the
  ;;character, if  an error occurs raise  an exception, if  EOF is found
  ;;return the EOF object.
  ;;
  (get-char port))

(define-inline (reverse-list->string ell)
  ;;There are more efficient ways to do this, but ELL is usually short.
  ;;
  (list->string (reverse ell)))

(define-inline (port-in-r6rs-mode? port)
  (eq? (port-mode port) 'r6rs))

(define-inline (port-in-vicare-mode? port)
  (eq? (port-mode port) 'vicare))


;;;; data structures

(define-struct loc
  (value value^ set?))

(define-struct annotation
  (expression source stripped))
  ;;; - source is a pair of file-name x char-position
  ;;; - stripped is an s-expression with no annotations
  ;;; - expression is a list/vector/id/whathaveyou that
  ;;;   may contain further annotations.

(define (make-compound-position port)
  (cons (port-id port) (input-port-byte-position port)))

(define (make-compound-position/with-offset port offset)
  (let ((byte (input-port-byte-position port)))
    (cons (port-id port) (and byte (+ byte offset)))))


;;;; exception raisers

(define (die/lex pos who msg . irritants)
  (raise
   (condition (make-lexical-violation)
	      (make-message-condition msg)
	      (if (null? irritants)
		  (condition)
		(make-irritants-condition irritants))
	      (let ((port-id (car pos))
		    (byte    (cdr pos)))
		(make-source-position-condition port-id byte #f))
	      )))

(define-inline (die/pos port offset who msg . irritants)
  (die/lex (make-compound-position/with-offset port offset) who msg . irritants))

(define-inline (die/p p who msg . irritants)
  (die/pos p 0 who msg . irritants))

(define-inline (die/p-1 p who msg . irritants)
  (die/pos p -1 who msg . irritants))

(define-inline (die/ann ann who msg . irritants)
  (die/lex (annotation-source ann) who msg . irritants))

(define-inline (num-error p str ls)
  (die/p-1 p 'read str (reverse-list->string ls)))


;;;; characters classification

(define CHAR-FIXNUM-0		($char->fixnum #\0))
(define CHAR-FIXNUM-a		($char->fixnum #\a))
;;(define CHAR-FIXNUM-f		($char->fixnum #\f))
(define CHAR-FIXNUM-A		($char->fixnum #\A))
;;(define CHAR-FIXNUM-F		($char->fixnum #\F))
(define CHAR-FIXNUM-a-10	(unsafe.fx- CHAR-FIXNUM-a 10))
(define CHAR-FIXNUM-A-10	(unsafe.fx- CHAR-FIXNUM-A 10))

(define-inline (char-is-standalone-newline? ch)
  (or (unsafe.fx= ch #\x000A)	;; linefeed
      (unsafe.fx= ch #\x0085)	;; next line
      (unsafe.fx= ch #\x2028)))	;; line separator

(define-inline (char-is-newline-after-carriage-return? ch)
  ;;This is used to recognise 2-char newline sequences.
  ;;
  (or (unsafe.fx= ch #\x000A)	;; linefeed
      (unsafe.fx= ch #\x0085)))	;; next line

(define (delimiter? ch)
  (or (char-whitespace? ch)
      (unsafe.char= ch #\()
      (unsafe.char= ch #\))
      (unsafe.char= ch #\[)
      (unsafe.char= ch #\])
      (unsafe.char= ch #\")
      (unsafe.char= ch #\#)
      (unsafe.char= ch #\;)
      (unsafe.char= ch #\{)
      (unsafe.char= ch #\})
      (unsafe.char= ch #\|))
  #;(or (char-whitespace? ch)
      (memq ch '(#\( #\) #\[ #\] #\" #\# #\; #\{ #\} #\|))))

(define-inline (dec-digit? ch)
  (and ($char<= #\0 ch) ($char<= ch #\9)))

(define (initial? ch)
  (cond (($char<= ch #\x7F #;($fixnum->char 127))
	 (or (letter? ch) (special-initial? ch)))
	(else
	 (unicode-printable-char? ch))))

(define (letter? ch)
  (or (and ($char<= #\a ch) ($char<= ch #\z))
      (and ($char<= #\A ch) ($char<= ch #\Z))))

(define (special-initial? ch)
  (or (unsafe.char= ch #\!)
      (unsafe.char= ch #\$)
      (unsafe.char= ch #\%)
      (unsafe.char= ch #\&)
      (unsafe.char= ch #\*)
      (unsafe.char= ch #\/)
      (unsafe.char= ch #\:)
      (unsafe.char= ch #\<)
      (unsafe.char= ch #\=)
      (unsafe.char= ch #\>)
      (unsafe.char= ch #\?)
      (unsafe.char= ch #\^)
      (unsafe.char= ch #\_)
      (unsafe.char= ch #\~))
  #;(memq c '(#\! #\$ #\% #\& #\* #\/ #\: #\< #\= #\> #\? #\^ #\_ #\~)))

(define (special-subsequent? ch)
  (or (unsafe.char= ch #\+)
      (unsafe.char= ch #\-)
      (unsafe.char= ch #\.)
      (unsafe.char= ch #\@))
  #;(memq c '(#\+ #\- #\. #\@)))

(define (subsequent? ch)
  (cond ((unsafe.char<= ch #\x7F #;($fixnum->char 127))
	 (or (letter? ch)
	     (dec-digit?  ch)
	     (special-initial? ch)
	     (special-subsequent? ch)))
	(else
	 (or (unicode-printable-char? ch)
	     (memq (char-general-category ch) '(Nd Mc Me))))))


;;;; conversion between characters and integers

(define (integer->char/checked N accumulated-chars port)
  ;;Validate the  fixnum N  as valid Unicode  code point and  return the
  ;;corresponding character.
  ;;
  ;;If  N is  invalid: raise  an exception  using  ACCUMULATED-CHARS and
  ;;PORT.  ACCUMULATED-CHARS must be a reversed list of chars from which
  ;;N was  parsed.  PORT  must be  the port from  which the  chars where
  ;;drawn.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define (valid-integer-char? N)
    (cond ((<= N #xD7FF)   #t)
	  ((<  N #xE000)   #f)
	  ((<= N #x10FFFF) #t)
	  (else            #f)))
  (if (valid-integer-char? N)
      (unsafe.integer->char N)
    (%error "invalid numeric value for character" (reverse-list->string accumulated-chars))))

(define (char->dec-digit ch)
  (unsafe.fx- ($char->fixnum ch) CHAR-FIXNUM-0))

(define (char->hex-digit x)
  ;;If X is a character in the range of hex digits [0-9a-fA-F]: return a
  ;;fixnum representing such digit, else return #f.
  ;;
  (define-inline (y)
    ($char->fixnum x))
  (cond ((and ($char<= #\0 x) ($char<= x #\9))
	 (unsafe.fx- (y) CHAR-FIXNUM-0))
	((and ($char<= #\a x) ($char<= x #\f))
	 (unsafe.fx- (y) CHAR-FIXNUM-a-10))
	((and ($char<= #\A x) ($char<= x #\F))
	 (unsafe.fx- (y) CHAR-FIXNUM-A-10))
	(else #f)))


;;;; tokenising identifiers
;;
;;Three functions are involved:
;;
;;  TOKENIZE-IDENTIFIER
;;  TOKENIZE-IDENTIFIER/BAR
;;  TOKENIZE-IDENTIFIER/BACKSLASH
;;
;;they call each other accumulating characters in a reversed list.  When
;;all of  an identifier has  been read: the  return value is  always the
;;reversed list of characters.
;;

(define (tokenize-identifier accumulated-chars port)
  ;;Read from PORT characters from an identifier token, accumulate them,
  ;;in reverse order and return the resulting list.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define-inline (recurse accum)
    (tokenize-identifier accum port))
  (let ((ch (peek-char port)))
    (cond ((eof-object? ch)
	   accumulated-chars)
	  ((subsequent? ch)
	   (read-char port)
	   (recurse (cons ch accumulated-chars)))
	  ((delimiter? ch)
	   accumulated-chars)
	  ((unsafe.char= ch #\\)
	   (read-char port)
	   (tokenize-identifier/backslash accumulated-chars port #f))
	  ((port-in-r6rs-mode? port)
	   (%error "invalid identifier syntax" (reverse-list->string (cons ch accumulated-chars))))
	  ;;FIXME Is this  correct?  To return the list  if peeked CH is
	  ;;not recognised?
	  (else accumulated-chars))))

(define (tokenize-identifier/bar accumulated-chars port)
  ;;Read from PORT characters  from an identifier token between vertical
  ;;bars  "|abcd|" after  the  opening bar  has  been already  consumed;
  ;;accumulate the characters in  reverse order and return the resulting
  ;;list.
  ;;
  ;;This is a syntax outside  of R6RS: identifiers between bars can hold
  ;;any character.
  ;;
  (define-inline (%unexpected-eof-error . args)
    (die/p port 'tokenize "unexpected EOF while reading symbol" . args))
  (define-inline (recurse accum)
    (tokenize-identifier/bar accum port))
  (let ((ch (read-char port)))
    (cond ((eof-object? ch)
	   (%unexpected-eof-error))
	  ((unsafe.char= #\\ ch)
	   (tokenize-identifier/backslash accumulated-chars port #t))
	  ((unsafe.char= #\| ch) ;end of symbol, whatever comes after
	   accumulated-chars)
	  (else
	   (recurse (cons ch accumulated-chars))))))

(define (tokenize-identifier/backslash accumulated-chars port inside-bar?)
  ;;Read from PORT characters from  an identifier token whose first char
  ;;is a backslash sequence "\x41;" after the opening backslash has been
  ;;already  consumed; accumulate  the characters  in reverse  order and
  ;;return the resulting list.
  ;;
  ;;When reading the baskslash sequence is terminated: if INSIDE-BAR? is
  ;;true  TOKENIZE-IDENTIFIER/BAR is invoked  to continue  reading, else
  ;;TOKENIZE-IDENTIFIER is invoked to continue reading.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define-inline (%error-1 msg . args)
    (die/p-1 port 'tokenize msg . args))

  (define-inline (main)
    (let ((ch (read-char port)))
      (cond ((eof-object? ch)
	     (%error "invalid EOF after backslash while reading symbol" #\\))
	    ((unsafe.char= #\x ch)
	     (%tokenize-hex-digits))
	    (else
	     (%error "expected character x after backslash \
                      while reading symbol"
		     (string #\\ ch)
		     (reverse-list->string accumulated-chars))))))

  (define-inline (%tokenize-hex-digits)
    (let next-digit ((code-point 0)
		     (accumul    (list #\x #\\)))
      (let ((ch (read-char port)))
	(cond ((eof-object? ch)
	       (%error "invalid EOF after backslash sequence \
                        while reading symbol"
		       (reverse-list->string accumul)
		       (reverse-list->string accumulated-chars)))
	      ((unsafe.char= #\; ch)
	       (let ((accum (cons (integer->char/checked code-point accumul port)
				  accumulated-chars)))
		 (if inside-bar?
		     (tokenize-identifier/bar accum port)
		   (tokenize-identifier accum port))))
	      ((char->hex-digit ch)
	       => (lambda (digit)
		    (next-digit (unsafe.fx+ digit (fx* code-point 16))
				(cons ch accumul))))
	      (else
	       (%error "expected hex digit after backslash sequence \
                        while reading symbol"
		       (reverse-list->string (cons ch accumul))
		       (reverse-list->string accumulated-chars)))))))

  (main))


;;;; reading strings

(define (tokenize-string ls p)
  (let ((c (read-char p)))
    (cond ((eof-object? c)
	   (die/p p 'tokenize "invalid eof inside string"))
	  (else
	   (tokenize-string-char ls p c)))))

(define (tokenize-string-char ls p c)
  (define (intraline-whitespace? c)
    (or (eqv? c #\x9)
	(eq? (char-general-category c) 'Zs)))
  (define (tokenize-string-continue ls p c)
    (cond ((eof-object? c)
	   (die/p p 'tokenize "invalid eof inside string"))
	  ((intraline-whitespace? c)
	   (let f ()
	     (let ((c (read-char p)))
	       (cond
		((eof-object? c)
		 (die/p p 'tokenize "invalid eof inside string"))
		((intraline-whitespace? c) (f))
		(else (tokenize-string-char ls p c))))))
	  (else (tokenize-string-char ls p c))))
  (cond (($char= #\" c) ls)
	(($char= #\\ c)
	 (let ((c (read-char p)))
	   (cond ((eof-object? c)
		  (die/p p 'tokenize "invalid eof after string escape"))
		 (($char= #\a c) (tokenize-string (cons #\x7 ls) p))
		 (($char= #\b c) (tokenize-string (cons #\x8 ls) p))
		 (($char= #\t c) (tokenize-string (cons #\x9 ls) p))
		 (($char= #\n c) (tokenize-string (cons #\xA ls) p))
		 (($char= #\v c) (tokenize-string (cons #\xB ls) p))
		 (($char= #\f c) (tokenize-string (cons #\xC ls) p))
		 (($char= #\r c) (tokenize-string (cons #\xD ls) p))
		 (($char= #\" c) (tokenize-string (cons #\x22 ls) p))
		 (($char= #\\ c) (tokenize-string (cons #\x5C ls) p))
		 (($char= #\x c) ;;; unicode escape \xXXX;
		  (let ((c (read-char p)))
		    (cond ((eof-object? c)
			   (die/p p 'tokenize "invalid eof inside string"))
			  ((char->hex-digit c) =>
			   (lambda (n)
			     (let f ((n n) (ac (cons c '(#\x))))
			       (let ((c (read-char p)))
				 (cond ((eof-object? n)
					(die/p p 'tokenize "invalid eof inside string"))
				       ((char->hex-digit c) =>
					(lambda (v) (f (+ (* n 16) v) (cons c ac))))
				       (($char= c #\;)
					(tokenize-string
					 (cons (integer->char/checked n ac p) ls) p))
				       (else
					(die/p-1 p 'tokenize
						 "invalid char in escape sequence"
						 (reverse-list->string (cons c ac)))))))))
			  (else
			   (die/p-1 p 'tokenize
				    "invalid char in escape sequence" c)))))
		 ((intraline-whitespace? c)
		  (let f ()
		    (let ((c (read-char p)))
		      (cond ((eof-object? c)
			     (die/p p 'tokenize "invalid eof inside string"))
			    ((intraline-whitespace? c) (f))
			    ((char-is-standalone-newline? c)
			     (tokenize-string-continue ls p (read-char p)))
			    ((eqv? c #\return)
			     (let ((c (read-char p)))
			       (cond ((char-is-newline-after-carriage-return? c)
				      (tokenize-string-continue ls p (read-char p)))
				     (else
				      (tokenize-string-continue ls p c)))))
			    (else
			     (die/p-1 p 'tokenize
				      "non-whitespace character after escape"))))))
		 ((char-is-standalone-newline? c)
		  (tokenize-string-continue ls p (read-char p)))
		 ((eqv? c #\return)
		  (let ((c (read-char p)))
		    (cond ((char-is-newline-after-carriage-return? c)
			   (tokenize-string-continue ls p (read-char p)))
			  (else
			   (tokenize-string-continue ls p c)))))
		 (else (die/p-1 p 'tokenize "invalid string escape" c)))))
	((char-is-standalone-newline? c)
	 (tokenize-string (cons #\linefeed ls) p))
	((unsafe.fx= c #\return)
	 (let ((ch1 (peek-char p)))
	   (when (char-is-newline-after-carriage-return? ch1)
	     (read-char p))
	   (tokenize-string (cons #\linefeed ls) p)))
	(else
	 (tokenize-string (cons c ls) p))))


(define (tokenize-dot port)
  ;;Read from  PORT a token starting  with a dot, the  dot being already
  ;;read.  There return value is a datum describing the token:
  ;;
  ;;dot			The token is a standalone dot.
  ;;(datum . ...)	The token is the symbol "...".
  ;;(datum . <num>)	The token is the inexact number <NUM>.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (let ((ch (peek-char port)))
    (cond ((eof-object? ch) 'dot)
	  ((delimiter?  ch) 'dot)
	  (($char= ch #\.) ;a second dot, maybe a "..." opening
	   (read-char port)
	   (let ((ch1 (peek-char port)))
	     (cond ((eof-object? ch1)
		    (%error "invalid syntax .. near end of file"))
		   (($char= ch #\.) ;this is the third
		    (read-char port)
		    (let ((ch2 (peek-char port)))
		      (cond ((eof-object? ch2) '(datum . ...))
			    ((delimiter?  ch2) '(datum . ...))
			    (else
			     (%error "invalid syntax" (string-append "..." (string ch2)))))))
		   (else
		    (%error "invalid syntax" (string-append ".." (string ch1)))))))
	  (else
	   (cons 'datum (u:dot port '(#\.) 10 #f #f +1))))))


(define (tokenize-char-seq port str datum)
  ;;Subroutine  of TOKENIZE-CHAR.  Read  characters from  PORT verifying
  ;;that they are equal to the  characters drawn from the string STR; if
  ;;reading and  comparing is successful:  peek one more char  from PORT
  ;;and verify that it is EOF or a delimiter (according to DELIMITER?).
  ;;
  ;;If successful return DATUM, else raise an exception.
  ;;
  ;;This function is used to parse characters: in the format "#\newline"
  ;;when the sequence "#\ne" has already been consumed; in this case the
  ;;function is called as:
  ;;
  ;;   (tokenize-char-seq port "ewline" '(datum . #\xA))
  ;;
  ;;As an extension  (currently not used in the  lexer, Marco Maggi; Oct
  ;;12, 2011), this function supports  also the case of character in the
  ;;format "#\A" when the sequence  "#\A" has already been consumed, and
  ;;we only  need to verify  that the  next char from  PORT is EOF  or a
  ;;delimiter.  In this case DATUM is ignored.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (let ((ch (peek-char port)))
    (cond ((or (eof-object? ch) (delimiter? ch))
	   (cons 'datum (unsafe.string-ref str 0)))
	  (($char= ch (unsafe.string-ref str 1))
	   (read-char port)
	   (tokenize-char* 2 str port datum))
	  (else
	   (%error "invalid syntax" (unsafe.string-ref str 0) ch)))))


(define (tokenize-char* str.index str port datum)
  ;;Recusrive subroutine of TOKENIZE-CHAR-SEQ.  Draw characters from the
  ;;string STR, starting at STR.INDEX, and verify that they are equal to
  ;;the  characters  read  from   PORT;  if  reading  and  comparing  is
  ;;successful: peek one  more char from PORT and verify  that it is EOF
  ;;or a delimiter (according to DELIMITER?).
  ;;
  ;;If successful return DATUM, else raise an exception.
  ;;
  (define-inline (recurse idx)
    (tokenize-char* idx str port datum))
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (if (unsafe.fx= str.index (unsafe.string-length str))
      (let ((ch (peek-char port)))
	(cond ((eof-object? ch) datum)
	      ((delimiter?  ch) datum)
	      (else
	       (%error "invalid character after sequence" (string-append str (string ch))))))
    (let ((ch (read-char port)))
      (cond ((eof-object? ch)
	     (%error "invalid EOF in the middle of expected sequence" str))
	    (($char= ch (unsafe.string-ref str str.index))
	     (recurse (unsafe.fxadd1 str.index)))
	    (else
	     (%error "invalid char while scanning string" ch str))))))


(define (tokenize-char port)
  ;;Called after a hash character followed by a backslash character have
  ;;been read from PORT.  Read  characters from PORT parsing a character
  ;;datum; return the datum:
  ;;
  ;;   (datum . <ch>)
  ;;
  ;;where <CH> is the character value.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (let ((ch (read-char port)))
    (cond ((eof-object? ch)
	   (%error "invalid #\\ near end of file"))

	  ;;There are multiple character sequences starting with "#\n".
	  (($char= #\n ch)
	   (let ((ch1 (peek-char port)))
	     (cond ((eof-object? ch1)
		    '(datum . #\n))
		   (($char= #\u ch1)
		    (read-char port)
		    (tokenize-char-seq port "ul"	'(datum . #\x0)))
		   (($char= #\e ch1)
		    (read-char port)
		    (tokenize-char-seq port "ewline"	'(datum . #\xA)))
		   ((delimiter? ch1)
		    '(datum . #\n))
		   (else
		    (%error "invalid syntax" (string #\# #\\ #\n ch1))))))

	  (($char= #\a ch)
	   (tokenize-char-seq port "alarm"	'(datum . #\x7)))
	  (($char= #\b ch)
	   (tokenize-char-seq port "backspace"	'(datum . #\x8)))
	  (($char= #\t ch)
	   (tokenize-char-seq port "tab"	'(datum . #\x9)))
	  (($char= #\l ch)
	   (tokenize-char-seq port "linefeed"	'(datum . #\xA)))
	  (($char= #\v ch)
	   (tokenize-char-seq port "vtab"	'(datum . #\xB)))
	  (($char= #\p ch)
	   (tokenize-char-seq port "page"	'(datum . #\xC)))
	  (($char= #\r ch)
	   (tokenize-char-seq port "return"	'(datum . #\xD)))
	  (($char= #\e ch)
	   (tokenize-char-seq port "esc"	'(datum . #\x1B)))
	  (($char= #\s ch)
	   (tokenize-char-seq port "space"	'(datum . #\x20)))
	  (($char= #\d ch)
	   (tokenize-char-seq port "delete"	'(datum . #\x7F)))

	  ;;Read the char "#\x" or a character in hex format "#\xHHHH".
	  (($char= #\x ch)
	   (let ((ch1 (peek-char port)))
	     (cond ((or (eof-object? ch1)
			(delimiter?  ch1))
		    '(datum . #\x))
		   ((char->hex-digit ch1)
		    => (lambda (digit)
			 (read-char port)
			 (let next-digit ((digit       digit)
					  (accumulated (cons ch1 '(#\x))))
			   (let ((chX (peek-char port)))
			     (cond ((eof-object? chX)
				    (cons 'datum (integer->char/checked digit accumulated port)))
				   ((delimiter? chX)
				    (cons 'datum (integer->char/checked digit accumulated port)))
				   ((char->hex-digit chX)
				    => (lambda (digit0)
					 (read-char port)
					 (next-digit (+ (* digit 16) digit0)
						     (cons chX accumulated))))
				   (else
				    (%error "invalid character sequence"
					    (reverse-list->string (cons chX accumulated)))))))))
		   (else
		    (%error "invalid character sequence" (string #\# #\\ ch1))))))

	  ;;It is a normal character.
	  (else
	   (let ((ch1 (peek-char port)))
	     (if (or (eof-object? ch1)
		     (delimiter?  ch1))
		 (cons 'datum ch)
	       (%error "invalid syntax" (string #\# #\\ ch ch1))))))))


;;;; reading comments

(define (skip-comment port)
  (let ((ch (read-char port)))
    (unless (or (eof-object? ch)
		(char-is-standalone-newline? ch)
		(unsafe.char= ch #\return))
      (skip-comment port))))

(define (multiline-comment port)
  ;;Parse a multiline comment  "#| ... |#", possibly nested.  Accumulate
  ;;the characters in the comment, excluding the "#|" and "|#", and hand
  ;;the  resulting string to  the function  referenced by  the parameter
  ;;COMMENT-HANDLER.    Return  the  return   value  of   such  function
  ;;application.
  ;;
  (define-inline (%multiline-error)
    (die/p port 'tokenize "end of file encountered while inside a #|-style comment"))

  (define-inline (string->reverse-list str str.start accumulated)
    (%string->reverse-list str str.start (unsafe.string-length str) accumulated))
  (define (%string->reverse-list str str.index str.len accumulated)
    (if (unsafe.fx= str.index str.len)
	accumulated
      (%string->reverse-list str (unsafe.fxadd1 str.index) str.len
			     (cons (unsafe.string-ref str str.index) accumulated))))

  (define (accumulate-comment-chars port ac)
    (define-inline (recurse ac)
      (accumulate-comment-chars port ac))
    (let ((c (read-char port)))
      (cond ((eof-object? c)
	     (%multiline-error))

	    ;;A vertical bar character may or may not end this multiline
	    ;;comment.
	    (($char= #\| c)
	     (let next-vertical-bar ((ch1 (read-char port)) (ac ac))
	       (cond ((eof-object? ch1)
		      (%multiline-error))
		     (($char= #\# ch1) ;end of comment
		      ac)
		     (($char= #\| ch1) ;optimisation for sequence of bars?!?
		      (next-vertical-bar (read-char port) (cons ch1 ac)))
		     (else
		      (recurse (cons ch1 ac))))))

	    ;;A hash character  may or may not start  a nested multiline
	    ;;comment.   Read a  nested multiline  comment, if  there is
	    ;;one.
	    (($char= #\# c)
	     (let ((ch1 (read-char port)))
	       (cond ((eof-object? ch1)
		      (%multiline-error))
		     (($char= #\| ch1) ;it is a nested comment
		      (let ((v (multiline-comment port)))
			(if (string? v)
			    (recurse (string->reverse-list v 0 ac))
			  (recurse ac))))
		     (else ;it is a standalone hash char
		      (recurse (cons ch1 (cons #\# ac)))))))

	    (else
	     (recurse (cons c ac))))))

  ((comment-handler) (reverse-list->string (accumulate-comment-chars port '()))))


(define (skip-whitespace port caller)
  ;;Read and  discard characters from  PORT while they are  white spaces
  ;;according  to  CHAR-WHITESPACE?.  Return  the  first character  read
  ;;which is not a white space.
  ;;
  ;;CALLER must be a string  describing the token the caller is parsing,
  ;;it is used for error reporting.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define-inline (recurse)
    (skip-whitespace port caller))
  (let ((ch (read-char port)))
    (cond ((eof-object? ch)
	   (%error "invalid EOF inside" caller))
	  ((char-whitespace? ch)
	   (recurse))
	  (else ch))))


(define-inline (tokenize-hash port)
  ;;Read a token from PORT.  Called after a #\# character has been read.
  ;;
  (tokenize-hash/c (read-char port) port))

(define (tokenize-hash/c ch port)
  ;;Recognise  a  token  to be  read  from  PORT.   Called after  a  #\#
  ;;character has been read.  CH is the character right after the hash.
  ;;
  ;;Return a datum representing the token that must be read:
  ;;
  ;;(datum . #t)		The token is the value #t.
  ;;(datum . #f)		The token is the value #f.
  ;;(datum . <char>)		The token is the character <char>.
  ;;(datum . <sym>)		The token is the symbol <sym>.
  ;;(datum . <num>)		The token is the number <num>.
  ;;(datum . #!eof)		The token is the "#!eof" comment.
  ;;(macro . syntax)		The token is a syntax form: #'---.
  ;;(macro . quasisyntax)	The token is a quasisyntax form: #`---.
  ;;(macro . unsyntax-splicing)	The token is an unsyntax-splicing form: #,@---.
  ;;(macro . unsyntax)		The token is an unsyntax form: #,---.
  ;;(mark . <n>)		The token is a graph syntax mark: #<N>=---
  ;;(ref . <n>)			The token is a graph syntax reference: #<N>#
  ;;vparen			The token is a vector.
  ;;vu8				The token is a u8 bytevector.
  ;;vs8				The token is a s8 bytevector.
  ;;
  ;;When the token is the  "#!r6rs" or "#!vicare" comment: the port mode
  ;;is changed  accordingly and TOKENIZE/1  is applied to the  port; the
  ;;return value is the return value of TOKENIZE/1.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define-inline (%error-1 msg . args)
    (die/p-1 port 'tokenize msg . args))

  (cond
   ((eof-object? ch)
    (%error "invalid # near end of file"))

   ((or ($char= #\t ch) ($char= #\T ch)) #;(memq ch '(#\t #\T))
    (let ((c1 (peek-char port)))
      (cond ((eof-object? c1) '(datum . #t))
	    ((delimiter?  c1) '(datum . #t))
	    (else
	     (%error (format "invalid syntax near #~a~a" ch c1))))))

   ((or ($char= #\f ch) ($char= #\F ch)) #;(memq ch '(#\f #\F))
    (let ((ch1 (peek-char port)))
      (cond ((eof-object? ch1) '(datum . #f))
	    ((delimiter?  ch1) '(datum . #f))
	    (else
	     (%error (format "invalid syntax near #~a~a" ch ch1))))))

   (($char= #\\ ch) (tokenize-char port))
   (($char= #\( ch) 'vparen)
   (($char= #\' ch) '(macro . syntax))
   (($char= #\` ch) '(macro . quasisyntax))

   (($char= #\, ch)
    (let ((ch1 (peek-char port)))
      (cond (($char= ch1 #\@)
	     (read-char port)
	     '(macro . unsyntax-splicing))
	    (else
	     '(macro . unsyntax)))))

   ;; #! comments and such
   (($char= #\! ch)
    (let ((ch1 (read-char port)))
      (when (eof-object? ch1)
	(%error "invalid eof near #!"))
      (case ch1
	((#\e)
	 (when (port-in-r6rs-mode? port)
	   (%error-1 "invalid syntax: #!e"))
	 (read-char* port '(#\e) "of" "eof sequence" #f #f)
	 (cons 'datum (eof-object)))
	((#\r)
	 (read-char* port '(#\r) "6rs" "#!r6rs comment" #f #f)
	 (set-port-mode! port 'r6rs)
	 (tokenize/1 port))
	((#\v)
	 (read-char* port '(#\v) "icare" "#!vicare comment" #f #f)
	 (set-port-mode! port 'vicare)
	 (tokenize/1 port))
	(else
	 (%error-1 (format "invalid syntax near #!~a" ch1))))))

   ((dec-digit? ch)
    (when (port-in-r6rs-mode? port)
      (%error-1 "graph syntax is invalid in #!r6rs mode" (format "#~a" ch)))
    (tokenize-hashnum port (char->dec-digit ch)))

   (($char= #\: ch)
    (when (port-in-r6rs-mode? port)
      (%error-1 "gensym syntax is invalid in #!r6rs mode" (format "#~a" ch)))
    (let* ((ch1 (skip-whitespace port "gensym"))
	   (id0 (cond ((initial? ch1)
		       (reverse-list->string (tokenize-identifier (cons ch1 '()) port)))
		      (($char= #\| ch1)
		       (reverse-list->string (tokenize-identifier/bar '() port)))
		      (else
		       (%error-1 "invalid char inside gensym" ch1)))))
      (cons 'datum (gensym id0))))

   ;;Gensym with one of the following syntaxes:
   ;;
   ;;#{ciao}
   ;;   In which "ciao" is ID0.
   ;;
   ;;#{|ciao|}
   ;;   In which "ciao" is ID0.
   ;;
   ;;#{d |95BEx%X86N?8X&yC|}
   ;;   In which "d" is ID0 and "95BEx%X86N?8X&yC" is ID1.
   ;;
   ;;#{|d| |95BEx%X86N?8X&yC|}
   ;;   In which "d" is ID0 and "95BEx%X86N?8X&yC" is ID1.
   ;;
   (($char= #\{ ch)
    (when (port-in-r6rs-mode? port)
      (%error-1 "gensym syntax is invalid in #!r6rs mode" (format "#~a" ch)))
    (let* ((ch1 (skip-whitespace port "gensym"))
	   (id0 (cond ((initial? ch1)
		       (reverse-list->string (tokenize-identifier (cons ch1 '()) port)))
		      (($char= #\| ch1)
		       (reverse-list->string (tokenize-identifier/bar '() port)))
		      (else
		       (%error-1 "invalid char inside gensym 1" ch1))))
	   (ch2 (skip-whitespace port "gensym")))
      (cond (($char= #\} ch2)
	     (cons 'datum (foreign-call "ikrt_strings_to_gensym" #f id0)))
	    (else
	     (let ((id1 (cond ((initial? ch2)
			       (reverse-list->string (tokenize-identifier (cons ch2 '()) port)))
			      (($char= #\| ch2)
			       (reverse-list->string (tokenize-identifier/bar '() port)))
			      (else
			       (%error-1 "invalid char inside gensym 2" ch2)))))
	       (let ((c (skip-whitespace port "gensym")))
		 (cond (($char= #\} ch2)
			(cons 'datum (foreign-call "ikrt_strings_to_gensym" id0 id1)))
		       (else
			(%error-1 "invalid char inside gensym 3" ch2)))))))))

   (($char= #\v ch)
    ;;Correct sequences of chars:
    ;;
    ;; ch  ch1  ch2  ch3  ch4  ch5  datum
    ;; ----------------------------------
    ;; v   u    8    (              #vu8
    ;; v   s    8    (              #vs8
    ;; v   u    1    6    l    (    #vu16l
    ;; v   u    1    6    b    (    #vu16b
    ;; v   s    1    6    l    (    #vs16l
    ;; v   s    1    6    b    (    #vs16b
    ;; v   u    3    2    l    (    #vu32l
    ;; v   u    3    2    b    (    #vu32b
    ;; v   s    3    2    l    (    #vs32l
    ;; v   s    3    2    b    (    #vs32b
    ;; v   u    6    4    l    (    #vu64l
    ;; v   u    6    4    b    (    #vu64b
    ;; v   s    6    4    l    (    #vs64l
    ;; v   s    6    4    b    (    #vs64b
    ;;
    (let ((ch1/eof (read-char port)))
      (define-inline (%read-bytevector)
	(cond ((char=? #\u ch1/eof)
	       (%read-unsigned))
	      ((char=? #\s ch1/eof)
	       (when (port-in-r6rs-mode? port)
		 (%error "invalid #vs8 syntax in #!r6rs mode" "#vs8"))
	       (%read-signed))
	      ((eof-object? ch1/eof)
	       (%error "invalid eof object after #v"))
	      (else
	       (%error (format "invalid sequence #v~a" ch1/eof)))))

      (define-inline (%read-unsigned)
	(let ((ch2/eof (read-char port)))
	  (cond ((char=? ch2/eof #\8) ;unsigned bytes bytevector
		 (%read-unsigned-8))
		((eof-object? ch2/eof)
		 (%error "invalid eof object after #vu"))
		(else
		 (%error-1 (format "invalid sequence #vu~a" ch2/eof))))))

      (define-inline (%read-signed)
	(let ((ch2/eof (read-char port)))
	  (cond ((char=? ch2/eof #\8) ;signed bytes bytevector
		 (%read-signed-8))
		((eof-object? ch2/eof)
		 (%error "invalid eof object after #vs"))
		(else
		 (%error-1 (format "invalid sequence #vs~a" ch2/eof))))))

      (define-inline (%read-unsigned-8)
	(let ((ch3/eof (read-char port)))
	  (cond ((char=? ch3/eof #\()
		 'vu8)
		((eof-object? ch3/eof)
		 (%error "invalid eof object after #vu8"))
		(else
		 (%error-1 (format "invalid sequence #vu8~a" ch3/eof))))))

      (define-inline (%read-signed-8)
	(let ((ch3/eof (read-char port)))
	  (cond ((char=? ch3/eof #\()
		 'vs8)
		((eof-object? ch3/eof)
		 (%error "invalid eof object after #vs8"))
		(else
		 (%error-1 (format "invalid sequence #vs8~a" ch3/eof))))))

      (%read-bytevector)))

   ((or ($char= ch #\e) ($char= ch #\E)) #;(memq ch '(#\e #\E))
    (cons 'datum (parse-string port (list ch #\#) 10 #f 'e)))

   ((or ($char= ch #\i) ($char= ch #\I)) #;(memq ch '(#\i #\I))
    (cons 'datum (parse-string port (list ch #\#) 10 #f 'i)))

   ((or ($char= ch #\b) ($char= ch #\B)) #;(memq ch '(#\b #\B))
    (cons 'datum (parse-string port (list ch #\#) 2 2 #f)))

   ((or ($char= ch #\x) ($char= ch #\X)) #;(memq ch '(#\x #\X))
    (cons 'datum (parse-string port (list ch #\#) 16 16 #f)))

   ((or ($char= ch #\o) ($char= ch #\O)) #;(memq ch '(#\o #\O))
    (cons 'datum (parse-string port (list ch #\#) 8 8 #f)))

   ((or ($char= ch #\d) ($char= ch #\D)) #;(memq ch '(#\d #\D))
    (cons 'datum (parse-string port (list ch #\#) 10 10 #f)))

;;;(($char= #\@ ch) DEAD: Unfixable due to port encoding
;;;                 that does not allow mixing binary and
;;;                 textual data in the same port.
;;;                Left here for historical value
;;; (when (port-in-r6rs-mode? port)
;;;   (%error-1 "fasl syntax is invalid in #!r6rs mode"
;;;      (format "#~a" ch)))
;;; (die/p-1 port 'read "FIXME: fasl read disabled")
;;; '(cons 'datum ($fasl-read port)))

   (else
    (%error-1 (format "invalid syntax #~a" ch)))))


;;;; number parser

(define-syntax port-config
  (syntax-rules (GEN-TEST GEN-ARGS FAIL EOF-ERROR GEN-DELIM-TEST)
    ((_ GEN-ARGS k . rest) (k (p ac) . rest))
    ((_ FAIL (p ac))
     (num-error p "invalid numeric sequence" ac))
    ((_ FAIL (p ac) c)
     (num-error p "invalid numeric sequence" (cons c ac)))
    ((_ EOF-ERROR (p ac))
     (num-error p "invalid eof while reading number" ac))
    ((_ GEN-DELIM-TEST c sk fk)
     (if (delimiter? c) sk fk))
    ((_ GEN-TEST var next fail (p ac) eof-case char-case)
     (let ((c (peek-char p)))
       (if (eof-object? c)
	   (let ()
	     (define-syntax fail
	       (syntax-rules ()
		 ((_) (num-error p "invalid numeric sequence" ac))))
	     eof-case)
	 (let ((var c))
	   (define-syntax fail
	     (syntax-rules ()
	       ((_)
		(num-error p "invalid numeric sequence" (cons var ac)))))
	   (define-syntax next
	     (syntax-rules ()
	       ((_ who args (... ...))
		(who p (cons (get-char p) ac) args (... ...)))))
	   char-case))))))

(define-string->number-parser port-config
  (parse-string u:digit+ u:sign u:dot))


(define (read-char* port ls str who case-insensitive? delimited?)
  ;;Read multiple characters from PORT expecting them to be the chars in
  ;;the string STR; this function is  used to read a chunk of token.  If
  ;;successful return  unspecified values; if  an error occurs  raise an
  ;;exception.
  ;;
  ;;LS  must  be  a  list  of  characters already  read  from  PORT  and
  ;;recognised to be the opening of  the token: they are used to build a
  ;;better error message.  WHO must  be a string describing the expected
  ;;token.
  ;;
  ;;If CASE-INSENSITIVE? is true: the comparison between characters read
  ;;from PORT and characters drawn from STR is case insensitive.
  ;;
  ;;If DELIMITED? is true: after the chars in STR have been successfully
  ;;read from PORT, a lookahead is performed on PORT and the result must
  ;;be EOF or a delimiter character (according to DELIMITER?).
  ;;
  ;;Usage example:  when reading the  comment "#!r6rs" this  function is
  ;;called as:
  ;;
  ;;	(read-char* port '(#\r) "6rs" #f #f)
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define-inline (%error-1 msg . args)
    (die/p-1 port 'tokenize msg . args))
  (define str.len
    (string-length str))
  (let loop ((i 0) (ls ls))
    (if (fx= i str.len)
	(when delimited?
	  (let ((ch (peek-char port)))
	    (when (and (not (eof-object? ch))
		       (not (delimiter?  ch)))
	      (%error (format "invalid ~a: ~s" who (reverse-list->string (cons ch ls)))))))
      (let ((ch (read-char port)))
	(cond ((eof-object? ch)
	       (%error (format "invalid eof inside ~a" who)))
	      ((or (and (not case-insensitive?)
			($char= ch (string-ref str i)))
		   (and case-insensitive?
			($char= (char-downcase ch)
				(string-ref str i))))
	       (loop (add1 i) (cons ch ls)))
	      (else
	       (%error-1 (format "invalid ~a: ~s" who (reverse-list->string (cons ch ls))))))))))


(define (tokenize-hashnum p n)
  (let ((c (read-char p)))
    (cond
     ((eof-object? c)
      (die/p p 'tokenize "invalid eof inside #n mark/ref"))
     (($char= #\= c) (cons 'mark n))
     (($char= #\# c) (cons 'ref n))
     ((dec-digit? c)
      (tokenize-hashnum p (fx+ (fx* n 10) (char->dec-digit c))))
     (else
      (die/p-1 p 'tokenize "invalid char while inside a #n mark/ref" c)))))


(define (tokenize/c ch port)
  ;;Recognise a  token to be read from  PORT after the char  CH has been
  ;;read.   Return a  datum representing  a full  token already  read or
  ;;describing a token that must still be read:
  ;;
  ;;lparen			The token is a left paranthesis.
  ;;rparen			The token is a right paranthesis.
  ;;lbrack			The token is a left bracket.
  ;;rbrack			The token is a right bracket.
  ;;(datum . <num>)		The token is the number <NUM>.
  ;;(datum . <sym>)		The token is the symbol <SYM>.
  ;;(datum . <str>)		The token is the string <STR>.
  ;;(datum . <ch>)		The token is the character <CH>.
  ;;(macro . quote)		The token is a quoted form.
  ;;(macro . quasiquote)	The token is a quasiquoted form.
  ;;(macro . unquote)		The token is an unquoted form.
  ;;(macro . unquote-splicing)	The token is an unquoted splicing form.
  ;;at-expr			The token is an @-expression.
  ;;
  ;;If CH is the character #\#:  the return value is the return value of
  ;;TOKENIZE-HASH applied to PORT.
  ;;
  ;;If CH is the dot character:  the return value is the return value of
  ;;TOKENIZE-DOT.
  ;;
  (define-inline (%error msg . args)
    (die/p port 'tokenize msg . args))
  (define-inline (%error-1 msg . args)
    (die/p-1 port 'tokenize msg . args))
  (cond ((eof-object? ch)
	 (error 'tokenize/c "hmmmm eof")
	 (eof-object))

	(($char= #\( ch)   'lparen)
	(($char= #\) ch)   'rparen)
	(($char= #\[ ch)   'lbrack)
	(($char= #\] ch)   'rbrack)
	(($char= #\' ch)   '(macro . quote))
	(($char= #\` ch)   '(macro . quasiquote))

	(($char= #\, ch)
	 (let ((ch1 (peek-char port)))
	   (cond ((eof-object? ch1)
		  '(macro . unquote))
		 (($char= ch1 #\@)
		  (read-char port)
		  '(macro . unquote-splicing))
		 (else
		  '(macro . unquote)))))

	;;everything starting with a hash
	(($char= #\# ch)
	 (tokenize-hash port))

	;;number
	((char<=? #\0 ch #\9)
	 (let ((d ($fx- (char->integer ch) (char->integer #\0))))
	   (cons 'datum (u:digit+ port (list ch) 10 #f #f +1 d))))

	;;symbol
	((initial? ch)
	 (let ((ls (reverse (tokenize-identifier (cons ch '()) port))))
	   (cons 'datum (string->symbol (list->string ls)))))

	;;string
	(($char= #\" ch)
	 (let ((ls (tokenize-string '() port)))
	   (cons 'datum (reverse-list->string ls))))

	;;symbol "+" or number
	(($char= #\+ ch)
	 (let ((ch1 (peek-char port)))
	   (cond ((eof-object? ch1) '(datum . +))
		 ((delimiter?  ch1)  '(datum . +))
		 (else
		  (cons 'datum (u:sign port '(#\+) 10 #f #f +1))))))

	;;symbol "-", symbol "->" or number
	(($char= #\- ch)
	 (let ((ch1 (peek-char port)))
	   (cond ((eof-object? ch1) '(datum . -))
		 ((delimiter?  ch1) '(datum . -))
		 (($char= ch1 #\>)
		  (read-char port)
		  (let ((ls (tokenize-identifier '() port)))
		    (let ((str (list->string (cons* #\- #\> (reverse ls)))))
		      (cons 'datum (string->symbol str)))))
		 (else
		  (cons 'datum (u:sign port '(#\-) 10 #f #f -1))))))

	;;everything  staring  with  a  dot  (standalone  dot,  ellipsis
	;;symbol, inexact number)
	(($char= #\. ch)
	 (tokenize-dot port))

	;;symbol with syntax "|<sym>|"
	(($char= #\| ch)
	 (when (port-in-r6rs-mode? port)
	   (%error "|symbol| syntax is invalid in #!r6rs mode"))
	 (cons 'datum (string->symbol (reverse-list->string (tokenize-identifier/bar '() port)))))

	;;symbol whose first char is a backslash sequence, "\x41;-ciao"
	(($char= #\\ ch)
	 (cons 'datum (string->symbol (reverse-list->string
				       (tokenize-identifier/backslash '() port #f)))))

;;;Unused for now.
;;;
;;;     (($char= #\{ ch) 'lbrace)

	(($char= #\@ ch)
	 (when (port-in-r6rs-mode? port)
	   (%error "@-expr syntax is invalid in #!r6rs mode"))
	 'at-expr)

	(else
	 (%error-1 "invalid syntax" ch))))


(define (tokenize/1 port)
  ;;Start  tokenizing the next  token from  PORT, skipping  comments and
  ;;whitespaces.  Return a datum representing the next token.
  ;;
  (define-inline (recurse)
    (tokenize/1 port))
  (let ((ch (read-char port)))
    (cond ((eof-object? ch)
	   (eof-object))
	  (($char= ch #\;)
	   (skip-comment port)
	   (recurse))
	  (($char= ch #\#)
	   (let ((ch1 (read-char port)))
	     (cond ((eof-object? ch1)
		    (die/p port 'tokenize "invalid EOF after #"))
		   (($char= ch1 #\;)
		    (read-as-comment port)
		    (recurse))
		   (($char= ch1 #\|)
		    (multiline-comment port)
		    (recurse))
		   (else
		    (tokenize-hash/c ch1 port)))))
	  ((char-whitespace? ch)
	   (recurse))
	  (else
	   (tokenize/c ch port)))))

(define (tokenize/1+pos port)
  ;;Start  tokenizing  the next  token  from  P,  skipping comments  and
  ;;whitespaces.   Return  two values:  a  datum  representing the  next
  ;;token, a compound position value.
  ;;
  (define-inline (recurse)
    (tokenize/1+pos port))
  (let* ((pos (make-compound-position port))
	 (ch  (read-char port)))
    (cond ((eof-object? ch)
	   (values (eof-object) pos))
	  (($char= ch #\;)
	   (skip-comment port)
	   (recurse))
	  (($char= ch #\#)
	   (let ((pos (make-compound-position port)))
	     (let ((ch1 (read-char port)))
	       (cond ((eof-object? ch1)
		      (die/p port 'tokenize "invalid eof after #"))
		     (($char= ch1 #\;)
		      (read-as-comment port)
		      (recurse))
		     (($char= ch1 #\|)
		      (multiline-comment port)
		      (recurse))
		     (else
		      (values (tokenize-hash/c ch1 port) pos))))))
	  ((char-whitespace? ch)
	   (recurse))
	  (else
	   (values (tokenize/c ch port) pos)))))


(define (tokenize-script-initial port)
  (let ((ch (read-char port)))
    (cond ((eof-object? ch)
	   ch)
	  (($char= ch #\;)
	   (skip-comment port)
	   (tokenize/1 port))
	  (($char= ch #\#)
	   (let ((ch1 (read-char port)))
	     (cond ((eof-object? ch1)
		    (die/p port 'tokenize "invalid eof after #"))
		   (($char= ch1 #\!)
		    (skip-comment port)
		    (tokenize/1 port))
		   (($char= ch1 #\;)
		    (read-as-comment port)
		    (tokenize/1 port))
		   (($char= ch1 #\|)
		    (multiline-comment port)
		    (tokenize/1 port))
		   (else
		    (tokenize-hash/c ch1 port)))))
	  ((char-whitespace? ch)
	   (tokenize/1 port))
	  (else
	   (tokenize/c ch port)))))

(define (tokenize-script-initial+pos port)
  (let* ((pos (make-compound-position port))
	 (ch  (read-char port)))
    (cond ((eof-object? ch)
	   (values (eof-object) pos))
	  (($char= ch #\;)
	   (skip-comment port)
	   (tokenize/1+pos port))
	  (($char= ch #\#)
	   (let ((pos (make-compound-position port))
		 (ch1 (read-char port)))
	     (cond ((eof-object? ch1)
		    (die/p port 'tokenize "invalid eof after #"))
		   (($char= ch1 #\!)
		    (skip-comment port)
		    (tokenize/1+pos port))
		   (($char= ch1 #\;)
		    (read-as-comment port)
		    (tokenize/1+pos port))
		   (($char= ch1 #\|)
		    (multiline-comment port)
		    (tokenize/1+pos port))
		   (else
		    (values (tokenize-hash/c ch1 port) pos)))))
	  ((char-whitespace? ch)
	   (tokenize/1+pos port))
	  (else
	   (values (tokenize/c ch port) pos)))))


(module (read-expr read-expr-script-initial)
  (define-syntax tokenize/1 syntax-error)
  (define (annotate-simple datum pos p)
    (make-annotation datum pos #;(cons (port-id p) pos) datum))
  (define (annotate stripped expression pos p)
    (make-annotation expression pos #;(cons (port-id p) pos) stripped))

  (define (read-list p locs k end mis init?)
    (let-values (((t pos) (tokenize/1+pos p)))
      (cond
       ((eof-object? t)
	(die/p p 'read "end of file encountered while reading list"))
       ((eq? t end) (values '() '() locs k))
       ((eq? t mis)
	(die/p-1 p 'read "paren mismatch"))
       ((eq? t 'dot)
	(when init?
	  (die/p-1 p 'read "invalid dot while reading list"))
	(let-values (((d d^ locs k) (read-expr p locs k)))
	  (let-values (((t pos^) (tokenize/1+pos p)))
	    (cond
	     ((eq? t end) (values d d^ locs k))
	     ((eq? t mis)
	      (die/p-1 p 'read "paren mismatch"))
	     ((eq? t 'dot)
	      (die/p-1 p 'read "cannot have two dots in a list"))
	     (else
	      (die/p-1 p 'read
		       (format "expecting ~a, got ~a" end t)))))))
       (else
	(let-values (((a a^ locs k) (parse-token p locs k t pos)))
	  (let-values (((d d^ locs k) (read-list p locs k end mis #f)))
	    (let ((x (cons a d)) (x^ (cons a^ d^)))
	      (values x x^ locs (extend-k-pair x x^ a d k)))))))))

  (define (extend-k-pair x x^ a d k)
    (cond ((or (loc? a) (loc? d))
	   (lambda ()
	     (let ((a (car x)))
	       (when (loc? a)
		 (set-car! x (loc-value a))
		 (set-car! x^ (loc-value^ a))))
	     (let ((d (cdr x)))
	       (when (loc? d)
		 (set-cdr! x (loc-value d))
		 (set-cdr! x^ (loc-value^ d))))
	     (k)))
	  (else k)))

  (define (vector-put v v^ k i ls ls^)
    (cond ((null? ls) k)
	  (else
	   (let ((a (car ls)))
	     (vector-set! v i a)
	     (vector-set! v^ i (car ls^))
	     (vector-put v v^
			 (if (loc? a)
			     (lambda ()
			       (vector-set! v i (loc-value a))
			       (vector-set! v^ i (loc-value^ a))
			       (k))
			   k)
			 (fxsub1 i)
			 (cdr ls)
			 (cdr ls^))))))

  (define (read-vector p locs k count ls ls^)
    (let-values (((token pos) (tokenize/1+pos p)))
      (cond ((eof-object? token)
	     (die/p p 'read "end of file encountered while reading a vector"))
	    ((eq? token 'rparen)
	     (let ((v  (make-vector count))
		   (v^ (make-vector count)))
	       (let ((k (vector-put v v^ k (fxsub1 count) ls ls^)))
		 (values v v^ locs k))))
	    ((eq? token 'rbrack)
	     (die/p-1 p 'read "unexpected ) while reading a vector"))
	    ((eq? token 'dot)
	     (die/p-1 p 'read "unexpected . while reading a vector"))
	    (else
	     (let-values (((a a^ locs k) (parse-token p locs k token pos)))
	       (read-vector p locs k (fxadd1 count)
			    (cons a ls) (cons a^ ls^)))))))

  (define (read-u8-bytevector p locs k count ls)
    (let-values (((t pos) (tokenize/1+pos p)))
      (cond
       ((eof-object? t)
	(die/p p 'read "end of file encountered while reading a bytevector"))
       ((eq? t 'rparen)
	(let ((v (u8-list->bytevector (reverse ls))))
	  (values v v locs k)))
       ((eq? t 'rbrack)
	(die/p-1 p 'read "unexpected ) while reading a bytevector"))
       ((eq? t 'dot)
	(die/p-1 p 'read "unexpected . while reading a bytevector"))
       (else
	(let-values (((a a^ locs k) (parse-token p locs k t pos)))
	  (unless (and (fixnum? a) (fx<= 0 a) (fx<= a 255))
	    (die/ann a^ 'read "invalid value in a u8 bytevector" a))
	  (read-u8-bytevector p locs k (fxadd1 count) (cons a ls)))))))

  (define (read-s8-bytevector p locs k count ls)
    (let-values (((t pos) (tokenize/1+pos p)))
      (cond
       ((eof-object? t)
	(die/p p 'read "end of file encountered while reading a bytevector"))
       ((eq? t 'rparen)
	(let ((v (let ((bv ($make-bytevector count)))
		   (let loop ((i  (- count 1))
			      (ls ls))
		     (if (null? ls)
			 bv
		       (begin
			 ($bytevector-set! bv i (car ls))
			 (loop (- i 1) (cdr ls))))))))
	  (values v v locs k)))
       ((eq? t 'rbrack)
	(die/p-1 p 'read "unexpected ) while reading a bytevector"))
       ((eq? t 'dot)
	(die/p-1 p 'read "unexpected . while reading a bytevector"))
       (else
	(let-values (((a a^ locs k) (parse-token p locs k t pos)))
	  (unless (and (fixnum? a) (fx<= -128 a) (fx<= a 127))
	    (die/ann a^ 'read "invalid value in a s8 bytevector" a))
	  (read-s8-bytevector p locs k (fxadd1 count) (cons a ls)))))))


(define (read-at-expr p locs k at-pos)
  (define-struct nested (a a^))
  (define-struct nested* (a* a*^))

  ;;Commented out because it is never used (Marco Maggi; Oct 12, 2011).
  ;;
  ;; (define (get-chars chars pos p a* a*^)
  ;;   (if (null? chars)
  ;; 	(values a* a*^)
  ;;     (let ((str (list->string chars)))
  ;; 	(let ((str^ (annotate-simple str pos p)))
  ;; 	  (values (cons str a*) (cons str^ a*^))))))

  (define (return start-pos start-col c*** p)
    (let ((indent (apply min start-col
			 (map (lambda (c**)
				(define (st00 c* c** n)
				  (if (null? c*)
				      (st0 c** n)
				    (if (char=? (car c*) #\space)
					(st00 (cdr c*) c** (+ n 1))
				      n)))
				(define (st0 c** n)
				  (if (null? c**)
				      start-col
				    (let ((c* (car c**)))
				      (if (or (nested? c*) (nested*? c*))
					  start-col
					(st00 (car c*) (cdr c**) n)))))
				(st0 c** 0))
			   (cdr c***)))))
      (define (convert c*)
	(if (or (nested? c*) (nested*? c*))
	    c*
	  (let ((str (list->string (car c*))))
	    (let ((str^ (annotate-simple str (cdr c*) p)))
	      (make-nested str str^)))))
      (define (trim/convert c**)
	(define (mk n pos)
	  (let ((str (make-string (- n indent) #\space)))
	    (let ((str^ (annotate-simple str pos p)))
	      (make-nested str str^))))
	(define (s1 c* pos c** n)
	  (if (null? c*)
	      (let ((c* (car c**)))
		(if (or (nested? c*) (nested*? c*))
		    (cons (mk n pos) (map convert c**))
		  (s1 c* pos (cdr c**) n)))
	    (if (char=? (car c*) #\space)
		(s1 (cdr c*) pos c** (+ n 1))
	      (cons*
	       (mk n pos)
	       (map convert (cons (cons c* pos) c**))))))
	(define (s00 c* pos c** n)
	  (if (null? c*)
	      (s0 c** n)
	    (if (char=? #\space (car c*))
		(if (< n indent)
		    (s00 (cdr c*) pos c** (+ n 1))
		  (s1 (cdr c*) pos c** (+ n 1)))
	      (map convert (cons (cons c* pos) c**)))))
	(define (s0 c** n)
	  (if (null? c**)
	      '()
	    (let ((c* (car c**)))
	      (if (or (nested? c*) (nested*? c*))
		  (map convert c**)
		(s00 (car c*) (cdr c*) (cdr c**) n)))))
	(s0 c** 0))
      (define (cons-initial c** c***)
	(define (all-white? c**)
	  (andmap (lambda (c*)
		    (and (not (nested? c*))
			 (not (nested*? c*))
			 (andmap
			  (lambda (c) (char=? c #\space))
			  (car c*))))
		  c**))
	(define (nl)
	  (let ((str "\n"))
	    (list (make-nested str str))))
	(define (S1 c*** n)
	  (if (null? c***)
	      (make-list n (nl))
	    (let ((c** (car c***)) (c*** (cdr c***)))
	      (if (all-white? c**)
		  (S1 c*** (+ n 1))
		(append
		 (make-list n (nl))
		 (cons (trim/convert c**)
		       (S2 c*** 0 0)))))))
	(define (S2 c*** n m)
	  (if (null? c***)
	      (make-list (+ n m) (nl))
	    (let ((c** (car c***)) (c*** (cdr c***)))
	      (if (all-white? c**)
		  (S2 c*** (+ n 1) -1)
		(append
		 (make-list (+ n 1) (nl))
		 (cons (trim/convert c**)
		       (S2 c*** 0 0)))))))
	(define (S0 c** c***)
	  (if (all-white? c**)
	      (S1 c*** 0)
	    (cons
	     (map convert c**)
	     (S2 c*** 0 0))))
	(S0 c** c***))
      (let ((c** (cons-initial (car c***) (cdr c***))))
	(let ((n* (apply append c**)))
	  (define (extract p p* ls)
	    (let f ((ls ls))
	      (cond
	       ((null? ls) '())
	       ((nested? (car ls)) (cons (p (car ls)) (f (cdr ls))))
	       (else (append (p* (car ls)) (f (cdr ls)))))))
	  (let ((c* (extract nested-a nested*-a* n*))
		(c*^ (extract nested-a^ nested*-a*^ n*)))
	    (values c* (annotate c* c*^ start-pos p) locs k))))))
;;; end of RETURN function

  (define (read-text p locs k pref*)
    (let ((start-pos (port-position p))
	  (start-col (input-port-column-number p)))
      (let f ((c* '()) (pos start-pos)
	      (c** '()) (c*** '())
	      (depth 0) (locs locs) (k k))
	(define (match-prefix c* pref*)
	  (cond
	   ((and (pair? c*) (pair? pref*))
	    (and (char=? (car c*) (car pref*))
		 (match-prefix (cdr c*) (cdr pref*))))
	   (else (and (null? pref*) c*))))
	(let ((c (read-char p)))
	  (cond
	   ((eof-object? c)
	    (die/p p 'read "end of file while reading @-expr text"))
	   ((char=? c #\})
	    (let g ((x* (cons #\} c*)) (p* pref*))
	      (if (null? p*)
		  (if (= depth 0)
		      (let ((c**
			     (reverse
			      (if (null? c*)
				  c**
				(cons (cons (reverse c*) pos) c**)))))
			(let ((c*** (reverse (cons c** c***))))
			  (return start-pos start-col c*** p)))
		    (f x* pos c** c*** (- depth 1) locs k))
		(let ((c (peek-char p)))
		  (cond
		   ((eof-object? c)
		    (die/p p 'read "invalid eof inside @-expression"))
		   ((char=? c (rev-punc (car p*)))
		    (read-char p)
		    (g (cons c x*) (cdr p*)))
		   (else
		    (f x* pos c** c*** depth locs k)))))))
	   ((char=? c #\{)
	    (f (cons c c*) pos c** c***
	       (if (match-prefix c* pref*) (+ depth 1) depth)
	       locs k))
	   ((char=? c #\newline)
	    (f '()
	       (port-position p)
	       '()
	       (cons (reverse
		      (if (null? c*)
			  c**
			(cons (cons (reverse c*) pos) c**)))
		     c***)
	       depth locs k))
	   ((and (char=? c #\@) (match-prefix c* pref*)) =>
	    (lambda (c*)
	      (let ((c (peek-char p)))
		(cond
		 ((eof-object? c)
		  (die/p p 'read "invalid eof inside nested @-expr"))
		 ((char=? c #\")
		  (read-char p)
		  (let ((c* (tokenize-string c* p)))
		    (f c* pos c** c*** depth locs k)))
		 (else
		  (let-values (((a* a*^ locs k)
				(read-at-text-mode p locs k)))
		    (f '()
		       (port-position p)
		       (cons (make-nested* a* a*^)
			     (if (null? c*)
				 c**
			       (cons (cons (reverse c*) pos) c**)))
		       c*** depth locs k)))))))
	   (else
	    (f (cons c c*) pos c** c*** depth locs k)))))))
;;;end of READ-TEXT function

  (define (read-brackets p locs k)
    (let-values (((a* a*^ locs k)
		  (read-list p locs k 'rbrack 'rparen #t)))
      (unless (list? a*)
	(die/ann a*^ 'read "not a proper list"))
      (let ((c (peek-char p)))
	(cond
	 ((eof-object? c) ;;; @<cmd>(...)
	  (values a* a*^ locs k))
	 ((char=? c #\{)
	  (read-char p)
	  (let-values (((b* b*^ locs k)
			(read-text p locs k '())))
	    (values (append a* b*)
		    (append a*^ b*^)
		    locs k)))
	 ((char=? c #\|)
	  (read-char p)
	  (let-values (((b* b*^ locs k)
			(read-at-bar p locs k #t)))
	    (values (append a* b*)
		    (append a*^ b*^)
		    locs k)))
	 (else (values a* a*^ locs k))))))
  (define (left-punc? c)
    (define chars "((<!?~$%^&*-_+=:")
    (let f ((i 0))
      (cond
       ((= i (string-length chars)) #f)
       ((char=? c (string-ref chars i)) #t)
       (else (f (+ i 1))))))
  (define (rev-punc c)
    (cond
     ((char=? c #\() #\))
     ((char=? c #\[) #\])
     ((char=? c #\<) #\>)
     (else c)))
  (define (read-at-bar p locs k text-mode?)
    (let ((c (peek-char p)))
      (cond
       ((eof-object? c)
	(die/p p 'read "eof inside @|-expression"))
       ((and (char=? c #\|) text-mode?) ;;; @||
	(read-char p)
	(values '() '() locs k))
       ((char=? c #\{) ;;; @|{
	(read-char p)
	(read-text p locs k '(#\|)))
       ((left-punc? c) ;;; @|<({
	(read-char p)
	(let ((pos (port-position p)))
	  (let f ((ls (list c)))
	    (let ((c (peek-char p)))
	      (cond
	       ((eof-object? c)
		(die/p p 'read "eof inside @|< mode"))
	       ((left-punc? c)
		(read-char p)
		(f (cons c ls)))
	       ((char=? c #\{)
		(read-char p)
		(read-text p locs k (append ls '(#\|))))
	       (else
		(read-at-bar-others ls p locs k)))))))
       (text-mode? ;;; @|5 6 7|
	(read-at-bar-datum p locs k))
       (else
	(die/p p 'read "invalid char in @| mode" c)))))

  (define (read-at-bar-others ls p locs k)
    (define (split ls)
      (cond
       ((null? ls) (values '() '()))
       ((initial? (car ls))
	(let-values (((a d) (split (cdr ls))))
	  (values (cons (car ls) a) d)))
       (else
	(values '() ls))))
    (define (mksymbol ls)
      (let ((s (string->symbol (reverse-list->string ls))))
	(values s s)))
    (let-values (((inits rest) (split ls)))
      (let ((ls (tokenize-identifier inits p)))
	(let-values (((s s^) (mksymbol ls)))
	  (let g ((rest rest)
		  (a* (list s))
		  (a*^ (list s^))
		  (locs locs)
		  (k k))
	    (if (null? rest)
		(let-values (((b* b*^ locs k)
			      (read-at-bar-datum p locs k)))
		  (values (append a* b*) (append a*^ b*^) locs k))
	      (let ((x (car rest)))
		(case x
		  ((#\() #\) ;;; vim paren-matching sucks
		   (let-values (((b* b*^ locs k)
				 (read-list p locs k 'rparen 'rbrack #t)))
		     (g (cdr rest)
			(list (append a* b*))
			(list (append a*^ b*^))
			locs k)))
		  ((#\[) #\] ;;;  vim paren-matching sucks
		   (let-values (((b* b*^ locs k)
				 (read-list p locs k 'rbrack 'rparen #t)))
		     (g (cdr rest)
			(list (append a* b*))
			(list (append a*^ b*^))
			locs k)))
		  (else
		   (let-values (((inits rest) (split rest)))
		     (let-values (((s s^) (mksymbol inits)))
		       (g rest
			  (cons s a*)
			  (cons s^ a*^)
			  locs k))))))))))))
;;; end of READ-AT-BAR-OTHERS

  (define (read-at-bar-datum p locs k)
    (let ((c (peek-char p)))
      (cond
       ((eof-object? c) (die/p p 'read "eof inside @|datum mode"))
       ((char-whitespace? c)
	(read-char p)
	(read-at-bar-datum p locs k))
       ((char=? c #\|)
	(read-char p)
	(values '() '() locs k))
       (else
	(let-values (((a a^ locs k) (read-expr p locs k)))
	  (let-values (((a* a*^ locs k) (read-at-bar-datum p locs k)))
	    (values (cons a a*) (cons a^ a*^) locs k)))))))

  (define (read-at-text-mode p locs k)
    (let ((c (peek-char p)))
      (cond
       ((eof-object? c)
	(die/p p 'read "eof encountered inside @-expression"))
       ((char=? c #\|)
	(read-char p)
	(read-at-bar p locs k #t))
       (else
	(let-values (((a a^ locs k)
		      (read-at-sexpr-mode p locs k)))
	  (values (list a) (list a^) locs k))))))

  (define (read-at-sexpr-mode p locs k)
    (let ((c (peek-char p)))
      (cond
       ((eof-object? c)
	(die/p p 'read "eof encountered inside @-expression"))
       ((eqv? c '#\[) ;;;   @( ...
	(read-char p)
	(read-brackets p locs k))
       ((eqv? c #\{) ;;;   @{ ...
	(read-char p)
	(read-text p locs k '()))
       ((char=? c #\|)
	(read-char p)
	(read-at-bar p locs k #f))
       (else ;;;   @<cmd> ...
	(let-values (((a a^ locs k) (read-expr p locs k)))
	  (let ((c (peek-char p)))
	    (cond
	     ((eof-object? c) ;;; @<cmd><eof>
	      (values a a^ locs k))
	     ((eqv? c #\[)
	      (read-char p)
	      (let-values (((a* a*^ locs k)
			    (read-brackets p locs k)))
		(let ((v (cons a a*)) (v^ (cons a^ a*^)))
		  (values v (annotate v v^ at-pos p) locs k))))
	     ((eqv? c #\{) ;;; @<cmd>{ ...
	      (read-char p)
	      (let-values (((a* a*^ locs k)
			    (read-text p locs k '())))
		(let ((v (cons a a*)) (v^ (cons a^ a*^)))
		  (values v (annotate v v^ at-pos p) locs k))))
	     ((eqv? c #\|) ;;; @<cmd>| ...
	      (read-char p)
	      (let-values (((a* a*^ locs k)
			    (read-at-bar p locs k #f)))
		(let ((v (cons a a*)) (v^ (cons a^ a*^)))
		  (values v (annotate v v^ at-pos p) locs k))))
	     (else
	      (values a a^ locs k)))))))))

  (read-at-sexpr-mode p locs k))


(define (parse-token p locs k t pos)
  (cond
   ((eof-object? t)
    (values (eof-object)
	    (annotate-simple (eof-object) pos p) locs k))
   ((eq? t 'lparen)
    (let-values (((ls ls^ locs k)
		  (read-list p locs k 'rparen 'rbrack #t)))
      (values ls (annotate ls ls^ pos p) locs k)))
   ((eq? t 'lbrack)
    (let-values (((ls ls^ locs k)
		  (read-list p locs k 'rbrack 'rparen #t)))
      (values ls (annotate ls ls^ pos p) locs k)))
   ((eq? t 'vparen)
    (let-values (((v v^ locs k)
		  (read-vector p locs k 0 '() '())))
      (values v (annotate v v^ pos p) locs k)))
   ((eq? t 'vu8)
    (let-values (((v v^ locs k)
		  (read-u8-bytevector p locs k 0 '())))
      (values v (annotate v v^ pos p) locs k)))
   ((eq? t 'vs8)
    (let-values (((v v^ locs k)
		  (read-s8-bytevector p locs k 0 '())))
      (values v (annotate v v^ pos p) locs k)))
   ((eq? t 'at-expr)
    (read-at-expr p locs k pos))
   ((pair? t)
    (cond
     ((eq? (car t) 'datum)
      (values (cdr t)
	      (annotate-simple (cdr t) pos p) locs k))
     ((eq? (car t) 'macro)
      (let ((macro (cdr t)))
	(define (read-macro)
	  (let-values (((t pos) (tokenize/1+pos p)))
	    (cond
	     ((eof-object? t)
	      (die/p p 'read
		     (format "invalid eof after ~a read macro"
		       macro)))
	     (else (parse-token p locs k t pos)))))
	(let-values (((expr expr^ locs k) (read-macro)))
	  (let ((d (list expr)) (d^ (list expr^)))
	    (let ((x (cons macro d))
		  (x^ (cons (annotate-simple macro pos p) d^)))
	      (values x (annotate x x^ pos p) locs
		      (extend-k-pair d d^ expr '() k)))))))
     ((eq? (car t) 'mark)
      (let ((n (cdr t)))
	(let-values (((expr expr^ locs k)
		      (read-expr p locs k)))
	  (cond
	   ((assq n locs) =>
	    (lambda (x)
	      (let ((loc (cdr x)))
		(when (loc-set? loc) ;;; FIXME: pos
		  (die/p p 'read "duplicate mark" n))
		(set-loc-value! loc expr)
		(set-loc-value^! loc expr^)
		(set-loc-set?! loc #t)
		(values expr expr^ locs k))))
	   (else
	    (let ((loc (make-loc expr 'unused #t)))
	      (let ((locs (cons (cons n loc) locs)))
		(values expr expr^ locs k))))))))
     ((eq? (car t) 'ref)
      (let ((n (cdr t)))
	(cond
	 ((assq n locs) =>
	  (lambda (x)
	    (values (cdr x) 'unused locs k)))
	 (else
	  (let ((loc (make-loc #f 'unused #f)))
	    (let ((locs (cons (cons n loc) locs)))
	      (values loc 'unused locs k)))))))
     (else (die/p p 'read "invalid token" t))))
   (else
    (die/p-1 p 'read (format "unexpected ~s found" t)))))


(define read-expr
  (lambda (p locs k)
    (let-values (((t pos) (tokenize/1+pos p)))
      (parse-token p locs k t pos))))

(define read-expr-script-initial
  (lambda (p locs k)
    (let-values (((t pos) (tokenize-script-initial+pos p)))
      (parse-token p locs k t pos))))

#| end of module (read-expr read-expr-script-initial) |# )


(define (reduce-loc! p)
  (lambda (x)
    (let ((loc (cdr x)))
      (unless (loc-set? loc)
	(die/p p 'read "referenced mark is not set" (car x)))
      (when (loc? (loc-value loc))
	(let f ((h loc) (t loc))
	  (if (loc? h)
	      (let ((h1 (loc-value h)))
		(if (loc? h1)
		    (begin
		      (when (eq? h1 t)
			(die/p p 'read "circular marks"))
		      (let ((v (f (loc-value h1) (loc-value t))))
			(set-loc-value! h1 v)
			(set-loc-value! h v)
			v))
		  (begin
		    (set-loc-value! h h1)
		    h1)))
	    h))))))

(define (read-as-comment p)
  (begin (read-expr p '() void) (void)))

(define (return-annotated x)
  (cond
   ((and (annotation? x) (eof-object? (annotation-expression x)))
    (eof-object))
   (else x)))

(define my-read
  (lambda (p)
    (let-values (((expr expr^ locs k) (read-expr p '() void)))
      (cond
       ((null? locs) expr)
       (else
	(for-each (reduce-loc! p) locs)
	(k)
	(if (loc? expr)
	    (loc-value expr)
	  expr))))))

(define read-initial
  (lambda (p)
    (let-values (((expr expr^ locs k) (read-expr-script-initial p '() void)))
      (cond
       ((null? locs) expr)
       (else
	(for-each (reduce-loc! p) locs)
	(k)
	(if (loc? expr)
	    (loc-value expr)
	  expr))))))

(define read-annotated
  (case-lambda
   ((p)
    (unless (input-port? p)
      (error 'read-annotated "not an input port" p))
    (let-values (((expr expr^ locs k) (read-expr p '() void)))
      (cond
       ((null? locs) (return-annotated expr^))
       (else
	(for-each (reduce-loc! p) locs)
	(k)
	(if (loc? expr)
	    (loc-value^ expr)
	  (return-annotated expr^))))))
   (() (read-annotated (current-input-port)))))

(define read-script-annotated
  (lambda (p)
    (let-values (((expr expr^ locs k) (read-expr-script-initial p '() void)))
      (cond
       ((null? locs) (return-annotated expr^))
       (else
	(for-each (reduce-loc! p) locs)
	(k)
	(if (loc? expr)
	    (loc-value^ expr)
	  (return-annotated expr^)))))))

(define read-token
  (case-lambda
   (() (tokenize/1 (current-input-port)))
   ((p)
    (if (input-port? p)
	(tokenize/1 p)
      (assertion-violation 'read-token "not an input port" p)))))

(define read
  (case-lambda
   (() (my-read (current-input-port)))
   ((p)
    (if (input-port? p)
	(my-read p)
      (assertion-violation 'read "not an input port" p)))))

(define (get-datum p)
  (unless (input-port? p)
    (assertion-violation 'get-datum "not an input port"))
  (my-read p))

(define comment-handler
    ;;; this is stale, maybe delete
  (make-parameter
      (lambda (x) (void))
    (lambda (x)
      (unless (procedure? x)
	(assertion-violation 'comment-handler "not a procedure" x))
      x)))


;;;; done

)

;;; end of file
