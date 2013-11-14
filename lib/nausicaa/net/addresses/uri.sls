;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: URI handling
;;;Date: Wed Jun  2, 2010
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (c) 2010-2011, 2013 Marco Maggi <marco.maggi-ipsu@poste.it>
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
(library (nausicaa net addresses uri)
  (export
    <uri> <relative-ref>

    ;; URI components
    <scheme> <userinfo> <host> <port-number>
    <query> <fragment>
    <path> <path-empty> <path-abempty> <path-absolute> <path-rootless>
    <path-noscheme>

    ;; auxiliary classes and labels
    <segment>	<list-of-segments>

    ;; utility functions
    make-path-object

    ;; auxiliary syntaxes
    scheme		specified-authority?	userinfo
    host		port-number
    path		query			fragment

;;; --------------------------------------------------------------------
;;; reexported from (nausicaa net addresses ip)

    <ip-address>
    <ip-numeric-address>
    <reg-name-address>
    <ipvfuture-address>

    <ipv4-address>			<ipv4-address-prefix>
    <ipv4-address-fixnum>		<vector-of-ipv4-address-fixnums>
    <ipv4-address-prefix-length>

    <ipv6-address>			<ipv6-address-prefix>
    <ipv6-address-fixnum>		<vector-of-ipv6-address-fixnums>
    <ipv6-address-prefix-length>

    ;; utility functions
    make-host-object

    ;; multimethods
    ip-address->string
    ip-address->bytevector
    ip-address->bignum)
  (import (nausicaa)
    (nausicaa net addresses ip)
    (prefix (vicare language-extensions makers) mk.)
    (vicare unsafe operations)
    (vicare language-extensions ascii-chars)
    ;;FIXME  To be  removed at  the  next boot  image rotation.   (Marco
    ;;Maggi; Mon Nov 4, 2013)
    (only (vicare system $bytevectors)
	  $uri-encoded-bytevector?)
    (only (vicare system $strings)
	  $ascii->string)
    ;;FIXME  To be  removed at  the  next boot  image rotation.   (Marco
    ;;Maggi; Fri Nov 8, 2013)
    (only (vicare system $lists)
	  $for-all1))


;;;; helpers

(define-auxiliary-syntaxes
  scheme
  specified-authority?
  userinfo
  host
  port-number
  path
  query
  fragment)

(define-syntax $bytevector-for-all
  (syntax-rules ()
    ((_ (?pred0 ?pred ...) ?start ?bv)
     (let loop ((bv ?bv)
		(i  ?start))
       (or ($fx= i ($bytevector-length bv))
	   (and (let ((chi ($bytevector-u8-ref bv i)))
		  (or (?pred0 chi) (?pred  chi) ...))
		(loop bv ($fxadd1 i))))))
    ))


;;;; auxiliary labels and classes: scheme

(define-label <scheme>
  (parent <nonempty-bytevector>)

  (protocol
   (lambda ()
     ;;Apply the predicate, through the tagged argument, and return.
     (lambda ((bv <scheme>))
       bv)))

  (predicate
   (lambda (bv)
     (and ($ascii-alphabetic? ($bytevector-u8-ref bv 0))
	  ($bytevector-for-all ($ascii-alpha-digit?
				$ascii-chi-plus?
				$ascii-chi-minus?
				$ascii-chi-dot?)
			       1 bv))))

  (virtual-fields
   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <scheme>))
		;;58 = #\:
		(bytevector-append O '#vu8(58))))

   (immutable (string <ascii-string>)
	      (lambda ((O <scheme>))
		($ascii->string (O bytevector))))

   #| end of virtual-fields |# )

  (method (put-bytevector (O <scheme>) (port <binary-output-port>))
    (put-bytevector port O)
    ;;58 = #\:
    (put-u8         port 58))

  #| end of label |# )


;;;; auxiliary labels and classes: userinfo

(define-label <userinfo>
  (parent <bytevector>)

  (protocol
   (lambda ()
     ;;Apply the predicate, through the tagged argument, and return.
     (lambda ((bv <userinfo>))
       bv)))

  (predicate
   (lambda (bv)
     (let loop ((bv bv)
		(i  0))
       (or ($fx= i ($bytevector-length bv))
	   (let ((chi ($bytevector-u8-ref bv i)))
	     (and (or ($ascii-uri-unreserved? chi)
		      ($ascii-uri-sub-delim?  chi)
		      ($ascii-chi-colon?      chi)
		      ($ascii-uri-pct-encoded? chi bv i))
		  (loop bv ($fxadd1 i))))))))

  (virtual-fields
   (immutable (specified? <boolean>)
	      (lambda (bv)
		($bytevector-not-empty? bv)))

   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <userinfo>))
		(if (O specified?)
		    (bytevector-append O #vu8(64)) ;64 = #\@
		  '#vu8())))

   (immutable (string <ascii-string>)
	      (lambda ((O <userinfo>))
		($ascii->string (O bytevector))))

   #| end of virtual-fields |# )

  (method (put-bytevector (O <userinfo>) port)
    (when (O specified?)
      (put-bytevector port O)
      ;;64 = #\@
      (put-u8         port 64)))

  #| end of class |# )


;;;; auxiliary labels and classes: host

(define-label <host>
  (parent <ip-address>)

  (method (put-bytevector (O <ip-address>) port)
    (put-bytevector port (O bytevector)))

  #| end of label |# )


;;;; auxiliary labels and classes: port number

(module (<port-number>)

  (define-label <port-number>
    (parent <nonnegative-fixnum>)
    (predicate
     (lambda (fx)
       ($fx<= fx 65535)))

    (protocol
     (lambda ()
       ;;Validate the value through the tagged argument and return it.
       (lambda ((fx <port-number>))
	 fx)))

    (virtual-fields
     (immutable (specified? <boolean>)
		(lambda (fx)
		  (not ($fxzero? fx))))

     (immutable (bytevector <ascii-bytevector>)
		(lambda ((O <port-number>))
		  (if (O specified?)
		      ;;58 = #\:
		      (bytevector-append '#vu8(58) ($fixnum->bytevector O))
		    '#vu8())))

     (immutable (string <ascii-string>)
		(lambda ((O <port-number>))
		  ($ascii->string (O bytevector))))

     #| end of virtual-fields |# )

    (method (put-bytevector (O <port-number>) port)
      (when (O specified?)
	;;58 = #\:
	(put-u8 port 58)
	(put-bytevector port (string->ascii (number->string O)))))

    #| end of label |# )

  (define-inline ($fixnum->bytevector fx)
    (string->ascii (fixnum->string fx)))

  (define-inline (fixnum->string fx)
    (number->string fx))

  #| end of module |# )


;;;; auxiliary labels and classes: query

(define-label <query>
  (parent <bytevector>)

  (protocol
   (lambda ()
     ;;Apply the predicate, through the tagged argument, and return.
     (lambda ((bv <query>))
       bv)))

  (predicate
   (lambda (bv)
     (let loop ((bv bv)
		(i  0))
       (or ($fx= i ($bytevector-length bv))
	   (and ($ascii-uri-pchar? ($bytevector-u8-ref bv i) bv i)
		(loop bv ($fxadd1 i)))))))

  (virtual-fields
   (immutable (specified? <boolean>)
	      (lambda (bv)
		($bytevector-not-empty? bv)))

   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <query>))
		(if (O specified?)
		    ;;63 = ?
		    (bytevector-append '#vu8(63) O)
		  '#vu8())))

   (immutable (string <ascii-string>)
	      (lambda ((O <query>))
		(if (O specified?)
		    ($ascii->string (O bytevector))
		  "")))

   #| end of virtual-fields |# )

  (method (put-bytevector (O <query>) port)
    (when (O specified?)
      ;;63 = ?
      (put-u8 port 63)
      (put-bytevector port O)))

  #| end of label |# )


;;;; auxiliary labels and classes: fragment

(define-label <fragment>
  (parent <bytevector>)

  (protocol
   (lambda ()
     ;;Apply the predicate, through the tagged argument, and return.
     (lambda ((bv <fragment>))
       bv)))

  (predicate
   (lambda (bv)
     (let loop ((bv bv)
		(i  0))
       (or ($fx= i ($bytevector-length bv))
	   (and ($ascii-uri-pchar? ($bytevector-u8-ref bv i) bv i)
		(loop bv ($fxadd1 i)))))))

  (virtual-fields
   (immutable (specified? <boolean>)
	      (lambda (bv)
		($bytevector-not-empty? bv)))

   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <fragment>))
		(if (O specified?)
		    ;;35 = #
		    (bytevector-append '#vu8(35) O)
		  '#vu8())))

   (immutable (string <ascii-string>)
	      (lambda ((O <fragment>))
		(if (O specified?)
		    ($ascii->string (O bytevector))
		  "")))

   #| end of virtual-fields |# )

  (method (put-bytevector (O <fragment>) port)
    (when (O specified?)
      ;;35 = #
      (put-u8 port 35)
      (put-bytevector port O)))

  #| end of label |# )


;;;; path types: auxiliary label <segment>

(define-label <segment>
  (parent <bytevector>)

  (protocol
   ;;Apply the predicate, through the tagged argument, and return.
   (lambda ()
     (lambda ((bv <fragment>)) bv)))

  (predicate
   (lambda (bv)
     (and ($bytevector-not-empty? bv)
	  (let loop ((bv bv)
		     (i  0))
	    (or ($fx= i ($bytevector-length bv))
		(and ($ascii-uri-pchar? ($bytevector-u8-ref bv i) bv i)
		     (loop bv ($fxadd1 i))))))))

  (virtual-fields

   (immutable (bytevector <segment>)
	      (lambda (O) O))

   (immutable (string <ascii-string>)
	      $ascii->string)

   #| end of virtual-fields |# )

  (method-syntax put-bytevector
    (syntax-rules ()
      ((_ ?bv ?port)
       (put-bytevector ?port ?bv))))

  #| end of label |# )


;;;; path types: auxiliary label <list-of-segments>

(module (<list-of-segments>)

  (define-label <list-of-segments>
    (parent <list>)

    (protocol
     (lambda ()
       (lambda (ell)
	 (%normalise-list-of-segments ell))))

    (predicate
     (lambda (O)
       (%normalised-list-of-segments? O)))

    (virtual-fields

     (immutable (bytevector <ascii-bytevector>)
		(lambda ((O <list-of-segments>))
		  (receive (port getter)
		      (open-bytevector-output-port)
		    (O put-bytevector port)
		    (getter))))

     (immutable (string <ascii-string>)
		(lambda ((O <list-of-segments>))
		  ($ascii->string (O bytevector))))

     #| end of virtual-fields |# )

    (method (put-bytevector (O <list-of-segments>) port)
      ;;We  know  that in  a  normalised  list  of segments:  a  segment
      ;;representing the current directory can come only as last one; so
      ;;if  we find  such  a segment  we stop  putting  after the  slash
      ;;character.   This  way  when reconstructing  the  original  URIs
      ;;"a/b/" and  "a/b/." we get  "a/b/".  As  a special case:  if the
      ;;path  is composed  of  the current  directory  segment only,  we
      ;;output nothing.
      ;;
      (when (pair? O)
	(if (null? (O $cdr))
	    (unless ($current-directory? (O $car))
	      (put-bytevector port (O $car)))
	  (begin
	    (put-bytevector port (O $car))
	    (let loop (((S <spine>) (O $cdr)))
	      (when (pair? S)
		;;47 = (char->integer #\/)
		(put-u8 port 47)
		(unless ($current-directory? (S $car))
		  (put-bytevector port (S $car))
		  (loop (S $cdr)))))))))

    #| end of label |# )

  (define (%normalise-list-of-segments list-of-segments)
    ;;Given a proper list of bytevectors representing URI path segments:
    ;;validate and  normalise it as  described in section  5.2.4 "Remove
    ;;Dot  Segments" of  RFC  3986.  If  successful  return a,  possibly
    ;;empty,  proper  list  of   bytevectors  representing  the  result;
    ;;otherwise  raise an  exception with  compound condition  object of
    ;;types:   "&procedure-argument-violation",    "&who",   "&message",
    ;;"&irritants".
    ;;
    ;;We expect  the input list to  be "short".  We would  like to visit
    ;;recursively the  argument, but to process  the "uplevel directory"
    ;;segments we need  access to the previous item in  the list as well
    ;;as the current one;  so we process it in a loop and  at the end we
    ;;reverse the accumulated result.
    ;;
    ;;How do  we handle  segments representing the  "current directory"?
    ;;When the original  URI string contains the  sequence of characters
    ;;"a/./b", we expect it to be parsed as the list of segments:
    ;;
    ;;   (#ve(ascii "a") #ve(ascii ".") #ve(ascii "b"))
    ;;
    ;;when the original  URI string contains the  sequence of characters
    ;;"a//b", we expect it to be parsed as the list of segments:
    ;;
    ;;   (#ve(ascii "a") #vu8() #ve(ascii "b"))
    ;;
    ;;so  we interpret  an empty  bytevector  as alias  for the  segment
    ;;containing a standalone  dot.  We discard such  segment, unless it
    ;;is the last one; this is  because when the original URI terminates
    ;;with "a/b/" (slash  as last character), we want the  result of the
    ;;path normalisation to be:
    ;;
    ;;   (#ve(ascii "a") #ve(ascii "b") #ve(ascii "."))
    ;;
    ;;so  that  reconstructing the  URI  we  get  "a/b/." which  can  be
    ;;normalised to  "a/b/"; by discarding  the trailing dot  segment we
    ;;would get "a/b" as reconstructed URI.
    ;;
    ;;How do  we handle  segments representing the  "uplevel directory"?
    ;;If a segment  exists on the output stack: discard  both it and the
    ;;uplevel  directory segment;  otherwise  just  discard the  uplevel
    ;;directory segment.
    ;;
    (let next-segment ((input-stack  list-of-segments)
		       (output-stack '()))
      (cond ((pair? input-stack)
	     (let ((head ($car input-stack))
		   (tail ($cdr input-stack)))
	       (if (bytevector? head)
		   (cond (($current-directory? head)
			  ;;Discard a  segment representing  the current
			  ;;directory; unless  it is the last,  in which
			  ;;case we normalise  it to "." and  push it on
			  ;;the output stack.
			  (if (pair? tail)
			      (next-segment tail output-stack)
			    (reverse (cons '#vu8(46) output-stack))))
			 (($uplevel-directory? head)
			  ;;Remove  the  previously pushed  segment,  if
			  ;;any.
			  (next-segment tail (if (null? output-stack)
						 output-stack
					       ($cdr output-stack))))
			 (((<segment>) head)
			  ;;Just  push  on  the output  stack  a  normal
			  ;;segment.
			  (next-segment tail (cons head output-stack)))
			 (else
			  (procedure-argument-violation __who__
			    "expected URI segment bytevector as item in list argument"
			    list-of-segments head)))
		 (procedure-argument-violation __who__
		   "expected bytevector as item in list argument"
		   list-of-segments head))))
	    ((null? input-stack)
	     (reverse output-stack))
	    (else
	     (procedure-argument-violation __who__
	       "expected proper list as argument" list-of-segments)))))

  (define (%normalised-list-of-segments? list-of-segments)
    ;;Return  #t  if  the  argument  is a  proper  list  of  bytevectors
    ;;representing URI path  segments as defined by  RFC 3986; otherwise
    ;;return #f.
    ;;
    ;;Each   segment  must   be  a   non-empty  bytevector;   a  segment
    ;;representing the current  directory "." is accepted only  if it is
    ;;the  last one;  a segment  representing the  uplevel directory  is
    ;;rejected.
    ;;
    (cond ((pair? list-of-segments)
	   (let ((head ($car list-of-segments))
		 (tail ($cdr list-of-segments)))
	     (and (bytevector? head)
		  (cond (($current-directory? head)
			 ;;Accept  a  segment representing  the  current
			 ;;directory only if it is the last one.
			 (if (pair? tail)
			     #f
			   (%normalised-list-of-segments? tail)))
			(($uplevel-directory? head)
			 ;;Reject  a  segment representing  the  uplevel
			 ;;directory.
			 #f)
			(((<segment>) head)
			 (%normalised-list-of-segments? tail))
			(else #f)))))
	  ((null? list-of-segments)
	   #t)
	  (else #f)))

  (define ($current-directory? bv)
    (or ($bytevector-empty? bv)
	(and ($fx= 1 ($bytevector-length bv))
	     ;;46 = #\.
	     ($fx= 46 ($bytevector-u8-ref bv 0)))))

  (define ($uplevel-directory? bv)
    (and ($fx= 2 ($bytevector-length bv))
	 ;;46 = #\.
	 ($fx= 46 ($bytevector-u8-ref bv 0))
	 ($fx= 46 ($bytevector-u8-ref bv 1))))

  #| end of module |# )


;;;; path types

(define-generic uri-path-put-bytevector	(path port))
(define-generic uri-path-symbol		(path))

;;; --------------------------------------------------------------------

(define-class <path>
  (nongenerative nausicaa:net:addresses:uri:<path>)
  (abstract)

  (fields (immutable (path <list-of-segments>))
	  (mutable   memoized-bytevector)
	  (mutable   memoized-string))

  (super-protocol
   (lambda (make-top)
     (lambda (path)
       ((make-top) (<list-of-segments> (path)) #f #f))))

  (virtual-fields

   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <path>))
		(or (O $memoized-bytevector)
		    (receive-and-return (bv)
			(receive (port getter)
			    (open-bytevector-output-port)
			  (uri-path-put-bytevector O port)
			  (getter))
		      (set! (O $memoized-bytevector) bv)))))

   (immutable (string <ascii-string>)
	      (lambda ((O <path>))
		(or (O $memoized-string)
		    (receive-and-return (str)
			($ascii->string (O bytevector))
		      (set! (O $memoized-string) str)))))

   (immutable (type <symbol>)
	      uri-path-symbol)

   #| end of virtual-fields |# )

  (methods (put-bytevector	uri-path-put-bytevector))

  #| end of class |# )

(define-method (uri-path-put-bytevector (O <path>) (port <binary-output-port>))
  (O path put-bytevector port))

;;; --------------------------------------------------------------------

(define-class <path-empty>
  ;;There  is only  one instance  of this  class: the  constrctor always
  ;;returns the same object.
  ;;
  (nongenerative nausicaa:net:addresses:uri:<path-empty>)
  (parent <path>)
  (protocol
   (lambda (make-uri-path)
     (let ((singleton-instance #f))
       (lambda ()
	 (or singleton-instance
	     (receive-and-return (rv)
		 ((make-uri-path '()))
	       (set! singleton-instance rv)))))))
  #| end of class |# )

(define-method (uri-path-symbol (O <path-empty>))
  'path-empty)

;;; --------------------------------------------------------------------

(define-class <path-abempty>
  (nongenerative nausicaa:net:addresses:uri:<path-abempty>)
  (parent <path>)
  (protocol (lambda (make-uri-path)
	      (lambda (path)
		((make-uri-path path)))))
  #| end of class |# )

(define-method (uri-path-put-bytevector (O <path-abempty>) (port <binary-output-port>))
  ;;47 = (char->integer #\/)
  (put-u8 port 47)
  (call-next-method))

(define-method (uri-path-symbol (O <path-abempty>))
  'path-abempty)

;;; --------------------------------------------------------------------

(define-class <path-absolute>
  (nongenerative nausicaa:net:addresses:uri:<path-absolute>)
  (parent <path>)
  (protocol (lambda (make-uri-path)
	      (lambda ((path <nonempty-list>))
		((make-uri-path path)))))
  #| end of class |# )

(define-method (uri-path-put-bytevector (O <path-absolute>) (port <binary-output-port>))
  ;;47 = (char->integer #\/)
  (put-u8 port 47)
  (call-next-method))

(define-method (uri-path-symbol (O <path-absolute>))
  'path-absolute)

;;; --------------------------------------------------------------------

(define-class <path-rootless>
  (nongenerative nausicaa:net:addresses:uri:<path-rootless>)
  (parent <path>)
  (protocol (lambda (make-uri-path)
	      (lambda ((path <nonempty-list>))
		((make-uri-path path)))))
  #| end of class |# )

(define-method (uri-path-symbol (O <path-rootless>))
  'path-rootless)

;;; --------------------------------------------------------------------

(define-class <path-noscheme>
  (nongenerative nausicaa:net:addresses:uri:<path-noscheme>)
  (parent <path>)
  (protocol (lambda (make-uri-path)
	      (lambda ((path <nonempty-list>))
		((make-uri-path path)))))
  #| end of class |# )

(define-method (uri-path-symbol (O <path-noscheme>))
  'path-noscheme)

;;; --------------------------------------------------------------------

(define (make-path-object (path-type <symbol>) path)
  (case path-type
    ((path-abempty)
     (<path-abempty>	(path)))
    ((path-absolute)
     (<path-absolute>	(path)))
    ((path-rootless)
     (<path-rootless>	(path)))
    ((path-noscheme)
     (<path-noscheme>	(path)))
    ((path-empty)
     (<path-empty>	()))
    (else
     (procedure-argument-violation __who__
       "invalid URI path type" path-type))))


(define-class <uri>
  (nongenerative nausicaa:net:addresses:uri:<uri>)

  (maker (lambda (stx)
	   (syntax-case stx ()
	     ((_ (?clause ...))
	      #'(%make-uri ?clause ...)))))

  (protocol
   (lambda (make-top)
     (lambda (scheme specified-authority? userinfo host port-number path query fragment)
       (let (((scheme <scheme>)		scheme)
	     ((userinfo <userinfo>)	(if (unspecified? userinfo)
					    '#vu8()
					    userinfo))
	     ((host <ip-address>)	host)
	     ((port <port-number>)	(if (unspecified? port-number)
					    0
					  port-number))
	     ((path <path>)		(if (unspecified? path)
					    (<path-empty> ())
					  path))
	     ((query <query>)		(if (unspecified? query)
					    '#vu8()
					    query))
	     ((fragment <fragment>)	(if (unspecified? fragment)
					    '#vu8()
					    fragment)))
	 ((make-top) #f #f
	  scheme (if specified-authority? #t #f)
	  userinfo host port path query fragment)))))

  (fields (mutable memoized-bytevector)
	  (mutable memoized-string)
	  (immutable (scheme			<scheme>))
	  (immutable (specified-authority?	<boolean>))
		;True if the "authority" component is specified.  Notice
		;that the authority  can be specified even  when all its
		;sub-components are empty: it is the case of "authority"
		;equal  to a  "host"  component, equal  to a  "reg-name"
		;component which can be empty.
	  (immutable (userinfo			<userinfo>))
	  (immutable (host			<host>))
	  (immutable (port			<port-number>))
	  (immutable (path			<path>))
	  (immutable (query			<query>))
	  (immutable (fragment			<fragment>)))

  (virtual-fields
   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <uri>))
		(or (O $memoized-bytevector)
		    (receive-and-return (bv)
			(receive (port getter)
			    (open-bytevector-output-port)
			  (O put-bytevector port)
			  (getter))
		      (set! (O $memoized-bytevector) bv)))))

   (immutable (string <ascii-string>)
	      (lambda ((O <uri>))
		(or (O $memoized-string)
		    (receive-and-return (str)
			($ascii->string (O bytevector))
		      (set! (O $memoized-string) str)))))

   #| end of virtual-fields |# )

  (method (put-bytevector (O <uri>) (port <binary-output-port>))
    ;;We  want  to  recompose  the  URI  as  described  in  section  5.3
    ;;"Component Recomposition" of RFC 3986.
    (define who '<uri>-bytevector)
    (O $scheme put-bytevector port)
    (let ((authority (receive (authority-port authority-getter)
			 (open-bytevector-output-port)
		       (O $userinfo put-bytevector authority-port)
		       (O $host     put-bytevector authority-port)
		       (O $port     put-bytevector authority-port)
		       (authority-getter))))
      (when (or ($bytevector-not-empty? authority)
		((<path-abempty>) O)
		((<path-empty>)   O)
		(O $specified-authority?))
	(put-u8 port 47)   ;47 = #\/
	(put-u8 port 47)   ;47 = #\/
	(put-bytevector port authority)))
    (O $path  put-bytevector port)
    (O $query put-bytevector port)
    (O $fragment put-bytevector port))

  #| end of class |# )

(mk.define-maker %make-uri
    make-<uri>
  ((scheme			unspecified)
   (specified-authority?	#f)
   (userinfo			unspecified)
   (host			unspecified)
   (port-number			unspecified)
   (path			unspecified)
   (query			unspecified)
   (fragment			unspecified)))


(define-class <relative-ref>
  (nongenerative nausicaa:net:addresses:uri:<relative-ref>)

  (maker (lambda (stx)
	   (syntax-case stx ()
	     ((_ (?clause ...))
	      #'(%make-relative-ref ?clause ...)))))

  (protocol
   (lambda (make-top)
     (lambda (specified-authority? userinfo host port-number path query fragment)
       (let (((userinfo <userinfo>)	(if (unspecified? userinfo)
					    '#vu8()
					    userinfo))
	     ((host <ip-address>)	host)
	     ((port <port-number>)	(if (unspecified? port-number)
					    0
					  port-number))
	     ((path <path>)		(if (unspecified? path)
					    (<path-empty> ())
					  path))
	     ((query <query>)		(if (unspecified? query)
					    '#vu8()
					    query))
	     ((fragment <fragment>)	(if (unspecified? fragment)
					    '#vu8()
					    fragment)))
	 ((make-top) #f #f
	  (if specified-authority? #t #f)
	  userinfo host port path query fragment)))))

  (fields (mutable memoized-bytevector)
	  (mutable memoized-string)
	  (immutable (specified-authority?	<boolean>))
		;True if the "authority" component is specified.  Notice
		;that the authority  can be specified even  when all its
		;sub-components are empty: it is the case of "authority"
		;equal  to a  "host"  component, equal  to a  "reg-name"
		;component which can be empty.
	  (immutable (userinfo			<userinfo>))
	  (immutable (host			<host>))
	  (immutable (port			<port-number>))
	  (immutable (path			<path>))
	  (immutable (query			<query>))
	  (immutable (fragment			<fragment>)))

  (virtual-fields
   (immutable (bytevector <ascii-bytevector>)
	      (lambda ((O <relative-ref>))
		(or (O $memoized-bytevector)
		    (receive-and-return (bv)
			(receive (port getter)
			    (open-bytevector-output-port)
			  (O put-bytevector port)
			  (getter))
		      (set! (O $memoized-bytevector) bv)))))

   (immutable (string <ascii-string>)
	      (lambda ((O <relative-ref>))
		(or (O $memoized-string)
		    (receive-and-return (str)
			($ascii->string (O bytevector))
		      (set! (O $memoized-string) str)))))

   #| end of virtual-fields |# )

  (method (put-bytevector (O <relative-ref>) (port <binary-output-port>))
    ;;We  want  to  recompose  the  URI  as  described  in  section  5.3
    ;;"Component Recomposition" of RFC 3986.
    (define who '<relative-ref>-bytevector)
    (let ((authority (receive (authority-port authority-getter)
			 (open-bytevector-output-port)
		       (O $userinfo put-bytevector authority-port)
		       (O $host     put-bytevector authority-port)
		       (O $port     put-bytevector authority-port)
		       (authority-getter))))
      (when (or ($bytevector-not-empty? authority)
		((<path-abempty>) O)
		((<path-empty>)   O)
		(O $specified-authority?))
	(put-u8 port 47)   ;47 = #\/
	(put-u8 port 47)   ;47 = #\/
	(put-bytevector port authority)))
    (O $path  put-bytevector port)
    (O $query put-bytevector port)
    (O $fragment put-bytevector port))

  #| end of class |# )

(mk.define-maker %make-relative-ref
    make-<relative-ref>
  ((specified-authority?	#f)
   (userinfo			unspecified)
   (host			unspecified)
   (port-number			unspecified)
   (path			unspecified)
   (query			unspecified)
   (fragment			unspecified)))


;;;; done

)

;;; end of file
