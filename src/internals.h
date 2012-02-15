/*
  Part of: Vicare
  Contents: internal header file
  Date: Wed Jan 11, 2012

  Abstract



  Copyright (C) 2012 Marco Maggi <marco.maggi-ipsu@poste.it>
  Copyright (C) 2006-2008  Abdulaziz Ghuloum

  This program is  free software: you can redistribute	it and/or modify
  it under the	terms of the GNU General Public	 License as published by
  the Free Software Foundation, either	version 3 of the License, or (at
  your option) any later version.

  This program	is distributed in the  hope that it will  be useful, but
  WITHOUT   ANY	 WARRANTY;   without  even   the  implied   warranty  of
  MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See	 the GNU
  General Public License for more details.

  You  should have received  a copy  of the  GNU General  Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef INTERNALS_H
#define INTERNALS_H 1


/** --------------------------------------------------------------------
 ** Headers.
 ** ----------------------------------------------------------------- */

#include "vicare.h"
#include <stdint.h>
#include <stdio.h>

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif
#ifdef HAVE_ASSERT_H
#  include <assert.h>
#endif
#ifdef HAVE_ERRNO_H
#  include <errno.h>
#endif
#ifdef HAVE_LIMITS_H
#  include <limits.h>
#endif
#ifdef HAVE_NETDB_H
#  include <netdb.h>
#endif
#ifdef HAVE_STDARG_H
#  include <stdarg.h>
#endif
#ifdef HAVE_STDIO_H
#  include <stdio.h>
#endif
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif
#ifdef HAVE_STDDEF_H
#  include <stddef.h>
#endif
#ifdef HAVE_STRING_H
#  include <string.h>
#endif
#ifdef HAVE_STRINGS_H
#  include <strings.h>
#endif
#ifdef HAVE_ARPA_INET_H
#  include <arpa/inet.h>
#endif
#ifdef HAVE_NETINET_IN_H
#  include <netinet/in.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#  include <sys/socket.h>
#endif
#ifdef HAVE_SYS_RESOURCE_H
#  include <sys/resource.h>
#endif
#ifdef HAVE_SYS_TIME_H
#  include <sys/time.h>
#endif


/** --------------------------------------------------------------------
 ** Constants.
 ** ----------------------------------------------------------------- */

#define IK_GUARDIANS_GENERATION_NUMBER	0

#define IK_FORWARD_PTR		((ikptr)-1)
#define IK_MOST_BYTES_IN_MINOR	0x10000000

#define old_gen_mask		0x00000007
#define new_gen_mask		0x00000008
#define gen_mask		0x0000000F
#define new_gen_tag		0x00000008
#define meta_dirty_mask		0x000000F0
#define type_mask		0x00000F00
#define scannable_mask		0x0000F000
#define dealloc_mask		0x000F0000
#define large_object_mask	0x00100000
#define meta_dirty_shift	4

#define hole_type		0x00000000
#define mainheap_type		0x00000100
#define mainstack_type		0x00000200
#define pointers_type		0x00000300
#define dat_type		0x00000400
#define code_type		0x00000500
#define weak_pairs_type		0x00000600
#define symbols_type		0x00000700

#define scannable_tag		0x00001000
#define unscannable_tag		0x00000000

#define dealloc_tag_un		0x00010000
#define dealloc_tag_at		0x00020000
#define retain_tag		0x00000000

#define large_object_tag	0x00100000

#define hole_mt		(hole_type	 | unscannable_tag | retain_tag)
#define mainheap_mt	(mainheap_type	 | unscannable_tag | retain_tag)
#define mainstack_mt	(mainstack_type	 | unscannable_tag | retain_tag)
#define pointers_mt	(pointers_type	 | scannable_tag   | dealloc_tag_un)
#define symbols_mt	(symbols_type	 | scannable_tag   | dealloc_tag_un)
#define data_mt		(dat_type	 | unscannable_tag | dealloc_tag_un)
#define code_mt		(code_type	 | scannable_tag   | dealloc_tag_un)
#define weak_pairs_mt	(weak_pairs_type | scannable_tag   | dealloc_tag_un)

#define call_instruction_size	((wordsize == 4) ? 5 : 10)
#define disp_frame_size		(- (call_instruction_size + 3 * wordsize))
#define disp_frame_offset	(- (call_instruction_size + 2 * wordsize))
#define disp_multivale_rp	(- (call_instruction_size + 1 * wordsize))

/* ------------------------------------------------------------------ */

#define pagesize		4096

/* How much  to right-shift a pointer  value to obtain the  index of the
   page (of size PAGESIZE) it is in.

       4000 >> 12 = 0
       8000 >> 12 = 1
      10000 >> 12 = 2
*/
#define pageshift		12

#define generation_count	5  /* generations 0 (nursery), 1, 2, 3, 4 */

#define IK_HEAP_EXT_SIZE  (32 * 4096)
#define IK_HEAPSIZE	  (1024 * ((wordsize==4)?1:2) * 4096) /* 4/8 MB */

#define IK_FASL_HEADER		((sizeof(ikptr) == 4)? "#@IK01" : "#@IK02")
#define IK_FASL_HEADER_LEN	(strlen(IK_FASL_HEADER))

#define IK_PTR_PAGE_SIZE \
  ((pagesize - sizeof(long) - sizeof(struct ik_ptr_page*))/sizeof(ikptr))

/* Given the pointer X or tagged pointer X: evaluate to the index of the
   memory page  it is in; notice that  the tag bits of  a tagged pointer
   are not  influent.  Given a  number of bytes  X evaluate to  an index
   offset. */
#define IK_PAGE_INDEX(x)   \
  (((ik_ulong)(x)) >> pageshift)

#define IK_ALIGN_TO_NEXT_PAGE(x) \
  (((pagesize - 1 + (ik_ulong)(x)) >> pageshift) << pageshift)

#define IK_ALIGN_TO_PREV_PAGE(x) \
  ((((ik_ulong)(x)) >> pageshift) << pageshift)


/** --------------------------------------------------------------------
 ** Type definitions.
 ** ----------------------------------------------------------------- */

typedef struct ikpage {
  ikptr		 base;
  struct ikpage* next;
} ikpage;

/* Node for linked list of allocated pages. */
typedef struct ikpages {
  ikptr		base;
  int		size;
  struct ikpages* next;
} ikpages;

/* Node in  a linked list  referencing all the generated  FFI callbacks.
   It is used  to allow the garbage collector not  to collect data still
   in  use by  the callbacks.	See "ikarus-ffi.c"  for details	 on this
   structure. */
typedef struct ik_callback_locative {
  void *	callable_pointer;	/* pointer to callable C function */
  void *	closure;		/* data generated by Libffi */
  ikptr		data;			/* Scheme value holding required data */
  struct ik_callback_locative * next;	/* pointer to next link */
} ik_callback_locative;

typedef struct ik_ptr_page {
  long		count;
  struct ik_ptr_page* next;
  ikptr		ptr[IK_PTR_PAGE_SIZE];
} ik_ptr_page;

struct ikpcb {
  /* The  first locations  may	be  accessed by	 some  compiled code  to
     perform overflow/underflow ops. */
  ikptr	  allocation_pointer;		/* 32-bit offset =  0 */
  ikptr	  allocation_redline;		/* 32-bit offset =  4 */
  ikptr	  frame_pointer;		/* 32-bit offset =  8 */
  ikptr	  frame_base;			/* 32-bit offset = 12 */
  ikptr	  frame_redline;		/* 32-bit offset = 16 */
  ikptr	  next_k;			/* 32-bit offset = 20 */
  ikptr	  system_stack;			/* 32-bit offset = 24 */
  ikptr	  dirty_vector;			/* 32-bit offset = 28 */
  ikptr	  arg_list;			/* 32-bit offset = 32 */
  ikptr	  engine_counter;		/* 32-bit offset = 36 */
  ikptr	  interrupted;			/* 32-bit offset = 40 */
  ikptr	  base_rtd;			/* 32-bit offset = 44 */
  ikptr	  collect_key;			/* 32-bit offset = 48 */

  /* ------------------------------------------------------------------ */
  /* The  following fields are	not used  by any  scheme code  they only
     support the runtime system (GC, etc.) */

  /* Linked  list of  FFI callback  support data.   Used by  the garbage
     collector	not  to collect	 data  still  needed  by some  callbacks
     registered in data structures handled by foreign libraries. */
  ik_callback_locative * callbacks;

  /* Value of  "errno" right after the	last call to  a foreign function
     callout. */
  int			last_errno;

  /* Additional roots for the garbage collector.  They are used to avoid
     collecting objects still in use while they are in use by C code. */
  ikptr*		root0;
  ikptr*		root1;
  ikptr*		root2;
  ikptr*		root3;
  ikptr*		root4;
  ikptr*		root5;
  ikptr*		root6;
  ikptr*		root7;
  ikptr*		root8;
  ikptr*		root9;

  ik_uint *		segment_vector;
  ikptr			weak_pairs_ap;
  ikptr			weak_pairs_ep;
  /* Pointer to and number of  bytes of the current heap memory segment.
     New objects are allocated here. */
  ikptr			heap_base;
  ik_ulong		heap_size;
  /* Pointer to first node in  linked list of allocated memory segments.
     Initialised to  NULL when building	 the PCB.  Whenever  the current
     heap is full: a new node is prepended to the list, initialised with
     the fields "heap_base" and "heap_size". */
  ikpages*		heap_pages;
  /* Linked list of cached pages so that we don't map/unmap. */
  ikpage *		cached_pages;
  /* Linked list of cached ikpages so that we don't malloc/free. */
  ikpage *		uncached_pages;
  ikptr			cached_pages_base;
  int			cached_pages_size;
  ikptr			stack_base;
  ik_ulong		stack_size;
  ikptr			symbol_table;
  ikptr			gensym_table;
  /* Array of linked lists; one for each GC generation.  The linked list
     holds  references  to  Scheme  values  that  must  not  be  garbage
     collected  even   when  they   are  not  referenced,   for  example
     guardians. */
  ik_ptr_page*		protected_list[generation_count];
  ik_uint *		dirty_vector_base;
  ik_uint *		segment_vector_base;
  ikptr			memory_base;
  ikptr			memory_end;

  /* Number of garbage collections performed so far.  It is used: at the
     beginning	of a  GC ru,  to determine  which objects  generation to
     inspect; when reporting GC statistics to the user, to show how many
     GCs where performed between two timestamps. */
  int			collection_id;

  int			allocation_count_minor;
  int			allocation_count_major;

  /* Used for garbage collection statistics. */
  struct timeval	collect_utime;
  struct timeval	collect_stime;
  struct timeval	collect_rtime;

};

/* Node in a linked list of continuations. */
typedef struct ikcont {
  ikptr		tag;
  ikptr		top;
  long		size;
  ikptr		next;	/* pointer to next ikcont structure */
} ikcont;


/** --------------------------------------------------------------------
 ** Helper and legacy macros.
 ** ----------------------------------------------------------------- */

#define ref(X,N)	IK_REF((X),(N))

#define fix(X)		IK_FIX(X)
#define unfix(X)	IK_UNFIX(X)


/** --------------------------------------------------------------------
 ** Function prototypes.
 ** ----------------------------------------------------------------- */

ikpcb * ik_collect		(unsigned long, ikpcb*);

void*	ik_malloc		(int);
void	ik_free			(void*, int);

ikptr	ik_underflow_handler	(ikpcb*);

ikptr	ik_mmap			(unsigned long);
ikptr	ik_mmap_typed		(unsigned long size, unsigned type, ikpcb*);
ikptr	ik_mmap_ptr		(unsigned long size, int gen, ikpcb*);
ikptr	ik_mmap_data		(unsigned long size, int gen, ikpcb*);
ikptr	ik_mmap_code		(unsigned long size, int gen, ikpcb*);
ikptr	ik_mmap_mixed		(unsigned long size, ikpcb*);
void	ik_munmap		(ikptr, unsigned long);
ikpcb * ik_make_pcb		(void);
void	ik_delete_pcb		(ikpcb*);
void	ik_free_symbol_table	(ikpcb* pcb);

void	ik_fasl_load		(ikpcb* pcb, char* filename);
void	ik_relocate_code	(ikptr);

ikptr	ik_exec_code		(ikpcb* pcb, ikptr code_ptr, ikptr argcount, ikptr cp);

ikptr	ik_asm_enter		(ikpcb*, ikptr code_object, ikptr arg, ikptr cp);
ikptr	ik_asm_reenter		(ikpcb*, ikptr code_object, ikptr val);


/** --------------------------------------------------------------------
 ** Objects stuff.
 ** ----------------------------------------------------------------- */

ikptr	ik_normalize_bignum	(long limbs, int sign, ikptr r);

#define max_digits_per_limb	((wordsize==4)?10:20)


/** --------------------------------------------------------------------
 ** Other prototypes and external definitions.
 ** ----------------------------------------------------------------- */

extern char **		environ;

#ifdef __CYGWIN__
void	win_munmap(char* addr, size_t size);
char*	win_mmap(size_t size);
#endif

int	ikarus_main (int argc, char** argv, char* boot_file);

ikptr	ik_errno_to_code (void);


/** --------------------------------------------------------------------
 ** Interface to "getaddrinfo()".
 ** ----------------------------------------------------------------- */

#if (!HAVE_GETADDRINFO)
#  include <sys/types.h>
#  include <netdb.h>

struct addrinfo {
  int ai_family;
  int ai_socktype;
  int ai_protocol;
  size_t ai_addrlen;
  struct sockaddr *ai_addr;
  struct addrinfo *ai_next;
};

extern int
getaddrinfo(const char *hostname, const char* servname,
  const struct addrinfo* hints, struct addrinfo** res);

extern void
freeaddrinfo(struct addrinfo *ai);


#ifndef EAI_SYSTEM
# define EAI_SYSTEM 11 /* same code as in glibc */
#endif

#endif /* if (!HAVE_GETADDRINFO) */


/** --------------------------------------------------------------------
 ** Done.
 ** ----------------------------------------------------------------- */

#endif /* INTERNALS_H */

/* end of file */
