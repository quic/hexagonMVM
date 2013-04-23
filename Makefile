ARCH=hexagon-
CC=${ARCH}gcc
LD=${ARCH}ld
OBJCOPY=${ARCH}objcopy

ARCHV?=2
GUEST_ENTRY?=0x0

all: minivm 

CFLAGS=-mv${ARCHV} -DGUEST_ENTRY=${GUEST_ENTRY} -mv${ARCHV}
ASFLAGS=${CFLAGS}

OBJS=minivm.o

minivm: ${OBJS}
	${LD} -o $@ -T hexagon.lds ${OBJS}

minivm.bin: minivm
	${OBJCOPY} -O binary $< $@

clean:
	rm -f *.o minivm minivm.bin ${OBJS}


