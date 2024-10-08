/*
 * Copyright (c) 2024 Taylor Simpson <ltaylorsimpson@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include "../hexagon_vm.h"

#define USER_BIT		(0x1 << HVM_PTE_U_BIT)
#define PERM_BITS		(0x7 << HVM_PTE_R_BIT)    // X:1 W:1 R:1
#define CACHE_BITS		(0x7 << HVM_PTE_CCC_OFF)
#define GUEST_PTE_BITS		(PERM_BITS | CACHE_BITS | HVM_PTE_PGSIZE_4M)
#define XWR_PTE_BITS		((0x7 << HVM_PTE_R_BIT) | CACHE_BITS | HVM_PTE_PGSIZE_4M)
#define USER_XWR_PTE_BITS	(USER_BIT | (0x7 << HVM_PTE_R_BIT) | CACHE_BITS | HVM_PTE_PGSIZE_4M)
#define USER_WR_PTE_BITS	(USER_BIT | (0x3 << HVM_PTE_R_BIT) | CACHE_BITS | HVM_PTE_PGSIZE_4M)
#define USER_R_PTE_BITS		(USER_BIT | (0x1 << HVM_PTE_R_BIT) | CACHE_BITS | HVM_PTE_PGSIZE_4M)

#define FOUR_MB_BITS		22
#define FOUR_MB			(1 << FOUR_MB_BITS)
#define FOUR_MB_MASK		(~(FOUR_MB - 1))

#define CREATE_PTE_ENTRIES(START, END, BITS) \
	/* Number of entries between START and END */ \
	r26 = #(((END-START)+FOUR_MB-1)>>FOUR_MB_BITS); \
	r1 = #(START); \
	r1 = and(r1, #FOUR_MB_MASK); \
	r2 = lsr(r1, #FOUR_MB_BITS); \
	r0 = addasl(r24, r2, #2);	/* r0 = address of first PTE */ \
	r1 = add(r1, #(BITS));		/* r1 = 4MB PTE for the first entry */ \
	r2 = #FOUR_MB;			/* PTE increment */ \
	loop0(1f, r26); \
1: \
	memw(r0 ++ #4) = r1; \
	{ r1 = add(r1, r2) } :endloop0

#define FD_STDOUT                1

.section .start,"awx",@progbits
.global _start
_start:
	// Get the physical address of guest_pt
	r25 = pc
	r24 = ##(guest_pt-_start)
	r24 = add(r24, r25)

	CREATE_PTE_ENTRIES(_start, _end_guest, GUEST_PTE_BITS)
	// Intentionally leave out user bit to force a nouser exception
	CREATE_PTE_ENTRIES(_user_text, _end_user_text, XWR_PTE_BITS)
	CREATE_PTE_ENTRIES(_user_rodata, _end_user_rodata, USER_R_PTE_BITS)

	// Set up a two-level page table for _user_data
	r1 = #_user_data
	r1 = and(r1, #FOUR_MB_MASK)
	r2 = lsr(r1, #FOUR_MB_BITS)
	r0 = addasl(r24, r2, #2)	/* r0 = address of L1 PTE */
	r1 = #l2_pt
	r1 = and(r1, #0xfffffff0)
	r1 = or(r1, #HVM_PTE_PGSIZE_1M)	/* r1 = L1 PTE (points to L2 PT) */
	memw(r0) = r1

	// Write the L2 PTE for _user_data
	r0 = #l2_pt
	r1 = #_user_data
	r1 = and(r1, #0xfffff000)
	// Intentionally leave out the WR bits to force a page fault
	r1 = or(r1, #HVM_PTE_PGSIZE_1M)
	memw(r0) = r1

	// Write the L2 PTE for _user_data2
	r0 = #l2_pt + 4
	r1 = #_user_data2
	r1 = and(r1, #0xfffff000)
	r1 = or(r1, #(USER_WR_PTE_BITS | HVM_PTE_PGSIZE_1M))
	memw(r0) = r1

	r0 = r24
	vmnewmap

	// Install our event vectors
	r0 = ##GUEST_event_vectors
	vmsetvec

	// Switch to user mode
	r11 = gsr
	r10 = ##_user_text
	r11 = setbit(r11, #HVM_GSR_UM_BIT)
	g1:0 = r11:10
	vmrte

	// user space code should should do an exit
	// if we get here something went wrong
	r2 = #0xff		// return failure to shell
	vmstop


GUEST_event_vectors:
	jump GUEST_event_abort           // 0: reserved`
	jump GUEST_event_abort           // 1: machine check
	jump GUEST_event_abort           // 2: general exception
	jump GUEST_event_abort           // 3: reserved
	jump GUEST_event_abort           // 4: reserved
	jump GUEST_event_trap0           // 5: trap0
	jump GUEST_event_abort           // 6: reserved
	jump GUEST_event_abort           // 7: interrupt


GUEST_event_abort:
	r2 = gsr		// return gsr value to shell
	r5 = zxth(r2)

	// Special handling for the intentional page fault
	r3 = #HVM_EXCP_PROT_WR
	{ p0 = cmp.eq(r5, r3); if (!p0.new) jump:t #1f }
	r4 = gbadva
	r3 = ##angel_args
	{ p0 = cmp.eq(r4, r3); if (!p0.new) jump:t #1f }
	// Fix the page table entry
	r0 = #l2_pt
	r1 = #_user_data
	r1 = and(r1, #0xfffff000)
	r1 = or(r1, #(USER_WR_PTE_BITS | HVM_PTE_PGSIZE_1M))
	memw(r0) = r1
	r0 = ##guest_pt
	vmnewmap
	r0 = #1
	memw(##caught_page_fault_exception) = r0
	vmrte

1:
	// Special handling for the intentional nouser exception
	r3 = #HVM_EXCP_PROT_UEX
	{ p0 = cmp.eq(r5, r3); if (!p0.new) jump:t #2f }
	r4 = gbadva
	r3 = ##_user_text
	{ p0 = cmp.eq(r4, r3); if (!p0.new) jump:t #2f }
	// Fix the page table entry
	CREATE_PTE_ENTRIES(_user_text, _end_user_text, USER_XWR_PTE_BITS)
	r0 = ##guest_pt
	vmnewmap
	r0 = #1
	memw(##caught_nouser_exception) = r0
	vmrte

2:
	r3 = memw(##expected_exception)
	{ p0 = cmp.eq(r5, r3); if (!p0.new) jump:t #3f }
	// We hit the expected excption, carry on ...
	// Make sure the offending packet is exactly 4 bytes
	//     single instruction, no constant extenders
	r3 = #0
	memw(##expected_exception) = r3
	r3 = #1
	memw(##caught_expected_exception) = r3
	r3 = gelr
	r3 = add(r3, #4)
	gelr = r3
	vmrte
3:
	vmstop

// Simple trap0 handler
//    Cause code 0 is an angel call - do nothing
//    Cause code 1 will exit (r0 has return code to shell)
GUEST_event_trap0:
	r10 = gsr
	r10 = zxth(r10)
	{
		p0 = cmp.eq(r10, #1)
		if (!p0.new) jump:nt 1f
	}
	r2 = r0
	vmstop
1:
	vmrte

#define XLAT4M(VAL) \
	.word (VAL | HVM_PTE_PGSIZE_INVALID);

#define XLAT16M(VAL) \
	XLAT4M(VAL) \
	XLAT4M(VAL | 0x00400000) \
	XLAT4M(VAL | 0x00800000) \
	XLAT4M(VAL | 0x00c00000)

#define XLAT64M(VAL) \
	XLAT16M(VAL) \
	XLAT16M(VAL | 0x01000000) \
	XLAT16M(VAL | 0x02000000) \
	XLAT16M(VAL | 0x03000000)

#define XLAT256M(VAL) \
	XLAT64M(VAL) \
	XLAT64M(VAL | 0x04000000) \
	XLAT64M(VAL | 0x08000000) \
	XLAT64M(VAL | 0x0c000000)

	.p2align 12
guest_pt:
	XLAT256M(0x00000000)
	XLAT256M(0x10000000)
	XLAT256M(0x20000000)
	XLAT256M(0x30000000)
	XLAT256M(0x40000000)
	XLAT256M(0x50000000)
	XLAT256M(0x60000000)
	XLAT256M(0x70000000)
	XLAT256M(0x80000000)
	XLAT256M(0x90000000)
	XLAT256M(0xa0000000)
	XLAT256M(0xb0000000)
	XLAT256M(0xc0000000)
	XLAT256M(0xd0000000)
	XLAT256M(0xe0000000)
	XLAT256M(0xf0000000)

// L2 page table will hold a set of 4 1MB entries
	.p2align 4
l2_pt:
	.word 0x00000000 | HVM_PTE_PGSIZE_INVALID
	.word 0x00000000 | HVM_PTE_PGSIZE_INVALID
	.word 0x00000000 | HVM_PTE_PGSIZE_INVALID
	.word 0x00000000 | HVM_PTE_PGSIZE_INVALID
_end_guest:



.section .user_text,"awx",@progbits
.global _user_text
_user_text:
	r0 = #FD_STDOUT
	memw(##angel_args) = r0
	r0 = ##hello_str
	memw(##angel_args+4) = r0
	r0 = #8
	memw(##angel_args+8) = r0
	r0 = #5
	r1 = ##angel_args
	trap0(#0)

	// Test raising some exceptions
	r0 = ##expected_exception

	// Write to rodata
	memw(r0) = #HVM_EXCP_PROT_WR
	r1 = #0
	memw(##caught_expected_exception) = r1
	r1 = ##hello_str
	memb(r1) = #'h'
	r1 = memw(##caught_expected_exception)
	{ p0 = cmp.eq(r1, #1); if (!p0.new) jump:nt _fail }

	// Read from guest memory
	memw(r0) = #HVM_EXCP_PROT_URD
	r1 = #0
	memw(##caught_expected_exception) = r1
	r1 = ##l2_pt
	r1 = memw(r1)
	r1 = memw(##caught_expected_exception)
	{ p0 = cmp.eq(r1, #1); if (!p0.new) jump:nt _fail }

	memw(r0) = #HVM_EXCP_PROT_UWR
	r1 = #0
	memw(##caught_expected_exception) = r1
	r1 = ##l2_pt
	memw(r1) = #0
	r1 = memw(##caught_expected_exception)
	{ p0 = cmp.eq(r1, #1); if (!p0.new) jump:nt _fail }

	// Check that intentional exceptions were caught
	r0 = memw(##caught_page_fault_exception)
	{ p0 = cmp.eq(r0, #1); if (!p0.new) jump:nt _fail }
	r0 = memw(##caught_nouser_exception)
	{ p0 = cmp.eq(r0, #1); if (!p0.new) jump:nt _fail }

	// Print the PASS message
	r0 = #FD_STDOUT
	memw(##angel_args) = r0
	r0 = ##pass_str
	memw(##angel_args+4) = r0
	r0 = #6
	memw(##angel_args+8) = r0
	r0 = #5
	r1 = ##angel_args
	trap0(#0)

	// Exit with success
	r0 = #0
	trap0(#1)

_fail:
	// Print the FAIL message
	r0 = #FD_STDOUT
	memw(##angel_args) = r0
	r0 = ##fail_str
	memw(##angel_args+4) = r0
	r0 = #6
	memw(##angel_args+8) = r0
	r0 = #5
	r1 = ##angel_args
	trap0(#0)

	// Exit with failure
	r0 = #0xff
	trap0(#1)
_end_user_text:

.section .user_rodata,"a",@progbits
_user_rodata:
	.type	str,@object
hello_str:
	.string	"Hello!\n"
	.size	hello_str, 8
	.type	pass_str,@object
pass_str:
	.string	"PASS\n"
	.size	pass_str, 6
	.type	pass_str,@object
fail_str:
	.string	"FAIL\n"
	.size	fail_str, 6
_end_user_rodata:


.section .user_data,"awx",@progbits
_user_data:
	.type	angel_args,@object
angel_args:
	.word   0
	.word   0
	.word   0

// Put this in its own section so we can make it always read/write
.section .user_data2,"awx",@progbits
_user_data2:
	.type	expected_exception,@object
expected_exception:
	.word   0
	.type	caught_expected_exception,@object
caught_expected_exception:
	.word   0
	.type	caught_page_fault_exception,@object
caught_page_fault_exception:
	.word   0
	.type	caught_nouser_exception,@object
caught_nouser_exception:
	.word   0

.section ".note.ABI-tag", "a"
.align 4
.long 1f - 0f          /* name length */
.long 3f - 2f          /* data length */
.long  1               /* note type */

/*
 * vendor name seems like this should be MUSL but lldb doesn't agree.
 */
0:     .asciz "GNU"
1:     .align 4
2:     .long 0 /* linux */
       .long 3,0,0
3:     .align 4
