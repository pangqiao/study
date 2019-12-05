
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 开源社区介绍](#1-开源社区介绍)
  - [1.1. Linux开源社区](#11-linux开源社区)
  - [1.2. KVM开源社区](#12-kvm开源社区)
  - [1.3. QEMU开源社区](#13-qemu开源社区)
  - [1.4. 其他开源社区](#14-其他开源社区)
- [2. 代码结构简介](#2-代码结构简介)
  - [2.1. KVM代码](#21-kvm代码)
    - [2.1.1. KVM框架的核心代码](#211-kvm框架的核心代码)
    - [2.1.2. 与硬件架构相关的代码](#212-与硬件架构相关的代码)
    - [2.1.3. KVM相关的头文件](#213-kvm相关的头文件)
  - [2.2. QEMU代码](#22-qemu代码)
  - [2.3. KVM单元测试代码](#23-kvm单元测试代码)
    - [2.3.1. 介绍](#231-介绍)
    - [2.3.2. 代码目录](#232-代码目录)
    - [2.3.3. 基本原理](#233-基本原理)
    - [2.3.4. 编译运行](#234-编译运行)
- [3. 向开源社区贡献代码](#3-向开源社区贡献代码)
  - [开发者邮件列表](#开发者邮件列表)

<!-- /code_chunk_output -->

# 1. 开源社区介绍

“开源即开放源代码（Open Source），保证任何人都可以根据“自由许可证”获得软件的源代码，并且允许任何人对其代码进行修改并重新发布。

在英文中，Free可以有两个意思：一个是免费，一个是自由。当提及“Free Software”（自由软件）时，应该将“Free”理解为“自由的演讲”（Free Speech）中的自由，而不是“免费的啤酒”（Free Beer）中的免费。

一般来说，每个开源软件都有一个对应的开源社区.

## 1.1. Linux开源社区

KVM是Linux内核的一个模块，因此KVM社区也与Linux内核社区非常类似，也可以算作Linux内核社区的一部分。这里介绍的Linux开源社区主要是指Linux内核的社区而不是Linux系统的用户工具和发行版社区。

**Linus**并不会亲自审查每一个新的补丁、每一行新 的代码，而是将**大部分的工作**都交给各个**子系统的维护者**去处理。

各个维护者下面可能还有一些**驱动程序或几个特殊文件的维护者**，Linus自己则主要把握一些大的方向及合并(merge)各个子系统维护者的分支到Linux主干树。

如图所示，**普通的Linux内核开发者**一般都是向驱动程序或子系统的维护者提交代码，提交的代码经过**维护者**和开发社区中的**其他人审核**之后，才能进入**子系统！！！维护者**的**开发代码仓库！！！**，进入每个Linux内核的**合并窗口(merge window**)之后才能进入真正的Linux upstream代码仓库中。

注: upstream也被翻译为“上游”，是指在一些开源软件的开发过程中**最主干**的且**一直向前发展的代码树**。upstream中包含了**最新的代码**，一些新增的功能特性和修复bug的代码一般都先进入upstream中，然后才会到某一个具体的发型版本中。对于Linux内核来说， Linux upstream就是指最新的Linux内核代码树，而一些Linux发行版(如RHEL、Fedora、 Ubuntu等)的内核都是基于upstream中的某个版本再加上一部分patch来制作的。

在Linux内核中有许多的**子系统**(如:内存管理、PCI总线、网络子系统、ext4文件系 统、SCSI子系统、USB子系统、KVM模块等)，也分为更细的**许多驱动**(如:Intel的以 太网卡驱动、USB XHCI驱动、Intel的DRM驱动等)。各个**子系统**和**驱动**分别由相应的开发者来维护，如:PCI子系统的维护者是来自Google的Bjorn Helgaas，Intel以太网卡驱动 (如igb、ixgbe)的维护者是来自Intel的Jeff Kirsher。关于Linux内核中维护者相关的信 息，可以查看内核代码中名为“MAINTAINERS”的文件。

目前，Linux内核版本的发布周期一般是2~3个月，在这段时间中，一般会发布七八个RC[2]版本。

注: RC即**Release Candidate**，与Alpha、Beta等版本类似，RC也是一种**正式产品发布前**的一种**测试版本**。RC是**发布前的候选版本**，比Alpha/Beta更加成熟。一般来说，RC版本是前面已经经过测试并修复了大部分bug的，一般比较稳定、接近正式发布的产品。

![2019-11-27-16-17-43.png](./images/2019-11-27-16-17-43.png)

## 1.2. KVM开源社区

KVM(Kernel Virtual Machine)是Linux内核中原生的虚拟机技术，KVM内核部分的 代码全部都在Linux内核中，是Linux内核的一部分(相当于一个内核子系统)。

KVM项目的官方主页是 https://www.linux-kvm.org 。

除了平时在KVM邮件列表中讨论之外，KVM Forum是KVM开发者、用户等相互交流的一个重要会议。KVM Forum一般每年举行一届，其内容主要涉及KVM的一些最新开发 的功能、未来的发展思路，以及一些管理工具的开发。关于KVM Forum，可以参考其官方网页[3]，该网页提供了各届KVM Forum的议程和演讲文档，供用户下载。

KVM Forum官网: http://www.linux-kvm.org/page/KVM_Forum

## 1.3. QEMU开源社区

QEMU(Quick EMUlator)是一个实现**硬件虚拟化**的开源软件，它通过**动态二进制转换**实现了对中央处理单元(CPU)的模拟，并且提供了**一整套模拟的设备模型**，从而可以使未经修改的各种操作系统得以在QEMU上运行。

QEMU自身就是一个**独立的、完整的虚拟机模拟器**，可以独立**模拟CPU**和其他一些**基本外设**。除此之外，QEMU还可以为KVM、Xen等流行的虚拟化技术提供设备模拟功能。

在用普通QEMU来配合KVM使用时，在QEMU命令行启动客户机时要加上“\-enable\-kvm”参 数来使用KVM加速，而较老的qemu-kvm命令行默认开启了使用KVM加速的选项。

QEMU社区的代码仓库网址是 http://git.qemu.org ，其中qemu.git就是QEMU upstream的主干代码树。可以使用GIT工具，通过两个URL( git://git.qemu.org/qemu.git 和 http://git.qemu.org/git/qemu.git )中的任意一个来下载QEMU的最新源代码。

## 1.4. 其他开源社区

1)Libvirt，一个著名的虚拟化API项目。

https://libvirt.org

2)OpenStack，一个扩展性良好的开源云操作系统。 

www.openstack.org

3)CloudStack，一个可提供高可用性、高扩展性的开源云计算平台。 

http://cloudstack.apache.org 

4)ZStack，一个简单、强壮、可扩展性强的云计算管理平台。 

http://www.zstack.io

5)Xen，一个功能强大的虚拟化软件。

http://xen.org 

6)Ubuntu，一个免费开源的、外观漂亮的、非常流行的Linux操作系统。 

www.ubuntu.com

7)Fedora，一个免费的、开源的Linux操作系统。

fedoraproject.org 

8)CentOS，一个基于RHEL的开源代码进行重新编译构建的开源Linux操作系统。 

http://www.centos.org 

9)openSUSE，一个开源社区驱动的、开放式开发的Linux操作系统。 

www.opensuse.org

# 2. 代码结构简介

## 2.1. KVM代码

由于**Linux内核**过于庞大，因此**KVM开发者的代码**一般先进入**KVM社区的kvm.git代码仓库**，再由**KVM维护者**定期地将代码提**供给Linux 内核的维护者(即Linus Torvalds**)，并由其添加到**Linux内核代码仓库**中。可以分别查看如下两个网页来了解最新的KVM开发和Linux内核的代码仓库的状态。

```
https://git.kernel.org/cgit/virt/kvm/kvm.git/ 
https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/
```

KVM内核部分的代码主要由3部分组成:KVM框架的核心代码、与硬件架构相关的代码和KVM相关的头文件。在Linux 4.14.12版本中，KVM相关的代码行数大约是17多万行。基于Linux 4.14.12版本的Linux内核为例，对KVM代码结构进行简单的介绍。

### 2.1.1. KVM框架的核心代码

与具体硬件架构无关的代码，位于virt/kvm/目录中，有22 135行代码。

```
# ls virt/kvm/
arm  async_pf.c  async_pf.h  coalesced_mmio.c  coalesced_mmio.h  eventfd.c  irqchip.c  Kconfig  kvm_main.c  vfio.c  vfio.h
```

其中，`kvm_main.c`文件是KVM代码中最核心的文件之一，`kvm_main.c`中的`kvm_init`函数是与**硬件架构无关**的**KVM初始化入口**。

### 2.1.2. 与硬件架构相关的代码

不同的处理器架构有对应的KVM代码，位于arch/$ARCH/kvm/目录中。KVM目前支 持的架构包括:X86、ARM、ARM64、PowerPC、S390、MIPS等。与处理器硬件架构相关的KVM代码目录如下:

```
# ls -d arch/*/kvm
arch/arm64/kvm  arch/arm/kvm  arch/mips/kvm  arch/powerpc/kvm  arch/s390/kvm  arch/x86/kvm
```

在KVM支持的架构中，Intel和AMD的x86架构上的功能是最完善和成熟的。x86架构 相关的代码位于arch/x86/kvm/目录中，有51 911行代码。其代码结构如下:

```
# ls arch/x86/kvm/
cpuid.c  cpuid.h  debugfs.c  emulate.c  hyperv.c  hyperv.h  i8254.c  i8254.h  i8259.c  ioapic.c  ioapic.h  irq.c  irq_comm.c  irq.h  Kconfig  kvm_cache_regs.h  lapic.c  lapic.h  Makefile  mmu  mmu_audit.c  mmu.h  mmutrace.h  mtrr.c  pmu_amd.c  pmu.c  pmu.h  svm.c  trace.h  tss.h  vmx  x86.c  x86.h
```

其中，`vmx.c`和`svm.c`分别是Intel和AMD CPU的架构相关模块`kvm-intel`和`kvm-amd`的主要代码。

以`vmx.c`为例，其中`vmx_init()`函数是`kvm-intel`模块加载时执行的初始化函数，而 `vmx_exit()`函数是`kvm-intel`模块卸载时执行的函数。

### 2.1.3. KVM相关的头文件

在前面提及的代码中，一般都会引用一些相关的头文件，包括与各个处理器架构相关 的头文件(位于`arch/*/include/asm/kvm*`)和其他的头文件。KVM相关的头文件的结构如下:

```
# ls arch/*/include/asm/kvm*
arch/x86/include/asm/kvm_emulate.h
arch/x86/include/asm/kvm_host.h
arch/x86/include/asm/kvm_page_track.h
arch/x86/include/asm/kvm_para.h
arch/x86/include/asm/kvm_vcpu_regs.h
arch/x86/include/asm/kvmclock.h

.......
```

另外, 在Linux内核代码中关于KVM的文档, 主要位于`Documentation/virtual/kvm/*`和`Documentation/*kvm/*.txt`, 如下:

```
# ls Documentation/virt/kvm/*
Documentation/virt/kvm/amd-memory-encryption.rst  Documentation/virt/kvm/halt-polling.txt  Documentation/virt/kvm/locking.txt  Documentation/virt/kvm/nested-vmx.txt        Documentation/virt/kvm/s390-diag.txt
Documentation/virt/kvm/api.txt                    Documentation/virt/kvm/hypercalls.txt    Documentation/virt/kvm/mmu.txt      Documentation/virt/kvm/ppc-pv.txt            Documentation/virt/kvm/timekeeping.txt
Documentation/virt/kvm/cpuid.rst                  Documentation/virt/kvm/index.rst         Documentation/virt/kvm/msr.txt      Documentation/virt/kvm/review-checklist.txt  Documentation/virt/kvm/vcpu-requests.rst

Documentation/virt/kvm/arm:
hyp-abi.txt  psci.txt  pvtime.rst

Documentation/virt/kvm/devices:
arm-vgic-its.txt  arm-vgic.txt  arm-vgic-v3.txt  mpic.txt  README  s390_flic.txt  vcpu.txt  vfio.txt  vm.txt  xics.txt  xive.txt
```

## 2.2. QEMU代码

QEMU 1.3.0版本已将qemu-kvm中的代码全部合并到纯QEMU中了。

QEMU代码仓库如下:

```
http://git.qemu.org/?p=qemu.git;a=summary
```

......

## 2.3. KVM单元测试代码

### 2.3.1. 介绍

KVM相关的代码除了KVM和QEMU自身的代码之外，还包括本节介绍的KVM单元测 试代码和下一节将介绍的KVM Autotest代码。KVM单元测试代码用于测试一些细粒度的 系统底层的特性(如:客户机CPU中的MSR的值)，在一些重要的特性被加入KVM时， KVM维护者也会要求代码作者在KVM单元测试代码中添加对应的测试用例。

https://www.linux-kvm.org/page/KVM-unit-tests

KVM单元测试的代码仓库也存放在Linux内核社区的官方站点，参考如下的网页链接: 

https://git.kernel.org/cgit/virt/kvm/kvm-unit-tests.git

### 2.3.2. 代码目录

KVM单元测试的代码目录结构如下:

```
# ls
api  arm  configure  COPYRIGHT  errata.txt  lib  MAINTAINERS  Makefile  powerpc  README  README.md  run_tests.sh  s390x  scripts  x86
```

其中，

* lib目录下是一些公共的库文件，包括系统参数、打印、系统崩溃的处理，以及lib/x86/下面的x86架构相关的一些基本功能函数的文件(如apic.c、msr.h、io.c等); 

* x86目录下是关于x86架构下的一些具体测试代码(如msr.c、apic.c、vmexit.c等)。

### 2.3.3. 基本原理

KVM单元测试的**基本工作原理**是:

将编译好的**轻量级的测试内核镜像**(*.flat文件) 作为支持**多重启动**的QEMU的**客户机内核镜像！！！** 来启动，测试使用了一个**通过客户机BIOS来调用**的基础结构，该基础结构将主要**初始化客户机系统**(包括**CPU**等)，然后**切换到长模式**(x86\_64 CPU架构的一种运行模式)，并调**用各个具体测试用例的主函数**从而执行测试，在测试完成后QEMU进程自动退出。

### 2.3.4. 编译运行

编译KVM单元测试代码是很容易的，直接运行make命令即可。

```
$ ./configure
$ make
```

在编译完成后，在**x86**目录下会生成很多具体测试用例需要的内核镜像文件(*.flat)。

执行测试时，运行msr这个测试的命令行示例如下:

```
qemu-system-x86_64 -enable-kvm -device pc-testdev -serial stdio -device isa-debug-exit,iobase=0xf4,iosize=0x4 -kernel ./x86/msr.flat -vnc none
```

其中，\-kernel选项后的./**x86/msr.flat**文件即为被测试的**内核镜像**。测试结果会默认打印在当前执行测试的终端上。

KVM单元测试代码中还提供了一些脚本，以便让单元测试的执行更容易，如x86-run 脚本可以方便地执行一个具体的测试。

```
# ls ./x86/*.flat
./x86/access.flat              ./x86/hyperv_stimer.flat  ./x86/pcid.flat        ./x86/sieve.flat                ./x86/umip.flat
./x86/apic.flat                ./x86/hyperv_synic.flat   ./x86/pku.flat         ./x86/smap.flat                 ./x86/vmexit.flat
./x86/asyncpf.flat             ./x86/idt_test.flat       ./x86/pmu.flat         ./x86/smptest.flat              ./x86/vmware_backdoors.flat
./x86/debug.flat               ./x86/init.flat           ./x86/port80.flat      ./x86/svm.flat                  ./x86/vmx.flat
./x86/emulator.flat            ./x86/intel-iommu.flat    ./x86/rdpru.flat       ./x86/syscall.flat              ./x86/xsave.flat
./x86/eventinj.flat            ./x86/ioapic.flat         ./x86/realmode.flat    ./x86/tsc.flat
./x86/hypercall.flat           ./x86/kvmclock_test.flat  ./x86/rmap_chain.flat  ./x86/tsc_adjust.flat
./x86/hyperv_clock.flat        ./x86/memory.flat         ./x86/s3.flat          ./x86/tscdeadline_latency.flat
./x86/hyperv_connections.flat  ./x86/msr.flat            ./x86/setjmp.flat      ./x86/tsx-ctrl.flat
```

执行msr测试的示例如下:

```
# ./x86-run ./x86/msr.flat
/usr/local/bin/qemu-system-x86_64 -nodefaults -device pc-testdev -device isa-debug-exit,iobase=0xf4,iosize=0x4 -vnc none -serial stdio -device pci-testdev -machine accel=kvm -kernel ./x86/msr.flat # -initrd /tmp/tmp.Pd6jyCi0dG
[2019-11-28 17:10:40.421] /root/rpmbuild/BUILD/qemu-kvm-2.6.0_65/cpus.c:1067: vcpu 0 thread is 369518
[2019-11-28 17:10:40.448] /root/rpmbuild/BUILD/qemu-kvm-2.6.0_65/cpus.c:1355: enter resume_all_vcpus
[2019-11-28 17:10:40.448] vl.c:842: vm_start function cost 56
[2019-11-28 17:10:40.448] vl.c:844: vm_start: cost 56
enabling apic
PASS: IA32_SYSENTER_CS
PASS: MSR_IA32_SYSENTER_ESP
PASS: IA32_SYSENTER_EIP
PASS: MSR_IA32_MISC_ENABLE
PASS: MSR_IA32_CR_PAT
PASS: MSR_FS_BASE
PASS: MSR_GS_BASE
PASS: MSR_KERNEL_GS_BASE
PASS: MSR_EFER
PASS: MSR_LSTAR
PASS: MSR_CSTAR
PASS: MSR_SYSCALL_MASK
SUMMARY: 12 tests
```

`run_tests.sh`脚本可以默认运行`x86/unittests.cfg`文件中配置的所有测试。

```
# ./run_tests.sh
FAIL apic-split (timeout; duration=90s)
PASS ioapic-split (19 tests)
FAIL apic (timeout; duration=30)
FAIL ioapic (26 tests, 1 unexpected failures)
PASS smptest (1 tests)
PASS smptest3 (1 tests)
PASS vmexit_cpuid
PASS vmexit_vmcall
PASS vmexit_mov_from_cr8
PASS vmexit_mov_to_cr8
PASS vmexit_inl_pmtimer
PASS vmexit_ipi
PASS vmexit_ipi_halt
PASS vmexit_ple_round_robin
PASS vmexit_tscdeadline
PASS vmexit_tscdeadline_immed
PASS access
PASS smap (18 tests)
SKIP pku (0 tests)
PASS asyncpf (1 tests)
PASS emulator (125 tests, 2 skipped)
PASS eventinj (13 tests)
PASS hypercall (2 tests)
PASS idt_test (4 tests)
PASS memory (8 tests)
PASS msr (12 tests)
SKIP pmu (/proc/sys/kernel/nmi_watchdog not equal to 0)
FAIL vmware_backdoors (11 tests, 8 unexpected failures)
PASS port80
PASS realmode
PASS s3
PASS sieve
FAIL syscall (2 tests, 1 unexpected failures)
PASS tsc (3 tests)
PASS tsc_adjust (5 tests)
PASS xsave (17 tests)
PASS rmap_chain
SKIP svm (0 tests)
SKIP taskswitch (i386 only)
SKIP taskswitch2 (i386 only)
PASS kvmclock_test
PASS pcid (3 tests)
PASS rdpru (1 tests)
SKIP umip (qemu-system-x86_64: CPU feature umip not found)
SKIP vmx (0 tests)
SKIP ept (0 tests)
SKIP vmx_eoi_bitmap_ioapic_scan (0 tests)
SKIP vmx_hlt_with_rvi_test (0 tests)
SKIP vmx_apicv_test (0 tests)
SKIP vmx_apic_passthrough_thread (0 tests)
SKIP vmx_init_signal_test (0 tests)
SKIP vmx_apic_passthrough_tpr_threshold_test (0 tests)
SKIP vmx_vmcs_shadow_test (0 tests)
FAIL debug
SKIP hyperv_synic (qemu-system-x86_64: can't apply global kvm64-x86_64-cpu.hv-vpindex=on: Property '.hv-vpindex' not found)
SKIP hyperv_connections (qemu-system-x86_64: can't apply global kvm64-x86_64-cpu.hv-vpindex=on: Property '.hv-vpindex' not found)
SKIP hyperv_stimer (qemu-system-x86_64: can't apply global kvm64-x86_64-cpu.hv-vpindex=on: Property '.hv-vpindex' not found)
PASS hyperv_clock
FAIL intel_iommu
PASS tsx-ctrl
```

查看`x86/unittests.cfg`, 下面是其中一节. 这个用例将测试`apic.flat`在`x86_64`架构下30秒以内.

```conf
[apic]
file = apic.flat
smp = 2
extra_params = -cpu qemu64,+x2apic,+tsc-deadline
arch = x86_64
timeout = 30
```

每个用例都是通过`scripts/runtime.sh`打印到屏幕

```
PASS() { echo -ne "\e[32mPASS\e[0m"; }
SKIP() { echo -ne "\e[33mSKIP\e[0m"; }
FAIL() { echo -ne "\e[31mFAIL\e[0m"; }
```

在`logs/`目录下有更多测试结果信息.

```
# ./run_tests.sh
SKIP apic-split (qemu-kvm: -machine kernel_irqchip=split: Parameter 'kernel_irqchip' expects 'on' or 'off')
SKIP ioapic-split (qemu-kvm: -machine kernel_irqchip=split: Parameter 'kernel_irqchip' expects 'on' or 'off')
FAIL apic (53 tests, 1 unexpected failures)
FAIL ioapic (timeout; duration=90s)
PASS smptest (1 tests)
PASS smptest3 (1 tests)
PASS vmexit_cpuid
PASS vmexit_vmcall
PASS vmexit_mov_from_cr8
PASS vmexit_mov_to_cr8
PASS vmexit_inl_pmtimer
PASS vmexit_ipi
PASS vmexit_ipi_halt
PASS vmexit_ple_round_robin
PASS vmexit_tscdeadline
PASS vmexit_tscdeadline_immed
PASS access
PASS smap (18 tests)
SKIP pku (0 tests)
PASS asyncpf (1 tests)
PASS emulator (125 tests, 2 skipped)
PASS eventinj (13 tests)
PASS hypercall (2 tests)
PASS idt_test (4 tests)
PASS memory (8 tests)
PASS msr (12 tests)
SKIP pmu (/proc/sys/kernel/nmi_watchdog not equal to 0)
SKIP vmware_backdoors (qemu-kvm: -machine vmport=on: Invalid parameter 'vmport')
PASS port80
PASS realmode
PASS s3
PASS sieve
PASS syscall (2 tests)
PASS tsc (3 tests)
PASS tsc_adjust (5 tests)
PASS xsave (17 tests)
PASS rmap_chain
PASS svm (25 tests)
SKIP taskswitch (i386 only)
SKIP taskswitch2 (i386 only)
PASS kvmclock_test
PASS pcid (3 tests)
PASS rdpru (1 tests)
FAIL umip (11 tests)
SKIP vmx (0 tests)
SKIP ept (qemu-kvm: Property '.host-phys-bits' not found)
SKIP vmx_eoi_bitmap_ioapic_scan (0 tests)
SKIP vmx_hlt_with_rvi_test (0 tests)
SKIP vmx_apicv_test (0 tests)
SKIP vmx_apic_passthrough_thread (0 tests)
SKIP vmx_init_signal_test (0 tests)
SKIP vmx_apic_passthrough_tpr_threshold_test (0 tests)
SKIP vmx_vmcs_shadow_test (0 tests)
PASS debug (11 tests)
SKIP hyperv_synic (qemu-kvm: Property '.hv-vpindex' not found)
SKIP hyperv_connections (qemu-kvm: Property '.hv-vpindex' not found)
SKIP hyperv_stimer (qemu-kvm: Property '.hv-vpindex' not found)
PASS hyperv_clock
SKIP intel_iommu (Use -machine help to list supported machines!)
PASS tsx-ctrl
```

# 3. 向开源社区贡献代码

## 开发者邮件列表

开源社区的沟通交流方式有很多种，如电子邮件列表、IRC\[5]、wiki、博客、论坛等。一般来说，开发者的交流使用邮件列表比较多，普通用户则使用邮件列表、论坛、 IRC等多种方式。关于KVM和QEMU开发相关的讨论主要都依赖邮件列表。

邮件列表有两种基本形式:公告型(邮件列表)，通常由一个管理者向小组中的所有成员发送信息，如 电子杂志、新闻邮件等;讨论型(讨论组)，所有的成员都可以向组内的其他成员发送信 息，其操作过程简单来说就是发一个邮箱到小组的公共电子邮箱，通过系统处理后，将这 封邮件分发给组内所有成员。KVM和QEMU等开发社区使用的邮件列表是属于讨论型的邮件列表，任何人都可以向该列表中的成员发送电子邮件。




[4] 在Xen中使用QEMU upstream的信息，请参考xen.org的官方wiki上的文章: http://wiki.xen.org/wiki/QEMU_Upstream。
[5] IRC(Internet Relay Chat的缩写，意思是因特网中继聊天)是一种通过网络进行即时聊 天的方式。其主要用于群体聊天，但同样也可以用于个人对个人的聊天。IRC是一个分布 式的客户端/服务器结构，通过连接到一个IRC服务器，我们可以访问这个服务器及它所连 接的其他服务器上的频道。要使用IRC，必须先登录一个IRC服务器，如:一个常见的服 务器为irc.freenode.net。
[6] Google对开源项目代码风格的指导文档见https://github.com/google/styleguide。
[7] Linux内核代码风格的中英文版本分别为 https://www.kernel.org/doc/html/latest/translations/zh_CN/codinstyle.html， https://www.kernel.org/doc/html/latest/process/coding-style.html。
[8] Brian Kernighan和Dennis Ritchie共同编写C语言中最经典的书籍《C programming language》(也称为K&R C)，Linux内核中关于大括号的使用风格就是来自于K&R C中 的规范。他们是UNIX操作系统的最主要的开发者中的两位，Brian Kernighan是AWK编程 语言的联合作者，Dennis Ritchie发明了C语言(是“C语言之父”)。
[9] 匈牙利命名法是Microsoft公司推荐的命名方法，可以参考如下网页: http://en.wikipedia.org/wiki/Hungarian_notation。