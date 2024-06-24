
# Hexagon minivm

The hexagon minivm implements the
[Hexagon Virtual Machine specification](https://docs.qualcomm.com/bundle/publicresource/80-NB419-3_REV_A_Hexagin_Virtual_Machine_Specification.pdf) ([mirror](https://archive.is/yzlri)).
The Hexagon Virtual Machine is a hypervisor and portability layer.

This project is [licensed](LICENSE) with the BSD 3-clause license.

## Status

minivm can run some simple tests with `make test`:

- `first.S`: prints "Hello!" and exits.
- `test_mmu.S`: has a user space that prints "Hello!" and tests some privilege
  exceptions.

You can attach the LLDB debugger as follows

    $ make test QEMU_OPTS='-s -S'

And in another tab:

    $ make dbg LLDB_OPTS="-o 'break set -a 0x20000000' -o c"
