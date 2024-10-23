ARCH=hexagon-
CC=${ARCH}clang
LD=${CC}
OBJCOPY=${ARCH}objcopy

ARCHV?=73
GUEST_ENTRY?=0xc0000000
USER_TEXT?=0x20000000
USER_RODATA?=0x20400000
USER_DATA?=0x20800000
USER_DATA2?=0x20900000

TESTS=$(wildcard tests/*.S)
TESTS_BIN=$(patsubst tests/%.S,tests_bin/%,${TESTS})
RUN_TESTS=$(patsubst tests/%.S,run-%,${TESTS})

all: minivm test

CFLAGS+=-mv${ARCHV} -O0 -g -DGUEST_ENTRY=${GUEST_ENTRY}
ASFLAGS+=${CFLAGS}
LDFLAGS+=-nostdlib -static
GUEST_LDFLAGS=-nostdlib \
    -Wl,-section-start,.start=${GUEST_ENTRY} \
    -Wl,-section-start,.user_text=${USER_TEXT} \
    -Wl,-section-start,.user_rodata=${USER_RODATA} \
    -Wl,-section-start,.user_data=${USER_DATA} \
    -Wl,-section-start,.user_data2=${USER_DATA2}

OBJS=minivm.o

prefix?=/usr/local
exec_prefix?=$(prefix)
bindir?=$(exec_prefix)/bin

minivm.o: minivm.S hexagon_vm.h

minivm: ${OBJS} Makefile hexagon.lds
	${LD} -o $@ -T hexagon.lds ${OBJS} ${LDFLAGS}

tests_bin/%: tests/%.S hexagon_vm.h Makefile
	@mkdir -p tests_bin
	${CC} ${CFLAGS} -o $@ $< ${GUEST_LDFLAGS}

.PHONY: test build_tests run_tests FORCE
test:
	make build_tests
	make run_tests

build_tests: ${TESTS_BIN}

run_tests: ${RUN_TESTS}

run-%: tests_bin/% minivm
	qemu-system-hexagon \
		-display none -M SA8775P_CDSP0 -kernel ./minivm ${QEMU_OPTS} \
		-device loader,addr=${GUEST_ENTRY},file=$<

.PHONY: dbg install
dbg: FORCE
	lldb -o 'file ./minivm' -o 'target modules add ./vmlinux' -o 'target modules load -s 0 --file ./vmlinux' -o 'gdb-remote localhost:1234' ${LLDB_OPTS}

minivm.bin: minivm
	${OBJCOPY} -O binary $< $@

install: minivm minivm.bin $(TESTS_BIN)
	 mkdir -p $(bindir)/
	 install -D $^ $(bindir)/

clean:
	rm -rf tests_bin minivm minivm.bin ${OBJS}


