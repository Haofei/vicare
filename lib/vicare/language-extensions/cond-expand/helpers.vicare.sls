;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: Vicare Scheme
;;;Contents: helpers for cond-expand
;;;Date: Sun Mar 17, 2013
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2013 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This program is free software:  you can redistribute it and/or modify
;;;it under the terms of the  GNU General Public License as published by
;;;the Free Software Foundation, either version 3 of the License, or (at
;;;your option) any later version.
;;;
;;;This program is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY or  FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;General Public License for more details.
;;;
;;;You should  have received a  copy of  the GNU General  Public License
;;;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;


#!r6rs
(library (vicare language-extensions cond-expand helpers)
  (export define-cond-expand-identifiers-helper)
  (import (vicare))


(define-syntax define-cond-expand-identifiers-helper
  (lambda (stx)
    (define (syntax->list stx)
      (syntax-case stx ()
	((?car . ?cdr)
	 (cons #'?car (syntax->list #'?cdr)))
	(() '())))
    (syntax-case stx ()
      ((_ ?who (?feature-id ?expr) ...)
       (and (identifier? #'?who)
	    (syntax->list #'(?feature-id ...)))
       #'(define (?who id)
	   (cond ((free-identifier=? id #'?feature-id)
		  ?expr)
		 ...
		 (else #f)))))))


;;;; done

)

;;; end of file
