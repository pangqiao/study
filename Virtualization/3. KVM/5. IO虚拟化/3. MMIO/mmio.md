
# MMIO和PIO的区别

I/O作为CPU和外设交流的一个渠道，主要分为两种，一种是Port I/O，一种是MMIO(Memory mapping I/O)。 

前者就是我们常说的I/O端口，它实际上的应该被称为I/O地址空间。 对于x86架构来说，通过IN/OUT指令访问。PC架构一共有65536个8bit的I/O端口，组成64KI/O地址空间，编号从0~0xFFFF。连续两个8bit的端口可以组成一个16bit的端口，连续4个组成一个32bit的端口。I/O地址空间和CPU的物理地址空间是两个不同的概念，例如I/O地址空间为64K，一个32bit的CPU物理地址空间是4G。 

MMIO占用CPU的物理地址空间，对它的访问可以使用CPU访问内存的指令进行。一个形象的比喻是把文件用mmap()后，可以像访问内存一样访问文件、同样，MMIO是用访问内存一样的方式访问I/O资源，如设备上的内存。MMIO不能被cache（有特殊情况，如VGA）。 

Port I/O和MMIO的主要区别在于：

(1) 前者不占用CPU的物理地址空间，后者占有（这是对x86架构说的，一些架构，如IA64，port I/O占用物理地址空间）。

(2) 前者是顺序访问。也就是说在一条I/O指令完成前，下一条指令不会执行。例如通过Port I/O对设备发起了操作，造成了设备寄存器状态变化，这个变化在下一条指令执行前生效。uncache的MMIO通过uncahce memory的特性保证顺序性。

(3) 使用方式不同。 

由于port I/O有独立的64KI/O地址空间，但CPU的地址线只有一套，所以必须区分地址属于物理地址空间还是I/O地址空间。早期的CPU有一个M/I针脚来表示当前地址的类型，后来似乎改了。刚才查了一下，叫request command line，没搞懂，觉得还是一个针脚。

IBM PC架构规定了一些固定的I/O端口，ISA设备通常也有固定的I/O端口，这些可以通过ICH（南桥）的规范查到。PCI设备的I/O端口和MMIO基地址通过设备的PCI configure space报告给操作系统，这些内容以前的帖子都很多，可以查阅一下。 

通常遇到写死在I/O指令中的I/O端口，如果不是ISA设备，一般都是架构规定死的端口号，可查阅规范。

# qemu-kvm中的MMIO

我们知道X86体系结构上对设备进行访问可以通过PIO方式和MMIO(Memory Mapped I/O)两种方式进行， 那么QEMU-KVM具体是如何实现设备MMIO访问的呢？

MMIO是直接将设备I/O映射到物理地址空间内，虚拟机物理内存的虚拟化又是通过EPT机制来完成的， 那么模拟设备的MMIO实现也需要利用EPT机制．虚拟机的EPT页表是在EPT_VIOLATION异常处理的时候建立起来的， 对于模拟设备而言访问MMIO肯定要触发VM_EXIT然后交给QEMU/KVM去处理，那么怎样去标志MMIO访问异常呢？ 查看Intel SDM知道这是通过利用EPT_MISCONFIG来实现的．那么EPT_VIOLATION与EPT_MISCONFIG的区别是什么?

EXIT_REASON_EPT_VIOLATION is similar to a "page not present" pagefault.

EXIT_REASON_EPT_MISCONFIG is similar to a "reserved bit set" pagefault.

EPT_VIOLATION表示的是对应的物理页不存在，而EPT_MISCONFIG表示EPT页表中有非法的域．

那么这里有２个问题需要弄清楚．

## KVM如何标记EPT是MMIO类型 ?

hardware_setup时候虚拟机如果开启了ept支持就调用ept_set_mmio_spte_mask初始化shadow_mmio_mask， 设置EPT页表项**最低 3 bit**为：`110b`就会触发ept_msconfig（110b表示该页**可读可写**但是**还未分配**或者**不存在**，这显然是一个错误的EPT页表项）.

```cpp
#define VMX_EPT_WRITABLE_MASK                   0x2ull
#define VMX_EPT_EXECUTABLE_MASK                 0x4ull

/* The mask to use to trigger an EPT Misconfiguration in order to track MMIO */
#define VMX_EPT_MISCONFIG_WX_VALUE              (VMX_EPT_WRITABLE_MASK |       \
                                                 VMX_EPT_EXECUTABLE_MASK)


static void ept_set_mmio_spte_mask(void)
{
        /*
         * EPT Misconfigurations can be generated if the value of bits 2:0
         * of an EPT paging-structure entry is 110b (write/execute).
         */
        kvm_mmu_set_mmio_spte_mask(VMX_EPT_MISCONFIG_WX_VALUE, 0);
}
```

