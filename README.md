
# Hexagon minivm

The hexagon minivm implements the
[Hexagon Virtual Machine specification](https://docs.qualcomm.com/bundle/publicresource/80-NB419-3_REV_A_Hexagin_Virtual_Machine_Specification.pdf) ([mirror](https://archive.is/yzlri)).
The Hexagon Virtual Machine is a hypervisor and portability layer.

This project is [licensed](LICENSE) with the BSD 3-clause license.

## Status

The current status is the minivm can execute the first test (first.S).
It is a simple test that prints "Hello!" and exits.  Run "make test" to see
it in action.

You can attach the LLDB debugger as follows

    $ make test QEMU_OPTS='-s -S'

And in another tab:

    $ make dbg LLDB_OPTS="-o 'break set -a 0xc0000ac4' -o c -o stepi"
