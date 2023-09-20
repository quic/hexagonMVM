ARCH=hexagon-
CC=${ARCH}clang
LD=${ARCH}link
OBJCOPY=${ARCH}objcopy

ARCHV?=73
GUEST_ENTRY?=0x0

all: minivm 

CFLAGS=-mv${ARCHV} -DGUEST_ENTRY=${GUEST_ENTRY}
ASFLAGS=${CFLAGS}

OBJS=minivm.o

minivm: ${OBJS}
	${LD} -o $@ -T hexagon.lds ${OBJS}

minivm.bin: minivm
	${OBJCOPY} -O binary $< $@

clean:
	rm -f *.o minivm minivm.bin ${OBJS}


