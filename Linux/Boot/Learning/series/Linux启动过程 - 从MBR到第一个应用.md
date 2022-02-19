
在最早期的时候, 引导一台计算机意味着需要给计算机提供一个带有启动程序的纸带或者需要手动调整前端仪表盘中的地址/数据/控制开关来加载启动程序. 而如今的计算机则自带有启动设备用于简化启动过程, 但是这并不意味着启动过程就变得简单. 

我们先从总体上看Linux启动过程的各个阶段, 然后再深入各个阶段, 分别对其进行介绍. 在这个过程中, 对Linux内核源码的引用将帮助你查找和理解内核源码. 

# 概述

下图给出了Linux启动的总体过程. 

![2022-02-19-22-02-21.png](./images/2022-02-19-22-02-21.png)

当系统第一次启动或者重启的时候, 处理器将会从一个规定好的位置开始执行. 对于PC而言, 这个位置对应到主板flash芯片中的BIOS(Basic Input/Output System). 对于嵌入式系统而言, CPU的reset vector是一个已知的地址, 该地址指向flash/ROM的内部. 不管怎样, 结果都是一样的, 即初始化系统硬件, 并启动操作系统. 由于PC具有很高的灵活性, 所以BIOS需要寻找并决定哪些设备是可以启动的, 并且从哪个设备启动. 我们将会在后面进行详细的介绍. 

当一个启动设备被发现时, Stage 1 bootloader将会被加载到内存中并执行. 这个bootloader位于设备的第一个sector, 其长度少于512B, 它的作用就是加载Stage 2 bootloader. 

当Stage 2 bootloader被加载到内存并执行的时候, 屏幕将会显示boot splash界面, Linux内核和可选的initial RAM disk(临时根文件系统)将会被加载到内存. 当内核镜像加载完毕, Stage 2 bootloader会把控制权交给Linux内核, Linux内核这时候会将内核解压并执行, 对系统进行初始化. 这时候, 内核将会检测系统硬件, 枚举连接到系统的硬件设备, 挂载根设备, 并加载必要的内核模块. 当内核初始化完毕后, 第一个用户空间程序(init)被启动, 更上层的系统初始化将被执行. 

这就是Linux启动的大致流程. 下面我们再详细看看Linux启动的各个阶段. 

系统启动(System startup)

系统启动阶段根据系统硬件平台的变化而变化. 在嵌入式平台中, 当系统上电或者复位的时候, 它使用的是引导环境(bootstrap environment), 如U-Boot, RedBoot和Lucent的MicroMonitor. 嵌入式平台一般都会内置一个这种程序, 统一称作boot monitor, boot monitor位于目标硬件的flash memory的特殊区域, 为用户提供了加载Linux内核镜像并执行的功能. 除此之外, boot monitor还提供了系统检测和硬件初始化的功能. 对于嵌入式系统而言, 这些boot monitor通常覆盖了Stage 1 bootloader和Stage 2 bootloader. 

在PC环境中, 系统启动开始于地址0xFFFF0, 该地址位于BIOS中. BIOS程序的第一阶段任务就是上电自检POST(Power On Self Test), 对系统硬件进行基本的检测, 确保正常工作. 第二阶段的任务就是本地设备枚举和初始化. 

从BIOS程序功能的角度来看, BIOS由两部分组成：POST代码和runtime services. 当POST结束时, 内存中POST相关的代码将会被丢弃, 但是runtime services代码将继续保持在内存中, 为操作系统提供一些必要的信息和服务直到系统关闭. 

为了启动操作系统, BIOS runtime会根据用户设定的偏好顺序检测可启动的设备, 并尝试启动存放在设备中的操作系统. 典型的可启动设备可以是软盘、CD-ROM、硬盘的某个分区、网络设备或者是USB磁盘. 

通常Linux会从磁盘启动, 而该磁盘的MBR(Master Boot Record)会包含有primary bootloader, 也就是Stage 1 bootloader. MBR是一个512字节的扇区, 该扇区为磁盘的第一个扇区(sector 1, cylinder 0, head 0). 当将MBR读取到内存后, BIOS就会尝试执行该primary bootloader, 并将控制权交给它. 

为了查看MBR的内容, 在Linux中可以通过以下命令获取：

```
dd if=/dev/sda of=mbr.bin bs=512 count=1
od -xa mbr.bin
```

dd命令读取了/dev/sda(第一个IDE磁盘)的前512字节, 并将其写入mbr.bin文件中. od命令将二进制文件以16进制和ASCII码的形式将mbr.bin文件打印出来. 

Stage 1 bootloader

位于MBR中的primary bootloader是一个位于512字节image中, 该image包含了primary bootloader的可执行代码, 同时也包含了一个分区表(partition table). 如下图所示：

![2022-02-19-22-02-36.png](./images/2022-02-19-22-02-36.png)

前446字节是primary bootloader, 包含了可执行代码和错误信息字符串. 接下去64字节是磁盘的分区表, 该分区表中包含了四条分区记录, 每条分区记录为16字节, 分区记录可以为空, 若为空则表示分区不存在. 最后是2个字节的magic number, 这两个字节是固定的0xAA55, 这两个字节的magic number可以用于判断该MBR记录是否存在. 

primary bootloader的作用就是用于寻找并定位secondary bootloader, 也就是Stage 2 bootloader. 它通过遍历分区表寻找可用的分区, 当它发现可用的分区的时候, 还是会继续扫描其他分区, 确保其他分区是不可用的. 然后从可用的分区中读取secondary bootloader到内存中, 并执行. 

Stage 2 bootloader

Stage 2 bootloader也称作secondary bootloader, 也可以更恰当地称作kernel loader, 它的任务就是将Linux内核加载到内存中, 并根据设置, 有选择性地将initial RAM disk也加载到内存中. 

在x86 PC环境中, Stage 1 bootloader和Stage 2 bootloader合并起来就是 LILO (Linux Loader)或者GRUB(GRand Unified Bootloader). 因为LILO中存在一些缺点, 并且这些缺点在GRUB中得到了比较好的解决, 所以这里将会以GRUB为准进行讲解. 

GRUB的一大优点是, 它能够正确识别到Linux文件系统. 相对于像LILO那样只能读取原始扇区数据, GRUB则可以从ext2和ext3的文件系统中读取到Linux内核. 为了实现这个功能, GRUB将原本2个步骤的bootloader变成了3个步骤, 多了Stage 1.5 bootloader, 即在Stage 1 bootloader和Stage 2 bootload中间加载一个可以识别Linux文件系统的bootloader(Stage 1.5 bootloader), 例如reiserfs_stage1_5(用于识别Reiser日志文件系统)或者e2fs_stage1_5(用于识别ext2和ext3文件系统). 当Stage 1.5 bootloader被加载和执行后, 就可以继续Stage 2 bootloader的加载和执行了. 

当Stage 2 bootloader被加载到内存后, GRUB就能够显示一系列可启动的内核(这些可启动的内核定义于/etc/grub.conf文件中, 该文件是指向/etc/grub/menu.lst和/etc/grub.conf的软链接). 你可以在这些文件中配置, 让系统自己默认选择某一个内核启动, 并且可以配置内核启动的相应参数. 

当Stage 2 bootloader已经被加载到内存中, 文件系统被识别到, 并且默认的内核镜像和initrd镜像被加载到内存中, 这就意味着镜像都已经准备好了, 可以直接调用内核镜像开始内核的启动了. 

在Ubuntu中bootloader的相关信息可以在/boot/grub/目录下找到, 主要是/boot/grub/grub.cfg, 但是该文件是自读的, 需要在其他地方(如/etc/default/grub)更改, 然后执行update-grub. 

Kernel阶段

既然内核镜像已经准备好, 并且控制权已经从Stage 2 bootloader传递过来, 启动过程的Kernel阶段就可以开始了. 内核镜像并非直接可以运行, 而是一个被压缩过的. 通常情况下, 它是一个通过zlib压缩的zImage(compressed image小于51KB)或者bzImage(big compressed image, 大于512KB)文件. 在内核镜像的开头是一个小程序, 该程序对硬件进行简单的配置并将压缩过的内核解压到高内存地址空间中. 如果initial RAM disk存在, 则它将initial RAM disk加载到内存中, 做好标记等待后面使用. 这个时候, 就可以真正调用内核, 开始真正的内核启动了. 

在GRUB中可以通过以下方法手动启动内核：

```
grub> kernel /bzImage-2.6.14.2
  [Linux-bzImage, setup=0x1400, size=0x29672e]
grub> initrd /initrd-2.6.14.2.img
  [Linux-initrd @ 0x5f13000, 0xcc199 bytes]
grub> boot

Uncompressing Linux... Ok, booting the kernel.
```

如果不知道要启动的内核名字, 只需要出入/, 然后按Tab键让它自动补齐, 或者切换可用的内核. 

GRUB 2上加载内核的命令已经由kernel变成了linux, 所以需要用到的是下面的命令

```
grub> linux /vmlinuz
grub> initrd /initrd.img
grub> boot
```

而 `/vmlinuz和/initrd.img` 其实是链接到了 `/boot/` 目录下特定版本的内核

```
lrwxrwxrwx   1 root root    33 8月  10 06:48 initrd.img -> boot/initrd.img-4.15.0-30-generic
lrwxrwxrwx   1 root root    33 8月  10 06:48 initrd.img.old -> boot/initrd.img-4.15.0-29-generic
lrwxrwxrwx   1 root root    30 8月  10 06:48 vmlinuz -> boot/vmlinuz-4.15.0-30-generic
lrwxrwxrwx   1 root root    30 8月  10 06:48 vmlinuz.old -> boot/vmlinuz-4.15.0-29-generic
```

bzImage(对于i386镜像而言)被调用的入口点位于 `./arch/i386/boot/head.S` 的汇编函数 start. 这个函数先进行一个基本的硬件设置然后调用 `./arch/i386/boot/compressed/head.S` 中的 `startup_32` 函数. `startup_32` 函数建立一个基本的运行环境(堆栈、寄存器等), 并且清除BSS(Block Started by Symbol). 然后内核调用 `./arch/i386/boot/compressed/misc.c:decompress_kernel()` 函数对内核进行解压缩. 当内核解压缩完毕后, 就会调用另外一个 `startup_32` 函数开始内核的启动, 该函数为 `./arch/i386/kernel/head.S:startup_32`. 

在新的 `startup_32` 函数(也叫做 swapper 或者 `process 0`), 页表将被初始化并且内存的分页机制将会被使能. 物理CPU的类型将会被检测, 并且 **FPU**(`floating-point unit`)也会被检测以便后面使用. 然后 `./init/main.c:start_kernel()` 函数将会被调用, 开始通用的内核初始化(不针对某一具体的处理器架构). 其基本流程留下所示：

![2022-02-19-22-02-51.png](./images/2022-02-19-22-02-51.png)

在 `./init/main.c:start_kernl()` 函数中, 一长串的初始化函数将会被调用到用于设置中断、执行更详细的内存配置、加载initial RAM disk等. 接着, 将会调用 `./arch/i386/kernel/process.c:kernel_thread()` 函数来启动第一个用户空间进程, 该进程的执行函数是init. 最后, idle 进程(`cpu_idle`)将会被启动, 并且调度器其将接管整个系统. 当中断使能时, 可抢占的调度器周期性地接管系统, 用于提供多任务同时运行的能力. 

在内核启动的时候, 原本由Stage 2 bootloader加载到内核的initial RAM disk(initrd)将会被挂载上. 这个位于RAM里面的initrd将会临时充当根文件系统, 并且允许内核直接启动, 而不需要挂载任何的物理磁盘. 因为那些用于跟外设交互的内核模块可以被放置到initrd中, 所以内核可以做得非常小, 并且还能支持很多的外设配置. 当内核启动起来后, 这个临时的根文件系统将会被丢弃(通过pivot_root()函数), 即initrd文件系统将会被卸载, 而真正的根文件系统将会被挂载. 

initrd功能让驱动不需要直接整合到内存中, 而是以可加载的模块存在, 从而让Linux内核能够做到很小. 这些可加载模块为内核提供访问磁盘和文件系统的方法, 同时也提供了访问其他硬件设备的方法. 因为根文件系统其实是位于磁盘的一个文件系统, initrd提供了访问磁盘和挂载真正根文件系统的方法. 在没有磁盘的嵌入式文件系统中, initrd可以作为最终的根文件系统, 或者最终的根文件系统可以通过NFS(Network File System)挂载. 

Init

当内核启动并初始化完毕后, 内核就会开始启动第一个用户空间程序, 这个被调用的程序是第一个使用标准C库编译的程序, 在这之前, 所有的程序都不是使用标准C库编译得到的. 

在Linux桌面系统中, 虽然不是强制规定的, 但是第一个启动的应用程序通常是`/sbin/init`. 嵌入式系统中通常很少要求init程序通过 `/etc/inittab` 提供大量的初始化工作. 很多情况下, 用户可以通过调用一个简单的shell脚本来启动所需的应用程序. 

总结

就像Linux本身一样, Linux启动过程也是一个特别灵活的过程, 该过程支持了各种各样的处理器和硬件平台. 最早的时候, loadlin bootloader提供了最简单直接的方法来启动Linux. 后来 LILO bootloader 扩展强化了启动的能力, 但是却还是没法获取文件系统的信息. 最新的bootloader, 比如GRUB, 则允许从一些列的文件系统(从 Minix 到Reiser)中启动 Linux. 

# reference

https://zhuanlan.zhihu.com/p/49877275

https://developer.ibm.com/articles/l-linuxboot/