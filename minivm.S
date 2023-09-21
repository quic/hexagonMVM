/*

Copyright (c) 2013, The Linux Foundation. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted (subject to the limitations in the
disclaimer below) provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the
      distribution.
    * Neither the name of the Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#define TLB_ENTRIES 64
#define TLB_TEMP_ENTRY 1
#define TLB_FIRST_REPLACEABLE_ENTRY 2
#define TLB_LAST_REPLACEABLE_ENTRY 63

#define EVENT_NUMBER_FATAL 1
#define EVENT_NUMBER_EXCEPTION 2
#define EVENT_NUMBER_TRAP0 5
#define EVENT_NUMBER_INTERRUPT 7

#define CONTEXT_tlb_r3130 0x00
#define CONTEXT_tlb_r2928 0x08
#define CONTEXT_tlb_r2322 0x10
#define CONTEXT_tlb_r2120 0x18
#define CONTEXT_r1514     0x20
#define CONTEXT_r1312     0x28
#define CONTEXT_r1110     0x30
#define CONTEXT_gsp       0x40
#define CONTEXT_gevb      0x44
#define CONTEXT_gptb      0x48
#define CONTEXT_g10       0x50
#define CONTEXT_g32       0x58
#define CONTEXT_ETAB      0x60
#define CONTEXT_RESET_VEC (CONTEXT_ETAB + 0)
#define CONTEXT_FATAL_VEC (CONTEXT_ETAB + 1*4)
#define CONTEXT_EXCEPTION_VEC (CONTEXT_ETAB + 2*4)
#define CONTEXT_TRAP0_VEC (CONTEXT_ETAB + 3*4)
#define CONTEXT_INTERRUPT_VEC (CONTEXT_ETAB + 5*4)

#define FAKE_GUEST_SUPERVISOR_BIT 13

#define CACHEIDX_MAX 2048

#define MAKEWORK(X) lo(X)

#define WAYS_MAX 16
#define SETS_MAX (((32*1024)/32)/(WAYS_MAX))

	.section .vm_data,"awx",@progbits
	.global MINIVM_event_vectors
	.type	MINIVM_event_vectors, @function
	.p2align 14

        .global start
        .global _start
start:
_start:
MINIVM_event_vectors:
	jump vm_bootup_code
	jump MINIVM_handle_nmi
	jump MINIVM_handle_error
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_tlbmissx
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_tlbmissrw
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_trap0
	jump MINIVM_handle_trap1
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_rsvd
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int
	jump MINIVM_handle_int /* 31 */
	.size	MINIVM_event_vectors, .-MINIVM_event_vectors

#define GUEST_CAUSE_UM_BIT 31
#define GUEST_CAUSE_IE_BIT 30

/*
 * Page Table Format
 * 
 * L1: PPPP PPPP PPPP PPPP PPPP ... SSS
 * 
 * L2: PPPP PPPP PPPP PPPP PPPP ...
 * 
 * V2/V3 User/Supervisor Strategy:
 * MSB of ASID is used for User/Supervisor.
 * Look up the same page table set, but if the Supervisor bit is 
 * set and the MSB of ASID is not set, we get a Permissions Error 
 * instead of a fill.
 * 
 */

	.global MINIVM_handle_tlbmissx
MINIVM_handle_tlbmissx:
	crswap(r24,sgp)
	{
		memd(r24+#CONTEXT_tlb_r3130) = r31:30
		r31 = p3:0
		p3 = cmp.eq(r31,r31)	// set p3 to TRUE
	}
	r30 = ssr
	r30 = zxtb(r30)
	{
		p0 = cmp.eq(r30,#1)
		p1 = cmp.eq(r30,#2)
		if (p1.new) jump:nt 1f	// icinva.. badaddr in badva already
		if (p1.new) r30 = memw(r24+#CONTEXT_gptb)
	}
	r30 = elr
	if (p0) r30 = add(r30,#12)
	badva0 = r30 // TODO: badva0 or badva1?
	{
		jump 1f
		r30 = memw(r24+#CONTEXT_gptb)
	}
	.size MINIVM_handle_tlbmissx, .-MINIVM_handle_tlbmissx

	.global MINIVM_handle_tlbmissrw
MINIVM_handle_tlbmissrw:
	crswap(r24,sgp)
	{
		memd(r24+#CONTEXT_tlb_r3130) = r31:30
		r31 = p3:0
		r30 = memw(r24+#CONTEXT_gptb)
		p3 = cmp.gtu(r31,r31)		// set p3 to FALSE
	}
1:
	/* BADVA has the address to look up */
	/* r31:30 are saved */
	/* r31 is saved predicates */
	/* r30 set to gptb */
	/* P3 set if X permission */
	{
		memd(r24+#CONTEXT_tlb_r2928) = r29:28
		r29.h = #hi(0x300fffe0)			// valid global 0xfffe0000
	}
	{
		memd(r24+#CONTEXT_tlb_r2322) = r23:22
		r29.l = #lo(0x300fffe0)
		r28 = lsr(r30,#12)			// PPN
		r23 = #(0x002+(7<<6))			// no perm, ccc=7, pgsize=64k
	}
	{
		r28 |= asl(r23,#20)			// OR in bits
		r23 = #TLB_TEMP_ENTRY
		r30.h = #0xfffe				// replace upper bits
		r22 = #MAKEWORK(MINIVM_lock)
	}
	{
		memd(r24+#CONTEXT_tlb_r2120) = r21:20
		r21 = #1
	}
1:
	r20 = memw_locked(r22)
	{
		p0 = cmp.eq(r20,#0)			// lock not available
		if (!p0.new) jump:nt 1b			// spin
	}
	memw_locked(r22,p0) = r21			// write 1
	if (!p0) jump 1b
	r3 = r23
	r5 = r29
	r4 = r28
	tlbw(r5:4, r3)
	r29 = ssr
	r28 = badva
	{
		p2 = tstbit(r29,#FAKE_GUEST_SUPERVISOR_BIT)
		r30 = tableidxw(r28,#10,#22)		// l1 page entry addr
	}
	{
		r30 = memw(r30)				// get L1 page entry
		r29 = extractu(r29,#6,#8)		// get ASID
		r20 = #0
		r23 = #10
	}
	/* r30 has L1 entry */
	/* r30[2:0] == 0: ptr to 1024 4k translations, 4k aligned L2 PT */
	/* r30[2:0] == 1: ptr to 256 16k translations, 1k aligned L2 PT */
	/* r30[2:0] == 2: ptr to 64  64k translations, 256b aligned L2 PT */
	/* r30[2:0] == 3: ptr to 16 256k translations, 64b aligned L2 PT */
	/* r30[2:0] == 4: ptr to 4 1024k translations, 16b aligned L2 PT */
	/* r30[2:0] == 5: 4MB translation */
	/* r30[2:0] == 6: 16MB translation */
	/* r30[2:0] == 7: INVALID */
	/* Let's split up into two halves... */
	/* For L1 direct translations, save off the L1 entry and jump to appropriate code */
	/* Otherwise, we want to extract 10-(2*SSS) bits from badva at offset 12+(2*SSS) 
	 * and insert them at offset 2 of the (L1 entry & -16) ... */
	/* Note: TLBHI should already be 0x300fffe0, tlbidx==1 */
	{
		p1 = tstbit(r30,#5)		// U bit
		r20 = insert(r30,#3,#1)		// LSB field * 2 (size)
		r29 = add(r29,#0x200)		// set valid
		r30 = and(r30,#-16)		// clear LSB field (size) + rsvd bit
	}
	{
		p0 = cmp.gt(r20,#4*2)		// L1 entry or invalid?
		if (!p0.new) r23 = sub(r23,r20)		// width
		if (!p0.new) r22 = add(r20,#12)		// offset
	}
	{
		if (p0) jump 6f			// L1 entry is sufficient... 
		r21 = extractu(r28,r23:22)	// extract right number of bits...
		if (!p0) r22 = #2
		if (p0) r22 = r23		// dup l1
	}
	{
		r30 = insert(r21,r23:22)	// insert them at offset 2 (word)
		r23 = #(0x002+(7<<6))		// no perm, ccc=7, pgsize=64k
		r29:28 = lsr(r29:28,#12)	// tlbhi in r28
	}
	r21 = lsr(r30,#12)			// ppn
	{
		r21 |= asl(r23,#20)		// bits
		r30.h = #0xfffe			// form l2 vaddr
	}
	r4 = r21
	//  TLBHI still had the same value from previous tlbw (r30.h = 0xfffe)
	tlbw(r5:4, r3)
	{
		r30 = memw(r30)			// L2 entry
		r23 = #0x0e00			// mask to check RWX
	}
	{
		r30 = tableidxb(r20,#5,#1)	// r20 >> 1 == size, clear bits 3,4; no T in v2 */
		p0 = bitsclr(r30,r23)
	}
	{
		if (p0) jump MINIVM_pagefault	// no RWX bits, so pagefault
		p1 = tstbit(r30,#5)		// U bit set?
		r21:20 = combine(r30,r30)
		r22 = #MAKEWORK(MINIVM_tlbidx)
	}
	{
		p1 = or(p2,p1)			// Supervisor Mode, or User and User?
		if (!p1.new) jump:nt MINIVM_nouser	// No, User permission violation
		r30 = memw(r22)			// get index
	}
1:
	// r21:20 has duplicate PTE
	// R28 has tlbhi
	{
		r21:20 = lsr(r21:20,#12)	// tlblo in r20
		p1 = cmp.gt(r30,#TLB_LAST_REPLACEABLE_ENTRY-1)
	}
	r5 = r28
	r21 = tlbp(r5)
	{
		p0 = tstbit(r21,#31)
		if (!p0.new) jump:nt 2f		// replaced while spinlocking, skip write
		if (!p1) r21 = add(r30,#1)
		if (p1) r21 = #TLB_FIRST_REPLACEABLE_ENTRY
	}
	{
		memw(r22) = r21			// save new index
	}
	r4 = r20
	tlbw(r5:4, r21)
2:
	{
		r30 = #MAKEWORK(MINIVM_lock)
		r29 = #0
	}
	memw(r30) = r29
	{
		p3:0 = r31
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
	}
	{
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
	}
	crswap(r24,sgp)
	rte


6:
	/* Just use the L1 entry */
	/* Also might be invalid... */
	/* r30 has the L1 entry with size masked off */
	/* r20 has 2*SSS */
	/* P1 has bit 5 == true (U) */
	/* On exit, r22 must hold MINIVM_tlbidx */
	{
		p0 = cmp.eq(r20,#0xe)
		if (p0.new) jump:nt MINIVM_pagefault	// SSS = 7
		r21 = #0x0e00
		p1 = or(p1,p2)			// Supervisor Mode, or User and User?
	}
	{
		p0 = bitsclr(r30,r21)
		if (p0.new) jump:nt MINIVM_pagefault	// no rwx bits
	}
	{
		if (!p1) jump MINIVM_nouser
		r30 = tableidxb(r20,#3,#1)		// reinsert SSS bits
		r22 = #MAKEWORK(MINIVM_tlbidx)
	}
	{
		r30 = memw(r22)
		r21:20 = combine(r30,r30)
		r29:28 = lsr(r29:28,#12)	// tlbhi in r28
		jump 1b
	}
	.size MINIVM_handle_tlbmissrw, .-MINIVM_handle_tlbmissrw


	.global MINIVM_pagefault
MINIVM_pagefault:
	/* p3:0 saved in r31 */
	/* r20-r23, r28-r31 saved in tlb locations */
	/* r24/sgp swapped */
	/* R28 has badva */
	/* R29 should have ASID */
	/* Detect if page fault was from VM (look @ ELR)... if so, fatal */
	/* P3 is TRUE if it was a TLB miss X */
	/* We signify page fault as either X, LD, or ST protection violation */
	/* We also need to unlock the tlb lock */
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r15 = r31
		r20 = #MAKEWORK(MINIVM_lock)
	}
	r14 = ssr
	{
		memd(r24+#CONTEXT_r1312) = r13:12
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
		r12 = mux(p3,#0x11,#0x22)
		r13 = zxtb(r14)
	}
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		if (!p3) r12 = add(r12,r13)		// add cause if LD/ST (0=LD, 1=ST)
	}
	{
		r14 = insert(r12,#8,#0)			// put CAUSE back into SSR
		r21 = #0
	}
	ssr = r14
	{
		memw(r20) = r21				// unlock
		r14 = #(EVENT_NUMBER_EXCEPTION*4)
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
		jump MINIVM_common_user_push
	}

	.global MINIVM_nouser
MINIVM_nouser:
	/* p3:0 saved in r31 */
	/* r20-r23, r28-r31 saved in tlb locations */
	/* r24/sgp swapped */
	/* R28 has badva */
	/* R29 should have ASID */
	/* Detect if page fault was from VM (look @ ELR)... if so, fatal */
	/* P3 is TRUE if it was a TLB miss X */
	/* We also need to unlock the tlb lock */
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r15 = r31
		r20 = #MAKEWORK(MINIVM_lock)
	}
	r14 = ssr
	{
		memd(r24+#CONTEXT_r1312) = r13:12
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
		r12 = mux(p3,#0x14,#0x24)
		r13 = zxtb(r14)
	}
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		if (!p3) r12 = add(r12,r13)		// add cause if LD/ST (0=LD, 1=ST)
	}
	{
		r14 = insert(r12,#8,#0)			// put CAUSE back into SSR
		r21 = #0
	}
	ssr = r14
	{
		memw(r20) = r21				// unlock
		r14 = #EVENT_NUMBER_EXCEPTION*4
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
		jump MINIVM_common_user_push
	}

MINIVM_handle_nmi:
MINIVM_handle_rsvd:
MINIVM_machine_check:
	crswap(r24,sgp)
	memd(r24+#CONTEXT_r1514) = r15:14
	memd(r24+#CONTEXT_r1312) = r13:12
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		r15 = p3:0
		r14 = #EVENT_NUMBER_FATAL*4
		jump MINIVM_common_user_push
	}

/* trap0 */
/* This will go back to Guest mode.  */
/* If user mode, get new SP from KSP */
/* Prepare for taking possible tlbmiss on stack pushes */
/* Set Guest OS Mode, push OLDSP, GELR, GCAUSE for quick retrieval */
/* Return to GEVB + XXX */

/* Stack: */
/* OLD_SP-> ???????? ???????? */
/*          BADVA    OLDSP    */
/* NEW_SP-> GCAUSE   GELR     */

/* SSR[18:0]: IE EX UM -- -- AS AS AS AS AS AS CC CC CC CC CC CC CC CC */
/* To switch to Supervisor ASID / DI / Supervisor Mode, insert 0 0 0 0 0 1 at bit 13 */

/* Shared Code */

	.global MINIVM_angel
MINIVM_angel:
	nop
	jump 1f

MINIVM_handle_trap0:
	crswap(r24,sgp)
	memd(r24+#CONTEXT_r1514) = r15:14
	memd(r24+#CONTEXT_r1312) = r13:12
	r12 = ssr
	r12 = and(r12,#255)
	r15 = p3:0
	p0 = cmp.eq(r12,#0)
	if (p0) jump MINIVM_angel
1:
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		//r15 = p3:0
		r14 = #EVENT_NUMBER_TRAP0*4
		jump MINIVM_common_user_push
	}

/* Common code to push stuff onto supervisor stack */
/* Assumes r10-r15 are saved, p3:0 in r15, r14 has event offset */
/* Takes info out of SSR, goes into supervisor mode */
/* Also: disables interrupts */

MINIVM_common_user_push:
	r10 = ssr
	r13 = badva
	{
		r12 = memw(r24+#CONTEXT_g32)				// osp
		p0 = tstbit(r10,#FAKE_GUEST_SUPERVISOR_BIT)
		p1 = tstbit(r10,#18)				// IE?
		r11 = #0x19  /* 0 1 1 0 0 1 */
	}
	{
		r11 = mux(p0,#0,#2)
		if (!p0) r29 = r12
		if (!p0) r12 = r29
		r10 = insert(r11,#6,#FAKE_GUEST_SUPERVISOR_BIT)
	}
	ssr = r10
	{
		if (p1) r10 = add(r11,#1)
		if (!p1) r10 = r11
		r11 = zxtb(r10)
		memd(r24+#CONTEXT_g32) = r13:12
	}
	{
		r11 = insert(r10,#2,#GUEST_CAUSE_IE_BIT)
		r12 = memw(r24+#CONTEXT_gevb)
	}
	r10 = elr
	{
		memd(r24+#CONTEXT_g10) = r11:10
		r10 = add(r14,r12)
		r13:12 = memd(r24+#CONTEXT_r1312)
	}
	elr = r10
	{
		p3:0 = r15
		r15:14 = memd(r24+#CONTEXT_r1514)
		r11:10 = memd(r24+#CONTEXT_r1110)
	}
	crswap(r24,sgp)
	rte

/* TRAP1 */
/* These are requests from the Guest to the VMM */
/* At least, they'd better be requests from the Guest... if they are user then we need
 * to ignore or error or something ... whatever the spec says to do
 */
/* Note that we've decided to have these not clobber any registers, except the return value. */

MINIVM_handle_trap1:
	crswap(r24,sgp)
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r15.h = #hi(MINIVM_trap1tab)
	}
	r14 = ssr
	{
		memd(r24+#CONTEXT_r1312) = r13:12
		r15.l = #lo(MINIVM_trap1tab)
		r12 = and(r14,#0x1f)			// if we align trap1tab we can use tableidx... comes out the same
		r13 = p3:0
	}
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		r12 = addasl(r15,r12,#2)
		p0 = tstbit(r14,#FAKE_GUEST_SUPERVISOR_BIT)
	}
	{
		r15 = r13
		if (p0) jumpr r12
	}
	// WE WERE IN USER MODE... 
	// Fallthrough: jump MINIVM_trap1_from_user
MINIVM_trap1_from_user:
MINIVM_trap1_done:
	{
		p3:0 = r15
		r15:14 = memd(r24+#CONTEXT_r1514)
	}
	{
		r13:12 = memd(r24+#CONTEXT_r1312)
		r11:10 = memd(r24+#CONTEXT_r1110)
	}
	crswap(r24,sgp)
	rte

MINIVM_trap1tab:
	jump MINIVM_trap1_done		// 0
	jump MINIVM_return		// 1
	jump MINIVM_setvec		// 2
	jump MINIVM_setie		// 3
	jump MINIVM_getie		// 4
	jump MINIVM_intop		// 5
	jump MINIVM_trap1_done		// 6
	jump MINIVM_trap1_done		// 7
	jump MINIVM_trap1_done		// 8
	jump MINIVM_trap1_done		// 9
	jump MINIVM_clrmap		// a
	jump MINIVM_register_ptb	// b
	jump MINIVM_trap1_done		// c
	jump MINIVM_cachectl		// d
	jump MINIVM_get_pcycles		// e
	jump MINIVM_set_pcycles		// f
	jump MINIVM_wait		// 10
	jump MINIVM_yield		// 11
	jump MINIVM_start		// 12
	jump MINIVM_stop		// 13
	jump MINIVM_vpid		// 14
	jump MINIVM_setregs		// 15
	jump MINIVM_getregs		// 16
	jump MINIVM_trap1_done		// 17
	jump MINIVM_trap1_done		// 18
	jump MINIVM_trap1_done		// 19
	jump MINIVM_trap1_done		// 1a
	jump MINIVM_trap1_done		// 1b
	jump MINIVM_trap1_done		// 1c
	jump MINIVM_trap1_done		// 1d
	jump MINIVM_trap1_done		// 1e
	jump MINIVM_trap1_dump		// 1f

	.size MINIVM_handle_trap1, .-MINIVM_handle_trap1

MINIVM_trap1_dump:
	r0 = s20 /* ipendad */
	r0 = extractu(r0, #16, #0)
	r1 = s20 /* ipendad */
	r1 = extractu(r1, #16, #16)
	r2 = imask
	r3 = iel
	r4 = iahl
	jump MINIVM_trap1_done


MINIVM_stop:
	stop(r0)
	nop
	nop

MINIVM_yield:
	jump MINIVM_trap1_done

MINIVM_vpid:	// return hw tnum
	r0 = ssr
	r0 = extractu(r0,#3,#19)
	jump MINIVM_trap1_done

MINIVM_setregs:	// set guest regs
	memd(r24+#CONTEXT_g10) = r1:0
	memd(r24+#CONTEXT_g32) = r3:2
	jump MINIVM_trap1_done

MINIVM_getregs:	// return guest regs
	r1:0 = memd(r24+#CONTEXT_g10)
	r3:2 = memd(r24+#CONTEXT_g32)
	jump MINIVM_trap1_done

MINIVM_wait:
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_start:
	// Start up new CPU!  Wohoo!
	r11 = modectl
	{
		r11 = ct1(r11)
		r10 = #lo(MINIVM_context_t1-MINIVM_context_t0)
	}
	{
		p0 = cmp.eq(r11,#6)
		if (p0.new) r0 = #-1
		if (p0.new) jump:nt MINIVM_trap1_done
		r12 = #lo(MINIVM_context_t0)
	}
	r12 += mpyi(r10,r11)
	{
		memw(r12+#0) = r0
		r10 = #0
	}
	{
		memw(r12+#4) = r1
		r10 = setbit(r10,r11)
	}
	memw(r12+#8) = r24
	start(r10)
	{
		r0 = r11
		jump MINIVM_trap1_done
	}


/* register new PTB 
 * Record the new location
 * Also, flush the TLB 
 * Make sure we get the lock
 */
	.global MINIVM_register_ptb
MINIVM_register_ptb:
	{
		memw(r24+#CONTEXT_gptb) = r0
		r10 = #TLB_FIRST_REPLACEABLE_ENTRY
		r13 = #0
		r12 = #MAKEWORK(MINIVM_lock)
	}
9:					// get lock
	r11 = memw_locked(r12)
	{
		p0 = cmp.eq(r11,#0)
		if (!p0.new) jump:nt 9b
	}
	memw_locked(r12,p0) = r12
	if (!p0) jump 9b
	r4 = r13
	r5 = r13
1:
	tlbw(r5:4, r10)
	{
		r10 = add(r10,#1)
		p0 = cmp.gt(r10,#TLB_LAST_REPLACEABLE_ENTRY-1)
		if (!p0.new) jump:t 1b
	}
	{
		memw(r12) = r13		// unlock
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_clrmap:
	{
		r0 = memw(r24+#CONTEXT_gptb)
		jump MINIVM_register_ptb // blow everything away for simplicity
	}

	.global MINIVM_get_pcycles
MINIVM_get_pcycles:
	r1 = PCYCLEHI
	r0 = PCYCLELO
	r10 = PCYCLEHI
	{
		p0 = cmp.eq(r1,r10)
		if (!p0.new) jump:nt MINIVM_get_pcycles
	}
	jump MINIVM_trap1_done

MINIVM_set_pcycles:
	PCYCLELO = r0
	PCYCLEHI = r1
	{
		r0 = #0
		jump MINIVM_trap1_done
	}


MINIVM_getie:
	r0 = ssr
	{
		r0 = extractu(r0,#1,#18)
		jump MINIVM_trap1_done
	}

MINIVM_setie:
	r10 = ssr
	{
		r1 = r10
		r10 = insert(r0,#1,#18)
	}
	ssr = r10
	{
		r0 = extractu(r1,#1,#18)
		jump MINIVM_trap1_done
	}


MINIVM_intop:
	{
		r10.h = #hi(MINIVM_intop_tab)
		r11 = #11
	}
	{
		r10.l = #lo(MINIVM_intop_tab)
		r11 = minu(r11,r0)
	}
	{
		r10 = addasl(r10,r11,#2)
	}
	jumpr r10

MINIVM_intop_tab:
	jump MINIVM_intop_nop
	jump MINIVM_intop_globen
	jump MINIVM_intop_globdis
	jump MINIVM_intop_locen
	jump MINIVM_intop_locdis
	jump MINIVM_intop_affinity
	jump MINIVM_intop_get
	jump MINIVM_intop_peek
	jump MINIVM_intop_status
	jump MINIVM_intop_post
	jump MINIVM_intop_clear
	jump MINIVM_intop_bad

MINIVM_intop_bad:
	r0 = #-1
	jump MINIVM_trap1_done

MINIVM_intop_nop:
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_intop_globen:
	/* ciad */
	r10 = #0
	r10 = setbit(r10,r1)
	r10 = brev(r10)
	ciad(r10)
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_intop_globdis:
	/* Can't do */
	r0 = #-1
	jump MINIVM_trap1_done

MINIVM_intop_locen:
	/* clrbit IMASK */
	r10 = imask
	r10 = brev(r10)
	r10 = clrbit(r10,r1)
	r10 = brev(r10)
	imask = r10
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_intop_locdis:
	/* setbit IMASK */
	r10 = imask
	r10 = brev(r10)
	r10 = setbit(r10,r1)
	r10 = brev(r10)
	imask = r10
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_intop_affinity:
	/* iassignw */
	r10 = #-1
	r10 = clrbit(r10,r2)
	r10 = combine(r1.l,r10.l)
	iassignw(r10)
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_intop_get:
	/* Hard to do... */
	r10 = #-1
	jump MINIVM_trap1_done

MINIVM_intop_peek:
	/* cl0 IPEND */
	r10 = s20 /* ipendad */
	r10 = extractu(r10, #16, #0) 
	r0 = cl0(r10)
	p0 = cmp.eq(r0,#32)
	if (p0) r0 = #-1
	jump MINIVM_trap1_done

MINIVM_intop_status:
	/* tstbit IPEND/IAD/IMASK */
	r13 = #1
	r12 = r1
	r11 = s20 /* ipendad */
	r11 = extractu(r11, #16, #16) 
	r10 = extractu(r11,r13:12)
	r11 = imask
	r11 = extractu(r11,r13:12)
	r10 = addasl(r11,r10,#1)
	r11 = s20 /* ipendad */
	r11 = extractu(r11, #16, #0) 
	r11 = extractu(r11,r13:12)
	r10 = addasl(r11,r10,#1)
	r11 = #6
	r0  = xor(r10,r11)	// imask/iad opposite sense from enable
	jump MINIVM_trap1_done

MINIVM_intop_post:
	/* swi */
	r10 = #0
	r10 = setbit(r10,r1)
	r10 = brev(r10)
	swi(r10)
	r0 = #0
	jump MINIVM_trap1_done

MINIVM_intop_clear:
	/* cswi */
	r10 = #0
	r10 = setbit(r10,r1)
	r10 = brev(r10)
	cswi(r10)
	r0 = #1
	jump MINIVM_trap1_done

MINIVM_setvec: // r0=vector address
	{
		memw(r24+#CONTEXT_gevb) = r0
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_cachectl:
	/* 
	 * r0: op enum { ICKILL, DCKILL, L2KILL, DCCLEANINVA, ICINVA, PASYNC, PF }
	 * r1: start VA
	 * r2: len
	 */
	{
		r10.h = #hi(9f)
		p0 = cmp.gtu(r0,#6)
		if (p0.new) r0 = #-1
	}
	{
		r10.l = #lo(9f)
		if (p0) jump MINIVM_trap1_done		// invalid type
	}
	{
		r10 = addasl(r10,r0,#2)
	}
	{
		jumpr r10
	}

	.p2align 3
9:
		jump 1f
		jump 2f
		jump MINIVM_trap1_done
		jump 2f
		jump 1f
		jump MINIVM_cachectl_pasync
		jump MINIVM_cachectl_pf
1:
	ickill
	{
		r0 = #0
		jump MINIVM_trap1_done
	}
	.falign
2:
	{
		r10 = #0
		r11 = #CACHEIDX_MAX
	}
8:
	dccleaninvidx(r10)
	{
		r10 = add(r10,#1)
		p0 = cmp.eq(r10,r11)
		if (!p0.new) jump:t 8b
	}
	{
		r0 = #0
		jump MINIVM_trap1_done
	}
3:
	l2kill					// possibly unsafe
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_cachectl_pf:
	r10 = ssr
	r10 = insert(r1,#3,#22)
	ssr = r10
	r0 = #0
	jump MINIVM_trap1_done

	/* r1 has Paddress, r2 has bytes */
	/* Lock TLB and use temp mapping */
MINIVM_cachectl_pasync:
	{
		loop1(11f,#WAYS_MAX)
		r10 = #-1
	}
	.falign
11:
	{
		loop0(12f,#SETS_MAX)
		r10 = add(r10,#1)
	}
	.falign
12:
	icinvidx(r10)
	{
		dccleanidx(r10)
		r10 = add(r10,#0x20)
	}:endloop0:endloop1
	{
		r0 = #0
		jump MINIVM_trap1_done
	}


/* RETURN
 * Guest regs hold values
 * restore regs and return
 * Note that ELR is now irrelevant
 * If going from supervisor->user, save kstack in GOSP
 * We won't need BADVA (r11?) from the stack
 */

	.falign
MINIVM_return:
	r14 = ssr
	{
		r12 = memw(r24+#CONTEXT_g32)		//r2: gosp
		r11:10 = memd(r24+#CONTEXT_g10)		//gssr:gelr
		r13 = #0x18				// -- EX UM -- -- --
	}
	{
		p0 = tstbit(r11,#GUEST_CAUSE_UM_BIT)
		p1 = tstbit(r11,#GUEST_CAUSE_IE_BIT)
		if (p1.new) r13 = #0x38			// IE EX UM -- -- --
	}
	{
		if (!p0) r13 = add(r13,#1)		// IE EX UM -- -- SU
		if (p0) memw(r24+#CONTEXT_g32) = r29	// user mode: switch stacks
		if (p0) r29 = r12
	}
	elr = r10
	{
		p3:0 = r15
		r14 = insert(r13,#6,#FAKE_GUEST_SUPERVISOR_BIT)
		r13:12 = memd(r24+#CONTEXT_r1312)
	}
	ssr = r14
	{
		r15:14 = memd(r24+#CONTEXT_r1514)
		r11:10 = memd(r24+#CONTEXT_r1110)
	}
	crswap(r24,sgp)
	rte

/* 
 * Handle Interrupt 
 * 
 * Two options here:
 * A) Save off enough registers to go to C, then go to C for 
 *    implementing the interrupt machine virtual model
 * B) Cheap & Easy: Just save off enough registers to do the
 *    interrupt work
 * 
 *    We can augment "Cheap & Easy" by actually having EI/DI 
 *    modify the IE bit...
 */

	.global MINIVM_handle_int
MINIVM_handle_int:
	crswap(r24,sgp)
	memd(r24+#CONTEXT_r1514) = r15:14
	memd(r24+#CONTEXT_r1312) = r13:12
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		r15 = p3:0
		r14 = #EVENT_NUMBER_INTERRUPT*4
		jump MINIVM_common_user_push
	}

/* 
 * Double exception!  That means a bug in the MINIVMM 
 * most likely... spin here to help debug
 */
MINIVM_double_exception:
1:
	jump 1b


/* 
 * Handle exception... 
 */
MINIVM_handle_error:
	crswap(r24,sgp)
	memd(r24+#CONTEXT_r1514) = r15:14
	r15 = ssr
	{
		memd(r24+#CONTEXT_r1312) = r13:12
		r15 = zxtb(r15)
	}
	{
		r15 = p3:0
		p3 = cmp.eq(r15,#0x29)
		p2 = cmp.eq(r15,#0x3)
	}
	{
		if (p2) jump MINIVM_double_exception
		if (p3) r14 = #EVENT_NUMBER_FATAL*4
		if (!p3) r14 = #EVENT_NUMBER_EXCEPTION*4
	}
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		jump MINIVM_common_user_push
	}

vm_newcpu_startup:
	// startup a new cpu
	// tnum in r11
	// form pointer myself
	// word @ ptr is elr
	// word @ ptr+4 is new sp
	// word @ ptr+8 is callee context block (inherit everything)
	r24.h = #hi(MINIVM_context_t0)
	r24.l = #lo(MINIVM_context_t0)
	r23 = #lo(MINIVM_context_t1-MINIVM_context_t0)
	r24 += mpyi(r23,r11)
	sgp = r24
	r31 = memw(r24+#0)
	r14 = memw(r24+#8)
	r11:10 = memd(r14+#0x40)
	{
		memd(r24+#0x40) = r11:10
		r11:10 = memd(r14+#0x48)
	}
	{
		memd(r24+#0x48) = r11:10
		r11:10 = memd(r14+#0x50)
	}
	{
		memd(r24+#0x50) = r11:10
		r11:10 = memd(r14+#0x58)
	}
	{
		memd(r24+#0x58) = r11:10
		r11:10 = memd(r14+#0x60)
	}
	{
		memd(r24+#0x60) = r11:10
		r11:10 = memd(r14+#0x68)
	}
	{
		memd(r24+#0x68) = r11:10
		r11:10 = memd(r14+#0x70)
	}
	{
		memd(r24+#0x70) = r11:10
		r11:10 = memd(r14+#0x78)
	}
	memd(r24+#0x70) = r11:10
	r29 = memw(r24+#4)
	r0 = ssr
	r1 = extractu(r0,#3,#19)
	r0 = insert(r1,#3,#8)		// ASID per-thread bits
	r1 = #3
	r0 = insert(r1,#3,#16)		// EX/UM
	r0 = setbit(r0,#FAKE_GUEST_SUPERVISOR_BIT)
	ssr = r0

	// Mask all interrupts
	r0.h = #hi(0xFFFFFFFF)
	r0.l = #lo(0xFFFFFFFF)
	imask = r0

	elr = r31
	rte

vm_bootup_code:
	r10 = pc
	r11 = ssr
	r11 = extractu(r11,#3,#19)
	p0 = cmp.eq(r11,#0)
	if (!p0) jump vm_newcpu_startup
	
	/* Disabled the CLK Gating */
	r0.h = #0x0040
	r0.l = #0x0000
	s60 = r0 
 
 	r0.h = #0xd013
 	r0.l = #0xd013
 	s61 = r0
 	
 	r0.h = #0x0002
 	r0.l = #0x0d01
 	s62 = r0
 
 	r0.h = #0x0000
	r0.l = #0x0010
#if __HEXAGON_ARCH__ == 2
	r0.l = #0x0000
	r10 = setbit(r10,#10)	// disable same-line detection in iu
#endif
	s63 = r0

	// Mask all interrupts
	r0.h = #hi(0xFFFFFFFF)
	r0.l = #lo(0xFFFFFFFF)
	imask = r0

 	//  Clear pending interrupts and lingering IAD
	cswi(r0)
	ciad(r0);

	r0 = #0x78
	syscfg = r0
	isync
	nop
	nop
	brkpt
	nop
	nop
	ickill
	dckill
	l2kill

1:
	r0 = #0x7e
	syscfg = r0
	isync
	r0 = #-1
	iahl = r0

	iel = r0
	r0 = #-1
	{
		r9.h = #hi(MINIVM_event_vectors)
		r11.h = #hi(initial_pt-vm_bootup_code)
		r15 = #0
	}
	{
		r9.l = #lo(MINIVM_event_vectors)
		r11.l = #lo(initial_pt-vm_bootup_code)
		loop0(1f,#TLB_ENTRIES)
	}
	r12 = add(r10,r11)		// initial PT PA
	evb = r9
	r5 = r15
	r4 = r15
1:
	// clear TLB
	tlbw(r5:4, r15)
	{
		r15 = add(r15,#1)
	}:endloop0
	// Add Mini VM entry
	{
		r15 = #0
		r14.h = #hi(0x300ffff0)
		r13 = lsr(r10,#12)
#if __HEXAGON_ARCH__ == 2
		r11 = #0x1c2	// ccc=7, 64K
#else				// elif V3
		r11 = #0x9c2	// ccc=7, 64K,  X on for V3 bug
#endif
	}
	{
		r13 |= asl(r11,#20)
		r14.l = #lo(0x300ffff0)
	}
	r5 = r14
	r4 = r13
	tlbw(r5:4, r15)

	// Add temp. guest translation
	r15 = #1
	r14.h = #hi(0x30000000 | (GUEST_ENTRY >> 12))
	r14.l = #lo(0x30000000 | (GUEST_ENTRY >> 12))
	r11 = #0xec6		// ccc=7, 16MB, X on for V3 bug

	r13.h = #hi(GUEST_ENTRY >> 12)
	r13.l = #lo(GUEST_ENTRY >> 12)
	r13 |= asl(r11,#20)

	r5 = r14
	r4 = r13
	tlbw(r5:4, r15)

	// Add temporary entry
	r15 = #3
	r3 = r15
	r14 = lsr(r10,#12)
	r14 |= asl(r15,#28)
#if __HEXAGON_ARCH__ == 2
	r11 = #0x1c2		// ccc=7, 64K
#else				// elif V3
        r11 = #0x9c2		// ccc=7, 64K, X on for V3 bug
#endif
	r13 = lsr(r10,#12)
	r13 |= asl(r11,#20)
	r5 = r14
	r4 = r13
	tlbw(r5:4, r3)

	r0 = #0x7f
	r0.h = #0x3			//  l2 cache 256kB
	syscfg = r0

	r0 = #1				// turn on isdb
	isync
	r1.h = #hi(1f)
	r1.l = #lo(1f)
	jumpr r1			// jump to virtual space
1:
	r15 = #0
	r5:4 = #0
	tlbw(r5:4, r3)				// clear out tmp mapping

	r7.h = #hi(MINIVM_context_t0)
	r7.l = #lo(MINIVM_context_t0)
	memw(r7+#CONTEXT_gptb) = r12	// set initial page table
	r2 = #-1
	sgp = r7
	r8 = #MAKEWORK(MINIVM_tlbidx)
	r6 = #TLB_FIRST_REPLACEABLE_ENTRY
	memw(r8) = r6

	r0 = ssr
	r1 = #3
	r0 = insert(r1,#3,#16)
	r0 = setbit(r0,#FAKE_GUEST_SUPERVISOR_BIT)
	ssr = r0

	// Set return point to guest entry
	r31.h = #hi(GUEST_ENTRY)
	r31.l = #lo(GUEST_ENTRY)

	elr =  r31
	rte

	.p2align 3
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0

#define XLAT16M(VAL) .word (VAL | 6); \
	.word (VAL | 6); \
	.word (VAL | 6); \
	.word (VAL | 6); 

#define XLAT64M(VAL) XLAT16M(VAL) \
	XLAT16M(VAL | 0x01000000) \
	XLAT16M(VAL | 0x02000000) \
	XLAT16M(VAL | 0x03000000)

#define XLAT256M(VAL) XLAT64M(VAL) \
	XLAT64M(VAL | 0x04000000) \
	XLAT64M(VAL | 0x08000000) \
	XLAT64M(VAL | 0x0c000000)

	.p2align 12
initial_pt:
	XLAT256M(0x00000fc0)
	XLAT256M(0x10000fc0)
	XLAT256M(0x20000fc0)
	XLAT256M(0x30000fc0)
	XLAT256M(0x40000fc0)
	XLAT256M(0x50000fc0)
	XLAT256M(0x60000fc0)
	XLAT256M(0x70000fc0)
	XLAT256M(0x80000fc0)
	XLAT256M(0x90000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)


	// Should be 0xffff8000 or higher

	.p2align 15
MINIVM_context_t0:
	.word 0,0,0,0,0,0,0,0 // 00-1f
	.word 0,0,0,0,0,0,0,0 // 20-3f
	.word 0,0,0,0,0,0,0,0 // 40-5f
	.word 0,0,0,0,0,0,0,0 // 60-7f
	.word 0,0,0,0,0,0,0,0 // 80-9f
	.word 0,0,0,0,0,0,0,0 // a0-bf
MINIVM_context_t1:
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
MINIVM_context_t2:
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
MINIVM_context_t3:
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
MINIVM_context_t4:
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
MINIVM_context_t5:
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0
	.word 0,0,0,0,0,0,0,0

MINIVM_lock:
	.word 0

MINIVM_tlbidx:
	.word 0

