
# 作用

guest在发生`VM-exit`时会切换**保存guest的寄存器值**，**加载host寄存器值**，因为host侧可能会使用对应的寄存器的值。

当**再次进入VM**即发生`vcpu_load`时，**保存host寄存器值**，**加载guest的寄存器值**。

来回的`save/load`就是成本，而**某些msr的值**在某种情况是**不会使用**的，那边就无需进行save/load，这些msr如下：

```

```

这些msr只在userspace才会被linux OS使用，kernel模式下并不会被读取，具体msr作用见如上注释。那么当VM发生VM-exit时，此时无需load host msr值，只需要在VM退出到QEMU时再load host msr，因为很多VM-exit是hypervisor直接处理的，无需退出到QEMU，那么此处就有了一些优化。


# 参考

http://oenhan.com/kvm_shared_msrs