
# 基本原理

kvm虚拟机实际运行于`qemu-kvm`的**进程上下文**中，因此，需要建立**虚拟机的物理内存空间**(GPA)与`qemu-kvm`**进程的虚拟地址空间**(HVA)的映射关系。

**虚拟机的物理地址空间**实际也是**不连续**的，分成**不同的内存区域**(slot)，因为物理地址空间中通常还包括**BIOS**、**MMIO**、**显存**、**ISA保留**等部分。

qemu-kvm通过ioctl vm指令KVM_SET_USER_MEMORY_REGION来为虚拟机设置内存。主要建立guest物理地址空间中的内存区域与qemu-kvm虚拟地址空间中的内存区域的映射，从而建立其从GVA到HVA的对应关系，该对应关系主要通过kvm_mem_slot结构体保存，所以实质为设置kvm_mem_slot结构体。

本文简介ioctl vm指令KVM_SET_USER_MEMORY_REGION在内核中的执行流程，qemu-kvm用户态部分暂不包括。