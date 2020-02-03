#!/usr/bin/bash
qemu-system-x86_64 -cpu host -smp 2 -m 1024 -kernel arch/x86/boot/bzImage -nographic -append "rdinit=/linuxrc loglevel=8 console=ttyS0" -S -s