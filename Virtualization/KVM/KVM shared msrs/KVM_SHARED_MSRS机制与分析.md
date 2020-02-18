
# 作用

guest在发生`VM-exit`时会切换**保存guest的寄存器值**，**加载host寄存器值**，因为host侧可能会使用对应的寄存器的值。

当**再次进入VM**即发生`vcpu_load`时，**保存host寄存器值**，**加载guest的寄存器值**。

来回的`save/load`就是成本，而**某些msr的值**在某种情况是**不会使用**的，那边就无需进行save/load，这些msr如下：

```cpp
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

那么当VM发生`VM-exit`时，此时**无需load host msr值**，只需要在**VM退出到QEMU**时再load host msr，因为很多VM-exit是hypervisor直接处理的，无需退出到QEMU，那么此处就有了一些优化。



# 参考

http://oenhan.com/kvm_shared_msrs