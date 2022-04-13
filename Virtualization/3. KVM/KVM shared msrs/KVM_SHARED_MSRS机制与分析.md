
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. kvm shared msr的作用](#1-kvm-shared-msr的作用)
- [2. kvm shared msr相关的两个变量以及定义](#2-kvm-shared-msr相关的两个变量以及定义)
- [3. kvm shared msr在KVM模块加载中的处理](#3-kvm-shared-msr在kvm模块加载中的处理)
  - [3.1. shared_masrs初始化](#31-shared_masrs初始化)
  - [3.2. shared_msrs_global初始化](#32-shared_msrs_global初始化)
- [4. kvm shared msr在VM创建中的处理](#4-kvm-shared-msr在vm创建中的处理)
- [5. kvm shared msr在VM运行中的切换](#5-kvm-shared-msr在vm运行中的切换)
- [6. user_return_notifier的作用](#6-user_return_notifier的作用)
- [7. 问题出现的场景](#7-问题出现的场景)
- [8. 参考](#8-参考)

<!-- /code_chunk_output -->

在做**KVM模块热升级**的过程中碰到了这个坑, 通读代码时本来以为msr在vcpu load和vcpu exit中进行切换, 便忽略了`kvm_shared_msr_cpu_online`, 没想到它能直接重置了host, 连投胎的过程都没有, 直接没办法debug, 还是要多亏这个问题在某种情况下不必现, 才更快找到原因, 顺便看了一下`kvm_shared_msrs`机制, 理清楚了问题的触发逻辑, 记录如下. 

# 1. kvm shared msr的作用

guest在发生`VM-exit`时会切换**保存guest的寄存器值**, **加载host寄存器值**, 因为host侧可能会使用对应的寄存器的值. 

当**再次进入VM**即发生`vcpu_load`时, **保存host寄存器值**, **加载guest的寄存器值**. 

来回的`save/load`就是成本, 而**某些msr的值**在**某种情况**是**不会使用**的, 那便就无需进行save/load, 这些msr如下: 

```cpp
// arch/x86/kvm/vmx/vmx.c
/* x86-64 specific MSRs */
#define MSR_EFER                0xc0000080 /* extended feature register */
#define MSR_STAR                0xc0000081 /* legacy mode SYSCALL target */
#define MSR_LSTAR               0xc0000082 /* long mode SYSCALL target */
#define MSR_CSTAR               0xc0000083 /* compat mode SYSCALL target */
#define MSR_SYSCALL_MASK        0xc0000084 /* EFLAGS mask for syscall */
#define MSR_FS_BASE             0xc0000100 /* 64bit FS base */
#define MSR_GS_BASE             0xc0000101 /* 64bit GS base */
#define MSR_KERNEL_GS_BASE      0xc0000102 /* SwapGS GS shadow */
#define MSR_TSC_AUX             0xc0000103 /* Auxiliary TSC */

/*
 * Though SYSCALL is only supported in 64-bit mode on Intel CPUs, kvm
 * will emulate SYSCALL in legacy mode if the vendor string in guest
 * CPUID.0:{EBX,ECX,EDX} is "AuthenticAMD" or "AMDisbetter!" To
 * support this emulation, IA32_STAR must always be included in
 * vmx_msr_index[], even in i386 builds.
 */
const u32 vmx_msr_index[] = {
#ifdef CONFIG_X86_64
        MSR_SYSCALL_MASK, MSR_LSTAR, MSR_CSTAR,
#endif
        MSR_EFER, MSR_TSC_AUX, MSR_STAR,
        MSR_IA32_TSX_CTRL,
};
```

这些msr只在**userspace**才会被linux OS使用, **kernel**模式下并**不会**被读取, 具体msr作用见如上注释. 

那么当VM发生`VM-exit`时, 此时**无需load host msr值**, 只需要在**VM退出到QEMU**时再load host msr, 因为很多`VM-exit`是hypervisor直接处理的, 无需退出到QEMU, 那么此处就有了一些优化. 

# 2. kvm shared msr相关的两个变量以及定义

kvm shared msr有两个变量, `shared_msrs_global`和`shared_msrs`, 对应代码如下: 

```cpp
// arch/x86/kvm/x86.c
#define KVM_NR_SHARED_MSRS 16

//标记这有那些MSR需要被shared, 具体msr index存储在msrs下
struct kvm_shared_msrs_global {
    int nr;
    u32 msrs[KVM_NR_SHARED_MSRS];
};

//这是per cpu变量, 每个cpu下需要存储的msr值都在values中
struct kvm_shared_msrs {
    struct user_return_notifier urn;
    bool registered;
    struct kvm_shared_msr_values {
        //host上msr值save到此处
        u64 host;
        //当前物理CPU上msr的值
        u64 curr;
    } values[KVM_NR_SHARED_MSRS];
};

static struct kvm_shared_msrs_global __read_mostly shared_msrs_global;
static struct kvm_shared_msrs __percpu *shared_msrs;
```

# 3. kvm shared msr在KVM模块加载中的处理

`kvm_arch_init`和`hardware_setup`都是在**KVM模块加载过程**中执行的. 

## 3.1. shared_masrs初始化

`shared_msrs`在`kvm_arch_init`下初始化: 

```cpp
// arch/x86/kvm/x86.c
shared_msrs = alloc_percpu(struct kvm_shared_msrs);
```

## 3.2. shared_msrs_global初始化

`shared_msrs_global`在`hardware_setup`下初始化, 就是将`vmx_msr_index`的msr index填充到`shared_msrs_global`中: 

```cpp
void kvm_define_shared_msr(unsigned slot, u32 msr)
{
    BUG_ON(slot >= KVM_NR_SHARED_MSRS);
    shared_msrs_global.msrs[slot] = msr;
    if (slot >= shared_msrs_global.nr)
        shared_msrs_global.nr = slot + 1;
}
static __init int hardware_setup(void)
{
    for (i = 0; i < ARRAY_SIZE(vmx_msr_index); ++i)
        kvm_define_shared_msr(i, vmx_msr_index[i]);
}
```

# 4. kvm shared msr在VM创建中的处理

VM创建过程中执行`kvm_arch_hardware_enable`, 继而调用`kvm_shared_msr_cpu_online`, 再调用`shared_msr_update`函数负责**存储host的msr值**

```cpp
static void kvm_shared_msr_cpu_online(void)
{
    unsigned i;
 
    for (i = 0; i < shared_msrs_global.nr; ++i)
        shared_msr_update(i, shared_msrs_global.msrs[i]);
}
static void shared_msr_update(unsigned slot, u32 msr)
{
    u64 value;
    unsigned int cpu = smp_processor_id();
    struct kvm_shared_msrs *smsr = per_cpu_ptr(shared_msrs, cpu);
 
    /* only read, and nobody should modify it at this time,
     * so don't need lock */
    if (slot >= shared_msrs_global.nr) {
        printk(KERN_ERR "kvm: invalid MSR slot!");
        return;
    }
//VM-enter还没发生, 此时msr是host值, 而且host msr只获取这一次, VM生命周期内再也不会更新
    rdmsrl_safe(msr, &value);
    smsr->values[slot].host = value;
    smsr->values[slot].curr = value;
}
```

# 5. kvm shared msr在VM运行中的切换

前面提到**host msr**值已经**保存**在`smsr->values[slot].host`下, 那么**进入guest前**则会执行`vmx_prepare_switch_to_guest`, 通过`kvm_set_shared_msr`完成**加载guest msr的动作**. 

```cpp
    /*
        * Note that guest MSRs to be saved/restored can also be changed
        * when guest state is loaded. This happens when guest transitions
        * to/from long-mode by setting MSR_EFER.LMA.
        */
    if (!vmx->guest_msrs_ready) {
        vmx->guest_msrs_ready = true;
        for (i = 0; i < vmx->save_nmsrs; ++i)
            kvm_set_shared_msr(vmx->guest_msrs[i].index,
                        vmx->guest_msrs[i].data,
                        vmx->guest_msrs[i].mask);

    }
    if (vmx->guest_state_loaded)
        return;
```

另外因为guest可能也会设置guest msr而发生`VM-exit`, 这一步则由`vmx_set_msr`来完成, 此处可知, **guest msr**保存在`vmx->guest_msrs`中. 

再说`kvm_set_shared_msr`, 就是**设置物理MSR值**, 同时将值保存在`smsr->values[slot].curr`. 

```cpp
int kvm_set_shared_msr(unsigned slot, u64 value, u64 mask)
{
    unsigned int cpu = smp_processor_id();
    struct kvm_shared_msrs *smsr = per_cpu_ptr(shared_msrs, cpu);
    int err;
 
    if (((value ^ smsr->values[slot].curr) & mask) == 0)
        return 0;
    smsr->values[slot].curr = value;
    err = wrmsrl_safe(shared_msrs_global.msrs[slot], value);
    if (err)
        return 1;
 
    if (!smsr->registered) {
        smsr->urn.on_user_return = kvm_on_user_return;
        user_return_notifier_register(&smsr->urn);
        smsr->registered = true;
    }
    return 0;
}
```

# 6. user_return_notifier的作用

`kvm_set_shared_msr`末尾设置了`smsr->urn.on_user_return`为`kvm_on_user_return`, `user_return_notifier_register`将其注册到`return_notifier_list`, 顾名思义, 就是**返回用户态时的通知链**. 

在`do_syscall_64`和`do_fast_syscall_32`都会处理到`prepare_exit_to_usermode`, 在`exit_to_usermode_loop`中会执行`fire_user_return_notifiers`, 将**链表上的函数**执行一遍. 

```cpp
void fire_user_return_notifiers(void)
{
    struct user_return_notifier *urn;
    struct hlist_node *tmp2;
    struct hlist_head *head;
 
    head = &get_cpu_var(return_notifier_list);
    hlist_for_each_entry_safe(urn, tmp2, head, link)
        urn->on_user_return(urn);
    put_cpu_var(return_notifier_list);
}
```

实际上此时使用`user_return_notifier_register`只有`kvm_set_shared_msr`.

看一下**回调函数**`kvm_on_user_return`, 就干了两件事, 将`smsr->values[slot].host`写入到**msr中**, 和**取消**`kvm_on_user_return`的注册. 

```cpp
static void kvm_on_user_return(struct user_return_notifier *urn)
{
    unsigned slot;
    struct kvm_shared_msrs *locals
        = container_of(urn, struct kvm_shared_msrs, urn);
    struct kvm_shared_msr_values *values;
    unsigned long flags;
 
    /*
     * Disabling irqs at this point since the following code could be
     * interrupted and executed through kvm_arch_hardware_disable()
     */
    local_irq_save(flags);
    if (locals->registered) {
        locals->registered = false;
        user_return_notifier_unregister(urn);
    }
    local_irq_restore(flags);
    for (slot = 0; slot < shared_msrs_global.nr; ++slot) {
        values = &locals->values[slot];
        if (values->host != values->curr) {
            wrmsrl(shared_msrs_global.msrs[slot], values->host);
            values->curr = values->host;
        }
    }
}
```

# 7. 问题出现的场景

当**KVM模块**A上的**VM**的某个VCPU运行在非用户态时, **KVM模块B**加载, 因为`kvm_shared_msr_cpu_online`是通过`kvm_arch_hardware_enable`, `hardware_enable_nolock`在`hardware_enable_all`下的`on_each_cpu`函数上执行, 即`kvm_shared_msr_cpu_online`被执行前, KVM模块A上的VCPU并没有发生从`kernel->userspace`, 那么此时KVM模块B上`kvm_shared_msrs.values[X].host`存储的则是**KVM模块A**上**VM的guest msr值**, 当KVM模块B上的VM切换到QEMU时, 此刻host msr则被置为KVM模块A上VM的guest msr, 于是就崩了. 

# 8. 参考

http://oenhan.com/kvm_shared_msrs