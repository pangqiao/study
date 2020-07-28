https://lore.kernel.org/lkml/556B5316.6010201@hp.com/t/


代码入口在 arch/x86/kernel/kvm.c的kvm_spinlock_init函数, 会调用kernel/locking/qspinlock_paravirt.h的__pv_init_lock_hash函数