
# Hexagon minivm

The hexagon minivm implements the
[Hexagon Virtual Machine specification](https://docs.qualcomm.com/bundle/publicresource/80-NB419-3_REV_A_Hexagin_Virtual_Machine_Specification.pdf) ([mirror](https://archive.is/yzlri).
The Hexagon Virtual Machine is a hypervisor and portability layer.

This project is [licensed](LICENSE) with the BSD 3-clause license.

## Status

Current fails when trying to enable the MMU at 1223

See it failing with:

$ make test QEMU_OPTS='-s -S'

And in another tab:

$ make dbg LLDB_OPTS="-o 'break set -a 0xc0000aa4' -o c"
$ step
