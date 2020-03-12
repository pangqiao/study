
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

## kvm_mem_slot 结构体: GPA到HVA的映射关系

由于**GPA不能直接用于物理 MMU 进行寻址！！！**，所以需要**将GPA转换为HVA**，kvm中利用 `kvm_memory_slot` 数据结构来记录**每一个地址区间**(**Guest中的物理地址区间**)中**GPA与HVA**的**映射关系**

```cpp
struct kvm_rmap_head {
        unsigned long val;
};

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
        /*
         * GPA对应的host虚拟地址(HVA), 由于虚拟机都运行在qemu的地址空间中
         * 而qemu是用户态程序, 所以通常使用root-module下的用户地址空间.
         */
        unsigned long userspace_addr;
        u32 flags;
        short id;
};
```

## kvm_vm_ioctl(): vm指令入口

**kvm ioctl vm指令的入口**，传入的fd为`KVM_CREATE_VM`中返回的fd。主要用于针对VM虚拟机进行控制，如：内存设置、创建VCPU等。

```cpp
static long kvm_vm_ioctl(struct file *filp,
             unsigned int ioctl, unsigned long arg)
{
    struct kvm *kvm = filp->private_data;
    void __user *argp = (void __user *)arg;
    int r;

    if (kvm->mm != current->mm)
        return -EIO;
    switch (ioctl) {
    // 创建VCPU
    case KVM_CREATE_VCPU:
        r = kvm_vm_ioctl_create_vcpu(kvm, arg);
        break;
    // 建立guest物理地址空间中的内存区域与qemu-kvm虚拟地址空间中的内存区域的映射
    case KVM_SET_USER_MEMORY_REGION: {
        // 存放内存区域信息的结构体，该内存区域从qemu-kvm进程的用户地址空间中分配
        struct kvm_userspace_memory_region kvm_userspace_mem;

        r = -EFAULT;
        // 从用户态拷贝相应数据到内核态，入参argp指向用户态地址
        if (copy_from_user(&kvm_userspace_mem, argp,
                        sizeof kvm_userspace_mem))
            goto out;
        // 进入实际处理流程
        r = kvm_vm_ioctl_set_memory_region(kvm, &kvm_userspace_mem);
        break;
    }
...
```

根据流程, 最终调用 `__kvm_set_memory_region()`

```cpp
/*
 * Allocate some memory and give it an address in the guest physical address
 * space.
 *
 * Discontiguous memory is allowed, mostly for framebuffers.
 *
 * Must be called holding kvm->slots_lock for write.
 */
int __kvm_set_memory_region(struct kvm *kvm,
                            const struct kvm_userspace_memory_region *mem)
{
        struct kvm_memory_slot old, new;
        struct kvm_memory_slot *tmp;
        enum kvm_mr_change change;
        int as_id, id;
        int r;
        // 标记检查
        r = check_memory_region_flags(mem);
        if (r)
                return r;

        as_id = mem->slot >> 16;
        id = (u16)mem->slot;
        // 合规检查, 防止用户态恶意传参而导致安全漏洞
        /* General sanity checks */
        if (mem->memory_size & (PAGE_SIZE - 1))
                return -EINVAL;
        if (mem->guest_phys_addr & (PAGE_SIZE - 1))
                return -EINVAL;
        /* We can read the guest memory with __xxx_user() later on. */
        if ((id < KVM_USER_MEM_SLOTS) &&
            ((mem->userspace_addr & (PAGE_SIZE - 1)) ||
             !access_ok((void __user *)(unsigned long)mem->userspace_addr,
                        mem->memory_size)))
                return -EINVAL;
        if (as_id >= KVM_ADDRESS_SPACE_NUM || id >= KVM_MEM_SLOTS_NUM)
                return -EINVAL;
        if (mem->guest_phys_addr + mem->memory_size < mem->guest_phys_addr)
                return -EINVAL;

        /*
         * Make a full copy of the old memslot, the pointer will become stale
         * when the memslots are re-sorted by update_memslots(), and the old
         * memslot needs to be referenced after calling update_memslots(), e.g.
         * to free its resources and for arch specific behavior.
         */
        // 将 kvm_userspace_memory_region->slot 转换为 kvm_mem_slot 结构，该结构从 kvm->memslots 获取
        // 完全拷贝了一份到tmp
        tmp = id_to_memslot(__kvm_memslots(kvm, as_id), id);
        if (tmp) {
                old = *tmp;
                tmp = NULL;
        } else {
                memset(&old, 0, sizeof(old));
                old.id = id;
        }
        // 新设置区域大小为 0, 删除原有区域, 直接返回
        if (!mem->memory_size)
                // 最终还是会调用 kvm_set_memslot
                return kvm_delete_memslot(kvm, mem, &old, as_id);
        // 新的 kvm_memory_slot
        new.id = id;
        // 内存区域起始位置在Guest物理地址空间中的页框号
        new.base_gfn = mem->guest_phys_addr >> PAGE_SHIFT;
        // 内存区域大小转换为page单位
        new.npages = mem->memory_size >> PAGE_SHIFT;
        new.flags = mem->flags;
        // HVA
        new.userspace_addr = mem->userspace_addr;

        if (new.npages > KVM_MEM_MAX_NR_PAGES)
                return -EINVAL;
        // 旧 pages 为0, 说明要创建新内存区域
        if (!old.npages) {
                /*
                 * 设置 KVM_MR_CREATE 标记
                 */
                change = KVM_MR_CREATE;
                new.dirty_bitmap = NULL;
                memset(&new.arch, 0, sizeof(new.arch));
        } else { /* Modify an existing slot. */
                // 判断是否修改现有的内存区域
                // 旧 page 数不为 0
                // 修改的区域的HVA不同 或者 大小不同 或者 flag中的
                // KVM_MEM_READONLY 标记不同，直接退出。
                if ((new.userspace_addr != old.userspace_addr) ||
                    (new.npages != old.npages) ||
                    ((new.flags ^ old.flags) & KVM_MEM_READONLY))
                        return -EINVAL;
                /*
                 * 走到这，说明被修改的区域HVA和大小都是相同的
                 *
                 * 判断区域起始的 GFN 是否相同，如果是，则说明需
                 * 要在Guest物理地址空间中move这段区域，设置KVM_MR_MOVE标记
                 */
                if (new.base_gfn != old.base_gfn)
                        change = KVM_MR_MOVE;
                // 如果仅仅是flag不同，则仅修改标记，设置KVM_MR_FLAGS_ONLY标记
                else if (new.flags != old.flags)
                        change = KVM_MR_FLAGS_ONLY;
                // 否则, 啥也不干, 退出
                else /* Nothing to change. */
                        return 0;

                /* Copy dirty_bitmap and arch from the current memslot. */
                new.dirty_bitmap = old.dirty_bitmap;
                memcpy(&new.arch, &old.arch, sizeof(new.arch));
        }
        if ((change == KVM_MR_CREATE) || (change == KVM_MR_MOVE)) {
                /* Check for overlaps */
                // 检查现有区域中是否重叠, 有的话直接返回
                kvm_for_each_memslot(tmp, __kvm_memslots(kvm, as_id)) {
                        // 当前要加入的slot, 不管, 直接跳过
                        if (tmp->id == id)
                                continue;
                        // new_end > slot_base && new_base < slot_end，说明已经有覆盖该段内存了
                        if (!((new.base_gfn + new.npages <= tmp->base_gfn) ||
                              (new.base_gfn >= tmp->base_gfn + tmp->npages)))
                                return -EEXIST;
                }
        }

        /* Allocate/free page dirty bitmap as needed */
        if (!(new.flags & KVM_MEM_LOG_DIRTY_PAGES))
                new.dirty_bitmap = NULL;
        else if (!new.dirty_bitmap) {
                r = kvm_alloc_dirty_bitmap(&new);
                if (r)
                        return r;

                if (kvm_dirty_log_manual_protect_and_init_set(kvm))
                        bitmap_set(new.dirty_bitmap, 0, new.npages);
        }

        r = kvm_set_memslot(kvm, mem, &old, &new, as_id, change);
        if (r)
                goto out_bitmap;

        if (old.dirty_bitmap && !new.dirty_bitmap)
                kvm_destroy_dirty_bitmap(&old);
        return 0;

out_bitmap:
        if (new.dirty_bitmap && !old.dirty_bitmap)
                kvm_destroy_dirty_bitmap(&new);
        return r;
}
EXPORT_SYMBOL_GPL(__kvm_set_memory_region);
```

该函数主要用来建立**guest物理地址空间**(虚拟机物理地址空间)中的**内存区域**与`qemu-kvm`**虚拟地址空间**(宿主机虚拟地址, HVA)中的**内存区域的映射**, 相应信息由`uerspace_memory_region` 参数传入，而其源头来自于**用户态qemu-kvm**。

每次调用**设置一个内存区间**。内存区域可以**不连续**(实际的物理内存区域也经常不连续，因为有可能有保留内存)

最终调用`kvm_set_memslot()`

```cpp
static int kvm_set_memslot(struct kvm *kvm,
                           const struct kvm_userspace_memory_region *mem,
                           struct kvm_memory_slot *old,
                           struct kvm_memory_slot *new, int as_id,
                           enum kvm_mr_change change)
{
        struct kvm_memory_slot *slot;
        struct kvm_memslots *slots;
        int r;
        // 复制kvm->memslots的副本
        slots = kvm_dup_memslots(__kvm_memslots(kvm, as_id), change);
        if (!slots)
                return -ENOMEM;
        // 如果删除或move内存区域
        if (change == KVM_MR_DELETE || change == KVM_MR_MOVE) {
                /*
                 * Note, the INVALID flag needs to be in the appropriate entry
                 * in the freshly allocated memslots, not in @old or @new.
                 */
                // 获取旧的slot(内存条模型)
                slot = id_to_memslot(slots, old->id);
                slot->flags |= KVM_MEMSLOT_INVALID;

                /*
                 * We can re-use the old memslots, the only difference from the
                 * newly installed memslots is the invalid flag, which will get
                 * dropped by update_memslots anyway.  We'll also revert to the
                 * old memslots if preparing the new memory region fails.
                 */
                // 安装新memslots，返回旧的memslots
                slots = install_new_memslots(kvm, as_id, slots);

                /* From this point no new shadow pages pointing to a deleted,
                 * or moved, memslot will be created.
                 *
                 * validation of sp->gfn happens in:
                 *      - gfn_to_hva (kvm_read_guest, gfn_to_pfn)
                 *      - kvm_is_visible_gfn (mmu_check_root)
                 */
                // flush影子页表中的条目
                kvm_arch_flush_shadow_memslot(kvm, slot);
        }
        // 处理private memory slots, 对其分配用户态地址, 即HVA
        r = kvm_arch_prepare_memory_region(kvm, new, mem, change);
        if (r)
                goto out_slots;

        update_memslots(slots, new, change);
        // 安装新memslots, 将其写入kvm->memslots[]数组, 返回旧的memslots
        slots = install_new_memslots(kvm, as_id, slots);

        kvm_arch_commit_memory_region(kvm, mem, old, new, change);
        // 释放旧内存区域相应的物理内存, HPA
        kvfree(slots);
        return 0;

out_slots:
        if (change == KVM_MR_DELETE || change == KVM_MR_MOVE)
                slots = install_new_memslots(kvm, as_id, slots);
        kvfree(slots);
        return r;
}
```

```cpp
int kvm_arch_prepare_memory_region(struct kvm *kvm,
                                struct kvm_memory_slot *memslot,
                                const struct kvm_userspace_memory_region *mem,
                                enum kvm_mr_change change)
{
        // 创建或move区域
        if (change == KVM_MR_CREATE || change == KVM_MR_MOVE)
                // 初始化memslot中arch相关内容
                return kvm_alloc_memslot_metadata(memslot,
                                                  mem->memory_size >> PAGE_SHIFT);
        return 0;
}
```