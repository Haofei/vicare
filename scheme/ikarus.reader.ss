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


(define (die/lex pos who msg arg*)
  (raise
   (condition (make-lexical-violation)
	      (make-message-condition msg)
	      (if (null? arg*)
		  (condition)
		(make-irritants-condition arg*))
	      (let ((port-id (car pos))
		    (byte    (cdr pos)))
		(make-source-position-condition port-id byte #f))
	      )))

(define (die/pos port offset who msg arg*)
  (die/lex (make-compound-position/with-offset port offset) who msg arg*))

(define (die/p p who msg . arg*)
  (die/pos p 0 who msg arg*))

(define (die/p-1 p who msg . arg*)
  (die/pos p -1 who msg arg*))

(define (die/ann ann who msg . arg*)
  (die/lex (annotation-source ann) who msg arg*))

(define (num-error p str ls)
  (die/p-1 p 'read str (list->string (reverse ls))))


(define (checked-integer->char n ac p)
  (define (valid-integer-char? n)
    (cond
     ((<= n #xD7FF)   #t)
     ((< n #xE000)    #f)
     ((<= n #x10FFFF) #t)
     (else            #f)))
  (if (valid-integer-char? n)
      ($fixnum->char n)
    (die/p p 'tokenize
	   "invalid numeric value for character"
	   (list->string (reverse ac)))))

(define-syntax read-char
  (syntax-rules ()
    ((_ p) (get-char p))))

(define delimiter?
  (lambda (c)
    (or (char-whitespace? c)
	(memq c '(#\( #\) #\[ #\] #\" #\# #\; #\{ #\} #\|)))))
(define digit?
  (lambda (c)
    (and ($char<= #\0 c) ($char<= c #\9))))
(define char->num
  (lambda (c)
    (fx- ($char->fixnum c) ($char->fixnum #\0))))

(define (initial? c)
  (cond (($char<= c ($fixnum->char 127))
	 (or (letter? c) (special-initial? c)))
	(else
	 (unicode-printable-char? c))))

(define letter?
  (lambda (c)
    (or (and ($char<= #\a c) ($char<= c #\z))
	(and ($char<= #\A c) ($char<= c #\Z)))))
(define special-initial?
  (lambda (c)
    (memq c '(#\! #\$ #\% #\& #\* #\/ #\: #\< #\= #\> #\? #\^ #\_ #\~))))
(define special-subsequent?
  (lambda (c)
    (memq c '(#\+ #\- #\. #\@))))
(define subsequent?
  (lambda (c)
    (cond
     (($char<= c ($fixnum->char 127))
      (or (letter? c)
	  (digit? c)
	  (special-initial? c)
	  (special-subsequent? c)))
     (else
      (or (unicode-printable-char? c)
	  (memq (char-general-category c) '(Nd Mc Me)))))))
(define tokenize-identifier
  (lambda (ls p)
    (let ((c (peek-char p)))
      (cond
       ((eof-object? c) ls)
       ((subsequent? c)
	(read-char p)
	(tokenize-identifier (cons c ls) p))
       ((delimiter? c)
	ls)
       ((char=? c #\\)
	(read-char p)
	(tokenize-backslash ls p))
       ((eq? (port-mode p) 'r6rs-mode)
	(die/p p 'tokenize "invalid identifier syntax"
	       (list->string (reverse (cons c ls)))))
       (else ls)))))
(define (tokenize-string ls p)
  (let ((c (read-char p)))
    (cond
     ((eof-object? c)
      (die/p p 'tokenize "invalid eof inside string"))
     (else (tokenize-string-char ls p c)))))
(define LF1 '(#\xA #\x85 #\x2028)) ;;; these are considered newlines
(define LF2 '(#\xA #\x85))         ;;; these are not newlines if they
                                     ;;; appear after CR
(define (tokenize-string-char ls p c)
  (define (intraline-whitespace? c)
    (or (eqv? c #\x9)
	(eq? (char-general-category c) 'Zs)))
  (define (tokenize-string-continue ls p c)
    (cond
     ((eof-object? c)
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
  (cond
   (($char= #\" c) ls)
   (($char= #\\ c)
    (let ((c (read-char p)))
      (cond
       ((eof-object? c)
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
	  (cond
	   ((eof-object? c)
	    (die/p p 'tokenize "invalid eof inside string"))
	   ((hex c) =>
	    (lambda (n)
	      (let f ((n n) (ac (cons c '(#\x))))
		(let ((c (read-char p)))
		  (cond
		   ((eof-object? n)
		    (die/p p 'tokenize "invalid eof inside string"))
		   ((hex c) =>
		    (lambda (v) (f (+ (* n 16) v) (cons c ac))))
		   (($char= c #\;)
		    (tokenize-string
		     (cons (checked-integer->char n ac p) ls) p))
		   (else
		    (die/p-1 p 'tokenize
			     "invalid char in escape sequence"
			     (list->string (reverse (cons c ac))))))))))
	   (else
	    (die/p-1 p 'tokenize
		     "invalid char in escape sequence" c)))))
       ((intraline-whitespace? c)
	(let f ()
	  (let ((c (read-char p)))
	    (cond
	     ((eof-object? c)
	      (die/p p 'tokenize "invalid eof inside string"))
	     ((intraline-whitespace? c) (f))
	     ((memv c LF1)
	      (tokenize-string-continue ls p (read-char p)))
	     ((eqv? c #\return)
	      (let ((c (read-char p)))
		(cond
		 ((memv c LF2)
		  (tokenize-string-continue ls p (read-char p)))
		 (else
		  (tokenize-string-continue ls p c)))))
	     (else
	      (die/p-1 p 'tokenize
		       "non-whitespace character after escape"))))))
       ((memv c LF1)
	(tokenize-string-continue ls p (read-char p)))
       ((eqv? c #\return)
	(let ((c (read-char p)))
	  (cond
	   ((memv c LF2)
	    (tokenize-string-continue ls p (read-char p)))
	   (else
	    (tokenize-string-continue ls p c)))))
       (else (die/p-1 p 'tokenize "invalid string escape" c)))))
   ((memv c LF1)
    (tokenize-string (cons #\linefeed ls) p))
   ((eqv? c #\return)
    (let ((c (peek-char p)))
      (when (memv c LF2) (read-char p))
      (tokenize-string (cons #\linefeed ls) p)))
   (else
    (tokenize-string (cons c ls) p))))
(define skip-comment
  (lambda (p)
    (let ((c (read-char p)))
      (unless (or (eof-object? c) (memv c LF1) (eqv? c #\return))
	(skip-comment p)))))


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
	  (($char= #\x ch)
	   (let ((n (peek-char port)))
	     (cond ((or (eof-object? n) (delimiter? n))
		    '(datum . #\x))
		   ((hex n)
		    => (lambda (v)
			 (read-char port)
			 (let f ((v v) (ac (cons n '(#\x))))
			   (let ((c (peek-char port)))
			     (cond ((eof-object? c)
				    (cons 'datum (checked-integer->char v ac port)))
				   ((delimiter? c)
				    (cons 'datum (checked-integer->char v ac port)))
				   ((hex c)
				    => (lambda (v0)
					 (read-char port)
					 (f (+ (* v 16) v0) (cons c ac))))
				   (else
				    (%error "invalid character sequence"
					    (list->string (reverse (cons c ac))))))))))
		   (else
		    (%error "invalid character sequence"
			    (string-append "#\\" (string n)))))))
	  (else
	   (let ((ch1 (peek-char port)))
	     (if (or (eof-object? ch1)
		     (delimiter?  ch1))
		 (cons 'datum ch)
	       (%error "invalid syntax" (string-append "#\\" (string ch ch1)))))))))


(define (hex x)
  (cond
   ((and ($char<= #\0 x) ($char<= x #\9))
    ($fx- ($char->fixnum x) ($char->fixnum #\0)))
   ((and ($char<= #\a x) ($char<= x #\f))
    ($fx- ($char->fixnum x)
	  ($fx- ($char->fixnum #\a) 10)))
   ((and ($char<= #\A x) ($char<= x #\F))
    ($fx- ($char->fixnum x)
	  ($fx- ($char->fixnum #\A) 10)))
   (else #f)))
(define multiline-error
  (lambda (p)
    (die/p p 'tokenize
	   "end of file encountered while inside a #|-style comment")))
(define apprev
  (lambda (str i ac)
    (cond
     ((fx= i (string-length str)) ac)
     (else
      (apprev str (fx+ i 1) (cons (string-ref str i) ac))))))
(define multiline-comment
  (lambda (p)
    (define f
      (lambda (p ac)
	(let ((c (read-char p)))
	  (cond
	   ((eof-object? c) (multiline-error p))
	   (($char= #\| c)
	    (let g ((c (read-char p)) (ac ac))
	      (cond
	       ((eof-object? c) (multiline-error p))
	       (($char= #\# c) ac)
	       (($char= #\| c)
		(g (read-char p) (cons c ac)))
	       (else (f p (cons c ac))))))
	   (($char= #\# c)
	    (let ((c (read-char p)))
	      (cond
	       ((eof-object? c) (multiline-error p))
	       (($char= #\| c)
		(let ((v (multiline-comment p)))
		  (if (string? v)
		      (f p (apprev v 0 ac))
		    (f p ac))))
	       (else
		(f p (cons c (cons #\# ac)))))))
	   (else (f p (cons c ac)))))))
    (let ((ac (f p '())))
      ((comment-handler)
       (list->string (reverse ac))))))

(define (skip-whitespace p caller)
  (let ((c (read-char p)))
    (cond
     ((eof-object? c)
      (die/p p 'tokenize "invalid eof inside" caller))
     ((char-whitespace? c)
      (skip-whitespace p caller))
     (else c))))


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
	 (when (eq? (port-mode port) 'r6rs-mode)
	   (%error-1 "invalid syntax: #!e"))
	 (read-char* port '(#\e) "of" "eof sequence" #f #f)
	 (cons 'datum (eof-object)))
	((#\r)
	 (read-char* port '(#\r) "6rs" "#!r6rs comment" #f #f)
	 (set-port-mode! port 'r6rs-mode)
	 (tokenize/1 port))
	((#\v)
	 (read-char* port '(#\v) "icare" "#!vicare comment" #f #f)
	 (set-port-mode! port 'vicare-mode)
	 (tokenize/1 port))
	(else
	 (%error-1 (format "invalid syntax near #!~a" ch1))))))

   ((digit? ch)
    (when (eq? (port-mode port) 'r6rs-mode)
      (%error-1 "graph syntax is invalid in #!r6rs mode" (format "#~a" ch)))
    (tokenize-hashnum port (char->num ch)))

   (($char= #\: ch)
    (when (eq? (port-mode port) 'r6rs-mode)
      (%error-1 "gensym syntax is invalid in #!r6rs mode" (format "#~a" ch)))
    (let* ((ch1 (skip-whitespace port "gensym"))
	   (id0 (cond ((initial? ch1)
		       (list->string (reverse (tokenize-identifier (cons ch1 '()) port))))
		      (($char= #\| ch1)
		       (list->string (reverse (tokenize-bar port '()))))
		      (else
		       (%error-1 "invalid char inside gensym" ch1)))))
      (cons 'datum (gensym id0))))

   (($char= #\{ ch)
    (when (eq? (port-mode port) 'r6rs-mode)
      (%error-1 "gensym syntax is invalid in #!r6rs mode" (format "#~a" ch)))
    (let* ((ch1 (skip-whitespace port "gensym"))
	   (id0 (cond ((initial? ch1)
		       (list->string (reverse (tokenize-identifier (cons ch1 '()) port))))
		      (($char= #\| ch1)
		       (list->string (reverse (tokenize-bar port '()))))
		      (else
		       (%error-1 "invalid char inside gensym" ch1))))
	   (ch1 (skip-whitespace port "gensym")))
      (cond (($char= #\} ch1)
	     (cons 'datum (foreign-call "ikrt_strings_to_gensym" #f id0)))
	    (else
	     (let ((id1 (cond ((initial? ch1)
			       (list->string (reverse (tokenize-identifier (cons ch1 '()) port))))
			      (($char= #\| ch1)
			       (list->string (reverse (tokenize-bar port '()))))
			      (else
			       (%error-1 "invalid char inside gensym" ch1)))))
	       (let ((c (skip-whitespace port "gensym")))
		 (cond (($char= #\} ch1)
			(cons 'datum (foreign-call "ikrt_strings_to_gensym" id0 id1)))
		       (else
			(%error-1 "invalid char inside gensym" ch1)))))))))

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
	       (when (eq? (port-mode port) 'r6rs-mode)
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
;;; (when (eq? (port-mode port) 'r6rs-mode)
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
	      (%error (format "invalid ~a: ~s" who (list->string (reverse (cons ch ls))))))))
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
	       (%error-1 (format "invalid ~a: ~s" who (list->string (reverse (cons ch ls)))))))))))


(define (tokenize-hashnum p n)
  (let ((c (read-char p)))
    (cond
     ((eof-object? c)
      (die/p p 'tokenize "invalid eof inside #n mark/ref"))
     (($char= #\= c) (cons 'mark n))
     (($char= #\# c) (cons 'ref n))
     ((digit? c)
      (tokenize-hashnum p (fx+ (fx* n 10) (char->num c))))
     (else
      (die/p-1 p 'tokenize "invalid char while inside a #n mark/ref" c)))))

(define tokenize-bar
  (lambda (p ac)
    (let ((c (read-char p)))
      (cond
       ((eof-object? c)
	(die/p p 'tokenize "unexpected eof while reading symbol"))
       (($char= #\\ c)
	(let ((c (read-char p)))
	  (cond
	   ((eof-object? c)
	    (die/p p 'tokenize "unexpected eof while reading symbol"))
	   (else (tokenize-bar p (cons c ac))))))
       (($char= #\| c) ac)
       (else (tokenize-bar p (cons c ac)))))))

(define (tokenize-backslash main-ac p)
  (let ((c (read-char p)))
    (cond
     ((eof-object? c)
      (die/p p 'tokenize "invalid eof after symbol escape"))
     (($char= #\x c)
      (let ((c (read-char p)))
	(cond
	 ((eof-object? c)
	  (die/p p 'tokenize "invalid eof after \\x"))
	 ((hex c) =>
	  (lambda (v)
	    (let f ((v v) (ac `(,c #\x #\\)))
	      (let ((c (read-char p)))
		(cond
		 ((eof-object? c)
		  (die/p p 'tokenize
                         (format "invalid eof after ~a"
                           (list->string (reverse ac)))))
		 (($char= #\; c)
		  (tokenize-identifier
		   (cons (checked-integer->char v ac p) main-ac)
		   p))
		 ((hex c) =>
		  (lambda (v0)
		    (f (+ (* v 16) v0) (cons c ac))))
		 (else
		  (die/p-1 p 'tokenize "invalid sequence"
			   (list->string (cons c (reverse ac))))))))))
	 (else
	  (die/p-1 p 'tokenize
		   (format "invalid sequence \\x~a" c))))))
     (else
      (die/p-1 p 'tokenize
	       (format "invalid sequence \\~a" c))))))


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
	   (cons 'datum (list->string (reverse ls)))))

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
	 (when (eq? (port-mode port) 'r6rs-mode)
	   (%error "|symbol| syntax is invalid in #!r6rs mode"))
	 (let ((ls (reverse (tokenize-bar port '()))))
	   (cons 'datum (string->symbol (list->string ls)))))

	;;everything starting with a backslash, for example characters
	(($char= #\\ ch)
	 (cons 'datum (string->symbol (list->string (reverse (tokenize-backslash '() port))))))

;;;Unused for now.
;;;
;;;     (($char= #\{ ch) 'lbrace)

	(($char= #\@ ch)
	 (when (eq? (port-mode port) 'r6rs-mode)
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
      (let ((s (string->symbol (list->string (reverse ls)))))
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

#| end of module |# )


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
      (die 'read-token "not an input port" p)))))

(define read
  (case-lambda
   (() (my-read (current-input-port)))
   ((p)
    (if (input-port? p)
	(my-read p)
      (die 'read "not an input port" p)))))

(define (get-datum p)
  (unless (input-port? p)
    (die 'get-datum "not an input port"))
  (my-read p))

(define comment-handler
    ;;; this is stale, maybe delete
  (make-parameter
      (lambda (x) (void))
    (lambda (x)
      (unless (procedure? x)
	(die 'comment-handler "not a procedure" x))
      x)))


;;;; done

)

;;; end of file
