;;;
;;;Part of: Vicare Scheme
;;;Contents: tests for fxreverse-bit-field
;;;Date: Mon Jun  7, 2010
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (c) 2010, 2012, 2015, 2016 Marco Maggi <marco.maggi-ipsu@poste.it>
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


(import (vicare)
  (prefix (vicare expander) expander::)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing fxreverse-bit-field\n")


;;;; code

(check
    (fxreverse-bit-field #b1010010 1 4)
  =>                     #b1011000)

;;; --------------------------------------------------------------------

(check
    (try
	(eval '(fxreverse-bit-field 'ciao 1 4)
	      (environment '(rnrs)))
      (catch E
	((expander::&expand-time-type-signature-warning)
	 #t)
	(else E)))
  => #t)

(check
    (try
	(eval '(fxreverse-bit-field #b1010010 'ciao 4)
	      (environment '(rnrs)))
      (catch E
	((expander::&expand-time-type-signature-warning)
	 #t)
	(else E)))
  => #t)

(check
    (try
	(eval '(fxreverse-bit-field #b1010010 1 'ciao)
	      (environment '(rnrs)))
      (catch E
	((expander::&expand-time-type-signature-warning)
	 #t)
	(else E)))
  => #t)

(check
    (guard (E ((assertion-violation? E)
;;;(write (condition-message E))(newline)
	       #t)
	      (else #f))
      (eval '(fxreverse-bit-field #b1010010 1 500)
	    (environment '(rnrs))))
  => #t)

(check
    (guard (E ((assertion-violation? E)
;;;(write (condition-message E))(newline)
	       #t)
	      (else #f))
      (eval '(fxreverse-bit-field #b1010010 500 1)
	    (environment '(rnrs))))
  => #t)

(check
    (guard (E ((assertion-violation? E)
;;;(write (condition-message E))(newline)
	       #t)
	      (else #f))
      (eval '(fxreverse-bit-field #b1010010 4 1)
	    (environment '(rnrs))))
  => #t)


;;;; done

(check-report)

;;; end of file
;; Local Variables:
;; coding: utf-8-unix
;; End:
