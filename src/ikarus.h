/*
 * Ikarus Scheme -- A compiler for R6RS Scheme.
 * Copyright (C) 2006,2007,2008  Abdulaziz Ghuloum
 * Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
 *
 * This program is free software:  you can redistribute it and/or modify
 * it under  the terms of  the GNU General  Public License version  3 as
 * published by the Free Software Foundation.
 *
 * This program is  distributed in the hope that it  will be useful, but
 * WITHOUT  ANY   WARRANTY;  without   even  the  implied   warranty  of
 * MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See  the GNU
 * General Public License for more details.
 *
 * You should  have received  a copy of  the GNU General  Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef IKARUS_H
#  define IKARUS_H


/** --------------------------------------------------------------------
 ** Headers.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <limits.h>
#include <errno.h>
#include "ikarus-data.h"


/** --------------------------------------------------------------------
 ** Prototypes and external definitions.
 ** ----------------------------------------------------------------- */

extern char **environ;

int     ikarus_main (int argc, char** argv, char* boot_file);

ikptr   ik_errno_to_code (void);

/* object utilities */
int     ik_list_length (ikptr x);
void    ik_list_to_argv (ikptr x, char **argv);
char**  ik_list_to_vec (ikptr x);

ikptr   ik_bytevector_alloc (ikpcb * pcb, long int requested_number_of_bytes);



/** --------------------------------------------------------------------
 ** Done.
 ** ----------------------------------------------------------------- */

#endif /* ifndef IKARUS_H */

/* end of file */
