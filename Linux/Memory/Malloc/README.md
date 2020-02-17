malloc 源码分析: https://blog.csdn.net/conansonic/article/details/50186489

大家好，今天给大家分享的是一个我参考 Linux 内核在用户空间实现的 VMLLOC 内存分配器，该分配器的的特点就是分配虚拟地址连续而物理地址不连续。这个项目实现了 VMALLOC 的核心逻辑，包括了红黑树以及页表等。在这个项目中我实现了一个软件虚拟的 mmu，大家对 VMALLOC 内存分配器感兴趣的可以参考下面链接直接实践 https://github.com/BiscuitOS/HardStack/tree/master/Memory-Allocator/vmalloc/vmalloc_userspace