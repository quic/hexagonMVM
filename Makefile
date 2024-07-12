ARCH=hexagon-
CC=${ARCH}clang
LD=${CC}
OBJCOPY=${ARCH}objcopy

ARCHV?=73
GUEST_ENTRY?=0x10000000

all: minivm test 

CFLAGS=-mv${ARCHV} -O0 -g -DGUEST_ENTRY=${GUEST_ENTRY}
ASFLAGS=${CFLAGS}
LDFLAGS=-nostdlib -static
GUEST_LDFLAGS=-nostdlib -Wl,-section-start,.start=${GUEST_ENTRY}

OBJS=minivm.o

minivm: ${OBJS} Makefile hexagon.lds
	${LD} -o $@ -T hexagon.lds ${OBJS} ${LDFLAGS}

first: first.S Makefile
	${CC} ${CFLAGS} -o $@ $< ${GUEST_LDFLAGS}

.PHONY: test FORCE
test: minivm first FORCE
	qemu-system-hexagon -M SA8775P_CDSP0 ${QEMU_OPTS} -device loader,addr=${GUEST_ENTRY},file=./first -kernel ./minivm

.PHONY: dbg
dbg: FORCE
	lldb -o 'file ./minivm' -o 'target modules add ./first' -o 'target modules load -s 0 --file ./first' -o 'gdb-remote localhost:1234' ${LLDB_OPTS}

minivm.bin: minivm
	${OBJCOPY} -O binary $< $@

clean:
	rm -f *.o minivm first minivm.bin ${OBJS}


