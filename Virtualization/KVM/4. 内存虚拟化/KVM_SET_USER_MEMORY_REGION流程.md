
# 基本原理

kvm虚拟机实际运行于`qemu-kvm`的**进程上下文**中，因此，需要建立**虚拟机的物理内存空间**(GPA)与`qemu-kvm`**进程的虚拟地址空间**(HVA)的映射关系。

**虚拟机的物理地址空间**实际也是**不连续**的，分成**不同的内存区域**(slot)，因为物理地址空间中通常还包括**BIOS**、**MMIO**、**显存**、**ISA保留**等部分。

qemu-kvm通过**ioctl vm**指令`KVM_SET_USER_MEMORY_REGION`来**为虚拟机设置内存**。主要建立**guest物理地址空间**中的内存区域与**qemu-kvm虚拟地址空间中的内存区域**的映射，从而建立其从**GVA到HVA的对应关系**，该**对应关系**主要通过`kvm_mem_slot`结构体保存，所以实质为设置kvm_mem_slot结构体。

本文简介ioctl vm指令KVM_SET_USER_MEMORY_REGION在内核中的执行流程，qemu-kvm用户态部分暂不包括。

# 基本流程

ioctl vm指令`KVM_SET_USER_MEMORY_REGION`在内核主要执行流程如下：

```cpp
kvm_vm_ioctl()
    kvm_vm_ioctl_set_memory_region()
        kvm_set_memory_region()
            __kvm_set_memory_region()
                kvm_iommu_unmap_pages() // 原来的slot需要删除，所以需要unmap掉相应的内存区域
                install_new_memslots() //将new分配的memslot写入kvm->memslots[]数组中
                kvm_free_physmem_slot() // 释放旧内存区域相应的物理内存(HPA)
```

# 代码分析

由于**GPA不能直接用于物理 MMU 进行寻址！！！**，所以需要**将GPA转换为HVA**，kvm中利用 `kvm_memory_slot` 数据结构来记录**每一个地址区间**(**Guest中的物理地址区间**)中**GPA与HVA**的**映射关系**

`kvm_mem_slot`结构：

```cpp
struct kvm_lpage_info {
        int disallow_lpage;
};

struct kvm_arch_memory_slot {
        struct kvm_rmap_head *rmap[KVM_NR_PAGE_SIZES];
        struct kvm_lpage_info *lpage_info[KVM_NR_PAGE_SIZES - 1];
        unsigned short *gfn_track[KVM_PAGE_TRACK_MAX];
};

struct kvm_memory_slot {
        // 虚拟机物理地址(即GPA)对应的页框号
        gfn_t base_gfn;
        // 当前slot中包含的page数目
        unsigned long npages;
        // 脏页位图
        unsigned long *dirty_bitmap;
        // 架构相关部分
        struct kvm_arch_memory_slot arch;
        unsigned long userspace_addr;
        u32 flags;
        short id;
};
```