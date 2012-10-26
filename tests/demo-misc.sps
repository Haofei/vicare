;;; demo-misc.sps --
;;
;;Demo miscellaneous stuff.
;;

#!r6rs
(import (vicare))

(let loop ((i 0))
  (when (zero? (mod i #e1e6))
    (fprintf (current-error-port) "~a " i)
    (flush-output-port (current-error-port))
    (void))
  (when (< i #e1e9)
    (cons i (loop (+ 1 i)))))


;;; end of file
;;Local Variables:
;;coding: utf-8
;;End:
