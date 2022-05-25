KVM: Posted Interrupt

https://zhuanlan.zhihu.com/p/51018597

https://kernelgo.org/posted-interrupt.html


Posted Interrupt 允许APIC中断直接注入到guest而不需要VM-Exit

-  需要给guest传递中断的时候, 如果vcpu正在运行, 那么更新posted-intrrupt请求位图, 并向vcpu发送通知, vcpu自动处理该中断, 不需要软件干预

-  如果vcpu没有在运行或者已经有通知事件pending, 那么什么都不做, 中断会在下次VM-Entry的时候处理

-  Posted Interrupt需要一个特别的IPI来给Guest传递中断, 并且有较高的优先级, 不能被阻塞

-  ”acknowledge interrupt on exit"允许中断CPU运行在non-root模式产生时, 可以被VMX的handler处理, 而不是IDT的handler处理


KVM: x86: add method to test PIR bitmap vector
* v3: https://www.spinics.net/lists/kvm/msg111674.html
* v4: https://www.spinics.net/lists/kvm/msg111881.html