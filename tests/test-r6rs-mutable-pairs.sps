;;;Copyright (c) 2008 Matthew Flatt
;;;Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
;;;
;;;This library is free software;  you can redistribute it and/or modify
;;;it  under the  terms of  the GNU  Library General  Public  License as
;;;published by  the Free Software  Foundation; either version 2  of the
;;;License, or (at your option) any later version.
;;;
;;;This library is  distributed in the hope that it  will be useful, but
;;;WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
;;;MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
;;;Library General Public License for more details.
;;;
;;;You should  have received  a copy of  the GNU Library  General Public
;;;License along with  this library; if not, write  to the Free Software
;;;Foundation,  Inc.,  51  Franklin  Street,  Fifth  Floor,  Boston,  MA
;;;02110-1301 USA.

#!r6rs
(import (r6rs mutable-pairs)
  (r6rs test)
  (rnrs io simple)
  (only (vicare checks)
	check-display))
(check-display "*** Flatt's R6RS tests for (rnrs mutable-pairs)\n\n")
(run-mutable-pairs-tests)
(report-test-results)

;;; end of file
