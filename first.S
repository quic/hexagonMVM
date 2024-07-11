
#include "hexagon_vm.h"

#define FD_STDOUT                1

.section .start,"awx",@progbits
.global _start
_start:
	r0 = ##GUEST_event_vectors
	vmsetvec

	r0 = #5
	r1 = ##angel_args
	trap0(#0)

	r2 = #0			// return success to shell
	vmstop

	.type	str,@object
str:
	.string	"Hello!\n"
	.size	str, 8
	.type	angel_args,@object
angel_args:
	.word   FD_STDOUT
	.word   str
	.word   8

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
	vmstop

GUEST_event_trap0:
	vmrte

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
