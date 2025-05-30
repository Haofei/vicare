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
#include <gmp.h>

#if (IK_WORDSIZE == 4)
#  define BIGNUM_LIMB_SHIFT	5
#else
#  define BIGNUM_LIMB_SHIFT	6
#endif


/** --------------------------------------------------------------------
 ** Debugging helpers.
 ** ----------------------------------------------------------------- */

#if 0
#define DEBUG_VERIFY_BIGNUM(x,caller)		(x)
#else
static ikptr_t
DEBUG_VERIFY_BIGNUM (ikptr_t x, const char * caller)
/* Validate the bignum X, which must be a tagged reference. */
{
  ikptr_t	first_word;
  iksword_t	limb_count;
  int		is_positive;
  mp_limb_t	last_limb;
  if (IK_TAGOF(x) != vector_tag)
    ik_abort("error in (%s) invalid primary tag 0x%016lx", caller, x);
  first_word = IK_REF(x, off_bignum_tag);
  limb_count = IK_BNFST_LIMB_COUNT(first_word);
  if (limb_count <= 0)
    ik_abort("error in (%s) invalid limb count in first_word=0x%016lx", caller, (iksword_t)first_word);
  is_positive = IK_BNFST_NEGATIVE(first_word)? 0 : 1;
  last_limb   = IK_BIGNUM_LAST_LIMB(x, limb_count);
  if (last_limb == 0)
    ik_abort("error in (%s) invalid last limb = 0x%016lx", caller, last_limb);
  if (limb_count == 1) {
    if (is_positive) {
      if (last_limb <= most_positive_fixnum) {
	ik_abort("error in (%s) should be a positive fixnum: 0x%016lx", caller, last_limb);
      }
    } else {
      if (last_limb <= most_negative_fixnum) {
	ik_abort("in '%s' should be a negative fixnum: 0x%016lx", caller, last_limb);
      }
    }
  }
  /* ok */
  return x;
}
#endif


/** --------------------------------------------------------------------
 ** Inspection.
 ** ----------------------------------------------------------------- */

int
ik_is_bignum (ikptr_t x)
{
  return ((vector_tag == IK_TAGOF(x)) &&
	  (bignum_tag == (bignum_mask & (int)IK_REF(x, -vector_tag))));
}
ikptr_t
ikrt_positive_bn (ikptr_t x)
{
  ikptr_t first_word = IK_REF(x, -vector_tag);
  return (IK_BNFST_NEGATIVE(first_word))? IK_FALSE_OBJECT : IK_TRUE_OBJECT;
}
ikptr_t
ikrt_even_bn (ikptr_t x)
{
  mp_limb_t first_limb = IK_BIGNUM_FIRST_LIMB(x);
  return (first_limb & 1)? IK_FALSE_OBJECT : IK_TRUE_OBJECT;
}


/** --------------------------------------------------------------------
 ** Arithmetics: addition.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_fxfxplus (ikptr_t x, ikptr_t y, ikpcb_t* pcb)
{
  iksword_t	n1 = IK_UNFIX(x);
  iksword_t	n2 = IK_UNFIX(y);
  iksword_t	R  = n1 + n2;
  ikptr_t	Q  = IK_FIX(R);
  if (R == IK_UNFIX(Q)) {
    return Q;
  } else {
    ikptr_t s_bn = IKA_BIGNUM_ALLOC(pcb, 1);
    if (R > 0) {
      IK_REF(s_bn, off_bignum_tag)  = IK_POSITIVE_BIGNUM_FIRST_WORD(1);
      IK_REF(s_bn, off_bignum_data) = (ikptr_t)+R;
    } else {
      IK_REF(s_bn, off_bignum_tag)  = IK_NEGATIVE_BIGNUM_FIRST_WORD(1);
      IK_REF(s_bn, off_bignum_data) = (ikptr_t)-R;
    }
    return DEBUG_VERIFY_BIGNUM(s_bn, "fxfx+");
  }
}
ikptr_t
ikrt_fxbnplus (ikptr_t x, ikptr_t y, ikpcb_t* pcb)
{
  /* If X is the fixnum zero: just return Y. */
  if (x == 0) {
    return y ;
  }
  ikptr_t	first_word	= IK_REF(y, -vector_tag);
  iksword_t	limb_count	= IK_BNFST_LIMB_COUNT(first_word);
  iksword_t	intx		= IK_UNFIX(x);
  if (intx > 0) {
    if (IK_BNFST_POSITIVE(first_word)) {
      /* positive fx + positive bn = even bigger positive */
      ikptr_t	r;
      mp_limb_t	carry;
      pcb->root0 = &y;
      {
	/* We may allocate one limb more than needed here if CARRY below
	   results  zero.  We  accept  it because  we  must perform  the
	   operation before knowing if the CARRY is non-zero. */
	r = IKA_BIGNUM_ALLOC(pcb, limb_count + 1);
      }
      pcb->root0 = 0;
      carry = mpn_add_1(IK_BIGNUM_DATA_LIMBP(r), IK_BIGNUM_DATA_LIMBP(y), limb_count, intx);
      if (carry) {
	IK_LIMB(r, limb_count) = (ikptr_t)1;
	IK_BIGNUM_FIRST(r)            = IK_POSITIVE_BIGNUM_FIRST_WORD(limb_count + 1);
	return DEBUG_VERIFY_BIGNUM(r, "fxbn+1");
      } else {
	IK_BIGNUM_FIRST(r) = IK_POSITIVE_BIGNUM_FIRST_WORD(limb_count);
	return DEBUG_VERIFY_BIGNUM(r, "fxbn+2");
      }
    } else {
      /* positive fx + negative bn = smaller negative bn */
      ikptr_t	r;
      mp_limb_t borrow;
      iksword_t	result_size;
      pcb->root0 = &y;
      {
	r = IKA_BIGNUM_ALLOC(pcb, limb_count);
      }
      pcb->root0 = 0;
      borrow = mpn_sub_1(IK_BIGNUM_DATA_LIMBP(r), IK_BIGNUM_DATA_LIMBP(y), limb_count, intx);
      if (borrow)
	ik_abort("BUG in borrow1 %ld", borrow);
      result_size = IK_BIGNUM_LAST_LIMB(r, limb_count)? limb_count : (limb_count - 1);
      if (0 == result_size) {
	return 0; /* the fixnum zero */
      } else {
	if (1 == result_size) {
	  mp_limb_t last = IK_BIGNUM_LAST_LIMB(r, result_size);
	  if (last <= most_negative_fixnum)
	    return IK_FIX(-(iksword_t)last);
	}
	IK_BIGNUM_FIRST(r) = IK_NEGATIVE_BIGNUM_FIRST_WORD(result_size);
	return DEBUG_VERIFY_BIGNUM(r, "fxbn+3");
      }
    }
  } else {
    if (IK_BNFST_POSITIVE(first_word)) {
      /* negative fx + positive bn = smaller positive fx or bn */
      ikptr_t	r;
      mp_limb_t borrow;
      iksword_t	result_size;
      pcb->root0 = &y;
      {
	r = IKA_BIGNUM_ALLOC(pcb, limb_count);
      }
      pcb->root0 = 0;
      borrow = mpn_sub_1(IK_BIGNUM_DATA_LIMBP(r), IK_BIGNUM_DATA_LIMBP(y), limb_count, -intx);
      if (borrow)
	ik_abort("BUG in borrow2\n");
      result_size = (0 == IK_BIGNUM_LAST_LIMB(r, limb_count))? (limb_count - 1) : limb_count;
      if (result_size == 0) {
	return 0;
      } else {
	if (1 == result_size) {
	  mp_limb_t last = IK_BIGNUM_LAST_LIMB(r, result_size);
	  if (last <= most_positive_fixnum)
	    return IK_FIX(last);
	}
	IK_BIGNUM_FIRST(r) = IK_POSITIVE_BIGNUM_FIRST_WORD(result_size);
	return DEBUG_VERIFY_BIGNUM(r, "fxbn+4");
      }
    } else {
      /* negative fx + negative bn = larger negative bn */
      ikptr_t	r;
      mp_limb_t carry;
      pcb->root0 = &y;
      {
	r = IKA_BIGNUM_ALLOC(pcb, 1 + limb_count);
      }
      pcb->root0 = 0;
      carry = mpn_add_1(IK_BIGNUM_DATA_LIMBP(r), IK_BIGNUM_DATA_LIMBP(y), limb_count, -intx);
      if (carry) {
	IK_LIMB(r, limb_count) = (ikptr_t)1;
	IK_BIGNUM_FIRST(r) = IK_NEGATIVE_BIGNUM_FIRST_WORD(limb_count + 1);
	return DEBUG_VERIFY_BIGNUM(r, "fxbn+5");
      } else {
	IK_BIGNUM_FIRST(r) = IK_NEGATIVE_BIGNUM_FIRST_WORD(limb_count);
	return DEBUG_VERIFY_BIGNUM(r, "fxbn+6");
      }
    }
  }
}
ikptr_t
ikrt_bnbnplus (ikptr_t x, ikptr_t y, ikpcb_t* pcb)
/* Depending on the sign of the operands we do a different operation:

   X>0 Y>0 => RES = X + Y
   X<0 Y<0 => RES = -(|X| + |Y|)
   X>0 Y<0 => RES = X - |Y|
   X<0 Y>0 => RES = Y - |X|

*/
{
  ikuword_t	xfst   = (ikuword_t)IK_BIGNUM_FIRST(x);
  ikuword_t	yfst   = (ikuword_t)IK_BIGNUM_FIRST(y);
  iksword_t		xsign  = xfst & bignum_sign_mask;
  iksword_t		ysign  = yfst & bignum_sign_mask;
  iksword_t		xlimbs = xfst >> bignum_nlimbs_shift;
  iksword_t		ylimbs = yfst >> bignum_nlimbs_shift;
  if (xsign == ysign) { /* bignums of equal sign */
    ikptr_t	res;	/* return value */
    ikptr_t	bn1;	/* bignum with greater number of limbs */
    ikptr_t	bn2;	/* bignum with lesser number of limbs */
    iksword_t	nlimb1;	/* number of limbs in BN1 */
    iksword_t	nlimb2;	/* number of limbs in BN2 */
    mp_limb_t	carry;
    if (xlimbs > ylimbs) {
      nlimb1 = xlimbs;
      nlimb2 = ylimbs;
      bn1 = x;
      bn2 = y;
    } else {
      nlimb1 = ylimbs;
      nlimb2 = xlimbs;
      bn1 = y;
      bn2 = x;
    }
    pcb->root0 = &bn1;
    pcb->root1 = &bn2;
    {
      res = IKA_BIGNUM_ALLOC(pcb, 1 + nlimb1);
    }
    pcb->root1 = NULL;
    pcb->root0 = NULL;
    carry = mpn_add(IK_BIGNUM_DATA_LIMBP(res),
		    IK_BIGNUM_DATA_LIMBP(bn1), nlimb1,
		    IK_BIGNUM_DATA_LIMBP(bn2), nlimb2);
    if (carry) {
      IK_LIMB(res, xlimbs) = (ikptr_t)1;
      IK_BIGNUM_FIRST(res) = IK_COMPOSE_BIGNUM_FIRST_WORD(1 + nlimb1, xsign);
      return DEBUG_VERIFY_BIGNUM(res, "bnbn+1");
    } else {
      IK_BIGNUM_FIRST(res) = IK_COMPOSE_BIGNUM_FIRST_WORD(nlimb1, xsign);
      return DEBUG_VERIFY_BIGNUM(res, "bnbn+2");
    }
  } else { /* bignums of different sign */
    ikptr_t	res;				/* the return value */
    ikptr_t	bn1		= x;
    ikptr_t	bn2		= y;
    iksword_t	nlimb1		= xlimbs;
    iksword_t	nlimb2		= ylimbs;
    iksword_t	len;
    iksword_t	result_sign	= xsign;
    mp_limb_t	burrow;
    /* If the limbs are equal ther result is zero. */
    while ((xlimbs == ylimbs) && (IK_LIMB(x, xlimbs - 1) == IK_LIMB(y, xlimbs - 1))) {
      xlimbs -= 1;
      ylimbs -= 1;
      if (0 == xlimbs)
	return 0; /* the fixnum zero */
    }
    /* |x| != |y| */
    if (xlimbs <= ylimbs) {
      if (xlimbs == ylimbs) {
	if (IK_LIMB(y, xlimbs - 1) > IK_LIMB(x, xlimbs - 1)) {
	  bn1		= y;
	  nlimb1	= ylimbs;
	  bn2		= x;
	  nlimb2	= xlimbs;
	  result_sign	= ysign;
	}
      } else {
	bn1		= y;
	nlimb1		= ylimbs;
	bn2		= x;
	nlimb2		= xlimbs;
	result_sign	= ysign;
      }
    }
    /* |bn1| > |bn2| */
    pcb->root0 = &bn1;
    pcb->root1 = &bn2;
    {
      res = IKA_BIGNUM_ALLOC(pcb, nlimb1);
    }
    pcb->root0 = 0;
    pcb->root1 = 0;
    burrow = mpn_sub(IK_BIGNUM_DATA_LIMBP(res),
		     IK_BIGNUM_DATA_LIMBP(bn1), nlimb1,
		     IK_BIGNUM_DATA_LIMBP(bn2), nlimb2);
    if (burrow)
      ik_abort("bug: burrow error in bnbn+");
    for (len = nlimb1; 0 == IK_LIMB(res, len - 1);) {
      --len;
      if (0 == len)
	return 0; /* the fixnum zero */
    }
    if (0 == result_sign) {
      /* positive result */
      if (1 == len) {
	mp_limb_t first_limb = IK_BIGNUM_FIRST_LIMB(res);
	if (first_limb <= most_positive_fixnum) {
	  return IK_FIX((iksword_t)first_limb);
	}
      }
      IK_BIGNUM_FIRST(res) = IK_COMPOSE_BIGNUM_FIRST_WORD(len, result_sign);
      return DEBUG_VERIFY_BIGNUM(res, "bnbn+3");
    } else {
      /* negative result */
      if (len == 1) {
	mp_limb_t first_limb = IK_BIGNUM_FIRST_LIMB(res);
	if (first_limb <= most_negative_fixnum)
	  return IK_FIX(-(iksword_t)first_limb);
      }
      IK_BIGNUM_FIRST(res) = IK_COMPOSE_BIGNUM_FIRST_WORD(len, result_sign);
      return DEBUG_VERIFY_BIGNUM(res, "bnbn+4");
    }
  }
}


/** --------------------------------------------------------------------
 ** Arithmetics: subtraction.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_fxfxminus (ikptr_t x, ikptr_t y, ikpcb_t* pcb)
{
  iksword_t n1 = IK_UNFIX(x);
  iksword_t n2 = IK_UNFIX(y);
  iksword_t r = n1 - n2;
  if (r >= 0) {
    if (((ikuword_t)r) <= most_positive_fixnum) {
      return IK_FIX(r);
    } else {
      ikptr_t bn = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + wordsize));
      IK_REF(bn, 0) = (ikptr_t) (bignum_tag | (1 << bignum_nlimbs_shift));
      IK_REF(bn, disp_bignum_data) = (ikptr_t)r;
      return DEBUG_VERIFY_BIGNUM(bn+vector_tag,"fxfx-1");
    }
  } else {
    ikptr_t fxr = IK_FIX(r);
    if (IK_UNFIX(fxr) == r) {
      return fxr;
    } else {
      ikptr_t bn = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + wordsize));
      IK_REF(bn, 0) = (ikptr_t)
	(bignum_tag |
	 (1 << bignum_sign_shift) |
	 (1 << bignum_nlimbs_shift));
      IK_REF(bn, disp_bignum_data) = (ikptr_t)(-r);
      return DEBUG_VERIFY_BIGNUM(bn+vector_tag, "fxfx-2");
    }
  }
}
ikptr_t
ikrt_fxbnminus (ikptr_t x, ikptr_t y, ikpcb_t* pcb)
{
  /* If the fixnum X is zero: just return Y negated. */
  if (0 == x) {
    return ikrt_bnnegate(y, pcb);
  }
  ikptr_t	first_word	= IK_REF(y, -vector_tag);
  iksword_t	limb_count	= IK_BNFST_LIMB_COUNT(first_word);
  iksword_t	intx		= IK_UNFIX(x);
  if (intx > 0) {
    if (IK_BNFST_NEGATIVE(first_word)) {
      ikptr_t	r;
      iksword_t	carry;
      /* positive fx - negative bn = positive bn */
      pcb->root0 = &y;
      {
	r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+(limb_count+1)*wordsize));
      }
      pcb->root0 = 0;
      carry = mpn_add_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
			(mp_limb_t*)(ikuword_t)(y - vector_tag + disp_bignum_data),
			limb_count, intx);
      if (carry) {
	IK_REF(r, disp_bignum_data + limb_count*wordsize) = (ikptr_t)1;
	IK_REF(r, 0) = IK_POSITIVE_BIGNUM_FIRST_WORD((limb_count + 1));
	return DEBUG_VERIFY_BIGNUM(r|vector_tag, "fxbn-1");
      } else {
	IK_REF(r, 0) = IK_POSITIVE_BIGNUM_FIRST_WORD(limb_count);
	return DEBUG_VERIFY_BIGNUM(r|vector_tag, "fxbn-2");
      }
    } else {
      ikptr_t	r;
      iksword_t	borrow;
      iksword_t	result_size;
      /* positive fx - positive bn = smaller negative bn/fx */
      pcb->root0 = &y;
      {
	r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+limb_count*wordsize));
      }
      pcb->root0 = 0;
      borrow = mpn_sub_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
			 (mp_limb_t*)(ikuword_t)(y - vector_tag + disp_bignum_data),
			 limb_count, intx);
      if (borrow)
	ik_abort("BUG in borrow3\n");
      result_size = (IK_REF(r, disp_bignum_data + (limb_count-1)*wordsize))?
	limb_count : (limb_count - 1);
      if (result_size == 0) {
	return 0; /* the fixnum zero */
      } else {
	if (1 == result_size) {
	  ikuword_t	last = (ikuword_t) IK_REF(r, disp_bignum_data + (result_size-1)*wordsize);
	  if (last <= most_negative_fixnum)
	    return IK_FIX(-((iksword_t)last));
	}
	IK_REF(r, 0) = (ikptr_t) ((result_size << bignum_nlimbs_shift)
				| (1 << bignum_sign_shift)
				| bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxbn-");
      }
    }
  } else {
    if (IK_BNFST_NEGATIVE(first_word)) {
      /* negative fx - negative bn = smaller positive */
      pcb->root0 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+limb_count*wordsize));
      pcb->root0 = 0;
      iksword_t borrow =
	mpn_sub_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
		  (mp_limb_t*)(ikuword_t)(y - vector_tag + disp_bignum_data),
		  limb_count,
		  - intx);
      if (borrow)
	ik_abort("BUG in borrow4");
      iksword_t result_size =
	(IK_REF(r, disp_bignum_data + (limb_count-1)*wordsize) == 0)
	? (limb_count - 1)
	: limb_count;
      if (result_size == 0) {
	return 0;
      }
      if (1 == result_size) {
	iksword_t	last = (iksword_t) IK_REF(r, disp_bignum_data + (result_size-1)*wordsize);
	if (last <= most_positive_fixnum) {
	  return IK_FIX(last);
	}
      }
      IK_REF(r, 0) = (ikptr_t)
	((result_size << bignum_nlimbs_shift) |
	 (0 << bignum_sign_shift) |
	 bignum_tag);
      return DEBUG_VERIFY_BIGNUM(r+vector_tag,"fxbn-");
    } else {
      /* negative fx - positive bn = larger negative */
      pcb->root0 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+(limb_count+1)*wordsize));
      pcb->root0 = 0;
      iksword_t carry =
	mpn_add_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
		  (mp_limb_t*)(ikuword_t)(y - vector_tag + disp_bignum_data),
		  limb_count,
		  -intx);
      if (carry) {
	IK_REF(r, disp_bignum_data + limb_count*wordsize) = (ikptr_t)1;
	IK_REF(r, 0) = (ikptr_t)
	  (((limb_count + 1) << bignum_nlimbs_shift) |
	   (1 << bignum_sign_shift) |
	   bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxbn-");
      } else {
	IK_REF(r, 0) = (ikptr_t)
	  ((limb_count << bignum_nlimbs_shift) |
	   (1 << bignum_sign_shift) |
	   bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxbn-");
      }
    }
  }
}
ikptr_t
ikrt_bnfxminus (ikptr_t x, ikptr_t y, ikpcb_t* pcb)
{
  if (y == 0) { return x; }
  ikptr_t first_word = IK_REF(x, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  iksword_t inty = IK_UNFIX(y);
  if (inty < 0) {
    if (!IK_BNFST_NEGATIVE(first_word)) {
      /* - negative fx + positive bn = positive bn */
      pcb->root0 = &x;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+(limb_count+1)*wordsize));
      pcb->root0 = 0;
      iksword_t carry =
	mpn_add_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
		  (mp_limb_t*)(ikuword_t)(x - vector_tag + disp_bignum_data),
		  limb_count,
		  -inty);
      if (carry) {
	IK_REF(r, disp_bignum_data + limb_count*wordsize) = (ikptr_t)1;
	IK_REF(r, 0) = (ikptr_t)
	     (((limb_count + 1) << bignum_nlimbs_shift) |
	      (0 << bignum_sign_shift) |
	      bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag,"bnfx-");
      } else {
	IK_REF(r, 0) = (ikptr_t)
	  ((limb_count << bignum_nlimbs_shift) |
	   (0 << bignum_sign_shift) |
	   bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag,"bnfx-");
      }
    }
    else {
      /* - negative fx + negative bn = smaller negative bn/fx */
      pcb->root0 = &x;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+limb_count*wordsize));
      pcb->root0 = 0;
      iksword_t borrow =
	mpn_sub_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
		  (mp_limb_t*)(ikuword_t)(x - vector_tag + disp_bignum_data),
		  limb_count,
		  -inty);
      if (borrow)
	ik_abort("BUG in borrow5\n");
      iksword_t result_size =
	(IK_REF(r, disp_bignum_data + (limb_count-1)*wordsize))
	? limb_count
	: (limb_count - 1);
      if (result_size == 0) {
	return 0;
      }
      if (1 == result_size) {
	ikuword_t	last = (ikuword_t) IK_REF(r, disp_bignum_data + (result_size-1)*wordsize);
	if (last <= most_negative_fixnum) {
	  return IK_FIX(-((iksword_t)last));
	}
      }
      IK_REF(r, 0) = (ikptr_t)
	((result_size << bignum_nlimbs_shift) |
	 (1 << bignum_sign_shift) |
	 bignum_tag);
      return DEBUG_VERIFY_BIGNUM(r+vector_tag,"bnfx-");
    }
  }
  else {
    if ((bignum_sign_mask & (iksword_t)first_word) == 0) {
      /* - positive fx + positive bn = smaller positive */
      pcb->root0 = &x;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+limb_count*wordsize));
      pcb->root0 = 0;
      iksword_t borrow =
	mpn_sub_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
		  (mp_limb_t*)(ikuword_t)(x - vector_tag + disp_bignum_data),
		  limb_count,
		  inty);
      if (borrow)
	ik_abort("BUG in borrow6\n");
      iksword_t result_size =
	(IK_REF(r, disp_bignum_data + (limb_count-1)*wordsize) == 0)
	? (limb_count - 1)
	: limb_count;
      if (result_size == 0) {
	return 0;
      }
      if (1 == result_size) {
	iksword_t	last = (iksword_t) IK_REF(r, disp_bignum_data + (result_size-1)*wordsize);
	if (last <= most_positive_fixnum) {
	  return IK_FIX(last);
	}
      }
      IK_REF(r, 0) = (ikptr_t)
	((result_size << bignum_nlimbs_shift) |
	 (0 << bignum_sign_shift) |
	 bignum_tag);
      return DEBUG_VERIFY_BIGNUM(r+vector_tag, "bnfx-");
    } else {
      /* - positive fx + negative bn = larger negative */
      pcb->root0 = &x;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+(limb_count+1)*wordsize));
      pcb->root0 = 0;
      iksword_t carry =
	mpn_add_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
		  (mp_limb_t*)(ikuword_t)(x - vector_tag + disp_bignum_data),
		  limb_count,
		  inty);
      if (carry) {
	IK_REF(r, disp_bignum_data + limb_count*wordsize) = (ikptr_t)1;
	IK_REF(r, 0) = (ikptr_t)
	     (((limb_count + 1) << bignum_nlimbs_shift) |
	      (1 << bignum_sign_shift) |
	      bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag, "bnfx-");
      } else {
	IK_REF(r, 0) = (ikptr_t)
	  ((limb_count << bignum_nlimbs_shift) |
	   (1 << bignum_sign_shift) |
	   bignum_tag);
	return DEBUG_VERIFY_BIGNUM(r+vector_tag, "bnfx-");
      }
    }
  }
}
ikptr_t
ikrt_bnbnminus(ikptr_t x, ikptr_t y, ikpcb_t* pcb)
{
  if (x == y) { return 0; }
  ikuword_t xfst = (ikuword_t)IK_REF(x, -vector_tag);
  ikuword_t yfst = (ikuword_t)IK_REF(y, -vector_tag);
  iksword_t xsign = xfst & bignum_sign_mask;
  iksword_t ysign = yfst & bignum_sign_mask;
  iksword_t xlimbs = xfst >> bignum_nlimbs_shift;
  iksword_t ylimbs = yfst >> bignum_nlimbs_shift;
  if (xsign != ysign) {
    iksword_t n1,n2;
    ikptr_t s1,s2;
    if (xlimbs >= ylimbs) {
      n1 = xlimbs; n2 = ylimbs; s1 = x; s2 = y;
    } else {
      n1 = ylimbs; n2 = xlimbs; s1 = y; s2 = x;
    }
    pcb->root0 = &s1;
    pcb->root1 = &s2;
    ikptr_t res = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + (n1+1)*wordsize));
    pcb->root0 = 0;
    pcb->root1 = 0;
    mp_limb_t carry =
      mpn_add((mp_limb_t*)(ikuword_t)(res+disp_bignum_data),
	      (mp_limb_t*)(ikuword_t)(s1-vector_tag+disp_bignum_data),
	      n1,
	      (mp_limb_t*)(ikuword_t)(s2-vector_tag+disp_bignum_data),
	      n2);
    if (carry) {
      IK_REF(res, disp_vector_data + xlimbs*wordsize) = (ikptr_t)1;
      IK_REF(res, 0) = (ikptr_t)
		    (((n1+1) << bignum_nlimbs_shift) |
		     xsign |
		     bignum_tag);
      return DEBUG_VERIFY_BIGNUM(res+vector_tag, "bnbn-");
    } else {
      IK_REF(res, 0) = (ikptr_t)
		    ((n1 << bignum_nlimbs_shift) |
		     xsign |
		     bignum_tag);
      return DEBUG_VERIFY_BIGNUM(res+vector_tag, "bnbn-");
    }
  }
  else {
    /* same sign */
    if (xlimbs == ylimbs) {
      while (IK_REF(x, -vector_tag+disp_bignum_data+(xlimbs-1)*wordsize) ==
	     IK_REF(y, -vector_tag+disp_bignum_data+(xlimbs-1)*wordsize)) {
	xlimbs -= 1;
	if (xlimbs == 0) { return 0; }
      }
      ylimbs = xlimbs;
    }
    ikptr_t s1=x, s2=y;
    iksword_t n1=xlimbs, n2=ylimbs;
    iksword_t result_sign = xsign;
    /* |x| != |y| */
    if (xlimbs <= ylimbs) {
      if (xlimbs == ylimbs) {
	if ((IK_REF(y, -vector_tag+disp_bignum_data+(xlimbs-1)*wordsize) >
	    IK_REF(x, -vector_tag+disp_bignum_data+(xlimbs-1)*wordsize))) {
	  s1 = y; n1 = ylimbs;
	  s2 = x; n2 = xlimbs;
	  result_sign = (1 << bignum_sign_shift) - ysign;
	}
      } else {
	s1 = y; n1 = ylimbs;
	s2 = x; n2 = xlimbs;
	result_sign = (1 << bignum_sign_shift) - ysign;
      }
    }
    /* |s1| > |s2| */
    pcb->root0 = &s1;
    pcb->root1 = &s2;
    ikptr_t res = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + n1 * wordsize));
    bzero((void*)(res+disp_bignum_data), n1*wordsize);
    pcb->root0 = 0;
    pcb->root1 = 0;
    iksword_t burrow =
      mpn_sub((mp_limb_t*)(ikuword_t)(res + disp_bignum_data),
	      (mp_limb_t*)(ikuword_t)(s1 - vector_tag + disp_bignum_data),
	      n1,
	      (mp_limb_t*)(ikuword_t)(s2 - vector_tag + disp_bignum_data),
	      n2);
    if (burrow)
      ik_abort("BUG: burrow error in bnbn-");
    iksword_t len = n1;
    while(IK_REF(res, disp_bignum_data + (len-1)*wordsize) == 0) {
      len--;
      if (len == 0) {
	return 0;
      }
    }
    if (result_sign == 0) {
      /* positive result */
      if (len == 1) {
	iksword_t	fst_limb = (iksword_t) IK_REF(res, disp_bignum_data);
	if (fst_limb <= most_positive_fixnum) {
	  return IK_FIX(fst_limb);
	}
      }
      IK_REF(res, 0) = (ikptr_t)
		    ((len << bignum_nlimbs_shift) |
		     result_sign |
		     bignum_tag);
      return DEBUG_VERIFY_BIGNUM(res+vector_tag, "bnbn-");
    } else {
      /* negative result */
      if (len == 1) {
	ikuword_t fst_limb = (ikuword_t) IK_REF(res, disp_bignum_data);
	if (fst_limb <= most_negative_fixnum) {
	  return IK_FIX(-((iksword_t)fst_limb));
	}
      }
      IK_REF(res, 0) = (ikptr_t)
		    ((len << bignum_nlimbs_shift) |
		     result_sign |
		     bignum_tag);
      return DEBUG_VERIFY_BIGNUM(res+vector_tag, "bnbn-");
    }
  }
}

ikptr_t
ikrt_bnnegate (ikptr_t x, ikpcb_t* pcb)
{
  ikptr_t first_word = IK_REF(x, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  if (limb_count == 1) {
    if (! IK_BNFST_NEGATIVE(first_word)) {
      /* positive bignum */
      mp_limb_t limb =
	(mp_limb_t) IK_REF(x, disp_bignum_data - vector_tag);
      if (limb == (most_positive_fixnum + 1)) {
	return IK_FIX(-(iksword_t)limb);
      }
    }
  }
  pcb->root0 = &x;
  ikptr_t bn = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + limb_count * wordsize));
  pcb->root0 = 0;
  memcpy((uint8_t*)(ikuword_t)bn+disp_bignum_data,
	 (uint8_t*)(ikuword_t)x-vector_tag+disp_bignum_data,
	 limb_count*wordsize);
  IK_REF(bn, 0) = (ikptr_t)
    (bignum_tag |
     ((1 << bignum_sign_shift) - (bignum_sign_mask & (iksword_t)first_word)) |
     (limb_count << bignum_nlimbs_shift));
  return DEBUG_VERIFY_BIGNUM(bn+vector_tag, "bnneg");
}



ikptr_t
ikrt_fxfxmult(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t n1 = IK_UNFIX(x);
  iksword_t n2 = IK_UNFIX(y);
  mp_limb_t lo = 0;
  mp_limb_t s1 = n1;
  mp_limb_t s2 = n2;
  iksword_t sign = 0;
  if (n1 < 0) {
    s1 = -n1;
    sign = 1 - sign;
  }
  if (n2 < 0) {
    s2 = -n2;
    sign = 1 - sign;
  }
  mp_limb_t hi = mpn_mul_1(&lo, &s1, 1, s2);
  if (hi == 0) {
    if (sign) {
      if (lo <= most_negative_fixnum) {
	return IK_FIX(-((iksword_t)lo));
      }
    } else {
      if (lo <= most_positive_fixnum) {
	return IK_FIX((iksword_t)lo);
      }
    }
    ikptr_t r = ik_safe_alloc(pcb, disp_bignum_data + wordsize);
    IK_REF(r, 0) = (ikptr_t)
      (bignum_tag |
       (sign << bignum_sign_shift) |
       (1 << bignum_nlimbs_shift));
    IK_REF(r, disp_bignum_data) = (ikptr_t)lo;
    return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxfxmult");
  } else {
    ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + 2*wordsize));
    IK_REF(r, 0) = (ikptr_t)
      (bignum_tag |
       (sign << bignum_sign_shift) |
       (2 << bignum_nlimbs_shift));
    IK_REF(r, disp_bignum_data) = (ikptr_t)lo;
    IK_REF(r, disp_bignum_data+wordsize) = (ikptr_t)hi;
    return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxfxmult");
  }
}

ikptr_t
ik_normalize_bignum (iksword_t limbs, int sign, ikptr_t r) {
  while(IK_REF(r, disp_bignum_data + (limbs-1)*wordsize) == 0) {
    limbs--;
    if (limbs == 0) { return 0;}
  }
  if (limbs == 1) {
    mp_limb_t last = (mp_limb_t) IK_REF(r, disp_bignum_data);
    if (sign == 0) {
      if (last <= most_positive_fixnum) {
	return IK_FIX(last);
      }
    } else {
      if (last <= most_negative_fixnum) {
	return IK_FIX(-(last));
      }
    }
  }
  IK_REF(r, 0) = (ikptr_t) (bignum_tag | sign | (limbs << bignum_nlimbs_shift));
  return DEBUG_VERIFY_BIGNUM(r+vector_tag, __func__);
}


ikptr_t
ikrt_fxbnmult(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t n2 = IK_UNFIX(x);
  if (n2 == 0) { return 0; }
  mp_limb_t s2 = (n2>0) ? n2 : (- n2);
  ikptr_t first_word = IK_REF(y, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  pcb->root0 = &y;
  ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + (limb_count+1)*wordsize));
  pcb->root0 = 0;
  mp_limb_t hi = mpn_mul_1((mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
			   (mp_limb_t*)(ikuword_t)(y-vector_tag+disp_bignum_data),
			   limb_count,
			   s2);
  IK_REF(r, disp_bignum_data + limb_count * wordsize) = (ikptr_t)hi;
  iksword_t sign =
    ((n2 > 0) ?
     (bignum_sign_mask & (iksword_t)first_word) :
     ((1 << bignum_sign_shift) - (bignum_sign_mask&(iksword_t)first_word)));
  return ik_normalize_bignum(limb_count+1, sign, r);
}

ikptr_t
ikrt_bnbnmult(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t f1 = (iksword_t)IK_REF(x, -vector_tag);
  iksword_t f2 = (iksword_t)IK_REF(y, -vector_tag);
  iksword_t n1 = IK_BNFST_LIMB_COUNT(f1);
  iksword_t n2 = IK_BNFST_LIMB_COUNT(f2);
  iksword_t nr = n1 + n2;
  pcb->root0 = &x;
  pcb->root1 = &y;
  ikptr_t bn = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + nr*wordsize));
  pcb->root0 = 0;
  pcb->root1 = 0;
  if (n1 >= n2) {
    mpn_mul((mp_limb_t*)(ikuword_t)(bn+disp_bignum_data),
	    (mp_limb_t*)(ikuword_t)(x-vector_tag+disp_bignum_data),
	    n1,
	    (mp_limb_t*)(ikuword_t)(y-vector_tag+disp_bignum_data),
	    n2);
  } else {
    mpn_mul((mp_limb_t*)(ikuword_t)(bn+disp_bignum_data),
	    (mp_limb_t*)(ikuword_t)(y-vector_tag+disp_bignum_data),
	    n2,
	    (mp_limb_t*)(ikuword_t)(x-vector_tag+disp_bignum_data),
	    n1);
  }
  iksword_t sign =
    ((bignum_sign_mask & f1) ?
     ((1 << bignum_sign_shift) - (bignum_sign_mask & f2)) :
     (bignum_sign_mask & f2));
  return ik_normalize_bignum(nr, sign, bn);
}




ikptr_t
ikrt_bnbncomp(ikptr_t bn1, ikptr_t bn2) {
  ikptr_t f1 = IK_REF(bn1, -vector_tag);
  ikptr_t f2 = IK_REF(bn2, -vector_tag);
  if (IK_BNFST_NEGATIVE(f1)) {
    if (IK_BNFST_NEGATIVE(f2)) {
      /* both negative */
      iksword_t n1 = ((mp_limb_t) f1) >> bignum_nlimbs_shift;
      iksword_t n2 = ((mp_limb_t) f2) >> bignum_nlimbs_shift;
      if (n1 < n2) {
	return IK_FIX(1);
      } else if (n1 > n2) {
	return IK_FIX(-1);
      } else {
	iksword_t i;
	for(i=(n1-1); i>=0; i--) {
	  mp_limb_t t1 =
	    (mp_limb_t) IK_REF(bn1,disp_bignum_data-vector_tag+i*wordsize);
	  mp_limb_t t2 =
	    (mp_limb_t) IK_REF(bn2,disp_bignum_data-vector_tag+i*wordsize);
	  if (t1 < t2) {
	    return IK_FIX(1);
	  } else if (t1 > t2) {
	    return IK_FIX(-1);
	  }
	}
      }
      return 0;
    } else {
      /* n1 negative, n2 positive */
      return IK_FIX(-1);
    }
  } else {
    if (IK_BNFST_NEGATIVE(f2)) {
      /* n1 positive, n2 negative */
      return IK_FIX(1);
    } else {
      /* both positive */
      iksword_t n1 = ((mp_limb_t) f1) >> bignum_nlimbs_shift;
      iksword_t n2 = ((mp_limb_t) f2) >> bignum_nlimbs_shift;
      if (n1 < n2) {
	return IK_FIX(-1);
      } else if (n1 > n2) {
	return IK_FIX(1);
      } else {
	iksword_t i;
	for(i=(n1-1); i>=0; i--) {
	  mp_limb_t t1 =
	   (mp_limb_t) IK_REF(bn1,disp_bignum_data-vector_tag+i*wordsize);
	  mp_limb_t t2 =
	    (mp_limb_t) IK_REF(bn2,disp_bignum_data-vector_tag+i*wordsize);
	  if (t1 < t2) {
	    return IK_FIX(-1);
	  } else if (t1 > t2) {
	    return IK_FIX(1);
	  }
	}
      }
      return 0;
    }
  }
}


static inline int
count_leading_ffs(int n, mp_limb_t* x) {
  int idx;
  for(idx=0; idx<n; idx++) {
    if (x[idx] != (mp_limb_t)-1) {
      return idx;
    }
  }
  return n;
}


static void
copy_limbs(mp_limb_t* src, mp_limb_t* dst, int n1, int n2) {
  while(n1 < n2) {
    dst[n1] = src[n1];
    n1++;
  }
}

static void
bits_complement(mp_limb_t* src, mp_limb_t* dst, iksword_t n) {
  mp_limb_t carry = 1;
  iksword_t i;
  for(i=0; i<n; i++) {
    mp_limb_t d = src[i];
    mp_limb_t c = carry + ~ d;
    dst[i] = c;
    carry = (carry && ! d);
  }
}

static void
bits_complement2(mp_limb_t* src, mp_limb_t* dst, int n1, int n2) {
  mp_limb_t carry = 1;
  int i;
  for(i=0; i<n1; i++) {
    mp_limb_t d = src[i];
    mp_limb_t c = carry + ~ d;
    dst[i] = c;
    carry = (carry && ! d);
  }
  for(i=n1; i<n2; i++) {
    mp_limb_t d = 0;
    mp_limb_t c = carry + ~ d;
    dst[i] = c;
    carry = (carry && ! d);
  }
}

static int
bits_complement_carry(mp_limb_t* src, mp_limb_t* dst, int n1, int n2, mp_limb_t carry) {
  int i;
  for(i=n1; i<n2; i++) {
    mp_limb_t d = src[i];
    mp_limb_t c = carry + ~ d;
    dst[i] = c;
    carry = (carry && ! d);
  }
  return carry;
}




static void
bits_complement_with_carry(mp_limb_t* src, mp_limb_t* dst, iksword_t n, iksword_t carry) {
  iksword_t i;
  for(i=0; i<n; i++) {
    mp_limb_t d = src[i];
    mp_limb_t c = carry + ~ d;
    dst[i] = c;
    carry = (carry && ! d);
  }
}

static void
bits_complement_logand(mp_limb_t* s1, mp_limb_t* s2, mp_limb_t* dst, int n) {
  int carry = 1;
  int i;
  for(i=0; i<n; i++) {
    mp_limb_t d = s1[i];
    mp_limb_t c = carry + ~ d;
    dst[i] = c & s2[i];
    carry = (carry && ! d);
  }
}



static int
bits_complement_logor(mp_limb_t* s1, mp_limb_t* s2, mp_limb_t* dst, int n) {
  int carry = 1;
  int i;
  for(i=0; i<n; i++) {
    mp_limb_t d = s1[i];
    mp_limb_t c = carry + ~ d;
    dst[i] = c | s2[i];
    carry = (carry && ! d);
  }
  return carry;
}


static iksword_t
bits_carry(mp_limb_t* s,  int n) {
  /*
  int carry = 1;
  int i;
  for(i=0; i<n; i++) {
    mp_limb_t d = s[i];
    carry = (carry && ! d);
  }
  return carry;
  */
  int i;
  for(i=0; i<n; i++) {
    if (s[i] != 0) {
      return 0;
    }
  }
  return 1;
}

ikptr_t
ikrt_bnlognot(ikptr_t x, ikpcb_t* pcb) {
  ikptr_t first_word = IK_REF(x, -vector_tag);
  iksword_t n = IK_BNFST_LIMB_COUNT(first_word);
  if (IK_BNFST_NEGATIVE(first_word)) {
    /* negative */
    pcb->root0 = &x;
    ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + n*wordsize));
    pcb->root0 = 0;
    mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
    mp_limb_t* rd = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
    int i;
    for(i=0; (i<n) && (s1[i] == 0); i++) {
      rd[i] = -1;
    }
    rd[i] = s1[i] - 1;
    for(i++; i<n; i++) {
      rd[i] = s1[i];
    }
    return ik_normalize_bignum(n, 0, r);
  } else {
    /* positive */
    iksword_t i;
    mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
    for(i=0; (i<n) && (s1[i] == (mp_limb_t)-1); i++) {/*nothing*/}
    if (i==n) {
      pcb->root0 = &x;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + (n+1)*wordsize));
      pcb->root0 = 0;
      bzero((uint8_t*)(ikuword_t)r+disp_bignum_data, n*wordsize);
      ((mp_limb_t*)(ikuword_t)(r+disp_bignum_data))[n] = 1;
      IK_REF(r, 0) = (ikptr_t)
	(bignum_tag | (1<<bignum_sign_shift) | ((n+1) << bignum_nlimbs_shift));
      return r+vector_tag;
    } else {
      pcb->root0 = &x;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + n*wordsize));
      pcb->root0 = 0;
      mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
      mp_limb_t* rd = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
      int j;
      for(j=0; j<i; j++) { rd[j] = 0; }
      rd[i] = s1[i] + 1;
      for(j=i+1; j<n; j++) { rd[j] = s1[j]; }
      IK_REF(r, 0) = (ikptr_t)
	(bignum_tag | (1<<bignum_sign_shift) | (n << bignum_nlimbs_shift));
      return r+vector_tag;
    }
  }
}


ikptr_t
ikrt_fxbnlogand(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t n1 = IK_UNFIX(x);
  ikptr_t first_word = IK_REF(y, -vector_tag);
  if (n1 >= 0) {
    /* x is positive */
    if (IK_BNFST_NEGATIVE(first_word)) {
      /* y is negative */
      return IK_FIX(n1 & (1+~(iksword_t)IK_REF(y, disp_vector_data-vector_tag)));
    } else {
      /* y is positive */
      return IK_FIX(n1 & (iksword_t)IK_REF(y, disp_vector_data-vector_tag));
    }
  } else {
    /* x is negative */
    if (n1 == -1) { return y; }
    if (IK_BNFST_NEGATIVE(first_word)) {
      /* y is negative */
      iksword_t len = IK_BNFST_LIMB_COUNT(first_word);
      pcb->root0 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + (len+1)*wordsize));
      pcb->root0 = 0;
      mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
      mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
      bits_complement2(s2, s, len, len+1);
      s[0] = s[0] & n1;
      bits_complement2(s, s, len+1, len+1);
      return ik_normalize_bignum(len+1, 1<<bignum_sign_shift, r);
    } else {
      /* y is positive */
      iksword_t len = IK_BNFST_LIMB_COUNT(first_word);
      pcb->root0 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + len * wordsize));
      pcb->root0 = 0;
      IK_REF(r, 0) = first_word;
      IK_REF(r, disp_bignum_data) = (ikptr_t)
	(((iksword_t)IK_REF(y, disp_bignum_data - vector_tag)) & n1);
      int i;
      for(i=1; i<len; i++) {
	IK_REF(r, disp_bignum_data+i*wordsize) =
	  IK_REF(y, disp_bignum_data-vector_tag+i*wordsize);
      }
      return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxbnlogand");
    }
  }
}

ikptr_t
ikrt_bnbnlogand(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  ikptr_t xfst = IK_REF(x, -vector_tag);
  ikptr_t yfst = IK_REF(y, -vector_tag);
  iksword_t n1 = IK_BNFST_LIMB_COUNT(xfst);
  iksword_t n2 = IK_BNFST_LIMB_COUNT(yfst);
  if (IK_BNFST_NEGATIVE(xfst)) {
    if (IK_BNFST_NEGATIVE(yfst)) {
      if (n1 >= n2) {
	pcb->root0 = &x;
	pcb->root1 = &y;
	ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + (n1+1)*wordsize));
	pcb->root0 = 0;
	pcb->root1 = 0;
	mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
	mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
	mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
	bits_complement2(s1, s, n1, n1+1);
	bits_complement_logand(s2, s, s, n2);
	bits_complement2(s, s, n1+1, n1+1);
	return ik_normalize_bignum(n1+1, 1<<bignum_sign_shift, r);
      } else {
	return ikrt_bnbnlogand(y,x,pcb);
      }
    } else {
      return ikrt_bnbnlogand(y,x,pcb);
    }
  } else {
    if (IK_BNFST_NEGATIVE(yfst)) {
      /* x positive, y negative */
      /*  the result is at most n1 words iksword_t */
      pcb->root0 = &x;
      pcb->root1 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + n1*wordsize));
      pcb->root0 = 0;
      pcb->root1 = 0;
      mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
      mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
      mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
      if (n1 <= n2) {
	bits_complement_logand(s2, s1, s, n1);
      } else {
	bits_complement_logand(s2, s1, s, n2);
	copy_limbs(s1, s, n2, n1);
      }
      return ik_normalize_bignum(n1, 0, r);
    } else {
      /* both positive */
      int n = (n1<n2)?n1:n2;
      iksword_t i;
      for(i=n-1; i>=0; i--) {
	iksword_t l1 =
	  (iksword_t) IK_REF(x, disp_bignum_data-vector_tag+i*wordsize);
	iksword_t l2 =
	  (iksword_t) IK_REF(y, disp_bignum_data-vector_tag+i*wordsize);
	ikuword_t last = l1 & l2;
	if (last) {
	  if ((i == 0) && (last < most_positive_fixnum)) {
	    return IK_FIX(last);
	  }
	  pcb->root0 = &x;
	  pcb->root1 = &y;
	  ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+(i+1)*wordsize));
	  pcb->root0 = 0;
	  pcb->root1 = 0;
	  IK_REF(r, 0) = (ikptr_t) (bignum_tag | ((i+1)<<bignum_nlimbs_shift));
	  IK_REF(r, disp_bignum_data + i*wordsize) = (ikptr_t)last;
	  int j;
	  for(j=0; j<i; j++) {
	    IK_REF(r, disp_bignum_data + j*wordsize) = (ikptr_t)
	      (((iksword_t)IK_REF(x, disp_bignum_data-vector_tag+j*wordsize))
	       &
	       ((iksword_t)IK_REF(y, disp_bignum_data-vector_tag+j*wordsize)));
	  }
	  return r+vector_tag;
	}
      }
      return 0;
    }
  }
}


ikptr_t
ikrt_fxbnlogor(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t n1 = IK_UNFIX(x);
  ikptr_t first_word = IK_REF(y, -vector_tag);
  if (n1 < 0) {
    /* x is negative */
    if (IK_BNFST_NEGATIVE(first_word)) {
      /* y is negative */
      return IK_FIX(n1 | (1+~(iksword_t)IK_REF(y, disp_vector_data-vector_tag)));
    } else {
      /* y is positive */
      return IK_FIX(n1 | (iksword_t)IK_REF(y, disp_vector_data-vector_tag));
    }
  } else {
    /* x is non negative */
    if (n1 == 0) { return y; }
    /* x is positive */
    if (IK_BNFST_NEGATIVE(first_word)) {
      /* y is negative */
      iksword_t len = IK_BNFST_LIMB_COUNT(first_word);
      pcb->root0 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + (len+1)*wordsize));
      pcb->root0 = 0;
      mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
      mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
      bits_complement2(s2, s, len, len+1);
      s[0] = s[0] | n1;
      bits_complement2(s, s, len+1, len+1);
      return ik_normalize_bignum(len+1, 1<<bignum_sign_shift, r);
    } else {
      /* y is positive */
      iksword_t len = IK_BNFST_LIMB_COUNT(first_word);
      pcb->root0 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + len * wordsize));
      pcb->root0 = 0;
      IK_REF(r, 0) = first_word;
      IK_REF(r, disp_bignum_data) = (ikptr_t)
	(((iksword_t)IK_REF(y, disp_bignum_data - vector_tag)) | n1);
      int i;
      for(i=1; i<len; i++) {
	IK_REF(r, disp_bignum_data+i*wordsize) =
	  IK_REF(y, disp_bignum_data-vector_tag+i*wordsize);
      }
      return DEBUG_VERIFY_BIGNUM(r+vector_tag, "fxbnlogor");
    }
  }
}

ikptr_t
ikrt_bnbnlogor(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  ikptr_t xfst = IK_REF(x, -vector_tag);
  ikptr_t yfst = IK_REF(y, -vector_tag);
  iksword_t n1 = IK_BNFST_LIMB_COUNT(xfst);
  iksword_t n2 = IK_BNFST_LIMB_COUNT(yfst);
  if (IK_BNFST_NEGATIVE(xfst)) {
    if (IK_BNFST_NEGATIVE(yfst)) {
      if (n1 >= n2) {
	pcb->root0 = &x;
	pcb->root1 = &y;
	ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + n1*wordsize));
	pcb->root0 = 0;
	pcb->root1 = 0;
	mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
	mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
	mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
	bits_complement2(s2, s, n2, n1);
	int carry = bits_complement_logor(s1, s, s, n1);
	bits_complement_carry(s,s,n1,n1,carry);
	bits_complement2(s, s, n1, n1);
	return ik_normalize_bignum(n1, 1<<bignum_sign_shift, r);
      } else {
	return ikrt_bnbnlogor(y,x,pcb);
      }
    } else {
      return ikrt_bnbnlogor(y,x,pcb);
    }
  } else {
    if (IK_BNFST_NEGATIVE(yfst)) {
      /* x positive, y negative */
      /*  the result is at most n2 words iksword_t */
      pcb->root0 = &x;
      pcb->root1 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + n2*wordsize));
      pcb->root0 = 0;
      pcb->root1 = 0;
      mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
      mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
      mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
      if (n2 <= n1) {
	bits_complement_logor(s2, s1, s, n2);
	bits_complement2(s, s, n2, n2);
      } else {
	int carry = bits_complement_logor(s2, s1, s, n1);
	bits_complement_carry(s2, s, n1, n2, carry);
	bits_complement_carry(s, s, 0, n2, 1);
      }
      return ik_normalize_bignum(n2, 1<<bignum_sign_shift, r);
    } else {
      /* both positive */
      int n = (n1>n2)?n1:n2;
      pcb->root0 = &x;
      pcb->root1 = &y;
      ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data+n*wordsize));
      mp_limb_t* s = (mp_limb_t*)(ikuword_t)(r+disp_bignum_data);
      mp_limb_t* s1 = (mp_limb_t*)(ikuword_t)(x+disp_bignum_data-vector_tag);
      mp_limb_t* s2 = (mp_limb_t*)(ikuword_t)(y+disp_bignum_data-vector_tag);
      pcb->root0 = 0;
      pcb->root1 = 0;
      iksword_t i;
      if (n == n1) {
	for(i=0; i<n2; i++) {
	  s[i] = s1[i] | s2[i];
	}
	for(i=n2; i<n1; i++) {
	  s[i] = s1[i];
	}
      } else {
	for(i=0; i<n1; i++) {
	  s[i] = s1[i] | s2[i];
	}
	for(i=n1; i<n2; i++) {
	  s[i] = s2[i];
	}
      }
      return ik_normalize_bignum(n, 0, r);
    }
  }
}

static void
copy_bits_shifting_right(mp_limb_t* src, mp_limb_t* dst, int n, int m) {
  mp_limb_t carry = src[0] >> m;
  int i;
  for(i=1; i<n; i++) {
    mp_limb_t b = src[i];
    dst[i-1] = (b << (mp_bits_per_limb-m)) | carry;
    carry = b >> m;
  }
  dst[n-1] = carry;
}

static void
copy_bits_shifting_left(mp_limb_t* src, mp_limb_t* dst, int n, int m) {
  mp_limb_t carry = 0;
  int i;
  for(i=0; i<n; i++) {
    mp_limb_t b = src[i];
    dst[i] = (b << m) | carry;
    carry = b >> (mp_bits_per_limb-m);
  }
  dst[n] = carry;
}





ikptr_t
ikrt_bignum_shift_right (ikptr_t s_bignum_integer, ikptr_t s_fixnum_offset, ikpcb_t* pcb)
/* NOTE For  some reason unknown to  me: when compiling for  32-bit with
   GCC 5.3.0 and "-O3" this function  is miscompiled in some case and an
   error  ensues.  IMHO  a compiler  bug.  Everything  is all  right for
   64-bit.  For this reason the C  code should be compiled with "-O2" on
   32-bit platforms.  Life is hard.  (Marco Maggi; Sat Jan 7, 2017) */
{
  iksword_t	offset			= IK_UNFIX(s_fixnum_offset);
  ikptr_t	first_word		= IK_BIGNUM_FIRST(s_bignum_integer);
  iksword_t	integer_limb_count	= IK_BNFST_LIMB_COUNT(first_word);
  iksword_t	whole_limb_shift	= offset >> BIGNUM_LIMB_SHIFT;
  iksword_t	bit_shift		= offset & (mp_bits_per_limb-1);
  iksword_t	new_limb_count		= integer_limb_count - whole_limb_shift;
  ikptr_t	p_result;
  if (IK_BNFST_NEGATIVE(first_word)) {
    /* The bignum to shift is negative. */
    if (new_limb_count <= 0) {
      return IK_FIX(-1);
    }
    pcb->root0 = &s_bignum_integer;
    {
      p_result = IKA_BIGNUM_ALLOC_NO_TAG(pcb, new_limb_count);
    }
    pcb->root0 = NULL;
    if (0 == bit_shift) {
      bits_complement_with_carry((mp_limb_t*)IK_LIMB_PTR(s_bignum_integer, whole_limb_shift),
				 (mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
				 new_limb_count,
				 bits_carry((mp_limb_t*)IK_LIMB_PTR(s_bignum_integer, 0), whole_limb_shift));
      bits_complement((mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
		      (mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
		      new_limb_count);
      return ik_normalize_bignum(new_limb_count, IK_BNFST_NEGATIVE_SIGN_BIT, p_result);
    } else {
      bits_complement_with_carry((mp_limb_t*)IK_LIMB_PTR(s_bignum_integer, whole_limb_shift),
				 (mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
				 new_limb_count,
				 bits_carry((mp_limb_t*)IK_LIMB_PTR(s_bignum_integer, 0), whole_limb_shift));
      copy_bits_shifting_right((mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
			       (mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
			       new_limb_count, bit_shift);
      *((mp_limb_t*)IK_PTR(p_result, disp_bignum_data+(new_limb_count-1)*IK_WORDSIZE)) |= (-1L << (mp_bits_per_limb - bit_shift));
      bits_complement((mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
		      (mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
		      new_limb_count);
      return ik_normalize_bignum(new_limb_count, IK_BNFST_NEGATIVE_SIGN_BIT, p_result);
    }
  } else {
    /* The bignum to shift is positive.   We need to remember the layout
     * of a bignum data area:
     *
     *    |----|-----|-----|-----|-----|
     *     1st  limb0 limb1 limb2 limb3
     *
     * shifting  to  the  right  means to  discard  bits  starting  from
     * "limb0", that is: to discard least significant bits.
     *
     * The  value  "whole_limb_shift"  is  the  number  of  whole  least
     * significant limbs that must  be discarded.  The value "bit_shift"
     * is the  number of least  significant bits that must  be discarded
     * after having discarded the whole limbs.
     */
    if (new_limb_count <= 0) {
      return IK_FIX(0);
    }
    pcb->root0 = &s_bignum_integer;
    {
      p_result = IKA_BIGNUM_ALLOC_NO_TAG(pcb, new_limb_count);
    }
    pcb->root0 = NULL;
    if (0 == bit_shift) {
      /* No  bit shift:  we just  copy the  most significant  limbs from
	 "s_bignum_integer" to "p_result". */
      memcpy((uint8_t*)IK_PTR(p_result, disp_bignum_data),
	     (uint8_t*)IK_LIMB_PTR(s_bignum_integer, whole_limb_shift),
	     new_limb_count * IK_WORDSIZE);
      return ik_normalize_bignum(new_limb_count, IK_BNFST_POSITIVE_SIGN_BIT, p_result);
    } else {
      copy_bits_shifting_right((mp_limb_t*)IK_LIMB_PTR(s_bignum_integer, whole_limb_shift),
			       (mp_limb_t*)IK_PTR(p_result, disp_bignum_data),
			       new_limb_count, bit_shift);
      return ik_normalize_bignum(new_limb_count, IK_BNFST_POSITIVE_SIGN_BIT, p_result);
    }
  }
}


ikptr_t
ikrt_fixnum_shift_left(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t m = IK_UNFIX(y);
  iksword_t n = IK_UNFIX(x);
  iksword_t limb_count = (m >> BIGNUM_LIMB_SHIFT) + 2;
  iksword_t bit_shift = m & (mp_bits_per_limb-1);
  ikptr_t r = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + limb_count * wordsize));
  ikuword_t* s = (ikuword_t*)(ikuword_t)(r+disp_bignum_data);
  bzero(s, limb_count * wordsize);
  if (n >= 0) {
    if (bit_shift) {
      s[limb_count-1] = n >> (mp_bits_per_limb - bit_shift);
    }
    s[limb_count-2] = n << bit_shift;
  } else {
    if (bit_shift) {
      s[limb_count-1] = (-n) >> (mp_bits_per_limb - bit_shift);
    }
    s[limb_count-2] = (-n) << bit_shift;
  }
  return ik_normalize_bignum(limb_count, (n>=0)?(0):(1<<bignum_sign_shift), r);
}


ikptr_t
ikrt_bignum_shift_left(ikptr_t s_bignum_integer, ikptr_t s_offset, ikpcb_t* pcb)
/* We need to remember the layout of a bignum data area:
 *
 *    |----|-----|-----|-----|-----|
 *     1st  limb0 limb1 limb2 limb3
 *
 * shifting to  the left  means to discard  bits starting  from "limb3",
 * that is: to discard most significant bits.
 *
 * The value "whole_limb_shift" is the  number of whole most significant
 * limbs that must be discarded.  The value "bit_shift" is the number of
 * most significant bits  that must be discarded  after having discarded
 * the whole limbs.
 */
{
  iksword_t	offset			= IK_UNFIX(s_offset);
  ikptr_t	first_word		= IK_BIGNUM_FIRST(s_bignum_integer);
  iksword_t	integer_limb_count	= IK_BNFST_LIMB_COUNT(first_word);
  iksword_t	whole_limb_shift	= offset >> BIGNUM_LIMB_SHIFT;
  iksword_t	bit_shift		= offset & (mp_bits_per_limb-1);
  iksword_t	new_limb_count;
  ikptr_t	p_result;
  mp_limb_t *	p_result_limbs;
  if (0 == bit_shift) {
    new_limb_count = integer_limb_count + whole_limb_shift;
  } else {
    new_limb_count = integer_limb_count + whole_limb_shift + 1;
  }
  pcb->root0 = &s_bignum_integer;
  {
    p_result = ik_safe_alloc(pcb, IK_ALIGN(disp_bignum_data + new_limb_count * IK_WORDSIZE));
  }
  pcb->root0 = NULL;
  p_result_limbs = (mp_limb_t*)IK_PTR(p_result, disp_bignum_data);
  bzero(p_result_limbs, whole_limb_shift * IK_WORDSIZE);
  if (0 == bit_shift) {
    /* No bit shift: just copy the  least significant whole limbs to the
       data area of "p_result" at the right offset. */
    memcpy(IK_PTR(p_result_limbs, whole_limb_shift * IK_WORDSIZE),
	   IK_LIMB_PTR(s_bignum_integer, 0),
	   integer_limb_count * IK_WORDSIZE);
  } else {
    copy_bits_shifting_left((mp_limb_t*)IK_LIMB_PTR(s_bignum_integer, 0),
			    (mp_limb_t*)IK_PTR(p_result_limbs, whole_limb_shift * IK_WORDSIZE),
			    integer_limb_count, bit_shift);
  }
  return ik_normalize_bignum(new_limb_count, IK_BNFST_NEGATIVE(first_word), p_result);
}


#if 0
From TFM:
void
mpn_tdiv_qr (
  mp limb t *qp,	/* quotient placed here */
  mp limb t *rp,	/* remainder placed here */
  mp size t qxn,	/* must be zero! */
  const mp limb t *np,	/* first number	 */
  mp size t nn,		/* its length	 */
  const mp limb t *dp,	/* second number */
  mp size t dn		/* its length	 */
)

Divide {np, nn} by {dp, dn} and put the quotient at {qp,nn-dn+1}
and the remainder at {rp, dn}. The quotient is rounded towards 0.
No overlap is permitted between arguments. nn must be greater than
or equal to dn. The most significant limb of dp must be non-zero.
The qxn operand must be zero.
#endif

ikptr_t
ikrt_bnbndivrem(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  ikptr_t xfst = IK_REF(x, -vector_tag);
  ikptr_t yfst = IK_REF(y, -vector_tag);
  mp_size_t xn = IK_BNFST_LIMB_COUNT(xfst);
  mp_size_t yn = IK_BNFST_LIMB_COUNT(yfst);
  if (xn < yn) {
    /* quotient is zero, remainder is x */
    pcb->root0 = &x;
    pcb->root1 = &y;
    ikptr_t rv = ik_safe_alloc(pcb, pair_size);
    pcb->root0 = 0;
    pcb->root1 = 0;
    IK_REF(rv, disp_car) = 0;
    IK_REF(rv, disp_cdr) = x;
    return rv+pair_tag;
  }
  mp_size_t qn = xn - yn + 1;
  mp_size_t rn = yn;
  /*
  ikptr_t q = ik_unsafe_alloc(pcb, IK_ALIGN(disp_bignum_data + qn*wordsize));
  ikptr_t r = ik_unsafe_alloc(pcb, IK_ALIGN(disp_bignum_data + rn*wordsize));
  */
  pcb->root0 = &x;
  pcb->root1 = &y;
  ikptr_t q = ik_safe_alloc(pcb,
	    IK_ALIGN(disp_bignum_data + qn*wordsize) +
	    IK_ALIGN(disp_bignum_data + rn*wordsize));
  ikptr_t r = q + IK_ALIGN(disp_bignum_data + qn*wordsize);
  pcb->root0 = 0;
  pcb->root1 = 0;
  mpn_tdiv_qr (
      (mp_limb_t*)(ikuword_t)(q+disp_bignum_data),
      (mp_limb_t*)(ikuword_t)(r+disp_bignum_data),
      0,
      (mp_limb_t*)(ikuword_t)(x+off_bignum_data),
      xn,
      (mp_limb_t*)(ikuword_t)(y+off_bignum_data),
      yn);

  if (IK_BNFST_NEGATIVE(xfst)) {
    /* x is negative => remainder is negative */
    r = ik_normalize_bignum(rn, 1 << bignum_sign_shift, r);
  } else {
    r = ik_normalize_bignum(rn, 0, r);
  }

  if (IK_BNFST_NEGATIVE(yfst)) {
    /* y is negative => quotient is opposite of x */
    iksword_t sign = bignum_sign_mask - IK_BNFST_NEGATIVE(xfst);
    q = ik_normalize_bignum(qn, sign, q);
  } else {
    /* y is positive => quotient is same as x */
    iksword_t sign = IK_BNFST_NEGATIVE(xfst);
    q = ik_normalize_bignum(qn, sign, q);
  }
  pcb->root0 = &q;
  pcb->root1 = &r;
  ikptr_t rv = ik_safe_alloc(pcb, pair_size);
  pcb->root0 = 0;
  pcb->root1 = 0;
  IK_REF(rv, disp_car) = q;
  IK_REF(rv, disp_cdr) = r;
  return rv+pair_tag;
}


/*
[Function]

mp_limb_t
mpn_divrem_1 (
  mp limb t *r1p,
  mp size t qxn,
  mp limb t *s2p,
  mp size t s2n,
  mp limb t s3limb
)

Divide {s2p, s2n} by s3limb, and write the quotient at r1p. Return the remainder.
The integer quotient is written to {r1p+qxn, s2n} and in addition qxn fraction limbs are
developed and written to {r1p, qxn}. Either or both s2n and qxn can be zero. For most
usages, qxn will be zero.
*/

ikptr_t
ikrt_bnfxdivrem(ikptr_t x, ikptr_t y, ikpcb_t* pcb) {
  iksword_t yint = IK_UNFIX(y);
  ikptr_t first_word = IK_REF(x, -vector_tag);
  mp_size_t s2n = IK_BNFST_LIMB_COUNT(first_word);
  pcb->root0 = &x;
  ikptr_t quot = ik_safe_alloc(pcb, IK_ALIGN(s2n*wordsize + disp_bignum_data));
  pcb->root0 = 0;
  mp_limb_t* s2p = (mp_limb_t*)(ikuword_t)(x+off_bignum_data);
  mp_limb_t rv = mpn_divrem_1(
      (mp_limb_t*)(ikuword_t)(quot+disp_bignum_data),
      0,
      s2p,
      s2n,
      labs(yint));

  ikptr_t rem;

  if (yint < 0) {
    /* y is negative => quotient is opposite of x */
    iksword_t sign = bignum_sign_mask - IK_BNFST_NEGATIVE(first_word);
    quot = ik_normalize_bignum(s2n, sign, quot);
  } else {
    /* y is positive => quotient is same as x */
    iksword_t sign = IK_BNFST_NEGATIVE(first_word);
    quot = ik_normalize_bignum(s2n, sign, quot);
  }

  /* the remainder is always less than |y|, so it will
     always be a fixnum.  (if y == most_negative_fixnum,
     then |remainder| will be at most most_positive_fixnum). */
  if (IK_BNFST_NEGATIVE(first_word)) {
    /* x is negative => remainder is negative */
    rem = (ikptr_t) -(rv << fx_shift);
  } else {
    rem = IK_FIX(rv);
  }
  pcb->root0 = &quot;
  pcb->root1 = &rem;
  ikptr_t p = ik_safe_alloc(pcb, pair_size);
  pcb->root0 = 0;
  pcb->root1 = 0;
  IK_REF(p, disp_car) = quot;
  IK_REF(p, disp_cdr) = rem;
  return p+pair_tag;
}


ikptr_t
ikrt_bnfx_modulo (ikptr_t x, ikptr_t y /*, ikpcb_t* pcb */)
/* Compute the modulo  of the integer division between the  bignum X and
   the  fixnum  Y.   This  function  makes use  of  the  GMP's  function
   "mpn_mod_1()". */
{
  iksword_t		yint		= IK_UNFIX(y);
  mp_limb_t*	s2p		= (mp_limb_t*)(ikuword_t)(x + off_bignum_data);
  ikptr_t		first_word	= IK_REF(x, off_bignum_tag);
  mp_size_t	s2n		= IK_BNFST_LIMB_COUNT(first_word);
  /* fprintf(stderr, "%s: yint = %ld\n", __func__, yint); */
  if (yint < 0) {
    if (-1 == yint) {
      return IK_FIX(0);
    } else if (IK_BNFST_NEGATIVE(first_word)) {
      /* x negative, y negative */
      mp_limb_t m = mpn_mod_1(s2p, s2n, -yint);
      return IK_FIX(-m);
    } else {
      /* x non-negative, y negative */
      mp_limb_t m = mpn_mod_1(s2p, s2n, -yint);
      return (m)? IK_FIX(yint+m) : IK_FIX(0);
    }
  } else {
    if (1 == yint) {
      return IK_FIX(0);
    } else if (IK_BNFST_NEGATIVE(first_word)) {
      /* x negative, y non-negative */
      mp_limb_t m = mpn_mod_1(s2p, s2n, yint);
      return (m)? IK_FIX(yint-m) : IK_FIX(0);
    } else {
      /* x positive, y non-negative */
      mp_limb_t m = mpn_mod_1(s2p, s2n, yint);
      return IK_FIX(m);
    }
  }
}


static int
limb_length (mp_limb_t n)
{
  int i=0;
  while(n != 0) {
    n = n >> 1;
    i++;
  }
  return i;
}


ikptr_t
ikrt_bignum_length(ikptr_t x) {
  ikptr_t first_word = IK_REF(x, -vector_tag);
  mp_limb_t* sp = (mp_limb_t*)(ikuword_t)(x+off_bignum_data);
  mp_size_t sn = IK_BNFST_LIMB_COUNT(first_word);
  mp_limb_t last = sp[sn-1];
  int n0 = limb_length(last);
  if (((ikuword_t) first_word) & bignum_sign_mask) {
    /* negative */
    if (last == (mp_limb_t)(1L<<(n0-1))) {
      /* single bit set in last limb */
      int i;
      for(i=0; i<(sn-1); i++) {
	if (sp[i] != 0) {
	  /* another bit set */
	  return IK_FIX((sn-1)*mp_bits_per_limb + n0);
	}
      }
      /* number is - #b100000000000000000000000000 */
      /* fxnot(n) =  #b011111111111111111111111111 */
      /* so, subtract 1. */
      return IK_FIX((sn-1)*mp_bits_per_limb + n0 - 1);
    } else {
      return IK_FIX((sn-1)*mp_bits_per_limb + n0);
    }
  } else {
    return IK_FIX((sn-1)*mp_bits_per_limb + n0);
  }
}


ikptr_t
ikrt_bignum_to_bytevector(ikptr_t x, ikpcb_t* pcb) {
  /* FIXME: avoid calling malloc, instead, use the heap pointer itself
   * as a buffer to hold the temporary data after ensuring that it has enough
   * space */
  ikptr_t first_word = IK_REF(x, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  if (limb_count <= 0)
    ik_abort("BUG: nbtostring: invalid length %ld", limb_count);
  iksword_t sign_bit = bignum_sign_mask & (iksword_t) first_word;
  iksword_t nbsize = limb_count * sizeof(mp_limb_t);
  iksword_t strsize = limb_count * max_digits_per_limb;
  iksword_t mem_req = nbsize + strsize + 1;
  uint8_t* mem = malloc(mem_req);
  if (! mem)
    ik_abort("error allocating space for bignum");
  memcpy((uint8_t*)(ikuword_t)mem,
	 (uint8_t*)(ikuword_t)x - vector_tag + disp_bignum_data,
	 nbsize);
  mp_size_t bytes =
    mpn_get_str(mem+nbsize,	  /* output string */
		10,		  /* base */
		(mp_limb_t*) mem, /* limb */
		limb_count	  /* number of limbs */
	);
  uint8_t* string_start = mem + nbsize;
  while(*string_start == 0) {
    string_start++;
    bytes--;
  }
  ikptr_t bv = ik_safe_alloc(pcb, IK_ALIGN(bytes + disp_bytevector_data + (sign_bit?1:0)));
  IK_REF(bv, 0) = IK_FIX(bytes + (sign_bit?1:0));
  {
    uint8_t *	dest = (uint8_t*)(ikuword_t)(bv + disp_bytevector_data);
    if (sign_bit) {
      *dest = '-';
      dest++;
    }
    {
      iksword_t i = 0;
      while(i < bytes) {
	dest[i] = string_start[i] + '0';
	i++;
      }
      dest[bytes] = 0;
    }
  }
  free(mem);
  return bv | bytevector_tag;
}


ikptr_t
ikrt_fxrandom(ikptr_t x) {
  iksword_t mask = 1;
  iksword_t n = IK_UNFIX(x);
  {
    while(mask < n) {
      mask = (mask << 1) | 1;
    }
  }
  while(1) {
    iksword_t r = random() & mask;
    if (r < n) {
      return IK_FIX(r);
    }
  }
}

static int
limb_size(mp_limb_t x) {
  int i = 0;
  while(x) {
    i++;
    x = x>>1;
  }
  return i;
}

static int
all_zeros(mp_limb_t* start, mp_limb_t* end) {
  while(start <= end) {
    if (*end) return 0;
    end--;
  }
  return 1;
}

#define PRECISION 53

static ikptr_t
ikrt_bignum_to_flonum64(ikptr_t bn, ikptr_t more_bits, ikptr_t fl) {
  ikptr_t first_word = IK_REF(bn, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  mp_limb_t* sp = (mp_limb_t*)(ikuword_t)(bn+off_bignum_data);
  double pos_result;
  if (limb_count == 1) {
    pos_result = sp[0];
  } else {
    mp_limb_t hi = sp[limb_count-1];
    int bc = limb_size(hi);
    if (bc < 64) {
      mp_limb_t mi = sp[limb_count-2];
      hi = (hi << (64-bc)) | (mi >> bc);
    }
    /* now hi has 64 full bits */
    mp_limb_t mask = ((1L<<(64-PRECISION)) - 1);
    if ((hi & mask) == ((mask+1)>>1)) {
      /* exactly at break point */
      if (((sp[limb_count-2] << (64-bc)) == 0) &&
	  all_zeros(sp, sp+limb_count-3) &&
	  (more_bits == 0)) {
	if (hi & (1L<<(64-PRECISION))) {
	  /* odd number, round to even */
	  hi = hi | mask;
	}
      } else {
	/* round up */
	hi = hi | mask;
      }
    } else if ((hi & mask) > ((mask+1)>>1)) {
      /* also round up */
      hi = hi | mask;
    } else {
      /* keep it to round down */
    }
    pos_result = hi;
    int bignum_bits = bc + (mp_bits_per_limb * (limb_count-1));
    int exponent = bignum_bits - mp_bits_per_limb;
    while(exponent) {
      pos_result *= 2.0;
      exponent -= 1;
    }
  }
  if (IK_BNFST_NEGATIVE(first_word)) {
    IK_FLONUM_DATA(fl)	= - pos_result;
  } else {
    IK_FLONUM_DATA(fl) = pos_result;
  }
  return fl;
}

ikptr_t
ikrt_bignum_to_flonum(ikptr_t bn, ikptr_t more_bits, ikptr_t fl) {
  if (mp_bits_per_limb == 64) {
    return ikrt_bignum_to_flonum64(bn, more_bits, fl);
  }
  ikptr_t first_word = IK_REF(bn, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  mp_limb_t* sp = (mp_limb_t*)(ikuword_t)(bn+off_bignum_data);
  double pos_result;
  if (limb_count == 1) {
    pos_result = sp[0];
  } else if (limb_count == 2) {
    mp_limb_t lo = sp[0];
    mp_limb_t hi = sp[1];
    pos_result = hi;
    pos_result = pos_result * 4294967296.0;
    pos_result = pos_result + lo;
  } else {
    mp_limb_t hi = sp[limb_count-1];
    mp_limb_t mi = sp[limb_count-2];
    int bc = limb_size(hi);
    if (bc < 32) {
      mp_limb_t lo = sp[limb_count-3];
      hi = (hi << (32-bc)) | (mi >> bc);
      mi = (mi << (32-bc)) | (lo >> bc);
    }
    /* now hi has 32 full bits, and mi has 32 full bits */
    mp_limb_t mask = ((1<<(64-PRECISION)) - 1);
    if ((mi & mask) == ((mask+1)>>1)) {
      /* exactly at break point */
      if (((sp[limb_count-3] << (32-bc)) == 0) &&
	  all_zeros(sp, sp+limb_count-4) &&
	  (more_bits == 0)) {
	if (mi & (1<<(64-PRECISION))) {
	  /* odd number, round to even */
	  mi = mi | mask;
	}
      } else {
	/* round up */
	mi = mi | mask;
      }
    } else if ((mi & mask) > ((mask+1)>>1)) {
      /* also round up */
      mi = mi | mask;
    } else {
      /* keep it to round down */
    }
    pos_result = hi;
    pos_result = pos_result * 4294967296.0;
    pos_result = pos_result + mi;
    int bignum_bits = bc + (mp_bits_per_limb * (limb_count-1));
    int exponent = bignum_bits - (2 * mp_bits_per_limb);
    while(exponent) {
      pos_result *= 2.0;
      exponent -= 1;
    }
  }
  if (IK_BNFST_NEGATIVE(first_word)) {
    IK_FLONUM_DATA(fl)	= - pos_result;
  } else {
    IK_FLONUM_DATA(fl) = pos_result;
  }
  return fl;
}

ikptr_t
ikrt_exact_fixnum_sqrt(ikptr_t fx /*, ikpcb_t* pcb*/) {
  mp_limb_t x = IK_UNFIX(fx);
  mp_limb_t s;
  mp_limb_t r;
  mpn_sqrtrem(&s, &r, &x, 1);
  return IK_FIX(s);
}

ikptr_t
ikrt_exact_bignum_sqrt(ikptr_t bn, ikpcb_t* pcb) {
  ikptr_t first_word = IK_REF(bn, -vector_tag);
  iksword_t limb_count = IK_BNFST_LIMB_COUNT(first_word);
  iksword_t result_limb_count = (limb_count + 1)/2;
  pcb->root0 = &bn;
  ikptr_t s = ik_safe_alloc(pcb,
	    IK_ALIGN(disp_bignum_data+result_limb_count*wordsize))
	  | vector_tag;
  IK_REF(s, -vector_tag) =
    (ikptr_t) (bignum_tag | (result_limb_count << bignum_nlimbs_shift));
  pcb->root1 = &s;
  ikptr_t r = ik_safe_alloc(pcb,
	      IK_ALIGN(disp_bignum_data+limb_count*wordsize))
	  | vector_tag;
  IK_REF(r, -vector_tag) =
    (ikptr_t) (bignum_tag | (limb_count << bignum_nlimbs_shift));
  pcb->root0 = &r;
  ikptr_t pair = ik_safe_alloc(pcb, pair_size) | pair_tag;
  pcb->root0 = 0;
  pcb->root1 = 0;
  mp_size_t r_actual_limbs = mpn_sqrtrem(
      (mp_limb_t*) (s+off_bignum_data),
      (mp_limb_t*) (r+off_bignum_data),
      (mp_limb_t*) (bn+off_bignum_data),
      limb_count);
  IK_REF(pair, off_car) = ik_normalize_bignum(result_limb_count, 0, s-vector_tag);
  if (r_actual_limbs == 0) {
    /* perfect square */
    IK_REF(pair, off_cdr) = 0;
  } else {
    IK_REF(pair, off_cdr) = ik_normalize_bignum(r_actual_limbs, 0, r-vector_tag);
  }
  return pair;
}


/** --------------------------------------------------------------------
 ** Numeric hash functions.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_flonum_hash (ikptr_t x /*, ikpcb_t* pcb */)
{
  uint16_t *	buf = (uint16_t*)(x+off_flonum_data);
  ikptr_t		H   = ((iksword_t)(buf[0]))
    ^ (((iksword_t)(buf[1])) << 3)
    ^ (((iksword_t)(buf[3])) << 7)
    ^ (((iksword_t)(buf[2])) << 11);
  /* Make it positive. */
  return IK_FIX((H << 4) >> 4);
}
ikptr_t
ikrt_bignum_hash (ikptr_t bn /*, ikpcb_t* pcb */)
{
  ikptr_t	first_word	= IK_REF(bn, -vector_tag);
  ikuword_t	limb_count	= IK_BNFST_LIMB_COUNT(first_word);
  ikuword_t	H		= (ikuword_t)first_word;
  mp_limb_t *	dat		= (mp_limb_t*)(bn+off_bignum_data);
  for (ikuword_t i=0; i<limb_count; ++i) {
    H = (H^dat[i]) << 3;
  }
  /* Make it positive. */
  return IK_FIX((H << 4) >> 4);
}

/* end of file */
