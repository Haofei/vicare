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


(library (ikarus.posix)
  (export
    ;; errno codes handling
    errno->string

    ;; interprocess singnal codes handling
    interprocess-signal->string

    ;; error handling
    strerror

    ;; system environment variables
    getenv			setenv
    unsetenv
    environ			environ-table
    environ->table		table->environ

    ;; process identifier
    getpid			getppid

    ;; executing processes
    posix-fork			fork
    system
    execv			execve
    execl			execle
    execvp			execlp

    ;; process exit status
    waitpid			wait
    WIFEXITED			WEXITSTATUS
    WIFSIGNALED			WTERMSIG
    WCOREDUMP			WIFSTOPPED
    WSTOPSIG

    ;; interprocess signals
    raise-signal		kill
    pause

    ;; file system inspection
    stat			lstat
    fstat
    make-struct-stat		struct-stat?
    struct-stat-st_mode		struct-stat-st_ino
    struct-stat-st_dev		struct-stat-st_nlink
    struct-stat-st_uid		struct-stat-st_gid
    struct-stat-st_size
    struct-stat-st_atime	struct-stat-st_atime_usec
    struct-stat-st_mtime	struct-stat-st_mtime_usec
    struct-stat-st_ctime	struct-stat-st_ctime_usec
    struct-stat-st_blocks	struct-stat-st_blksize

    file-is-directory?		file-is-char-device?
    file-is-block-device?	file-is-regular-file?
    file-is-symbolic-link?	file-is-socket?
    file-is-fifo?		file-is-message-queue?
    file-is-semaphore?		file-is-shared-memory?

    access			file-readable?
    file-writable?		file-executable?
    file-atime			file-ctime
    file-mtime

    S_ISDIR			S_ISCHR
    S_ISBLK			S_ISREG
    S_ISLNK			S_ISSOCK
    S_ISFIFO

    realpath			file-exists?
    file-size

    ;; file system muators
    chown			fchown

    ;; file system interface
    delete-file
    rename-file			split-file-name

    current-directory		directory-list
    make-directory		make-directory*
    delete-directory

    make-symbolic-link		make-hard-link

    change-mode

    nanosleep)
  (import (except (ikarus)
		  ;; errno codes handling
		  errno->string

		  ;; interprocess singnal codes handling
		  interprocess-signal->string

		  ;; error handling
		  strerror

		  ;; system environment variables
		  getenv			setenv
		  unsetenv
		  environ			environ-table
		  environ->table		table->environ

		  ;; process identifier
		  getpid			getppid

		  ;; executing processes
		  posix-fork			fork
		  system
		  execv				execve
		  execl				execle
		  execvp			execlp

		  ;; process exit status
		  waitpid			wait
		  WIFEXITED			WEXITSTATUS
		  WIFSIGNALED			WTERMSIG
		  WCOREDUMP			WIFSTOPPED
		  WSTOPSIG

		  ;; interprocess signals
		  raise-signal			kill
		  pause

		  ;; file system inspection
		  stat				lstat
		  fstat
		  make-struct-stat		struct-stat?
		  struct-stat-st_mode		struct-stat-st_ino
		  struct-stat-st_dev		struct-stat-st_nlink
		  struct-stat-st_uid		struct-stat-st_gid
		  struct-stat-st_size
		  struct-stat-st_atime		struct-stat-st_atime_usec
		  struct-stat-st_mtime		struct-stat-st_mtime_usec
		  struct-stat-st_ctime		struct-stat-st_ctime_usec
		  struct-stat-st_blocks		struct-stat-st_blksize

		  file-is-directory?		file-is-char-device?
		  file-is-block-device?		file-is-regular-file?
		  file-is-symbolic-link?	file-is-socket?
		  file-is-fifo?			file-is-message-queue?
		  file-is-semaphore?		file-is-shared-memory?

		  access			file-readable?
		  file-writable?		file-executable?

		  file-ctime			file-mtime
		  file-atime

		  S_ISDIR			S_ISCHR
		  S_ISBLK			S_ISREG
		  S_ISLNK			S_ISSOCK
		  S_ISFIFO

		  realpath			file-exists?
		  file-size

		  ;; file system muators
		  chown				fchown

		  ;; file system interface
		  delete-file
		  rename-file			split-file-name

		  current-directory		directory-list
		  make-directory		make-directory*
		  delete-directory

		  make-symbolic-link		make-hard-link

		  change-mode

		  nanosleep)
    (vicare syntactic-extensions)
    (vicare platform-constants)
    (prefix (vicare unsafe-capi)
	    capi.)
    (prefix (vicare unsafe-operations)
	    unsafe.))


;;;; arguments validation

(define-argument-validation (procedure who obj)
  (procedure? obj)
  (assertion-violation who "expected procedure as argument" obj))

(define-argument-validation (boolean who obj)
  (boolean? obj)
  (assertion-violation who "expected boolean as argument" obj))

(define-argument-validation (fixnum who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum as argument" obj))

(define-argument-validation (string who obj)
  (string? obj)
  (assertion-violation who "expected string as argument" obj))

;;; --------------------------------------------------------------------

(define-argument-validation (pid who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum pid as argument" obj))

(define-argument-validation (gid who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum gid as argument" obj))

(define-argument-validation (file-descriptor who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum file descriptor as argument" obj))

(define-argument-validation (signal who obj)
  (fixnum? obj)
  (assertion-violation who "expected fixnum signal code as argument" obj))

(define-argument-validation (pathname who obj)
  (or (bytevector? obj) (string? obj))
  (assertion-violation who "expected string or bytevector as pathname argument" obj))

(define-argument-validation (list-of-strings who obj)
  (for-all string? obj)
  (assertion-violation who "expected list of strings as argument" obj))

(define-argument-validation (struct-stat who obj)
  (struct-stat? obj)
  (assertion-violation who "expected struct stat instance as argument" obj))


;;;; errors handling

(define (strerror errno)
  (define who 'strerror)
  (with-arguments-validation (who)
      ((fixnum  errno))
    (let ((msg (capi.posix-strerror errno)))
      (if msg
	  (string-append (errno->string errno) ": " (utf8->string msg))
	(string-append "unknown errno code " (number->string (- errno)))))))

(define raise/strerror
  (case-lambda
   ((who errno-code)
    (raise/strerror who errno-code #f))
   ((who errno-code filename)
    (raise (condition
	    (make-error)
	    (make-who-condition who)
	    (make-message-condition (strerror errno-code))
	    (if filename
		(make-i/o-filename-error filename)
	      (condition)))))))

(define (raise-errno-error who errno . irritants)
  (raise (condition
	  (make-error)
	  (make-who-condition who)
	  (make-message-condition (strerror errno))
	  (make-irritants-condition irritants))))


;;;; errno handling

(define (errno->string negated-errno-code)
  ;;Convert an errno  code as represented by the  (vicare errno) library
  ;;into a string representing the errno code symbol.
  ;;
  (define who 'errno->string)
  (with-arguments-validation (who)
      ((fixnum negated-errno-code))
    (let ((errno-code (unsafe.fx- 0 negated-errno-code)))
      (and (unsafe.fx> errno-code 0)
	   (unsafe.fx< errno-code (vector-length ERRNO-VECTOR))
	   (vector-ref ERRNO-VECTOR errno-code)))))

(let-syntax
    ((make-errno-vector
      (lambda (stx)
	(define (%mk-vector)
	  (let* ((max	(fold-left (lambda (max pair)
				     (let ((code (cdr pair)))
				       (cond ((not code)
					      max)
					     ((< max (fx- code))
					      (fx- code))
					     (else
					      max))))
			  0 errno-alist))
		 (vec.len	(fx+ 1 max))
		 ;;All the unused positions are set to #f.
		 (vec	(make-vector vec.len #f)))
	    (for-each (lambda (pair)
			(when (cdr pair)
			  (vector-set! vec (fx- (cdr pair)) (car pair))))
	      errno-alist)
	    vec))
	(define errno-alist
	  `(("E2BIG"		. ,E2BIG)
	    ("EACCES"		. ,EACCES)
	    ("EADDRINUSE"	. ,EADDRINUSE)
	    ("EADDRNOTAVAIL"	. ,EADDRNOTAVAIL)
	    ("EADV"		. ,EADV)
	    ("EAFNOSUPPORT"	. ,EAFNOSUPPORT)
	    ("EAGAIN"		. ,EAGAIN)
	    ("EALREADY"		. ,EALREADY)
	    ("EBADE"		. ,EBADE)
	    ("EBADF"		. ,EBADF)
	    ("EBADFD"		. ,EBADFD)
	    ("EBADMSG"		. ,EBADMSG)
	    ("EBADR"		. ,EBADR)
	    ("EBADRQC"		. ,EBADRQC)
	    ("EBADSLT"		. ,EBADSLT)
	    ("EBFONT"		. ,EBFONT)
	    ("EBUSY"		. ,EBUSY)
	    ("ECANCELED"	. ,ECANCELED)
	    ("ECHILD"		. ,ECHILD)
	    ("ECHRNG"		. ,ECHRNG)
	    ("ECOMM"		. ,ECOMM)
	    ("ECONNABORTED"	. ,ECONNABORTED)
	    ("ECONNREFUSED"	. ,ECONNREFUSED)
	    ("ECONNRESET"	. ,ECONNRESET)
	    ("EDEADLK"		. ,EDEADLK)
	    ("EDEADLOCK"	. ,EDEADLOCK)
	    ("EDESTADDRREQ"	. ,EDESTADDRREQ)
	    ("EDOM"		. ,EDOM)
	    ("EDOTDOT"		. ,EDOTDOT)
	    ("EDQUOT"		. ,EDQUOT)
	    ("EEXIST"		. ,EEXIST)
	    ("EFAULT"		. ,EFAULT)
	    ("EFBIG"		. ,EFBIG)
	    ("EHOSTDOWN"	. ,EHOSTDOWN)
	    ("EHOSTUNREACH"	. ,EHOSTUNREACH)
	    ("EIDRM"		. ,EIDRM)
	    ("EILSEQ"		. ,EILSEQ)
	    ("EINPROGRESS"	. ,EINPROGRESS)
	    ("EINTR"		. ,EINTR)
	    ("EINVAL"		. ,EINVAL)
	    ("EIO"		. ,EIO)
	    ("EISCONN"		. ,EISCONN)
	    ("EISDIR"		. ,EISDIR)
	    ("EISNAM"		. ,EISNAM)
	    ("EKEYEXPIRED"	. ,EKEYEXPIRED)
	    ("EKEYREJECTED"	. ,EKEYREJECTED)
	    ("EKEYREVOKED"	. ,EKEYREVOKED)
	    ("EL2HLT"		. ,EL2HLT)
	    ("EL2NSYNC"		. ,EL2NSYNC)
	    ("EL3HLT"		. ,EL3HLT)
	    ("EL3RST"		. ,EL3RST)
	    ("ELIBACC"		. ,ELIBACC)
	    ("ELIBBAD"		. ,ELIBBAD)
	    ("ELIBEXEC"		. ,ELIBEXEC)
	    ("ELIBMAX"		. ,ELIBMAX)
	    ("ELIBSCN"		. ,ELIBSCN)
	    ("ELNRNG"		. ,ELNRNG)
	    ("ELOOP"		. ,ELOOP)
	    ("EMEDIUMTYPE"	. ,EMEDIUMTYPE)
	    ("EMFILE"		. ,EMFILE)
	    ("EMLINK"		. ,EMLINK)
	    ("EMSGSIZE"		. ,EMSGSIZE)
	    ("EMULTIHOP"	. ,EMULTIHOP)
	    ("ENAMETOOLONG"	. ,ENAMETOOLONG)
	    ("ENAVAIL"		. ,ENAVAIL)
	    ("ENETDOWN"		. ,ENETDOWN)
	    ("ENETRESET"	. ,ENETRESET)
	    ("ENETUNREACH"	. ,ENETUNREACH)
	    ("ENFILE"		. ,ENFILE)
	    ("ENOANO"		. ,ENOANO)
	    ("ENOBUFS"		. ,ENOBUFS)
	    ("ENOCSI"		. ,ENOCSI)
	    ("ENODATA"		. ,ENODATA)
	    ("ENODEV"		. ,ENODEV)
	    ("ENOENT"		. ,ENOENT)
	    ("ENOEXEC"		. ,ENOEXEC)
	    ("ENOKEY"		. ,ENOKEY)
	    ("ENOLCK"		. ,ENOLCK)
	    ("ENOLINK"		. ,ENOLINK)
	    ("ENOMEDIUM"	. ,ENOMEDIUM)
	    ("ENOMEM"		. ,ENOMEM)
	    ("ENOMSG"		. ,ENOMSG)
	    ("ENONET"		. ,ENONET)
	    ("ENOPKG"		. ,ENOPKG)
	    ("ENOPROTOOPT"	. ,ENOPROTOOPT)
	    ("ENOSPC"		. ,ENOSPC)
	    ("ENOSR"		. ,ENOSR)
	    ("ENOSTR"		. ,ENOSTR)
	    ("ENOSYS"		. ,ENOSYS)
	    ("ENOTBLK"		. ,ENOTBLK)
	    ("ENOTCONN"		. ,ENOTCONN)
	    ("ENOTDIR"		. ,ENOTDIR)
	    ("ENOTEMPTY"	. ,ENOTEMPTY)
	    ("ENOTNAM"		. ,ENOTNAM)
	    ("ENOTRECOVERABLE"	. ,ENOTRECOVERABLE)
	    ("ENOTSOCK"		. ,ENOTSOCK)
	    ("ENOTTY"		. ,ENOTTY)
	    ("ENOTUNIQ"		. ,ENOTUNIQ)
	    ("ENXIO"		. ,ENXIO)
	    ("EOPNOTSUPP"	. ,EOPNOTSUPP)
	    ("EOVERFLOW"	. ,EOVERFLOW)
	    ("EOWNERDEAD"	. ,EOWNERDEAD)
	    ("EPERM"		. ,EPERM)
	    ("EPFNOSUPPORT"	. ,EPFNOSUPPORT)
	    ("EPIPE"		. ,EPIPE)
	    ("EPROTO"		. ,EPROTO)
	    ("EPROTONOSUPPORT"	. ,EPROTONOSUPPORT)
	    ("EPROTOTYPE"	. ,EPROTOTYPE)
	    ("ERANGE"		. ,ERANGE)
	    ("EREMCHG"		. ,EREMCHG)
	    ("EREMOTE"		. ,EREMOTE)
	    ("EREMOTEIO"	. ,EREMOTEIO)
	    ("ERESTART"		. ,ERESTART)
	    ("EROFS"		. ,EROFS)
	    ("ESHUTDOWN"	. ,ESHUTDOWN)
	    ("ESOCKTNOSUPPORT"	. ,ESOCKTNOSUPPORT)
	    ("ESPIPE"		. ,ESPIPE)
	    ("ESRCH"		. ,ESRCH)
	    ("ESRMNT"		. ,ESRMNT)
	    ("ESTALE"		. ,ESTALE)
	    ("ESTRPIPE"		. ,ESTRPIPE)
	    ("ETIME"		. ,ETIME)
	    ("ETIMEDOUT"	. ,ETIMEDOUT)
	    ("ETOOMANYREFS"	. ,ETOOMANYREFS)
	    ("ETXTBSY"		. ,ETXTBSY)
	    ("EUCLEAN"		. ,EUCLEAN)
	    ("EUNATCH"		. ,EUNATCH)
	    ("EUSERS"		. ,EUSERS)
	    ("EWOULDBLOCK"	. ,EWOULDBLOCK)
	    ("EXDEV"		. ,EXDEV)
	    ("EXFULL"		. ,EXFULL)))
	(syntax-case stx ()
	  ((?ctx)
	   #`(quote #,(datum->syntax #'?ctx (%mk-vector))))))))

  (define ERRNO-VECTOR (make-errno-vector)))


;;;; interprocess singnal codes handling

(define (interprocess-signal->string interprocess-signal-code)
  ;;Convert an  interprocess signal code  as represented by  the (vicare
  ;;interprocess-signals)  library   into  a  string   representing  the
  ;;interprocess signal symbol.
  ;;
  (define who 'interprocess-signal->string)
  (with-arguments-validation (who)
      ((fixnum  interprocess-signal-code))
    (and (unsafe.fx> interprocess-signal-code 0)
	 (unsafe.fx< interprocess-signal-code (vector-length INTERPROCESS-SIGNAL-VECTOR))
	 (vector-ref INTERPROCESS-SIGNAL-VECTOR interprocess-signal-code))))

(let-syntax
    ((make-interprocess-signal-vector
      (lambda (stx)
	(define (%mk-vector)
	  (let* ((max	(fold-left (lambda (max pair)
				     (let ((code (cdr pair)))
				       (cond ((not code)	max)
					     ((< max code)	code)
					     (else		max))))
			  0 interprocess-signal-alist))
		 (vec.len	(fx+ 1 max))
		 ;;All the unused positions are set to #f.
		 (vec	(make-vector vec.len #f)))
	    (for-each (lambda (pair)
			(when (cdr pair)
			  (vector-set! vec (cdr pair) (car pair))))
	      interprocess-signal-alist)
	    vec))
	(define interprocess-signal-alist
	  `(("SIGFPE"		. ,SIGFPE)
	    ("SIGILL"		. ,SIGILL)
	    ("SIGSEGV"		. ,SIGSEGV)
	    ("SIGBUS"		. ,SIGBUS)
	    ("SIGABRT"		. ,SIGABRT)
	    ("SIGIOT"		. ,SIGIOT)
	    ("SIGTRAP"		. ,SIGTRAP)
	    ("SIGEMT"		. ,SIGEMT)
	    ("SIGSYS"		. ,SIGSYS)
	    ("SIGTERM"		. ,SIGTERM)
	    ("SIGINT"		. ,SIGINT)
	    ("SIGQUIT"		. ,SIGQUIT)
	    ("SIGKILL"		. ,SIGKILL)
	    ("SIGHUP"		. ,SIGHUP)
	    ("SIGALRM"		. ,SIGALRM)
	    ("SIGVRALRM"	. ,SIGVRALRM)
	    ("SIGPROF"		. ,SIGPROF)
	    ("SIGIO"		. ,SIGIO)
	    ("SIGURG"		. ,SIGURG)
	    ("SIGPOLL"		. ,SIGPOLL)
	    ("SIGCHLD"		. ,SIGCHLD)
	    ("SIGCLD"		. ,SIGCLD)
	    ("SIGCONT"		. ,SIGCONT)
	    ("SIGSTOP"		. ,SIGSTOP)
	    ("SIGTSTP"		. ,SIGTSTP)
	    ("SIGTTIN"		. ,SIGTTIN)
	    ("SIGTTOU"		. ,SIGTTOU)
	    ("SIGPIPE"		. ,SIGPIPE)
	    ("SIGLOST"		. ,SIGLOST)
	    ("SIGXCPU"		. ,SIGXCPU)
	    ("SIGXSFZ"		. ,SIGXSFZ)
	    ("SIGUSR1"		. ,SIGUSR1)
	    ("SIGUSR2"		. ,SIGUSR2)
	    ("SIGWINCH"		. ,SIGWINCH)
	    ("SIGINFO"		. ,SIGINFO)))
	(syntax-case stx ()
	  ((?ctx)
	   #`(quote #,(datum->syntax #'?ctx (%mk-vector))))))))
  (define INTERPROCESS-SIGNAL-VECTOR (make-interprocess-signal-vector)))


;;;; operating system environment variables

(define (getenv key)
  (define who 'getenv)
  (with-arguments-validation (who)
      ((string  key))
    (let ((rv (capi.posix-getenv (string->utf8 key))))
      (and rv (utf8->string rv)))))

(define setenv
  (case-lambda
   ((key val)
    (setenv key val #t))
   ((key val overwrite)
    (define who 'setenv)
    (with-arguments-validation (who)
	((string  key)
	 (string  val))
      (unless (capi.posix-setenv (string->utf8 key)
				 (string->utf8 val)
				 overwrite)
	(error who "cannot setenv" key val overwrite))))))

(define (unsetenv key)
  (define who 'unsetenv)
  (with-arguments-validation (who)
      ((string  key))
    (capi.posix-unsetenv (string->utf8 key))))

(define (%find-index-of-= str idx str.len)
  ;;Scan STR starint at index IDX  and up to STR.LEN for the position of
  ;;the character #\=.  Return the index or STR.LEN.
  ;;
  (cond ((unsafe.fx= idx str.len)
	 idx)
	((unsafe.char= #\= (unsafe.string-ref str idx))
	 idx)
	(else
	 (%find-index-of-= str (unsafe.fxadd1 idx) str.len))))

(define (environ)
  (map (lambda (bv)
	 (let* ((str     (utf8->string bv))
		(str.len (unsafe.string-length str))
		(idx     (%find-index-of-= str 0 str.len)))
	   (cons (substring str 0 idx)
		 (if (unsafe.fx< (unsafe.fxadd1 idx) str.len)
		     (substring str (unsafe.fxadd1 idx) str.len)
		   ""))))
    (capi.posix-environ)))

(define (environ-table)
  (environ->table (environ)))

(define (environ->table environ)
  (begin0-let ((table (make-hashtable string-hash string=?)))
    (for-each (lambda (pair)
		(hashtable-set! table (car pair) (cdr pair)))
      environ)))

(define (table->environ table)
  (let-values (((names values) (hashtable-entries table)))
    (let ((len     (unsafe.vector-length names))
	  (environ '()))
      (let loop ((i       0)
		 (environ '()))
	(if (unsafe.fx= i len)
	    environ
	  (loop (unsafe.fxadd1 i)
		(cons (cons (unsafe.vector-ref names  i)
			    (unsafe.vector-ref values i))
		      environ)))))))


;;;; process identifiers

(define (getpid)
  (capi.posix-getpid))

(define (getppid)
  (capi.posix-getppid))


;;;; executing and forking processes

(define (system x)
  (define who 'system)
  (with-arguments-validation (who)
      ((string  x))
    (let ((rv (capi.posix-system (string->utf8 x))))
      (if (unsafe.fx< rv 0)
	  (raise/strerror who rv)
	rv))))

(define (posix-fork)
  (capi.posix-fork))

(define (fork parent-proc child-proc)
  (define who 'fork)
  (with-arguments-validation (who)
      ((procedure  parent-proc)
       (procedure  child-proc))
    (let ((pid (capi.posix-fork)))
      (cond ((unsafe.fxzero? pid)
	     (child-proc))
	    ((unsafe.fx< pid 0)
	     (raise/strerror who pid))
	    (else
	     (parent-proc pid))))))

(define (execl filename . argv)
  (execv filename argv))

(define (execv filename argv)
  (define who 'execv)
  (with-arguments-validation (who)
      ((pathname	filename)
       (list-of-strings	argv))
    (with-pathnames ((filename.bv filename))
      (let ((rv (capi.posix-execv filename.bv (map string->utf8 argv))))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv filename argv)
	  rv)))))

(define (execle filename argv . env)
  (execve filename argv env))

(define (execve filename argv env)
  (define who 'execve)
  (with-arguments-validation (who)
      ((pathname	filename)
       (list-of-strings	argv)
       (list-of-strings	env))
    (with-pathnames ((filename.bv filename))
      (let ((rv (capi.posix-execve filename.bv
				   (map string->utf8 argv)
				   (map string->utf8 env))))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv filename argv env)
	  rv)))))

(define (execlp filename . argv)
  (execvp filename argv))

(define (execvp filename argv)
  (define who 'execvp)
  (with-arguments-validation (who)
      ((pathname	filename)
       (list-of-strings	argv))
    (with-pathnames ((filename.bv filename))
      (let ((rv (capi.posix-execvp filename.bv (map string->utf8 argv))))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv filename argv)
	  rv)))))


;;;; process termination status

(define (waitpid pid options)
  (define who 'waitpid)
  (with-arguments-validation (who)
      ((pid	pid)
       (fixnum	options))
    (let ((rv (capi.posix-waitpid pid options)))
      (if (unsafe.fx< rv 0)
	  (raise/strerror who rv)
	rv))))

(define (wait)
  (define who 'wait)
  (let ((rv (capi.posix-wait)))
    (if (unsafe.fx< rv 0)
	(raise/strerror who rv)
      rv)))

(let-syntax
    ((define-termination-status (syntax-rules ()
				  ((_ ?who ?primitive)
				   (define (?who status)
				     (define who '?who)
				     (with-arguments-validation (who)
					 ((fixnum  status))
				       (?primitive status)))))))
  (define-termination-status WIFEXITED		capi.posix-WIFEXITED)
  (define-termination-status WEXITSTATUS	capi.posix-WEXITSTATUS)
  (define-termination-status WIFSIGNALED	capi.posix-WIFSIGNALED)
  (define-termination-status WTERMSIG		capi.posix-WTERMSIG)
  (define-termination-status WCOREDUMP		capi.posix-WCOREDUMP)
  (define-termination-status WIFSTOPPED		capi.posix-WIFSTOPPED)
  (define-termination-status WSTOPSIG		capi.posix-WSTOPSIG))


;;;; interprocess signal handling

(define (raise-signal signum)
  (define who 'raise-signal)
  (with-arguments-validation (who)
      ((signal	signum))
    (let ((rv (capi.posix-raise signum)))
      (when (unsafe.fx< rv 0)
	(raise-errno-error who rv signum (interprocess-signal->string signum))))))

(define (kill pid signum)
  (define who 'kill)
  (with-arguments-validation (who)
      ((pid	pid)
       (signal	signum))
    (let ((rv (capi.posix-kill pid signum)))
      (when (unsafe.fx< rv 0)
	(raise-errno-error who rv signum (interprocess-signal->string signum))))))

(define (pause)
  (capi.posix-pause))


;;;; file system inspection

(define-struct struct-stat
  ;;The  order of  the fields  must match  the order  in the  C function
  ;;"fill_stat_struct()".
  ;;
  (st_mode st_ino st_dev st_nlink
	   st_uid st_gid st_size
	   st_atime st_atime_usec
	   st_mtime st_mtime_usec
	   st_ctime st_ctime_usec
	   st_blocks st_blksize))

(define (%struct-stat-printer S port sub-printer)
  (define-inline (%display thing)
    (display thing port))
  (%display "#[\"struct-stat\"")
  (%display " st_mode=#o")	(%display (number->string (struct-stat-st_mode S) 8))
  (%display " st_ino=")		(%display (struct-stat-st_ino S))
  (%display " st_dev=")		(%display (struct-stat-st_dev S))
  (%display " st_nlink=")	(%display (struct-stat-st_nlink S))
  (%display " st_uid=")		(%display (struct-stat-st_uid S))
  (%display " st_gid=")		(%display (struct-stat-st_gid S))
  (%display " st_size=")	(%display (struct-stat-st_size S))
  (%display " st_atime=")	(%display (struct-stat-st_atime S))
  (%display " st_atime_usec=")	(%display (struct-stat-st_atime_usec S))
  (%display " st_mtime=")	(%display (struct-stat-st_mtime S))
  (%display " st_mtime_usec=")	(%display (struct-stat-st_mtime_usec S))
  (%display " st_ctime=")	(%display (struct-stat-st_ctime S))
  (%display " st_ctime_usec=")	(%display (struct-stat-st_ctime_usec S))
  (%display " st_blocks=")	(%display (struct-stat-st_blocks S))
  (%display " st_blksize=")	(%display (struct-stat-st_blksize S))
  (%display "]"))

(define-inline (%make-stat)
  (make-struct-stat #f #f #f #f #f
		    #f #f #f #f #f
		    #f #f #f #f #f))

(define (stat pathname)
  (define who 'stat)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let* ((S  (%make-stat))
	     (rv (capi.posix-stat pathname.bv S)))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv pathname)
	  S)))))

(define (lstat pathname)
  (define who 'stat)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let* ((S  (%make-stat))
	     (rv (capi.posix-lstat pathname.bv S)))
	(if (unsafe.fx< rv 0)
	    (raise-errno-error who rv pathname)
	  S)))))

(define (fstat fd)
  (define who 'stat)
  (with-arguments-validation (who)
      ((file-descriptor  fd))
    (let* ((S  (%make-stat))
	   (rv (capi.posix-lstat fd S)))
      (if (unsafe.fx< rv 0)
	  (raise-errno-error who rv fd)
	S))))

;;; --------------------------------------------------------------------

(let-syntax
    ((define-file-is (syntax-rules ()
		       ((_ ?who ?func)
			(define (?who pathname follow-symlinks?)
			  (define who '?who)
			  (with-arguments-validation (who)
			      ((pathname  pathname))
			    (with-pathnames ((pathname.bv pathname))
			      (let ((rv (?func pathname.bv follow-symlinks?)))
				(if (boolean? rv)
				    rv
				  (raise-errno-error who rv pathname))))))
			))))
  (define-file-is file-is-directory?		capi.posix-file-is-directory?)
  (define-file-is file-is-char-device?		capi.posix-file-is-char-device?)
  (define-file-is file-is-block-device?		capi.posix-file-is-block-device?)
  (define-file-is file-is-regular-file?		capi.posix-file-is-regular-file?)
  (define-file-is file-is-symbolic-link?	capi.posix-file-is-symbolic-link?)
  (define-file-is file-is-socket?		capi.posix-file-is-socket?)
  (define-file-is file-is-fifo?			capi.posix-file-is-fifo?)
  (define-file-is file-is-message-queue?	capi.posix-file-is-message-queue?)
  (define-file-is file-is-semaphore?		capi.posix-file-is-semaphore?)
  (define-file-is file-is-shared-memory?	capi.posix-file-is-shared-memory?))

(let-syntax
    ((define-file-is (syntax-rules ()
		       ((_ ?who ?flag)
			(define (?who mode)
			  (with-arguments-validation (?who)
			      ((fixnum  mode))
			    (unsafe.fx= ?flag (unsafe.fxand ?flag mode))))
			))))
  (define-file-is S_ISDIR	S_IFDIR)
  (define-file-is S_ISCHR	S_IFCHR)
  (define-file-is S_ISBLK	S_IFBLK)
  (define-file-is S_ISREG	S_IFREG)
  (define-file-is S_ISLNK	S_IFLNK)
  (define-file-is S_ISSOCK	S_IFSOCK)
  (define-file-is S_ISFIFO	S_IFIFO))

;;; --------------------------------------------------------------------

(define (file-exists? pathname)
  ;;Defined by R6RS.
  ;;
  (define who 'file-exists?)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-file-exists? pathname.bv)))
	(if (boolean? rv)
	    rv
	  (raise-errno-error who rv pathname))))))

(define (access pathname how)
  (define who 'access)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (fixnum	  how))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-access pathname.bv how)))
	(if (boolean? rv)
	    rv
	  (raise-errno-error who rv pathname how))))))

;;; --------------------------------------------------------------------

(define (file-readable? pathname)
  (access pathname R_OK))

(define (file-writable? pathname)
  (access pathname W_OK))

(define (file-executable? pathname)
  (access pathname X_OK))

;;; --------------------------------------------------------------------

(define (file-size pathname)
  (define who 'file-size)
  (with-arguments-validation (who)
      ((pathname pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((v (capi.posix-file-size pathname.bv)))
	(if (>= v 0)
	    v
	  (raise/strerror who v pathname))))))

;;; --------------------------------------------------------------------

(let-syntax
    ((define-file-time (syntax-rules ()
			 ((_ ?who ?func)
			  (define (?who pathname)
			    (define who '?who)
			    (with-arguments-validation (who)
				((pathname  pathname))
			      (with-pathnames ((pathname.bv  pathname))
				(let* ((timespec (unsafe.make-vector 2))
				       (rv       (?func pathname.bv timespec)))
				  (if (unsafe.fxzero? rv)
				      (+ (* #e1e9 (unsafe.vector-ref timespec 0))
					 (unsafe.vector-ref timespec 1))
				    (raise-errno-error who rv pathname))))))
			  ))))
  (define-file-time file-atime	capi.posix-file-atime)
  (define-file-time file-mtime	capi.posix-file-mtime)
  (define-file-time file-ctime	capi.posix-file-ctime))


;;;; symbolic links

(define (realpath pathname)
  (define who 'realpath)
  (with-arguments-validation (who)
      ((pathname  pathname))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-realpath pathname.bv)))
	(if (bytevector? rv)
	    (if (bytevector? pathname)
		rv
	      ((filename->string-func) rv))
	  (raise-errno-error who rv pathname))))))


;;;; file system mutators

(define (chown pathname owner group)
  (define who 'chown)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (pid       owner)
       (gid	  group))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-chown pathname.bv owner group)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error who rv pathname owner group))))))

(define (fchown pathname owner group)
  (define who 'fchown)
  (with-arguments-validation (who)
      ((pathname  pathname)
       (pid       owner)
       (gid	  group))
    (with-pathnames ((pathname.bv pathname))
      (let ((rv (capi.posix-fchown pathname.bv owner group)))
	(if (unsafe.fxzero? rv)
	    rv
	  (raise-errno-error who rv pathname owner group))))))



(define (split-file-name str)
  (define who 'split-file-name)
  (define path-sep #\/)
  (define (find-last c str)
    (let f ((i (string-length str)))
      (if (fx=? i 0)
	  #f
	(let ((i (fx- i 1)))
	  (if (char=? (string-ref str i) c)
	      i
	    (f i))))))
  (unless (string? str) (die who "not a string" str))
  (cond
   ((find-last path-sep str) =>
    (lambda (i)
      (values
       (substring str 0 i)
       (let ((i (fx+ i 1)))
	 (substring str i (string-length str) )))))
   (else (values "" str))))

(define delete-file
  (lambda (x)
    (define who 'delete-file)
    (unless (string? x)
      (die who "filename is not a string" x))
    (let ((v (foreign-call "ikrt_delete_file" ((string->filename-func) x))))
      (unless (eq? v #t)
	(raise/strerror who v x)))))

(define rename-file
  (lambda (src dst)
    (define who 'rename-file)
    (unless (string? src)
      (die who "source file name is not a string" src))
    (unless (string? dst)
      (die who "destination file name is not a string" dst))
    (let ((v (foreign-call "ikrt_rename_file"
			   ((string->filename-func) src)
			   ((string->filename-func) dst))))
      (unless (eq? v #t)
	(raise/strerror who v src)))))

(define directory-list
  (lambda (path)
    (define who 'directory-list)
    (unless (string? path)
      (die who "not a string" path))
    (let ((r (foreign-call "ikrt_directory_list" ((string->filename-func) path))))
      (if (fixnum? r)
	  (raise/strerror who r path)
	(map utf8->string (reverse r))))))

(define ($make-directory path mode who)
  (unless (string? path)
    (die who "not a string" path))
  (unless (fixnum? mode)
    (die who "not a fixnum" mode))
  (let ((r (foreign-call "ikrt_mkdir" ((string->filename-func) path) mode)))
    (unless (eq? r #t)
      (raise/strerror who r path))))

(define default-dir-mode #o755)

(define make-directory
  (case-lambda
   ((path) (make-directory path default-dir-mode))
   ((path mode) ($make-directory path mode 'make-directory))))

(module (make-directory*)
  (define who 'make-directory*)
  (define (mkdir* dirname0 mode)
    (unless (string? dirname0)
      (die who "not a string" dirname0))
    (let f ((dirname dirname0))
      (cond
       ((file-exists? dirname)
	(unless (file-is-directory? dirname)
	  (die who
               (format "path component ~a is not a directory" dirname)
               dirname0)))
       (else
	(let-values (((base suffix) (split-file-name dirname)))
	  (unless (string=? base "") (f base))
	  (unless (string=? suffix "")
	    ($make-directory dirname mode who)))))))
  (define make-directory*
    (case-lambda
     ((name) (mkdir* name default-dir-mode))
     ((name mode) (mkdir* name mode)))))

(define delete-directory
  (case-lambda
   ((path) (delete-directory path #f))
   ((path want-error?)
    (define who 'delete-directory)
    (unless (string? path)
      (die who "not a string" path))
    (let ((r (foreign-call "ikrt_rmdir" ((string->filename-func) path))))
      (if want-error?
	  (unless (eq? r #t) (raise/strerror who r path))
	(eq? r #t))))))

(define change-mode
  (lambda (path mode)
    (define who 'change-mode)
    (unless (string? path)
      (die who "not a string" path))
    (unless (fixnum? mode)
      (die who "not a fixnum" mode))
    (let ((r (foreign-call "ikrt_chmod" ((string->filename-func) path) mode)))
      (unless (eq? r #t)
	(raise/strerror who r path)))))

(define ($make-link to path who proc)
  (unless (and (string? to) (string? path))
    (die who "not a string" (if (string? to) path to)))
  (let ((r (proc ((string->filename-func) to) ((string->filename-func) path))))
    (unless (eq? r #t)
      (raise/strerror who r path))))

(define (make-symbolic-link to path)
  ($make-link to path 'make-symbolic-link
	      (lambda (u-to u-path)
		(foreign-call "ikrt_symlink" u-to u-path))))

(define (make-hard-link to path)
  ($make-link to path 'make-hard-link
	      (lambda (u-to u-path)
		(foreign-call "ikrt_link" u-to u-path))))

(define (nanosleep secs nsecs)
  (import (ikarus system $fx))
  (unless (cond
	   ((fixnum? secs) ($fx>= secs 0))
	   ((bignum? secs) (<= 0 secs (- (expt 2 32) 1)))
	   (else (die 'nanosleep "not an exact integer" secs)))
    (die 'nanosleep "seconds must be a nonnegative integer <=" secs))
  (unless (cond
	   ((fixnum? nsecs) ($fx>= nsecs 0))
	   ((bignum? nsecs) (<= 0 nsecs 999999999))
	   (else (die 'nanosleep "not an exact integer" nsecs)))
    (die 'nanosleep "nanoseconds must be an integer \
                       in the range 0..999999999" nsecs))
  (let ((rv (foreign-call "ikrt_nanosleep" secs nsecs)))
    (unless (eq? rv 0)
      (error 'nanosleep "failed"))))


(define current-directory
  (case-lambda
   (()
    (let ((v (foreign-call "ikrt_getcwd")))
      (if (bytevector? v)
	  (utf8->string v)
	(raise/strerror 'current-directory v))))
   ((x)
    (if (string? x)
	(let ((rv (foreign-call "ikrt_chdir" ((string->filename-func) x))))
	  (unless (eq? rv #t)
	    (raise/strerror 'current-directory rv x)))
      (die 'current-directory "not a string" x)))))


;;;; done

(set-rtd-printer! (type-descriptor struct-stat) %struct-stat-printer)

)

;;; end of file
;; Local Variables:
;; eval: (put 'with-pathnames 'scheme-indent-function 1)
;; End:
