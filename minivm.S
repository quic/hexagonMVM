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


/* V3 ONLY */

// #define PREFETCH_SETTINGS 0
#define PREFETCH_SETTINGS 7

#define TLB_ENTRIES 64
#define TLB_FIRST_REPLACEABLE_ENTRY 3
#define TLB_LAST_REPLACEABLE_ENTRY 63
#define TLB_STLB_ADDR 0xc0000000

#define EVENT_NUMBER_EXCEPTION 2
#define EVENT_NUMBER_TRAP0 8
#define EVENT_NUMBER_INTERRUPT 15

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
#define CONTEXT_ETAB      0x50
#define CONTEXT_RESET_VEC (CONTEXT_ETAB + 0)
#define CONTEXT_FATAL_VEC (CONTEXT_ETAB + 1*4)
#define CONTEXT_EXCEPTION_VEC (CONTEXT_ETAB + 2*4)
#define CONTEXT_TRAP0_VEC (CONTEXT_ETAB + 3*4)
#define CONTEXT_INTERRUPT_VEC (CONTEXT_ETAB + 5*4)
#define CONTEXT_tlb_hashtab   0x70
#define CONTEXT_tlb_check   0x78

#define FAKE_GUEST_SUPERVISOR_BIT 13

#define CACHEIDX_MAX 2048

#define WAYS_MAX 16
#define SETS_MAX (((32*1024)/32)/(WAYS_MAX))

#define PAGE_BITS 12
/* OPTIMIZE FOR 64K PAGES */

/* 4096 entries * 8 bytes * 6 threads == 192KB */

#define HASH_BITS 12
#define HASH_OFF 12


#define MAKEWORK(X) lo(X)

#define USE_STLB 1
#define SETUP_STLB 1

#if 0
#define TLB_CHECK(X) X
#define TLB_NOCHECK(X)
#else
#define TLB_CHECK(X) 
#define TLB_NOCHECK(X) X
#endif

#if 1
#define YES_STLB(X) X
#define NO_STLB(X) 
#define UPDATE_STLB(X) X
#else
#define YES_STLB(X) 
#define NO_STLB(X) X
#define UPDATE_STLB(X) 
#endif




	.section .vm_data,"awx",@progbits
	.global MINIVM_event_vectors
	.type	MINIVM_event_vectors, @function
	.p2align 14
MINIVM_event_vectors:
	jump vm_bootup_code
	jump MINIVM_handle_nmi
	jump MINIVM_handle_error
	jump MINIVM_handle_rsvd
	{
#if USE_STLB
		jump MINIVM_handle_tlbmissx_stlb
#else
		jump MINIVM_handle_tlbmissx
#endif
		crswap(r24,sgp)
	}
	{
#if USE_STLB
		jump MINIVM_handle_tlbmissrw_stlb
#else
		jump MINIVM_handle_tlbmissrw
#endif
		crswap(r24,sgp)
	}
	jump MINIVM_handle_trap0
	jump MINIVM_handle_trap1
	jump MINIVM_handle_rsvd /* 10 */
        jump MINIVM_handle_rsvd /* 11 */
        jump MINIVM_handle_rsvd /* 12 */
        jump MINIVM_handle_rsvd /* 13 */
        jump MINIVM_handle_rsvd /* 14 */
        jump MINIVM_handle_rsvd /* 15 */
        jump MINIVM_handle_int  /* 0 */
        jump MINIVM_handle_int
        jump MINIVM_handle_int
        jump MINIVM_handle_int 
        jump MINIVM_handle_int  // 4
        jump MINIVM_handle_int // 5
        jump MINIVM_handle_int // 6
        jump MINIVM_handle_int // 7
        jump MINIVM_handle_int // 8
        jump MINIVM_handle_int // 9
        jump MINIVM_handle_int /* 10? */
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



#if USE_STLB


	.p2align 5					// align on cache line
MINIVM_handle_tlbmissx_stlb:
	TLB_CHECK(memd(r24+#CONTEXT_tlb_check) = r1:0)
	{
		memd(r24+#CONTEXT_tlb_r3130) = r31:30
		r31 = ssr
		r30 = #0x2000				// Guest bit
	}
	{
		memd(r24+#CONTEXT_tlb_r2928) = r29:28
		r29 = p3:0
		r31 = or(r31,#0x80)			// set CAUSE bit for pagefault/nouser
		r28 = and(r31,#0x0f)
	}
	{
		memd(r24+#CONTEXT_tlb_r2322) = r23:22
		p0 = cmp.eq(r28,#2)			// icinva?
		r31 = clrbit(r31,#16)			// clear UM bit, we know EX is set
		ssr = r31				// set CAUSE for later
	}
	{
		p1 = cmp.eq(r28,#1)			// next page?
		r28 = and(r30,r31)			// Isolate guest bit
		if (p0) jump 1f				// icinva
		r30 = elr				// ELR overwritten at 1f
	}
	{
		r23:22 = memd(r24+#CONTEXT_tlb_hashtab)
		r31 = extractu(r31,#10,#8)		// get ASID + EX bit which becomes valid
		if (p1) r30 = add(r30,#16)		// adjust for next page
		//jump 2f					// join for non-icinva
	}
	//  workaround for possible hardware bug with page straddling tlb miss x
	{
		memd(r24+#CONTEXT_tlb_r2120) = r31:30
		r31:30 = lsr(r31:30,#PAGE_BITS)
	}
	tlbhi = r30
	tlbp
	r30 = tlbidx
	{
		p0 = tstbit(r30,#31)
		if (p0.new) r31:30 = memd(r24+#CONTEXT_tlb_r2120)
		if (p0.new) jump:t 2f
	}
	.global MINIVM_TLBMISS_BUG
MINIVM_TLBMISS_BUG:
	/* Return */
	{
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
	}
	{
		crswap(r24,sgp)
		rteunlock // we expect to get an exception again
	}


	.p2align 5					// align on cache line
MINIVM_handle_tlbmissrw_stlb:
	TLB_CHECK(memd(r24+#CONTEXT_tlb_check) = r1:0)
	{
		memd(r24+#CONTEXT_tlb_r3130) = r31:30
		r31 = ssr
		r30 = #0x2000
		nop					// for alignment
	}
	{
		memd(r24+#CONTEXT_tlb_r2928) = r29:28
		r29 = p3:0
		r28 = and(r30,r31)			// isolate guest bit
		r31 = clrbit(r31,#16)			// clear UM bit, we know EX is set
	}
1:
	{
		memd(r24+#CONTEXT_tlb_r2322) = r23:22
		r31 = extractu(r31,#10,#8)		// get asid + EX bit which becomes valid
		r30 = badva
		r23:22 = memd(r24+#CONTEXT_tlb_hashtab)
	}
2:
	{
		memd(r24+#CONTEXT_tlb_r2120) = r21:20
		p3 = cmp.gtu(r28,#0)			// in guest mode?
		r31:30 = lsr(r31:30,#PAGE_BITS)		// form tlbhi
		r23 = tableidxd(r30,#HASH_BITS,#HASH_OFF)
	}
	{
		r21:20 = memd(r23)
		
		r22 = tableidxw(r30,#HASH_BITS-5,#5+(HASH_OFF-PAGE_BITS))
		tlbhi = r30
		r31 = #-1<<(HASH_OFF-PAGE_BITS)
	}
	/* Variable page sizes: */
	/* Only insert pages of our favored hash size or larger */
	/* tmp=xor(test,cache) will yield zero for all high bits that are zero */
	/* and (tmp,#-1<<(HASH_OFF-PAGE_BITS)) will mask off lsbs */
	/* compare for equal */
	/* No X units! */
	{
		r31 -= asl(r28,#12)			// If supervisor, user pages ok -- clear mask bit
		tlblo = r20
		r21 = xor(r21,r30)			// find different bits
	}
	// EJP: FIXME: Does this work? r28 = tableidxh(r20,#3,#20)
	{
		r21 = and(r21,r31)			// mask off don't care bits -- maybe supervisor + lsbs
		r28 = #MAKEWORK(MINIVM_tlbidx)
		r22 = memw(r22)				// read valid bits
		r31 = extractu(r30,#5,#(HASH_OFF-PAGE_BITS))
	}
	{
		r20 = memw(r28)
		YES_STLB(p0 = cmp.eq(r21,#0))
		NO_STLB(p0 = cmp.gtu(r21,r21))
		p1 = tstbit(r22,r31)
		if (!p0.new) jump:nt MINIVM_stlb_invalid
	}
	{
		if (!p1) jump MINIVM_stlb_invalid
		if (p1) r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		if (p1) r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		tlbidx = r20
	}
	.global MINIVM_hit
MINIVM_hit:
	{
		tlbw
		p2 = cmp.gtu(r20,#TLB_LAST_REPLACEABLE_ENTRY-1)
		if (p2.new) r20 = #TLB_FIRST_REPLACEABLE_ENTRY
		if (!p2.new) r20 = add(r20,#1)
	}
	{
		memw(r28) = r20
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
		p3:0 = r29
	}
	{
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
	}
	{
		crswap(r24,sgp)
		rteunlock
	}
	
	/* Oh, dear.  Our STLB didn't work this time. */
	/* Look up through the page tables, insert into the TLB */
	/* TLBLOCK is set. */
	/* r30 has a TLBHI: V|(asid)|(badva>>12) */
	/* r24 has context pointer (sgp swapped) */
	/* r28 has tlbidx */
	/* R20,21,22,23,28,29,30,31 are saved */
	/* p3:0 in r29 */
	/* full badaddr not in badva (for X miss) */
	/* SSR unmodified */
	/* P3 is true if in guest mode */
	/* Remember that TLBIDX is postincrement */
MINIVM_stlb_invalid:
	{
		r20 = memw(r24+#CONTEXT_gptb)
		r21 = #0x1c2
		r22.h = #hi(0x300fffe0)		// tlbhi = 0x300fffe0 
		r23 = #1			// tlbidx = 1
	}
	{
		r21:20 = lsr(r21:20,#12)	// form tlblo in r20
		r22.l = #lo(0x300fffe0)
		tlbidx = r23
		r23 = r20			// Keep ptb
	}
	{
		r23.h = #0xfffe
		tlblo = r20
		r28 = r30
	}
	{
		r23 = tableidxw(r28,#10,#10)	// form va to read from
		tlbhi = r22
	}
	{
		tlbw
		r20 = #0
	}
	{
		r22 = memw(r23)			// read L1 PTE
		r23 = #0x1c2			// 64K xlation
	}
	{
		r31:30 = lsr(r23:22,#12)	// form tlblo
		r20 = insert(r22,#3,#1)		// LSB field * 2 (size)
		
		r23 = and(r22,#~0x007)		// clear LSBs
	}
	{
		p0 = cmp.gt(r20,#4*2)		// 4MB, 16MB, or Invalid
		r21 = sub(#10,r20)		// l2 insert width
		tlblo = r30
		r30 = r22			// save L1 entry in r30
	}
	{
		p0 = cmp.eq(r20,#0xe)		// invalid?
		if (p0) jump MINIVM_tlbmiss_l1OK // L1 page
		r31 = extractu(r28,r21:20)	// read out l2 index bits
		r23.h = #0xfffe
	}
	{
		tlbw
		r22 = addasl(r23,r31,#2)	// form read address
		r21 = #0x0e00
		r23 = #MAKEWORK(MINIVM_tlbidx)
	}
	{
		p2 = cmp.ge(r20,#(HASH_OFF-PAGE_BITS))	// Do we have a large enough page?
		r22 = memw(r22)			// read l2 PT
		tlbhi = r28
	}
	{ // XX
		r22 = tableidxb(r20,#5,#1)	// LSB field * 2 / 2 + clear 3,4
		p0 = bitsclr(r22,r21)		// any perms?
		r21:20 = memd(r24+#CONTEXT_tlb_hashtab)
	}
	{ // XX
		r22 = memw(r23)			// get TLBIDX
		if (!p0) r31:30 = combine(r22,r22)
		if (p0) jump MINIVM_pagefault_stlb
		p1 = tstbit(r22,#5)		// U bit set?
	}
	{ // XX
		p0 = cmp.gtu(r22,#TLB_LAST_REPLACEABLE_ENTRY-1)
		r31:30 = lsr(r31:30,#12)
		p1 = or(p1,p3)			// Supervisor mode or User bit set?
	}
	{
		if (!p1) jump MINIVM_nouser_stlb	// Permission violation
		if (p0) r22 = #TLB_FIRST_REPLACEABLE_ENTRY
		if (!p0) r22 = add(r22,#1)
		tlbidx = r22
	}
	{
		memw(r23) = r22				// write new tlbidx
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)	// restore r23:22
		tlblo = r30
		r21 = tableidxd(r28,#HASH_BITS,#HASH_OFF-PAGE_BITS)
	}
	{
		r31:30 = combine(r28,r30)		// form tlbhi:tlblo
		r20 = tableidxw(r28,#HASH_BITS-5,#5+(HASH_OFF-PAGE_BITS))
		
		TLB_NOCHECK(tlbw)
	}
	{
		UPDATE_STLB(if (p2) memd(r21) = r31:30)			// save entry
		r21 = memw(r20)				// load valid bits
		TLB_CHECK(r1:0 = r31:30)
		r28 = extractu(r28,#5,#HASH_OFF-PAGE_BITS)
	}
	{
		r21 = setbit(r21,r28)			// set valid bit
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)	// restore
	}
	UPDATE_STLB(if (p2) memw(r20) = r21)				// save valid bit
	{
		p3:0 = r29				// restore preds
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)	// restore
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)	// restore
	}
	{
		TLB_NOCHECK(crswap(r24,sgp))
		TLB_NOCHECK(rteunlock)
	}
#if 0
	memd(r24+#CONTEXT_tlb_r3130) = r31:30
	r30 = ssr
	r31 = p3:0
	p0 = tstbit(r30,#7)
	r30 = clrbit(r30,#7)
	ssr = r30
	{
		p3:0 = r31
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		if (!p0) jump MINIVM_handle_tlbmissrw
	}
	jump MINIVM_handle_tlbmissx
#endif

	.falign
MINIVM_tlbmiss_l1OK:
	/* Just use the L1 entry */
	/* Also might be invalid... */
	/* r30 has the L1 entry with size masked off */
	/* r28 has a tlbhi */
	/* r20 has 2*SSS */
	/* P3 set if !supervisor */
	/* P0 set if invalid SSS field */
	{
		if (p0) jump MINIVM_pagefault_stlb	// SSS = 7
		r21 = #0x0e00
		p1 = tstbit(r30,#5)
		r22 = #MAKEWORK(MINIVM_tlbidx)
	}
	{
		r30 = memw(r22)		// read tlbidx
		r21:20 = combine(r30,r30)
		p0 = bitsclr(r30,r21)
		if (p0.new) jump:nt MINIVM_pagefault_stlb	// no rwx bits
	}
	{
		p1 = or(p1,p3)
		if (!p1.new) jump:nt MINIVM_nouser_stlb
		p0 = cmp.gtu(r30,#TLB_LAST_REPLACEABLE_ENTRY-1)
	}
	{
		r21:20 = lsr(r21:20,#12)
		if (!p0) r30 = add(r30,#1)
		if (p0) r30 = #TLB_FIRST_REPLACEABLE_ENTRY
		tlbidx = r30			// yes, we want old value
	}
	{
		memw(r22) = r30			// save tlbidx
		tlblo = r20
	}
	TLB_CHECK(r1:0 = combine(r28,r20))
	{
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)	// last reg restore
		r31 = r29			// move out of the way
		tlbhi = r28
	}
	{
		
		TLB_NOCHECK(tlbw)
	}
	{
		p3:0 = r31			// restore preds
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
	}
	{
		TLB_NOCHECK(crswap(r24,sgp))
		TLB_NOCHECK(rteunlock)
	}


#if 0
	memd(r24+#CONTEXT_tlb_r3130) = r31:30
	r30 = ssr
	r31 = p3:0
	p0 = tstbit(r30,#7)
	r30 = clrbit(r30,#7)
	ssr = r30
	{
		p3:0 = r31
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		if (!p0) jump MINIVM_handle_tlbmissrw
	}
	jump MINIVM_handle_tlbmissx
#endif

	.size MINIVM_handle_tlbmissrw, .-MINIVM_handle_tlbmissrw
	

MINIVM_pagefault_stlb:
	/* P3:0 saved in r29 */
	/* r20-23,r28-31 saved in TLB locations */
	/* R24/sgp swapped */
	/* R28 has a tlbidx, including VPN */
	/* TLB locked */
	/* SSR.CAUSE has bit 7 set if TLBMISSX */
	tlbunlock
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r14 = ssr
		r15 = asl(r28,#12)
	}
	{
		memd(r24+#CONTEXT_r1312) = r13:12
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		p0 = tstbit(r14,#7)
		r13 = and(r14,#0x1f)
	}
	{
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
		memd(r24+#CONTEXT_r1110) = r11:10
		r12 = mux(p0,#0x11,#0x22)
		if (!p0) jump 1f
	}
	badva = r15	// write ELR-->badva
1:
	{
		if (!p0) r12 = add(r12,r13)
	}
	{
		r14 = insert(r12,#8,#0)
		r15 = r29				// copy over preds
	}
	{
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
		r14 = #CONTEXT_EXCEPTION_VEC
		ssr = r14
		jump MINIVM_common_user_push
	}

MINIVM_nouser_stlb:
	/* P3:0 saved in r29 */
	/* r20-23,r28-31 saved in TLB locations */
	/* R24/sgp swapped */
	/* R28 has a tlbidx, including VPN */
	/* TLB locked */
	/* SSR.CAUSE has bit 7 set if TLBMISSX */
	tlbunlock
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r14 = ssr
		r15 = lsr(r28,#12)
	}
	{
		memd(r24+#CONTEXT_r1312) = r13:12
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		p0 = tstbit(r14,#7)
		r13 = and(r14,#0x1f)
	}
	{
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
		memd(r24+#CONTEXT_r1110) = r11:10
		r12 = mux(p0,#0x14,#0x24)
		if (!p0) jump 1f
	}
	badva = r15	// write ELR-->badva
1:
	{
		if (!p0) r12 = add(r12,r13)
	}
	{
		r14 = insert(r12,#8,#0)
		r15 = r29				// copy over preds
	}
	{
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
		r14 = #CONTEXT_EXCEPTION_VEC
		ssr = r14
		jump MINIVM_common_user_push
	}




#else

/* OLD VERSIONS */

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
 * TBD: add base/bounds checks
 * TBD: Map page to get known xlation while looking up page tables (Done?)
 */

	.global MINIVM_tlb_error
MINIVM_tlb_error:
	jump MINIVM_tlb_error

	.global MINIVM_handle_tlbmissx
	.p2align 5
MINIVM_handle_tlbmissx:
	{
		memd(r24+#CONTEXT_tlb_r3130) = r31:30
		r30 = ssr
	}
	{
		r31 = p3:0
		p3 = cmp.eq(r31,r31)		// set p3 to TRUE
		r30 = zxtb(r30)
	}
	{
		p0 = cmp.eq(r30,#1)
		p1 = cmp.eq(r30,#2)
		if (p1.new) jump:nt 1f // icinva.. badaddr in badva already
		if (p1.new) r30 = memw(r24+#CONTEXT_gptb)	// set up r30 correctly
	}
	r30 = elr
	if (p0) r30 = add(r30,#12)
	{
		badva = r30
		jump 1f
		r30 = memw(r24+#CONTEXT_gptb)
	}
	.size MINIVM_handle_tlbmissx, .-MINIVM_handle_tlbmissx

	.p2align 5
	.global MINIVM_handle_tlbmissrw
MINIVM_handle_tlbmissrw:
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
	/* P3 set if X permission */
	{
		memd(r24+#CONTEXT_tlb_r2928) = r29:28
		//p0 = cmp.eq(r30,#0)			// No translation for this ASID?
		//if (p0.new) jump:nt MINIVM_tlb_crash	// then crash
		r29.h = #hi(0x300fffe0)			// valid global 0xfffe0000
	}
	{
		memd(r24+#CONTEXT_tlb_r2322) = r23:22
		r29.l = #lo(0x300fffe0)
		r28 = lsr(r30,#12)			// PPN
		r23 = #0x1c2				// no perm, ccc=7, pgsize=64k
	}
	{
		r28 |= asl(r23,#20)			// OR in bits
		r23 = #1
		r30.h = #0xfffe				// replace upper bits
	}
	{
		memd(r24+#CONTEXT_tlb_r2120) = r21:20
	}
1:
	tlbidx = r23
	tlblo = r28
	tlbhi = r29
	tlbw
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
		r23 = #0x1c2			// no perm, ccc=7, pgsize=64k
		r29:28 = lsr(r29:28,#12)	// tlbhi in r28
	}
	r21 = lsr(r30,#12)			// ppn
	{
		r21 |= asl(r23,#20)		// bits
		r30.h = #0xfffe			// form l2 vaddr
	}
	tlblo = r21
	tlbw
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
	tlbhi = r28
	tlbp
	r21 = tlbidx
	{
		p0 = tstbit(r21,#31)
		if (!p0.new) jump:nt 2f		// replaced while spinlocking, skip write
		if (!p1) r21 = add(r30,#1)
		if (p1) r21 = #TLB_FIRST_REPLACEABLE_ENTRY
	}
	{
		memw(r22) = r21			// save new index
	}
	tlbidx = r21
	tlblo = r20
	tlbw
2:
	r21 = tlbhi
	TLB_CHECK(p0 = cmp.eq(r21:20,r1:0))
	TLB_CHECK(if (!p0) jump MINIVM_tlb_error)
	{
		p3:0 = r31
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r29:28 = memd(r24+#CONTEXT_tlb_r2928)
	}
	{
		r23:22 = memd(r24+#CONTEXT_tlb_r2322)
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
	}
	TLB_CHECK(r1:0 = memd(r24+#CONTEXT_tlb_check))
	crswap(r24,sgp)
	rteunlock


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
	tlbunlock
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r15 = r31
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
	}
	ssr = r14
	{
		r14 = #CONTEXT_EXCEPTION_VEC
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
	tlbunlock
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r31:30 = memd(r24+#CONTEXT_tlb_r3130)
		r15 = r31
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
	}
	ssr = r14
	{
		r14 = #CONTEXT_EXCEPTION_VEC
		r21:20 = memd(r24+#CONTEXT_tlb_r2120)
		jump MINIVM_common_user_push
	}
#endif






















	// tlbw
	// read fffe0000|(ptb &0x0000f000) | ((badva >> 22) << 2)

	/* L1 entry! */
	/* l1[2:0] == 0: ptr to 1024 4k translations, 4k aligned L2 PT */
	/* l1[2:0] == 1: ptr to 256 16k translations, 1k aligned L2 PT */
	/* l1[2:0] == 2: ptr to 64  64k translations, 256b aligned L2 PT */
	/* l1[2:0] == 3: ptr to 16 256k translations, 64b aligned L2 PT */
	/* l1[2:0] == 4: ptr to 4 1024k translations, 16b aligned L2 PT */
	/* l1[2:0] == 5: 4MB translation */
	/* l1[2:0] == 6: 16MB translation */
	/* l1[2:0] == 7: INVALID */
	/* Let's split up into two halves... */
	/* For L1 direct translations, save off the L1 entry and jump to appropriate code */
	/* Otherwise, we want to extract 10-(2*SSS) bits from badva at offset 12+(2*SSS) 
	 * and insert them at offset 2 of the (L1 entry & -16) ... */
	/* Note: TLBHI should already be 0x300fffe0, tlbidx==1 */



MINIVM_handle_nmi:
MINIVM_handle_rsvd:
MINIVM_machine_check:
	crswap(r24,sgp)
	memd(r24+#CONTEXT_r1514) = r15:14
	memd(r24+#CONTEXT_r1312) = r13:12
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		r15 = p3:0
		r14 = #CONTEXT_FATAL_VEC
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

/* TBD: also push USR? mainly for future V4 changes */
/* TBD: disable interrupts? */

/* SSR[18:0]: IE EX UM -- -- AS AS AS AS AS AS CC CC CC CC CC CC CC CC */
/* To switch to Supervisor ASID / DI / Supervisor Mode, insert 0 0 0 0 0 1 at bit 13 */

/* Share Code */

	.global MINIVM_angel
MINIVM_angel:
	nop
	jump 1f

MINIVM_handle_trap0:
	crswap(r24,sgp)
	{
		r12 = ssr
		memd(r24+#CONTEXT_r1312) = r13:12
	}
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r12 = and(r12,#255)
		r15 = p3:0
	}
	{
		p0 = cmp.eq(r12,#0)
		if (p0.new) jump:nt MINIVM_angel
	}
1:
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		//r15 = p3:0
		r14 = #CONTEXT_TRAP0_VEC
		jump MINIVM_common_user_push
	}

/* Common code to push stuff onto supervisor stack */
/* Assumes r10-r15 are saved, p3:0 in r15, r14 has event offset */
/* Takes info out of SSR, goes into supervisor mode */
/* Also: disables interrupts */

MINIVM_common_user_push:
	{
		p3 = r14
		r11 = #1
		r13 = #0
		r12 = r29
	}
	r14 = ssr
	{
		p0 = tstbit(r14,#FAKE_GUEST_SUPERVISOR_BIT)
		if (!p0.new) r29 = memw(r24+#CONTEXT_gsp)
		if (!p0.new) r13 = add(r13,#2)		// set UM bit
	}
	{
		p1 = tstbit(r14,#18)			// interrupts enabled?
		if (p1.new) r13 = add(r13,#1)		// IE BIT
		r11 = zxtb(r14)
		r14 = insert(r11,#6,#FAKE_GUEST_SUPERVISOR_BIT)
	}
	{
		r11 = insert(r13,#2,#GUEST_CAUSE_IE_BIT)
		r10 = elr
	}
	r13 = badva
	ssr = r14
	crswap(r24,sgp)
	/* After here we may get TLB misses */
	{
		memd(r29+#-8) = r13:12
		// IE=0 EX=1 UM=1 
		r12 = #3	
		r13 = p3
	}
	{
		memd(r29+#-16) = r11:10
		r29 = add(r29,#-16)
		r14 = insert(r12,#3,#16)
	}
	/* PUSHES DONE, NO MORE TLB MISSES!!! */
	ssr = r14
	crswap(r24,sgp)
	r10 = add(r13,r24)
	{
		r13:12 = memd(r24+#CONTEXT_r1312)
		r10 = memw(r10)
	}
	{
		elr = r10
		p0 = tstbit(r10,#0)
	}
	{
		p3:0 = r15
		if (p0) jump MINIVM_machine_check
		r15:14 = memd(r24+#CONTEXT_r1514)
		r11:10 = memd(r24+#CONTEXT_r1110)
	}
	{
		crswap(r24,sgp)
		rte
	}


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
		r14 = ssr
	}
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
		//if (p0) jumpr r12
		jumpr r12				// TEMPORARY: always allow from user to support PMU
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
	{
		crswap(r24,sgp)
		rte
	}

MINIVM_trap1tab:
	jump MINIVM_trap1_done		// 0
	jump MINIVM_return		// 1
	jump MINIVM_setvec		// 2
	jump MINIVM_setie		// 3
	jump MINIVM_getie		// 4
	jump MINIVM_swi			// 5
	jump MINIVM_iack		// 6
	jump MINIVM_setimask		// 7
	jump MINIVM_getimask		// 8
	jump MINIVM_iconf		// 9
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
	jump MINIVM_trap1_done		// 15
	jump MINIVM_trap1_done		// 16
	jump MINIVM_trap1_done		// 17
	jump MINIVM_trap1_done		// 18
	jump MINIVM_trap1_done		// 19
	jump MINIVM_trap1_done		// 1a
	jump MINIVM_trap1_done		// 1b
	jump MINIVM_trap1_done		// 1c
	jump MINIVM_trap1_done		// 1d
	jump MINIVM_trap1_pmu		// 1e
	jump MINIVM_trap1_dump		// 1f

	.size MINIVM_handle_trap1, .-MINIVM_handle_trap1

MINIVM_trap1_dump:
	r0 = ipend
	r1 = iad
	r2 = imask
	r3 = iel
	r4 = iahl
	jump MINIVM_trap1_done

MINIVM_trap1_pmu:
	{
		p0 = cmp.eq(r6,#1)
		if (p0.new) jump:nt 1f
	}
	jump MINIVM_trap1_done
	r0 = pmucnt0
	r1 = pmucnt1
	r2 = pmucnt2
	r3 = pmucnt3
	r4 = pmuevtcfg
	r5 = pmucfg
1:
	pmucnt0 = r0
	pmucnt1 = r1
	pmucnt2 = r2
	pmucnt3 = r3
	pmuevtcfg = r4
	pmucfg = r5
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

MINIVM_wait:
	//r0 = #0
	//jump MINIVM_trap1_done
	/* Enable interrupts, wait, restore state, repost int, return */
	/* If interrupts were enabled, we will take it once we return */
	r11 = ssr
	r14 = elr
	r24 = sgp
	r0 = #0
	sgp = r0
	r0 = ssr
	r0 = setbit(r0,#18)     // ie
	r0 = clrbit(r0,#17)     // !ex
	r0 = clrbit(r0,#16)     // !um
	ssr = r0
	wait(r0)
	nop

MINIVM_di_wait_return:
	{
		r0 = #lo(MINIVM_context_t1-MINIVM_context_t0)
		r24.h = #hi(MINIVM_context_t0)
		r10 = ssr		// get new SSR (cause)
	}
	{
		r24.l = #lo(MINIVM_context_t0)
		r12 = extractu(r10,#3,#19)
	}
	{
		r24 += mpyi(r12,r0)
		ssr = r11		// restore old SSR
		r10 = and(r10,#0x1f)	// get cause
	}
	{
		r10 = sub(#31,r10)
		r0 = #0
	}
	{
		r0 = setbit(r0,r10)
	}
	ciad(r0)
	swi(r0)
	{
		r0 = #0
		elr = r14
	}
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
 * Also, flush the TLB / STLB
 * Make sure we get the lock
 */
	.global MINIVM_register_ptb
MINIVM_register_ptb:
	/* invalidate STLB */
	/* Need to invalidate for all threads sharing my ptb */
#if USE_STLB
	{
		memw(r24+#CONTEXT_gptb) = r0
		r10.h = #hi(0xfff00000 + ((1<<HASH_BITS) * 8 * 6) + ((1<<HASH_BITS) * 0 / 8))
		r11 = #MAKEWORK(MINIVM_context_t0)
	}
	{
		r10.l = #lo(0xfff00000 + ((1<<HASH_BITS) * 8 * 6) + ((1<<HASH_BITS) * 0 / 8))
		r13 = #(1<<HASH_BITS)/8
		loop1(2f,#6)
	}
2:
	{
		loop0(1f,#((1<<HASH_BITS)/256))
		r12 = memw(r11+#CONTEXT_gptb)
		r11 = add(r11,#lo(MINIVM_context_t1-MINIVM_context_t0))
	}
	{
		p0 = cmp.eq(r12,r0)
		if (!p0.new) r10 = add(r10,r13)
		if (!p0.new) jump:t 2f
	}
	.falign
1:
	{
		dczeroa(r10)
		r10 = add(r10,#32)
	}:endloop0
	.falign
2:
	{
		nop
	}:endloop1
#endif
	{
		// memw(r24+#CONTEXT_gptb) = r0 -- done earlier
		r10 = #TLB_FIRST_REPLACEABLE_ENTRY
		r14 = #0
		loop0(1f,#TLB_ENTRIES-TLB_FIRST_REPLACEABLE_ENTRY)
	}
	tlblock
9:					// get lock
	tlbhi = r14
	tlblo = r14
	tlbidx = r10
	.falign
1:
	{
		tlbw
		r10 = add(r10,#1)
	}
	{
		tlbidx = r10
		nop
	}:endloop0
	tlbunlock
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_clrmap:
	{
		r0 = memw(r24+#CONTEXT_gptb)
		jump MINIVM_register_ptb
	}
	/* Invalidate STLB entry */
	/* Invalidate TLB entry */
	/* If more than one page, blow away everything... */
	{
		r10 = #4096
		r13 = #0
		r12 = r0
		loop0(1f,#6)
	}
	{
		if (p0.new) r0 = memw(r24+#CONTEXT_gptb)
		p0 = cmp.gtu(r1,r10)			// more than one page?
		if (p0.new) jump:nt MINIVM_register_ptb // If yes, wipe everything
		r13:12 = lsr(r13:12,#12)		// form tlbhi, valid clear
	}
	{
		r14.h = #hi(0xfff00000 + ((1<<HASH_BITS) * 8 * 6))
		r0.h = #hi(1<<20)
		r1 = #((1<<HASH_BITS) / 8)
	}
	{
		r14.l = #lo(0xfff00000 + ((1<<HASH_BITS) * 8 * 6))
		r0.l = #lo(1<<20)
	}
1:
	tlblock
	{
		tlbhi = r12
		r12 = togglebit(r12,#20+5)		// get other asid
	}
	{
		r11 = and(r12,#0x1f)
		r14 = tableidxw(r12,#PAGE_BITS-5,#5)
		tlbp
	}
	{
		r10 = memw(r14)
		r13 = tlbidx
	}
	{
		tlbhi = r12
		p0 = cmp.ge(r13,#TLB_FIRST_REPLACEABLE_ENTRY)
		if (!p0.new) jump:nt 1f
	}
	tlbw
1:
	tlbp
	{
		r13 = tlbidx
		r10 = clrbit(r10,r11)
	}
	{
		memw(r14) = r10				// clear bit in STLB
		p0 = cmp.ge(r13,#TLB_FIRST_REPLACEABLE_ENTRY)
		if (!p0.new) jump:nt 1f
	}
	tlbw
1:
	tlbunlock
	{
		r12 = add(r12,r0)			// next hw thread
		r14 = add(r14,r1)			// next stlb valid ptr
	}:endloop0
	{
		r0 = #0
		jump MINIVM_trap1_done
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

MINIVM_iack:
	r10 = #0
	r10 = setbit(r10,r0)
	r10 = brev(r10)
	ciad(r10)
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_swi:
	r10 = #0
	{
		r10 = setbit(r10,r0)
		p0 = tstbit(r1,#0)
	}
	{
		if (!p0) jump 2f		// even means cswi
		r10=brev(r10)
	}
	swi(r10)
	{
		r0 = #0
		jump MINIVM_trap1_done
	}
2:
	cswi(r10)
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_getimask:
	r10 = imask
	{
		r13 = #1
		r12 = r0
		r10 = brev(r10)
	}
	{
		r0 = extractu(r10,r13:12)
		jump MINIVM_trap1_done
	}

MINIVM_setimask:
	r10 = imask
	{
		r10 = brev(r10)
		r13 = #1
		r12 = r0
//		r1 = togglebit(r1,#0)
	}
	{
		r10 = insert(r1,r13:12)
	}
	r10 = brev(r10)
	imask = r10
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_iconf:
	{
		// -1 configuration vector means don't touch IAHL, IEL
		p0 = cmp.eq(r1,#-1)
		if (p0.new) jump:t 1f
	}
	r11 = #31
	{
		r12 = sub(r11,r0)
		r13 = #1
	}
	r10 = IAHL
	{
		r10 = insert(r1,r13:12)
		r1 = lsr(r1,#1)
	}
	IAHL = r10

	r10 = IEL;
	{
		r10 = insert(r1,r13:12)
		r11 = #-1
	}
	IEL = r10
1:
	cswi(r11)
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

MINIVM_setvec:
	{
		r10 = addasl(r24,r0,#2)	// pre-add reset/fatal/exc offset
		p0 = cmp.gt(r0,#EVENT_NUMBER_EXCEPTION)
		p1 = cmp.eq(r0,#EVENT_NUMBER_TRAP0)
		p2 = cmp.eq(r0,#EVENT_NUMBER_INTERRUPT)
		// Conveniently, we're not handling machine check
		// or soft reset, which are the cases where the
		// third argument (r2) has a stack base to be saved
	}
	{
		if (!p0) memw(r10+#CONTEXT_ETAB) = r1
		if (!p0) jump MINIVM_trap1_done
		if (!p0) r0 = #0
	}
	{
		if (p1) memw(r24+#CONTEXT_TRAP0_VEC) = r1
		if (p1) jump MINIVM_trap1_done
		if (p1) r0 = #0
	}
	{
		if (p2) memw(r24+#CONTEXT_INTERRUPT_VEC) = r1
		if (p2) r0 = #0
		if (!p2) r0 = #-1
		jump MINIVM_trap1_done
	}

MINIVM_cachectl:
	/* 
	 * r0: op enum { ICKILL, DCKILL, L2KILL, DCCLEANINVA, ICINVA }
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
		jump 1f	// ickill
		jump 2f // dckill
		//jump 3f // l2kill
		jump MINIVM_trap1_done // l2kill
		jump 2f // dcinv
		jump 1f // icinv
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
	{
		dccleanidx(r10)
		r10 = add(r10,#0x20)
	}:endloop0:endloop1
	{
		r0 = #0
		jump MINIVM_trap1_done
	}
3:
		r11.L = #LO(256*1024/4)
	{
		r10 = #0
		r11.H = #HI(256*1024/4)
	}
	loop0(7f,r11)
	.falign
7:
	{
		l2cleaninvidx(r10)
		r10 = add(r10,#1)
	}:endloop0
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
	ickill
	jump 2b
	/* Adjust to 4K pages */
	{
		r10 = extractu(r1,#12,#0)
		r11 = #4096
		r12 = #-4096
		r13 = #4095
	}
	{
		r13 += add(r2,r10)	// add rounding factor plus rewind bytes
		r10 = and(r1,r12)	// rewind to beginning of page
	}
	{
		r11 = lsr(r13,#12)		// get number of pages
		r12.h = #0x300f
	}
	/* For each 4K page: */
		/* Lock TLB */
		/* Put entry in TLB */
			/* dccleana/icinva * 4K/32 */
		/* Unlock TLB */
		/* Goto next page */
	{
		loop1(2f,r11)
		r11 = #0x1c2
		r12.l = #0xffe0
		r14 = lsr(r10,#12)
	}
	{
		r14 |= asl(r11,#20)
		r11 = #1
	}
2:
		{
			loop0(1f,#4096/32)
			r10.h = #0xfffe
		}
		tlblock
		tlbidx = r11
		tlbhi = r12
		tlblo = r14
		tlbw
1:
			icinva(r10)
			{
				dccleana(r10)
				r10 = add(r10,#32)
			}:endloop0
		tlbunlock
		{
			r14 = add(r14,#1)
		}:endloop1
	syncht
	{
		r0 = #0
		jump MINIVM_trap1_done
	}

/* RETURN
 * pop return address from stack
 * pop CAUSE from stack w/ user/supervisor (TBD: interrupt enable/disable?)
 * pop r29 from stack
 * restore regs and return
 * Note that ELR is now irrelevant
 * If going from supervisor->user, save kstack in GOSP
 * We won't need BADVA (r11?) from the stack
 */

MINIVM_return:
	{
		r11 = #0
		r14 = ssr
	}
	{
		r14 = insert(r11,#3,#16)
		r11 = #3
	}
	ssr = r14
	crswap(r24,sgp)
	/* After here we may get TLB misses */
	{
		r13:12 = memd(r29++#16)			// GSSR:GELR
		r10 = memw(r29+#8)			// OLDSP
		r14 = insert(r11,#3,#16)
		r11 = #0x18				// -- EX UM -- -- --
	}
	/* POPS DONE, NO MORE TLB MISSES!!! */
	crswap(r24,sgp)
	{
		p0 = tstbit(r13,#GUEST_CAUSE_UM_BIT)
		p1 = tstbit(r13,#GUEST_CAUSE_IE_BIT)
		if (p1.new) r11 = #0x38			// IE EX UM -- -- --
	}
	{
		if (!p0) r11 = add(r11,#1)		// IE EX UM -- -- SU
		if (p0) memw(r24+#CONTEXT_gsp) = r29
		r29 = r10
		elr = r12
	}
	{
		p3:0 = r15
		r14 = insert(r11,#6,#FAKE_GUEST_SUPERVISOR_BIT)	// SSR bits in place?
		r13:12 = memd(r24+#CONTEXT_r1312)
	}
	{
		ssr = r14
		r15:14 = memd(r24+#CONTEXT_r1514)
		r11:10 = memd(r24+#CONTEXT_r1110)
	}
	{
		crswap(r24,sgp)
		rte
	}

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
 *
 * Need to check whether this was DI-waitmode and if so, return to user
 */

	.global MINIVM_handle_int
MINIVM_handle_int:
	crswap(r24,sgp)
	if (r24 == #0) jump:nt MINIVM_di_wait_return
	memd(r24+#CONTEXT_r1514) = r15:14
	memd(r24+#CONTEXT_r1312) = r13:12
	{
		r15 = p3:0
		memd(r24+#CONTEXT_r1110) = r11:10
		r14 = #CONTEXT_INTERRUPT_VEC
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
	{
		memd(r24+#CONTEXT_r1514) = r15:14
		r15 = ssr
	}
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
		if (p3) r14 = #CONTEXT_FATAL_VEC
		if (!p3) r14 = #CONTEXT_EXCEPTION_VEC
	}
	{
		memd(r24+#CONTEXT_r1110) = r11:10
		jump MINIVM_common_user_push
	}

#define ADSP_SIRC1_INT_ENABLE 0xAB010400
#define ADSP_SIRC0_INT_ENABLE 0xAB010000

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
#if SETUP_STLB
	r1.h = #hi(0xfff00000 + ((1<<HASH_BITS) * 8 * 0))
	r1.l = #lo(0xfff00000 + ((1<<HASH_BITS) * 8 * 0))
	r2.h = #hi((1<<HASH_BITS) * 8) /* 8 bytes per entry */
	r2.l = #lo((1<<HASH_BITS) * 8) /* 8 bytes per entry */
	r1 += mpyi(r2,r11)
	r0.h = #hi(0xfff00000 + ((1<<HASH_BITS) * 8 * 6) + ((1<<HASH_BITS) * 0 / 8))
	r0.l = #lo(0xfff00000 + ((1<<HASH_BITS) * 8 * 6) + ((1<<HASH_BITS) * 0 / 8))
	r2.h = #hi((1<<HASH_BITS) / 8) /* 8 entries per byte */
	r2.l = #lo((1<<HASH_BITS) / 8) /* 8 entries per byte */
	r0 += mpyi(r2,r11)
	memd(r24+#CONTEXT_tlb_hashtab) = r1:0
#endif

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
		//memd(r24+#0x70) = r11:10 HASHTAB
		r11:10 = memd(r14+#0x78)
	}
	memd(r24+#0x78) = r11:10
	r29 = memw(r24+#4)
	r0 = ssr
	r1 = extractu(r0,#3,#19)
	r0 = insert(r1,#3,#8)		// ASID per-thread bits
	r1 = #3
	r0 = insert(r1,#3,#16)		// EX/UM
	r0 = setbit(r0,#FAKE_GUEST_SUPERVISOR_BIT)
	r1 = #PREFETCH_SETTINGS
	r0 = insert(r1,#3,#22)
	ssr = r0
	

	brkpt
	nop
	nop
	elr = r31
	rte

//  This will probably be deprecated; pull the sirc driver from MSM into Q6 Linux
vm_setup_l2int:
	// UART3 is SIRC1 # 18, SIRC1 is L1 int 24
	r0.h = #hi(ADSP_SIRC1_INT_ENABLE)
	r0.l = #lo(ADSP_SIRC1_INT_ENABLE)
	r1.h = #hi(1<<18)			// UART3
	r1.l = #lo(1<<18)
	r2 = #0
	memw(r0+#0x0c) = r2
	memw(r0+#0x10) = r2
	memw(r0+#0x00) = r1
	r0.h = #hi(ADSP_SIRC0_INT_ENABLE)
	r0.l = #lo(ADSP_SIRC0_INT_ENABLE)
	r1.h = #hi((1<<18) | (1<<19) | (1<<23))			// GPIO group 1: ethernet - 19 
	r1.l = #lo((1<<18) | (1<<19) | (1<<23))			// GPIO group 2: keyboard - 18, i2c - 23
	r2.h = #hi((1<<18) | (1<<23));
	r2.l = #lo((1<<18) | (1<<23));
	memw(r0+#0x0c) = r2			//  int_type set to level for eth, edge for i2c and keyboard
	r2.h = #hi(1<<18)			//  falling edge for keyboard
	r2.l = #lo(1<<18)
	memw(r0+#0x10) = r2			//  int_polarity set to positive
	memw(r0+#0x00) = r1			//  int_enable set to enable SIRC IRQs 19 and 23
	r2 = #-1;
	memw(r0+#0x18) = r2 //  Should probably clear all int status at this point.
	jump 1f

vm_bootup_code:
	r10 = pc

	r11 = ssr
	r11 = extractu(r11,#3,#19)
	p0 = cmp.eq(r11,#0)
	if (!p0) jump vm_newcpu_startup
	
	isdben = r0

	/* UPDATED FOR V3 */
        r0 = #0x0
	r0 = setbit(r0,#24)
        s60 = r0 

#if 0
 	r0.h = #0xd013
 	r0.l = #0xd013
 	s61 = r0
 	
 	r0.h = #0x0002
 	r0.l = #0x0d01
 	s62 = r0
#endif
 
 	r0 = #0x0000
	r0 = setbit(r0,#14)	// disable all-wait mode, linux needs accurate pcycles
 	s63 = r0


	r0 = #0x78
	syscfg = r0
	nop
	nop
	brkpt
	nop
	nop
	ickill
	dckill
	l2kill
	jump vm_setup_l2int
1:
	r0 = #0x7e
	syscfg = r0
	isync
	r0 = #-1
	iahl = r0
#ifdef CONFIG_QDSP6_ST1
	r0 = clrbit(R0,#31-23)
	r0 = clrbit(R0,#31-24)
#endif
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
	tlbhi = r15
	tlblo = r15
1:
	// clear TLB
	tlbidx = r15
	tlbw
	{
		r15 = add(r15,#1)
	}:endloop0
	// Add kernel entry
	{
		r15 = #0
		r14.h = #hi(0x300ffff0)
		r13 = lsr(r10,#12)
		r11 = #0x9c2		// ccc=7, 64K, X for V3 bug
	}
	{
		r13 |= asl(r11,#20)
		r14.l = #lo(0x300ffff0)
	}
	tlbidx = r15
	tlblo = r13
	tlbhi = r14
	tlbw
	// Add temporary entry
	r15 = #3
	tlbidx = r15
	r14 = lsr(r10,#12)
	r14 |= asl(r15,#28)
	tlbhi = r14
	tlbw
	r0 = #0x77f			// TE/PM/IDA + CRGTDIM
	r0.h = #0x0083			// L2$+WB
	syscfg = r0
	r0 = #1				// turn on isdb
	isync
	r1.h = #hi(1f)
	r1.l = #lo(1f)
	jumpr r1			// jump to virtual space
1:
	r15 = #0
	tlbhi = r15
	tlblo = r15
	tlbw				// clear out tmp mapping

	/* Set up STLB mapping */
	r15 = #2
	tlbidx = r15
	r15.h = #hi(0x300fff00)
	r15.l = #lo(0x300fff00)
	tlbhi = r15
	r15.h = #hi(0x1c3c0000)		// IMEM
	r15.l = #lo(0x1c3c0000)
	tlblo = r15
	tlbw
	r15 = #0
	
	r7.h = #hi(MINIVM_context_t0)
	r7.l = #lo(MINIVM_context_t0)
	memw(r7+#CONTEXT_gptb) = r12	// set initial page table
	r2 = #-1
	memw(r7+#CONTEXT_RESET_VEC) = r2
	memw(r7+#CONTEXT_FATAL_VEC) = r2
	memw(r7+#CONTEXT_EXCEPTION_VEC) = r2
	memw(r7+#CONTEXT_TRAP0_VEC) = r2
	memw(r7+#CONTEXT_INTERRUPT_VEC) = r2
	sgp = r7
	r8 = #MAKEWORK(MINIVM_tlbidx)
	r6 = #TLB_FIRST_REPLACEABLE_ENTRY
	memw(r8) = r6

#if SETUP_STLB
	r1.h = #hi(0xfff00000 + ((1<<HASH_BITS) * 8 * 0))
	r1.l = #lo(0xfff00000 + ((1<<HASH_BITS) * 8 * 0))
	r0.h = #hi(0xfff00000 + ((1<<HASH_BITS) * 8 * 6) + ((1<<HASH_BITS) * 0 / 8))
	r0.l = #lo(0xfff00000 + ((1<<HASH_BITS) * 8 * 6) + ((1<<HASH_BITS) * 0 / 8))
	memd(r7+#CONTEXT_tlb_hashtab) = r1:0

	r1.h = #hi((1<<HASH_BITS)*6/256)
	r1.l = #lo((1<<HASH_BITS)*6/256)
	loop0(1f,r1)
	.falign
1:
	{
		dczeroa(r0)
		r0 = add(r0,#32)
	}:endloop0
#endif

	r0 = ssr
	r1 = #3
	r0 = insert(r1,#3,#16)
	r0 = setbit(r0,#FAKE_GUEST_SUPERVISOR_BIT)
	r1 = #PREFETCH_SETTINGS
	r0 = insert(r1,#3,#22)
	ssr = r0

	//brkpt

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
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
	XLAT256M(0x00000fc0)
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
















