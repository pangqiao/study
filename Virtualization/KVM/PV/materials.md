
头文件:

arch/x86/include/uapi/asm/kvm_para.h


pv的入口和相关数据结构在 arch/x86/kernel/kvm.c , 很明显, 这不是kvm模块的范畴, 因为这也是虚拟机操作系统的一部分

```cpp
const __initconst struct hypervisor_x86 x86_hyper_kvm = {
        .name                   = "KVM",
        .detect                 = kvm_detect,
        .type                   = X86_HYPER_KVM,
        .init.guest_late_init   = kvm_guest_init,
        .init.x2apic_available  = kvm_para_available,
        .init.init_platform     = kvm_init_platform,
};
```

可以看到重新的几个初始化函数