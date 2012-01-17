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


/** --------------------------------------------------------------------
 ** Headers.
 ** ----------------------------------------------------------------- */

#include "internals.h"
#include <dirent.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>


/** --------------------------------------------------------------------
 ** Prototypes and internal definitions.
 ** ----------------------------------------------------------------- */

static int total_allocated_pages = 0;
static int total_malloced = 0;

#define segment_size  (pagesize*pagesize/4)
#define segment_shift (pageshift+pageshift-2)
#define segment_index(x) (((unsigned long)(x)) >> segment_shift)


static void
extend_table_maybe(ikptr p, unsigned long size, ikpcb* pcb){
  assert(size == IK_ALIGN_TO_NEXT_PAGE(size));
  ikptr q = p + size;
  if(p < pcb->memory_base){
    unsigned long new_lo = segment_index(p);
    unsigned long old_lo = segment_index(pcb->memory_base);
    unsigned long hi = segment_index(pcb->memory_end);
    unsigned long new_vec_size = (hi - new_lo) * pagesize;
    unsigned long old_vec_size = (hi - old_lo) * pagesize;
    ikptr v = ik_mmap(new_vec_size);
    bzero((char*)(long)v, new_vec_size - old_vec_size);
    memcpy((char*)(long)(v+new_vec_size-old_vec_size),
           (char*)(long)pcb->dirty_vector_base,
           old_vec_size);
    ik_munmap((ikptr)(long)pcb->dirty_vector_base, old_vec_size);
    pcb->dirty_vector_base = (unsigned int*)(long)v;
    pcb->dirty_vector = (v - new_lo * pagesize);
    ikptr s = ik_mmap(new_vec_size);
    bzero((char*)(long)s, new_vec_size - old_vec_size);
    memcpy((char*)(long)(s+new_vec_size-old_vec_size),
           (char*)(long)(pcb->segment_vector_base),
           old_vec_size);
    ik_munmap((ikptr)(long)pcb->segment_vector_base, old_vec_size);
    pcb->segment_vector_base = (unsigned int*)(long)s;
    pcb->segment_vector = (unsigned int*)(long)(s - new_lo * pagesize);
    pcb->memory_base = (new_lo * segment_size);
  }
  else if (q >= pcb->memory_end){
    unsigned long lo = segment_index(pcb->memory_base);
    unsigned long old_hi = segment_index(pcb->memory_end);
    unsigned long new_hi = segment_index(q+segment_size-1);
    unsigned long new_vec_size = (new_hi - lo) * pagesize;
    unsigned long old_vec_size = (old_hi - lo) * pagesize;
    ikptr v = ik_mmap(new_vec_size);
    memcpy((char*)(long)v,
           (char*)(long)pcb->dirty_vector_base,
           old_vec_size);
    bzero((char*)(long)(v+old_vec_size), new_vec_size - old_vec_size);
    ik_munmap((ikptr)(long)pcb->dirty_vector_base, old_vec_size);
    pcb->dirty_vector_base = (unsigned int*)(long)v;
    pcb->dirty_vector = (v - lo * pagesize);
    ikptr s = ik_mmap(new_vec_size);
    memcpy((char*)(long)s, pcb->segment_vector_base, old_vec_size);
    bzero((char*)(long)(s+old_vec_size), new_vec_size - old_vec_size);
    ik_munmap((ikptr)(long)pcb->segment_vector_base, old_vec_size);
    pcb->segment_vector_base = (unsigned int*)(long) s;
    pcb->segment_vector = (unsigned int*)(s - lo * pagesize);
    pcb->memory_end = (new_hi * segment_size);
  }
}


static void
set_segment_type(ikptr base, unsigned long size, unsigned int type, ikpcb* pcb){
  assert(base >= pcb->memory_base);
  assert((base+size) <= pcb->memory_end);
  assert(size == IK_ALIGN_TO_NEXT_PAGE(size));
  unsigned int* p = pcb->segment_vector + IK_PAGE_INDEX(base);
  unsigned int* q = p + IK_PAGE_INDEX(size);
  while(p < q){
    *p = type;
    p++;
  }
}

void
ik_munmap_from_segment(ikptr base, unsigned long size, ikpcb* pcb){
  assert(base >= pcb->memory_base);
  assert((base+size) <= pcb->memory_end);
  assert(size == IK_ALIGN_TO_NEXT_PAGE(size));
  unsigned int* p =
    ((unsigned int*)(long)(pcb->segment_vector)) + IK_PAGE_INDEX(base);
  unsigned int* s =
    ((unsigned int*)(long)(pcb->dirty_vector)) + IK_PAGE_INDEX(base);
  unsigned int* q = p + IK_PAGE_INDEX(size);
  while(p < q){
    assert(*p != hole_mt);
    *p = hole_mt; /* holes */
    *s = 0;
    p++; s++;
  }
  ikpage* r = pcb->uncached_pages;
  if (r){
    ikpage* cache = pcb->cached_pages;
    do{
      r->base = base;
      ikpage* next = r->next;
      r->next = cache;
      cache = r;
      r = next;
      base += pagesize;
      size -= pagesize;
    } while(r && size);
    pcb->cached_pages = cache;
    pcb->uncached_pages = r;
  }
  if(size){
    ik_munmap(base, size);
  }
}


ikptr
ik_mmap_typed (unsigned long size, unsigned int type, ikpcb* pcb)
{
  ikptr		segment;
  if (size == pagesize) {
    /* If available, recycle a page from the cache. */
    ikpage *	pages = pcb->cached_pages;
    if (pages) {
      /* Extract the first page from the linked list of cached pages. */
      segment		  = pages->base;
      pcb->cached_pages	  = pages->next;
      /* Prepend  the extracted  page  to the  linked  list of  uncached
	 pages. */
      pages->next	  = pcb->uncached_pages;
      pcb->uncached_pages = pages;
    } else
      segment = ik_mmap(size);
  } else
    segment = ik_mmap(size);
  extend_table_maybe(segment, size, pcb);
  set_segment_type(segment, size, type, pcb);
  return segment;
}
ikptr
ik_mmap_ptr (unsigned long size, int gen, ikpcb* pcb)
{
  return ik_mmap_typed(size, pointers_mt|gen, pcb);
}
ikptr
ik_mmap_data (unsigned long size, int gen, ikpcb* pcb)
{
  return ik_mmap_typed(size, data_mt|gen, pcb);
}
ikptr
ik_mmap_code (unsigned long size, int gen, ikpcb* pcb)
{
  ikptr p = ik_mmap_typed(size, code_mt|gen, pcb);
  if (size > pagesize)
    set_segment_type(p+pagesize, size-pagesize, data_mt|gen, pcb);
  return p;
}
ikptr
ik_mmap_mixed (unsigned long size, ikpcb* pcb)
/* Allocate a memory segment tagged as part of the Scheme heap. */
{
  return ik_mmap_typed(size, mainheap_mt, pcb);
}


ikptr
ik_mmap (unsigned long size)
{
  unsigned long pages = (size + pagesize - 1) / pagesize;
  total_allocated_pages += pages;
  unsigned long mapsize = pages * pagesize;
  assert(size == mapsize);
#ifndef __CYGWIN__
  char* mem = mmap(0, mapsize, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANON, -1, 0);
  /* FIXME: check if in range */
  if (mem == MAP_FAILED)
    ik_abort("mapping (0x%lx bytes) failed: %s", size, strerror(errno));
#else
  char* mem = win_mmap(mapsize);
#endif
  memset(mem, -1, mapsize);
  ik_debug_message("%s: 0x%016lx .. 0x%016lx\n", __func__,
		   (long)mem, ((long)(mem))+mapsize-1);
  return (ikptr)(long)mem;
}
void
ik_munmap (ikptr mem, unsigned long size)
{
  unsigned long pages = (size + pagesize - 1) / pagesize;
  unsigned long mapsize = pages * pagesize;
  assert(size == mapsize);
  assert(((-pagesize) & (int)mem) == (int)mem);
  total_allocated_pages -= pages;
#ifndef __CYGWIN__
  int err = munmap((char*)mem, mapsize);
  if (err)
    ik_abort("ik_munmap failed: %s", strerror(errno));
#else
  win_munmap((char*)mem, mapsize);
#endif
  ik_debug_message("%s: 0x%016lx .. 0x%016lx\n", __func__,
		   (long)mem, ((long)(mem))+mapsize-1);
}


void *
ik_malloc (int size)
{
  void* x = malloc(size);
  if (NULL == x)
    ik_abort("malloc failed: %s", strerror(errno));
  total_malloced += size;
  return x;
}
void
ik_free (void* x, int size)
{
  total_malloced -= size;
  free(x);
}


#define CACHE_SIZE (pagesize * 1) /* must be multiple of pagesize*/

ikpcb*
ik_make_pcb (void)
{
  ikpcb* pcb = ik_malloc(sizeof(ikpcb));
  bzero(pcb, sizeof(ikpcb));
  pcb->collect_key = false_object;
#define STAKSIZE (1024 * 4096)
  //#define STAKSIZE (256 * 4096)
  pcb->heap_base = ik_mmap(IK_HEAPSIZE);
  pcb->heap_size = IK_HEAPSIZE;
  pcb->allocation_pointer = pcb->heap_base;
  pcb->allocation_redline = pcb->heap_base + IK_HEAPSIZE - 2 * 4096;

  pcb->stack_base = ik_mmap(STAKSIZE);
  pcb->stack_size = STAKSIZE;
  pcb->frame_pointer = pcb->stack_base + pcb->stack_size;
  pcb->frame_base = pcb->frame_pointer;
  pcb->frame_redline = pcb->stack_base + 2 * 4096;


  { /* make cache ikpage */
    ikpage* p = (ikpage*)(long)ik_mmap(CACHE_SIZE * sizeof(ikpage));
    pcb->cached_pages_base = (ikptr)(long)p;
    pcb->cached_pages_size = CACHE_SIZE * sizeof(ikpage);
    ikpage* q = 0;
    ikpage* e = p + CACHE_SIZE;
    while(p < e){
      p->next = q;
      q = p;
      p++;
    }
    pcb->uncached_pages = q;
  }

  {
    /* compute extent of heap and stack */
    ikptr lo_mem;
    ikptr hi_mem;
    if(pcb->heap_base < pcb->stack_base){
      lo_mem = pcb->heap_base - pagesize;
      hi_mem = pcb->stack_base + pcb->stack_size + pagesize;
    } else {
      lo_mem = pcb->stack_base - pagesize;
      hi_mem = pcb->heap_base + pcb->heap_size + pagesize;
    }

    unsigned long lo_seg = segment_index(lo_mem);
    unsigned long hi_seg = segment_index(hi_mem+segment_size-1);
    unsigned long vec_size = (hi_seg - lo_seg) * pagesize;
    ikptr dvec = ik_mmap(vec_size);
    bzero((char*)(long)dvec, vec_size);
    pcb->dirty_vector_base = (unsigned int*)(long) dvec;
    pcb->dirty_vector = (dvec - lo_seg * pagesize);
    ikptr svec = ik_mmap(vec_size);
    bzero((char*)(long)svec, vec_size);
    pcb->segment_vector_base = (unsigned int*)(long)svec;
    pcb->segment_vector = (unsigned int*)(long)(svec - lo_seg * pagesize);
    pcb->memory_base = (ikptr)(lo_seg * segment_size);
    pcb->memory_end = (ikptr)(hi_seg * segment_size);
    set_segment_type(pcb->heap_base,
		     pcb->heap_size,
		     mainheap_mt,
		     pcb);
    set_segment_type(pcb->stack_base,
		     pcb->stack_size,
		     mainstack_mt,
		     pcb);
  }
  /* initialize base rtd */
  {
    ikptr r = ik_unsafe_alloc(pcb, IK_ALIGN(rtd_size)) | rtd_tag;
    ref(r, off_rtd_rtd) = r;
    ref(r, off_rtd_length) = (ikptr) (rtd_size-wordsize);
    ref(r, off_rtd_name) = 0;
    ref(r, off_rtd_fields) = 0;
    ref(r, off_rtd_printer) = 0;
    ref(r, off_rtd_symbol) = 0;
    pcb->base_rtd = r;
  }
  return pcb;
}

void ik_delete_pcb(ikpcb* pcb){
  ikpage* p = pcb->cached_pages;
  pcb->cached_pages = 0;
  pcb->uncached_pages = 0;
  while(p){
    ik_munmap(p->base, pagesize);
    p = p->next;
  }
  ik_munmap(pcb->cached_pages_base, pcb->cached_pages_size);
  {
    int i;
    for(i=0; i<generation_count; i++){
      ik_ptr_page* p = pcb->protected_list[i];
      while(p){
        ik_ptr_page* next = p->next;
        ik_munmap((ikptr)(long)p, pagesize);
        p = next;
      }
    }
  }
  ikptr base = pcb->memory_base;
  ikptr end = pcb->memory_end;
  unsigned int* segment_vec = pcb->segment_vector;
  long i = IK_PAGE_INDEX(base);
  long j = IK_PAGE_INDEX(end);
  while(i < j){
    unsigned int t = segment_vec[i];
    if(t != hole_mt){
      ik_munmap((ikptr)(i<<pageshift), pagesize);
    }
    i++;
  }
  long vecsize = (segment_index(end) - segment_index(base)) * pagesize;
  ik_munmap((ikptr)(long)pcb->dirty_vector_base, vecsize);
  ik_munmap((ikptr)(long)pcb->segment_vector_base, vecsize);
  ik_free(pcb, sizeof(ikpcb));
}


ikptr
ik_safe_alloc (ikpcb* pcb, unsigned long size)
/* Allocate a memory block on the  Scheme heap and return a reference to
   it as an *untagged* pointer.   PCB must reference the process control
   block, SIZE  must be the  requested number of bytes  filtered through
   "IK_ALIGN()".

   If  not enough memory  is available  on the  current heap  segment, a
   garbage collection  is triggered; then allocation is  tried again: if
   it  still   fails  the  process   is  terminated  with   exit  status
   EXIT_FAILURE.  */
{
  assert(size == IK_ALIGN(size));
  ikptr		alloc_ptr;
  ikptr		end_ptr;
  ikptr		new_alloc_ptr;
  alloc_ptr	= pcb->allocation_pointer;
  end_ptr	= pcb->heap_base + pcb->heap_size;
  new_alloc_ptr	= alloc_ptr + size;
  if (new_alloc_ptr < end_ptr) {
    /* There  is room  in the  current heap  block: update  the  pcb and
       return the offset. */
    pcb->allocation_pointer = new_alloc_ptr;
  } else {
    /* No room in the current heap block: run GC. */
    ik_collect(size, pcb);
    {
      alloc_ptr		= pcb->allocation_pointer;
      end_ptr		= pcb->heap_base + pcb->heap_size;
      new_alloc_ptr	= alloc_ptr + size;
      if (new_alloc_ptr < end_ptr)
	pcb->allocation_pointer = new_alloc_ptr;
      else
	ik_abort("collector did not leave enough room for %lu bytes", size);
    }
  }
  return alloc_ptr;
}


ikptr
ik_unsafe_alloc (ikpcb* pcb, unsigned long requested_size)
/* Allocate a memory block on the  Scheme heap and return a reference to
   it as an *untagged* pointer.   PCB must reference the process control
   block, REQUESTED_SIZE must be  the requested number of bytes filtered
   through "IK_ALIGN()".

   If not enough memory is available  on the current heap segment: a new
   heap segment is  allocated; is such allocation fails:  the process is
   terminated with exit status EXIT_FAILURE.

   This  function  is  meant  to  be used  to  allocate  "small"  memory
   blocks. */
{
  assert(requested_size == IK_ALIGN(requested_size));
  ikptr alloc_ptr       = pcb->allocation_pointer;
  ikptr end_ptr         = pcb->heap_base + pcb->heap_size;
  ikptr new_alloc_ptr   = alloc_ptr + requested_size;
  /* If there  is room in the  current heap segment: update  the PCB and
     return the offset. */
  if (new_alloc_ptr < end_ptr) {
    pcb->allocation_pointer = new_alloc_ptr;
    return alloc_ptr;
  } else {
    /* No room in the current heap block: enlarge the heap by allocating
       a new segment. */
    if (alloc_ptr) {
      /* This is not the first heap segment allocation, so prepend a new
	 "ikpages"  node to  the linked  list of  old heap  segments and
	 initialise it with a reference to the current heap segment. */
      ikpages *	p = ik_malloc(sizeof(ikpages));
      p->base = pcb->heap_base;
      p->size = pcb->heap_size;
      p->next = pcb->heap_pages;
      pcb->heap_pages = p;
    }
    { /* accounting */
      long bytes = ((long)pcb->allocation_pointer) - ((long)pcb->heap_base);
      long minor = bytes + pcb->allocation_count_minor;
      while (minor >= IK_MOST_BYTES_IN_MINOR) {
	minor -= IK_MOST_BYTES_IN_MINOR;
	pcb->allocation_count_major++;
      }
      pcb->allocation_count_minor = minor;
    }
    { /* Allocate a  new heap  segment and register  it as  current heap
	 base.  While  computing the segment size: make  sure that there
	 is always  some room at the  end of the new  heap segment after
	 allocating the requested memory for the new object. */
      unsigned long new_size = (requested_size > IK_HEAP_EXT_SIZE) ? requested_size : IK_HEAP_EXT_SIZE;
      new_size       += 2 * 4096;
      new_size       = IK_ALIGN_TO_NEXT_PAGE(new_size);
      alloc_ptr      = ik_mmap_mixed(new_size, pcb);
      pcb->heap_base = alloc_ptr;
      pcb->heap_size = new_size;
      pcb->allocation_redline = alloc_ptr + new_size - 2 * 4096;
      new_alloc_ptr = alloc_ptr + requested_size;
      pcb->allocation_pointer = new_alloc_ptr;
      return alloc_ptr;
    }
  }
}


#ifndef NDEBUG
void
ik_debug_message (const char * error_message, ...)
{
  va_list        ap;
  va_start(ap, error_message);
  fprintf(stderr, "*** Vicare debug message: ");
  vfprintf(stderr, error_message, ap);
  fprintf(stderr, "\n");
  va_end(ap);
}
#endif
int
ik_abort (const char * error_message, ...)
{
  va_list        ap;
  va_start(ap, error_message);
  fprintf(stderr, "*** Vicare error: ");
  vfprintf(stderr, error_message, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  exit(EXIT_FAILURE);
  return EXIT_FAILURE;
}
void
ik_error (ikptr args)
{
  fprintf(stderr, "*** Vicare error: ");
  ik_fprint(stderr, args);
  fprintf(stderr, "\n");
  exit(EXIT_FAILURE);
}
void ik_stack_overflow(ikpcb* pcb){
#ifndef NDEBUG
  fprintf(stderr, "entered ik_stack_overflow pcb=0x%016lx\n", (long)pcb);
#endif
  set_segment_type(pcb->stack_base, pcb->stack_size, data_mt, pcb);

  ikptr frame_base = pcb->frame_base;
  ikptr underflow_handler = ref(frame_base, -wordsize);
#ifndef NDEBUG
  fprintf(stderr, "underflow_handler = 0x%08x\n", (int)underflow_handler);
#endif
  /* capture continuation and set it as next_k */
  ikptr k = ik_unsafe_alloc(pcb, IK_ALIGN(continuation_size)) | vector_tag;
  ref(k, -vector_tag) = continuation_tag;
  ref(k, off_continuation_top) = pcb->frame_pointer;
  ref(k, off_continuation_size) =
    pcb->frame_base - pcb->frame_pointer - wordsize;
  ref(k, off_continuation_next) = pcb->next_k;
  pcb->next_k = k;

  pcb->stack_base = (ikptr)(long)ik_mmap_typed(STAKSIZE, mainstack_mt, pcb);
  pcb->stack_size = STAKSIZE;
  pcb->frame_base = pcb->stack_base + pcb->stack_size;
  pcb->frame_pointer = pcb->frame_base - wordsize;
  pcb->frame_redline = pcb->stack_base + 2 * 4096;
  ref(pcb->frame_pointer, 0) = underflow_handler;
  return;
}


/*
char* ik_uuid(char* str){
  assert((36 << fx_shift) == (int) ref(str, disp_string_length - string_tag));
  uuid_t u;
  uuid_clear(u);
  uuid_generate(u);
  uuid_unparse_upper(u, str + disp_string_data - string_tag);
  return str;
}
*/


static const char* uuid_chars =
"!$%&/0123456789<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
static int uuid_strlen = 1;
ikptr ik_uuid(ikptr bv){
  static int fd = -1;
  if(fd == -1){
    fd = open("/dev/urandom", O_RDONLY);
    if(fd == -1){
      return ik_errno_to_code();
    }
    uuid_strlen = strlen(uuid_chars);
  }
  long n = unfix(ref(bv, off_bytevector_length));
  unsigned char* data = (unsigned char*)(long)(bv+off_bytevector_data);
  int r = read(fd, data, n);
  if(r < 0){
    return ik_errno_to_code();
  }
  unsigned char* p = data;
  unsigned char* q = data + n;
  while(p < q){
    *p = uuid_chars[*p % uuid_strlen];
    p++;
  }
  return bv;
}


static char*
mtname(unsigned int n){
  if(n == mainheap_type)  { return "HEAP_T"; }
  if(n == mainstack_type) { return "STAK_T"; }
  if(n == pointers_type)  { return "PTER_T"; }
  if(n == dat_type)       { return "DATA_T"; }
  if(n == code_type)      { return "CODE_T"; }
  if(n == hole_type)      { return "      "; }
  return "WHAT_T";
}

ikptr
ik_dump_metatable(ikpcb* pcb){
  unsigned int* s = pcb->segment_vector_base;
  ikptr p = pcb->memory_base;
  ikptr hi = pcb->memory_end;
  while(p < hi){
    unsigned int t = *s & type_mask;
    ikptr start = p;
    p += pagesize;
    s++;
    while((p < hi) && ((*s & type_mask) == t)){
      p += pagesize;
      s++;
    }
    fprintf(stderr, "0x%016lx + %5ld pages = %s\n",
        (long) start,
        ((long)p-(long)start)/pagesize,
        mtname(t));
  }
  return void_object;
}

ikptr
ik_dump_dirty_vector(ikpcb* pcb){
  unsigned int* s = pcb->dirty_vector_base;
  ikptr p = pcb->memory_base;
  ikptr hi = pcb->memory_end;
  while(p < hi){
    unsigned int t = *s;
    ikptr start = p;
    p += pagesize;
    s++;
    while((p < hi) && (*s == t)){
      p += pagesize;
      s++;
    }
    fprintf(stderr, "0x%016lx + %5ld pages = 0x%08x\n",
        (long) start,
        ((long)p-(long)start)/pagesize,
        t);
  }
  return void_object;
}

ikptr
ikrt_make_code(ikptr codesizeptr, ikptr freevars, ikptr rvec, ikpcb* pcb){
  assert((fx_mask & (int)codesizeptr) == 0);
  long code_size = unfix(codesizeptr);
  long memreq = IK_ALIGN_TO_NEXT_PAGE(code_size + disp_code_data);
  ikptr mem = ik_mmap_code(memreq, 0, pcb);
  bzero((char*)(long)mem, memreq);
  ref(mem, 0) = code_tag;
  ref(mem, disp_code_code_size) = codesizeptr;
  ref(mem, disp_code_freevars) = freevars;
  ref(mem, disp_code_reloc_vector) = rvec;
  ref(mem, disp_code_annotation) = false_object;
  ik_relocate_code(mem);
  return mem+vector_tag;
}

ikptr
ikrt_set_code_reloc_vector(ikptr code, ikptr vec, ikpcb* pcb){
  ref(code, off_code_reloc_vector) = vec;
  ik_relocate_code(code-vector_tag);
  ((unsigned int*)(long)pcb->dirty_vector)[IK_PAGE_INDEX(code)] = -1;
  return void_object;
}

ikptr
ikrt_set_code_annotation(ikptr code, ikptr annot, ikpcb* pcb){
  ref(code, off_code_annotation) = annot;
  ((unsigned int*)(long)pcb->dirty_vector)[IK_PAGE_INDEX(code)] = -1;
  return void_object;
}



ikptr
ikrt_bvftime(ikptr outbv, ikptr fmtbv){
  time_t t;
  struct tm* tmp;
  t = time(NULL);
  tmp = localtime(&t);
  if(tmp == NULL){
    fprintf(stderr, "Error in time: %s\n", strerror(errno));
  }
  int rv =
    strftime((char*)(long)(outbv+off_bytevector_data),
             unfix(ref(outbv, off_bytevector_length)) + 1,
             (char*)(long)(fmtbv+off_bytevector_data),
             tmp);
  if(rv == 0){
    fprintf(stderr, "Error in strftime: %s\n", strerror(errno));
  }
  return fix(rv);
}

ikptr
ikrt_register_guardian_pair(ikptr p0, ikpcb* pcb){
  ik_ptr_page* x = pcb->protected_list[0];
  if((x == NULL) || (x->count == ik_ptr_page_size)){
    assert(sizeof(ik_ptr_page) == pagesize);
    ik_ptr_page* y = (ik_ptr_page*)(long)ik_mmap(pagesize);
    y->count = 0;
    y->next = x;
    pcb->protected_list[0] = y;
    x = y;
  }
  x->ptr[x->count++] = p0;
  return void_object;
}

ikptr
ikrt_register_guardian(ikptr tc, ikptr obj, ikpcb* pcb){
  ikptr p0 = ik_unsafe_alloc(pcb, pair_size) | pair_tag;
  ref(p0, off_car) = tc;
  ref(p0, off_cdr) = obj;
  return ikrt_register_guardian_pair(p0, pcb);
}

ikptr
ikrt_stats_now(ikptr t, ikpcb* pcb){
  struct rusage r;
  struct timeval s;

  gettimeofday(&s, 0);
  getrusage(RUSAGE_SELF, &r);
  /* Do  not  change the  order  of the  fields!!!   It  must match  the
     implementation     of     the     record    type     "stats"     in
     "scheme/ikarus.timer.ss". */
  IK_FIELD(t,  0) = fix(r.ru_utime.tv_sec);
  IK_FIELD(t,  1) = fix(r.ru_utime.tv_usec);
  IK_FIELD(t,  2) = fix(r.ru_stime.tv_sec);
  IK_FIELD(t,  3) = fix(r.ru_stime.tv_usec);
  IK_FIELD(t,  4) = fix(s.tv_sec);
  IK_FIELD(t,  5) = fix(s.tv_usec);
  IK_FIELD(t,  6) = fix(pcb->collection_id);
  IK_FIELD(t,  7) = fix(pcb->collect_utime.tv_sec);
  IK_FIELD(t,  8) = fix(pcb->collect_utime.tv_usec);
  IK_FIELD(t,  9) = fix(pcb->collect_stime.tv_sec);
  IK_FIELD(t, 10) = fix(pcb->collect_stime.tv_usec);
  IK_FIELD(t, 11) = fix(pcb->collect_rtime.tv_sec);
  IK_FIELD(t, 12) = fix(pcb->collect_rtime.tv_usec);
  {
    /* minor bytes */
    long bytes_in_heap	= ((long)pcb->allocation_pointer) - ((long)pcb->heap_base);
    long bytes		= bytes_in_heap + pcb->allocation_count_minor;
    IK_FIELD(t, 13)	= fix(bytes);
  }
  /* major bytes */
  IK_FIELD(t, 14) = fix(pcb->allocation_count_major);
  return void_object;
}

ikptr
ikrt_make_vector1(ikptr len, ikpcb* pcb){
  int intlen = (int)len;
  if(IK_IS_FIXNUM(len) && (intlen >= 0)){
    ikptr s = ik_safe_alloc(pcb, IK_ALIGN(len + disp_vector_data));
    ref(s, 0) = len;
    memset((char*)(long)(s+disp_vector_data), 0, len);
    return s+vector_tag;
  } else {
    return 0;
  }
}

#if 0
ikptr
ikrt_make_vector2(ikptr len, ikptr obj, ikpcb* pcb){
  if(IK_IS_FIXNUM(len) && ((len >> 31)!=0)){
    pcb->root0 = &obj;
    ikptr s = ik_safe_alloc(pcb, IK_ALIGN(((int)len) + disp_vector_data));
    pcb->root0 = 0;
    ref(s, 0) = len;
    memset(s+disp_vector_data, 0, (int)len);
    return s+vector_tag;
  } else {
    return false_object;
  }
}
#endif


/** --------------------------------------------------------------------
 ** Miscellaneous functions.
 ** ----------------------------------------------------------------- */

ikptr
ikrt_debug(ikptr x){
  fprintf(stderr, "DEBUG 0x%016lx\n", (long)x);
  return 0;
}


/** --------------------------------------------------------------------
 ** Termination.
 ** ----------------------------------------------------------------- */

ikptr
ikrt_exit (ikptr status, ikpcb* pcb)
/* This is nor for the public API. */
{
  ik_delete_pcb(pcb);
  assert(total_allocated_pages == 0);
  if(IK_IS_FIXNUM(status)){
    exit(unfix(status));
  } else {
    exit(EXIT_FAILURE);
  }
}

/* end of file */
