/*
 * Ikarus Scheme -- A compiler for R6RS Scheme.
 * Copyright (C) 2006,2007,2008	 Abdulaziz Ghuloum
 * Modified by Marco Maggi <marco.maggi-ipsu@poste.it>
 *
 * This program is free software:  you can redistribute it and/or modify
 * it under  the terms of  the GNU General  Public License version  3 as
 * published by the Free Software Foundation.
 *
 * This program is  distributed in the hope that it  will be useful, but
 * WITHOUT  ANY	  WARRANTY;  without   even  the  implied   warranty  of
 * MERCHANTABILITY  or FITNESS FOR  A PARTICULAR  PURPOSE.  See	 the GNU
 * General Public License for more details.
 *
 * You should  have received  a copy of	 the GNU General  Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "internals.h"

#define DEBUG_EXEC	0

ikptr
ik_exec_code (ikpcb * pcb, ikptr s_code, ikptr s_argcount, ikptr s_closure)
/* Execute  Scheme  code  and  all   its  continuations  until  no  more
   continuations are stored in the PCB or a system continuation is found
   in the continuations linked list.

   S_CODE  is  a  tagged  memory pointer  referencing  the  code  object
   implementing S_CLOSURE, if any.

   S_ARGCOUNT  is a  fixnum representing  the negated  number of  Scheme
   arguments.

   S_CLOSURE is a reference to the  closure object to execute; it can be
   the fixnum zero if there is no closure to execute, as when we enter a
   loaded FASL file.

   Return the return value of the last executed continuation. */
{
#if DEBUG_EXEC
  ik_debug_message_start("%s: enter closure 0x%016lx", __func__, (long)s_closure);
  ik_fprint(stderr, IK_REF(s_code, off_code_annotation));
  fprintf(stderr, "\n");
#endif
  /* A possibly zero fixnum representing  the negated number of returned
     Scheme values. */
  ikptr	s_retval_count = ik_asm_enter(pcb, s_code+off_code_data, s_argcount, s_closure);
  /* Reference to the  continuation object representing the  C or Scheme
     continuation we want to go back to. */
  ikptr s_kont       = pcb->next_k;
  while (s_kont) {
#if (0 || DEBUG_EXEC)
    ik_debug_message("%s: resuming saved continuation 0x%016lx", __func__, (long)s_kont);
#endif
    /* We are here  because the Scheme code wants to  return to a Scheme
       continuation object, handing  to the continuation -S_RETVAL_COUNT
       return  values.  This  requires installation  of the  appropriate
       (previously saved) stack. */
    ikcont * p_next_k = (ikcont *)(long)(s_kont - vector_tag);
    /* System continuations are created by the FFI to save the current C
       execution contest just before calling back a Scheme function.  So
       if S_KONT is  a system continuation: we have no  Scheme code to
       go back to, we just return to the caller of this C function. */
    if (system_continuation_tag == p_next_k->tag)
      break;
    /* TOP is  a raw memory pointer  to the highest machine  word in the
       last function call frame of the continuation.

       RP is a  raw memory address being the entry  point in binary code
       we have to jump back to.

       FRAMESIZE is the function call frame size of the function we have
       to return to.  This value was computed at compile time and stored
       in binary code just before the "call" instruction. */
    ikptr	top       = p_next_k->top;
    ikptr	rp        = IK_REF(top, 0);
    long	framesize = (long) IK_REF(rp, disp_frame_size);
#if DEBUG_EXEC
    ik_debug_message("%s: exec framesize=%ld kontsize=%ld rp=0x%016lx",
		     __func__, framesize, p_next_k->size, rp);
#endif
    if (0 == framesize) {
      framesize = IK_REF(top, wordsize);
#if (DEBUG_EXEC)
      ik_debug_message("%s: retrieved framesize=%ld from above top",
		       __func__, (long)framesize);
#endif
    }
    if (framesize <= 0)
      ik_abort("invalid caller function framesize %ld\n", framesize);
    if (framesize < p_next_k->size) {
      /* Insert a  new continuation "p_new_cont" between  "p_next_k" and
       * its next;  notice that  below we will  pop "s_kont"  from the
       * list in the PCB, so  "p_new_cont" will become the first, before
       * reentering assembly code.  Before:
       *
       *    s_kont
       *       |        s_further
       *       |--------->|
       *          next    |-------> NULL
       *                    next
       *
       * after:
       *
       *    s_kont
       *       |       s_new_kont
       *       |--------->|       s_further
       *          next    |-------->|
       *                    next    |--------> NULL
       *                               next
       */
      ikcont *	p_new_kont = (ikcont*)(long)ik_unsafe_alloc(pcb, sizeof(ikcont));
      p_new_kont->tag  = p_next_k->tag;
      p_new_kont->next = p_next_k->next;
      p_new_kont->top  = top + framesize;
      p_new_kont->size = p_next_k->size - framesize;
      p_next_k->size   = framesize;
      p_next_k->next   = (ikptr)(long)p_new_kont | vector_tag;
      { /* Record in  the dirty vector  the side effect of  mutating the
	   field "p_next_k->next". */
	ik_ulong idx = ((ik_ulong)(&p_next_k->next)) >> IK_PAGESHIFT;
	((int*)(long)(pcb->dirty_vector))[idx] = -1;
      }
    } else if (framesize > p_next_k->size) {
      /* long	rp_offset	= IK_UNFIX(IK_REF(rp, disp_frame_offset)); */
      /* long	code_offset	= rp_offset - disp_frame_offset; */
      /* ikptr	code_entry	= rp - code_offset; */
      /* ikptr	p_code		= code_entry - disp_code_data; */
      ik_abort("while resuming continuation 0x%016lx:\n\tinvalid framesize %ld, expected %ld or less\n\trp = 0x%016lx\n\trp offset = %ld",
	       (long)s_kont, framesize, p_next_k->size,
	       rp, IK_REF(rp, disp_frame_offset));
    }
    /* Pop "s_kont" from  the list in the PCB  structure.  Notice that
       if "s_kont" represents a  continuation saved with CALL/CC: such
       continuation object is still  referenced somewhere by the closure
       object implementing the continuation function. */
    pcb->next_k = p_next_k->next;
#if DEBUG_EXEC
    ik_debug_message("%s: reenter, argc %lu", __func__, IK_UNFIX(-s_retval_count));
#endif
    { /* Move the local  variables from the old frame to  the new frame.
       * Notice that S_RETVAL_COUNT is negative for a reason!
       *
       *      high memory
       *  |                   | <-- pcb->frame_base
       *  |-------------------|                          --
       *  |                   | <-- fbase                .
       *  |-------------------|                --        .
       *  | local value 0 src |                .         .
       *  |-------------------|                .         .
       *  | local value 1 src |                .         . framesize
       *  |-------------------|                . -s_retval_count .
       *  | local value 2 src | <-- arg_src    .         .
       *  |-------------------|                --        --
       *  |                   | <-- new_fbase
       *  |-------------------|                --
       *  | local value 0 dst |                .
       *  |-------------------|                .
       *  | local value 1 dst |                .
       *  |-------------------|                . -s_retval_count
       *  | local value 2 dst | <-- arg_dst    .
       *  |-------------------|                --
       *  |                   |
       *       low memory
       */
      ikptr	fbase     = pcb->frame_base - wordsize;
      ikptr	new_fbase = fbase - framesize;
      char *	arg_dst   = ((char*)(long)new_fbase) + s_retval_count;
      char *	arg_src   = ((char*)(long)fbase)     + s_retval_count;
      memmove(arg_dst, arg_src, -s_retval_count);
      /* Copy the frame.
       *
       *      high memory
       *  |                   | <-- pcb->frame_base
       *  |-------------------|                --
       *  | frame value 0 dst |                .
       *  |-------------------|                .
       *  | frame value 1 dst |                .
       *  |-------------------|                . framesize
       *  | frame value 2 dst |                .
       *  |-------------------|                .
       *  |   return address  | <-- new_fbase  .
       *  |-------------------|                --
       *  | local value 0 dst |                .
       *  |-------------------|                .
       *  | local value 1 dst |                .
       *  |-------------------|                . -s_retval_count
       *  | local value 2 dst |                .
       *  |-------------------|                --
       *           ...
       *  |-------------------|                --
       *  | frame value 0 src |                .
       *  |-------------------|                .
       *  | frame value 1 src |                .
       *  |-------------------|                . framesize
       *  | frame value 2 src |                .
       *  |-------------------|                .
       *  |   return address  | <-- top        .
       *  |-------------------|                --
       *  |                   |
       *       low memory
       */
      memcpy((char*)(long)new_fbase, (char*)(long)top, framesize);
      s_retval_count = ik_asm_reenter(pcb, new_fbase, s_retval_count);
    }
    s_kont =  pcb->next_k;
  }  /* end of while() */

  /* Retrieve  the return  value from  the stack  and return  it to  the
   * caller.
   *
   *      high memory
   *   |              |
   *   |--------------|
   *   |              | <-- pcb->frame_base
   *   |--------------|                                     --
   *   |              | <-- pcb->frame_base - wordsize      .
   *   |--------------|                                     .
   *   | return value | <-- pcb->frame_base - 2 * wordsize  . Scheme
   *   |--------------|                                     . stack
   *   |              |                                     .
   *   |              |                                     .
   *   |--------------| <-- pcb->stack_base                 --
   *   |              |
   *      low memory
   */
  ikptr rv = IK_REF(pcb->frame_base, -2*wordsize);
  return rv;
}

/* end of file */
