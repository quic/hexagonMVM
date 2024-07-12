ARCH=hexagon-
CC=${ARCH}clang
LD=${CC}
OBJCOPY=${ARCH}objcopy

ARCHV?=73
GUEST_ENTRY?=0x10000000
USER_TEXT?=0x20000000
USER_RODATA?=0x20400000
USER_DATA?=0x20800000
USER_DATA2?=0x20900000

all: minivm test

CFLAGS=-mv${ARCHV} -O0 -g -DGUEST_ENTRY=${GUEST_ENTRY}
ASFLAGS=${CFLAGS}
LDFLAGS=-nostdlib -static
GUEST_LDFLAGS=-nostdlib \
    -Wl,-section-start,.start=${GUEST_ENTRY} \
    -Wl,-section-start,.user_text=${USER_TEXT} \
    -Wl,-section-start,.user_rodata=${USER_RODATA} \
    -Wl,-section-start,.user_data=${USER_DATA} \
    -Wl,-section-start,.user_data2=${USER_DATA2}

OBJS=minivm.o

minivm: ${OBJS} Makefile hexagon.lds
	${LD} -o $@ -T hexagon.lds ${OBJS} ${LDFLAGS}

first: first.S Makefile
	${CC} ${CFLAGS} -o $@ $< ${GUEST_LDFLAGS}

test_mmu: test_mmu.S Makefile
	${CC} ${CFLAGS} -o $@ $< ${GUEST_LDFLAGS}

test_interrupts: test_interrupts.S Makefile
	${CC} ${CFLAGS} -o $@ $< ${GUEST_LDFLAGS}

test_processors: test_processors.S Makefile
	${CC} ${CFLAGS} -o $@ $< ${GUEST_LDFLAGS}

.PHONY: test FORCE
test: minivm first test_mmu test_interrupts test_processors FORCE
	qemu-system-hexagon -M SA8775P_CDSP0 ${QEMU_OPTS} -device loader,addr=${GUEST_ENTRY},file=./first -kernel ./minivm
	qemu-system-hexagon -M SA8775P_CDSP0 ${QEMU_OPTS} -device loader,addr=${GUEST_ENTRY},file=./test_mmu -kernel ./minivm
	qemu-system-hexagon -M SA8775P_CDSP0 ${QEMU_OPTS} -device loader,addr=${GUEST_ENTRY},file=./test_interrupts -kernel ./minivm
	qemu-system-hexagon -M SA8775P_CDSP0 ${QEMU_OPTS} -device loader,addr=${GUEST_ENTRY},file=./test_processors -kernel ./minivm

.PHONY: dbg
dbg: FORCE
	lldb -o 'file ./minivm' -o 'target modules add ./test_processors' -o 'target modules load -s 0 --file ./test_processors' -o 'gdb-remote localhost:1234' ${LLDB_OPTS}

minivm.bin: minivm
	${OBJCOPY} -O binary $< $@

clean:
	rm -f *.o minivm first test_mmu test_interrupts test_processors minivm.bin ${OBJS}


