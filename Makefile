ARCH=hexagon-
CC=${ARCH}clang
LD=${CC}
OBJCOPY=${ARCH}objcopy

ARCHV?=73
GUEST_ENTRY?=0x100000000

all: minivm test 

CFLAGS=-mv${ARCHV} -O0 -g -DGUEST_ENTRY=${GUEST_ENTRY}
ASFLAGS=${CFLAGS}
LDFLAGS=-nostdlib

OBJS=minivm.o

minivm: ${OBJS} Makefile hexagon.lds
	${LD} -o $@ -T hexagon.lds ${OBJS} ${LDFLAGS}

hello: hello.c Makefile
	${CC} ${CFLAGS} -o $@ $<

.PHONY: test FORCE
test: minivm hello FORCE
	qemu-system-hexagon -M SA8775P_CDSP0 ${QEMU_OPTS} -device loader,addr=${GUEST_ENTRY},file=./hello -kernel ./minivm

.PHONY: dbg
dbg: FORCE
	hexagon-lldb -o 'file ./minivm' -o 'target modules add ./hello' -o 'target modules load -s 0 --file ./hello' -o 'gdb-remote localhost:1234' ${LLDB_OPTS}

minivm.bin: minivm
	${OBJCOPY} -O binary $< $@

clean:
	rm -f *.o minivm hello minivm.bin ${OBJS}


