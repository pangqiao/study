
# kvm shared msr的作用

guest在发生`VM-exit`时会切换**保存guest的寄存器值**，**加载host寄存器值**，因为host侧可能会使用对应的寄存器的值。

当**再次进入VM**即发生`vcpu_load`时，**保存host寄存器值**，**加载guest的寄存器值**。

来回的`save/load`就是成本，而**某些msr的值**在某种情况是**不会使用**的，那边就无需进行save/load，这些msr如下：

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

这些msr只在**userspace**才会被linux OS使用，**kernel**模式下并**不会**被读取，具体msr作用见如上注释。

那么当VM发生`VM-exit`时，此时**无需load host msr值**，只需要在**VM退出到QEMU**时再load host msr，因为很多`VM-exit`是hypervisor直接处理的，无需退出到QEMU，那么此处就有了一些优化。

# kvm shared msr在KVM模块加载中的处理

kvm shared msr有两个变量，`shared_msrs_global`和`shared_msrs`，对应代码如下：

```cpp
// arch/x86/kvm/x86.c
#define KVM_NR_SHARED_MSRS 16

//标记这有那些MSR需要被shared，具体msr index存储在msrs下
struct kvm_shared_msrs_global {
    int nr;
    u32 msrs[KVM_NR_SHARED_MSRS];
};

//这是per cpu变量，每个cpu下需要存储的msr值都在values中
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

`shared_msrs`在`kvm_arch_init`下初始化：

```cpp
// arch/x86/kvm/x86.c
shared_msrs = alloc_percpu(struct kvm_shared_msrs);
```

`shared_msrs_global`在`hardware_setup`下初始化，就是将`vmx_msr_index`的msr index填充到`shared_msrs_global`中：



# 参考

http://oenhan.com/kvm_shared_msrs