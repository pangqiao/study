
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 内核调试工具总结](#1-内核调试工具总结)
- [用户空间与内核空间数据交换的文件系统](#用户空间与内核空间数据交换的文件系统)
- [3. Kprobe && systemtap](#3-kprobe-systemtap)
  - [3.1. 内核kprobe机制](#31-内核kprobe机制)
  - [3.2. 前端工具systemtap](#32-前端工具systemtap)
- [4. kgdb && kgtp](#4-kgdb-kgtp)
  - [4.1. kgdb](#41-kgdb)
  - [4.2. KGTP](#42-kgtp)
- [5. perf](#5-perf)
- [6. LTTng](#6-lttng)
- [7. 参考资料](#7-参考资料)
  - [7.1. 系列文章来源](#71-系列文章来源)
  - [7.2. 其他参考](#72-其他参考)

<!-- /code_chunk_output -->

# 1. 内核调试工具总结

内核总是那么捉摸不透, 内核也会犯错, 但是调试却不能像用户空间程序那样, 为此内核开发者为我们提供了一系列的工具和系统来支持内核的调试.

**内核的调试**, 其本质是**内核空间**与**用户空间**的**数据交换**, 内核开发者们提供了多样的形式来完成这一功能.

| 工具 | 描述 |
|:---:|:----|
| debugfs等文件系统 | 提供了 `procfs`, `sysfs`, `debugfs`以及 `relayfs` 来与用户空间进行数据交互, 尤其是 **`debugfs`**, 这是内核开发者们实现的专门用来调试的文件系统接口. <p><p>其他的工具或者接口, 多数都**依赖**于 `debugfs`.(比如下面的ftrace) |
| printk | 强大的输出系统, 没有什么逻辑上的`bug`是用print解决不了的 |
| ftrace以及其前端工具`trace-cmd`等 | **内核**提供了 **`ftrace`** 工具来实现**检查点**, **事件**等的检测, 这一框架依赖于 `debugfs`, 他在 `debugfs` 中的 `tracing` 子系统中为用户提供了丰富的操作接口, 我们可以通过该系统对内核实现检测和分析. <p><p>功能虽然强大, 但是其操作并不是很简单, 因此使用者们为其实现了 **`trace-cmd`** 等前端工具, 简化了 `ftrace` 的使用. |
| `kprobe`以及更强大的`systemtap` | 内核中实现的 `krpobe` 通过类似与**代码劫持**一样的技巧, 在内核的**代码**或者**函数执行前后**, 强制加上某些**调试信息**, 可以很巧妙的完成调试工作, 这是一项先进的调试技术. <p><p>但是仍然不够好, 劫持代码需要**用驱动的方式编译并加载**, 为了能通过**脚本的方式自动生成劫持代码**并**自动加载**和**收集数据**, 于是`systemtap` 出现了. 通过 `systemtap` 用户只需要编写脚本, 就可以完成调试并**动态分析内核** |
| kgdb 和 kgtp | `KGDB` 是大名鼎鼎的**内核调试工具**, `KGTP`则通过**驱动的方式**强化了 `gdb`的功能, 诸如tracepoint, 打印内核变量等. |
| perf | `perf Event`是一款随 `Linux`内核代码一同发布和维护的**性能诊断工具**, 核社区维护和发展. `Perf` 不仅可以用于**应用程序**的性能统计分析, 也可以应用于**内核代码**的性能统计和分析. <p><p>得益于其优秀的体系结构设计, 越来越多的新功能被加入 `Perf`, 使其已经成为一个多功能的性能统计工具集 |
| LTTng | `LTTng` 是一个 `Linux` 平台开源的**跟踪工具**, 是一套软件组件, 可允许跟踪 Linux **内核**和**用户程序**, 并**控制跟踪会话**(开始/停止跟踪、启动/停止事件 等等). |
| eBPF | eBPF(extended Berkeley Packet Filter) |
| ktap | |
| dtrace4linux | `Sun DTracer` 的 `Linux` 移植版 |
| OL DTrace | `Oracle Linux DTracer` |
| sysdig |  |

# 用户空间与内核空间数据交换的文件系统

见`./filesystem`

# 3. Kprobe && systemtap

## 3.1. 内核kprobe机制

`kprobe` 是 `linux` 内核的一个重要特性, 是一个轻量级的内核调试工具, 同时它又是其他一些更高级的内核调试工具(比如 `perf` 和 `systemtap`)的 "基础设施", 4.0版本的内核中, 强大的 `eBPF` 特性也寄生于 `kprobe` 之上, 所以 `kprobe` 在内核中的地位就可见一斑了.

`Kprobes` 提供了一个强行进入任何内核例程并从中断处理器无干扰地收集信息的接口. 使用 `Kprobes` 可以收集处理器寄存器和全局数据结构等调试信息。开发者甚至可以使用 `Kprobes` 来修改 寄存器值和全局数据结构的值.

如何高效地调试内核?

`printk` 是一种方法, 但是 `printk` 终归是毫无选择地全量输出, 某些场景下不实用, 于是你可以试一下`tracepoint`, 我使能 `tracepoint` 机制的时候才输出. 对于傻傻地放置 `printk` 来输出信息的方式, `tracepoint` 是个进步, 但是 `tracepoint` 只是内核在某些特定行为(比如进程切换)上部署的一些静态锚点, 这些锚点并不一定是你需要的, 所以你仍然需要自己部署`tracepoint`, 重新编译内核. 那么 `kprobe` 的出现就很有必要了, 它可以在运行的内核中动态插入探测点, 执行你预定义的操作.

它的基本工作机制是: 用户指定一个探测点, 并把一个用户定义的处理函数关联到该探测点, 当内核执行到该探测点时, 相应的关联函数被执行，然后继续执行正常的代码路径.

`kprobe` 实现了三种类型的探测点 : `kprobes`, `jprobes`和 `kretprobes`(也叫返回探测点). `kprobes` 是可以被插入到内核的任何指令位置的探测点, `jprobes` 则只能被插入到一个内核函数的入口, 而 `kretprobes` 则是在指定的内核函数返回时才被执行.

[kprobe工作原理](http://blog.itpub.net/15480802/viewspace-1162094/)

[随想录(强大的kprobe)](http://blog.csdn.net/feixiaoxing/article/details/40351811)

[kprobe原理解析（一）](http://www.cnblogs.com/honpey/p/4575928.html)

## 3.2. 前端工具systemtap

`SystemTap` 是监控和跟踪运行中的 `Linux` 内核的操作的动态方法. 这句话的关键词是动态, 因为 `SystemTap` 没有使用工具构建一个特殊的内核, 而是允许您在运行时动态地安装该工具. 它通过一个 `Kprobes` 的应用编程接口 (`API`) 来实现该目的.

`SystemTap` 与一种名为 `DTrace` 的老技术相似，该技术源于 `Sun Solaris` 操作系统. 在 `DTrace` 中, 开发人员可以用 `D` 编程语言(`C` 语言的子集, 但修改为支持跟踪行为)编写脚本. `DTrace` 脚本包含许多探针和相关联的操作, 这些操作在探针 "触发" 时发生. 例如, 探针可以表示简单的系统调用，也可以表示更加复杂的交互，比如执行特定的代码行

`DTrace` 是 `Solaris` 最引人注目的部分, 所以在其他操作系统中开发它并不奇怪. `DTrace` 是在 `Common Development and Distribution License (CDDL)` 之下发行的, 并且被移植到 `FreeBSD` 操作系统中.

另一个非常有用的内核跟踪工具是 `ProbeVue`, 它是 `IBM` 为 `IBM® AIX®` 操作系统 `6.1` 开发的. 您可以使用 `ProbeVue` 探查系统的行为和性能, 以及提供特定进程的详细信息. 这个工具使用一个标准的内核以动态的方式进行跟踪.

考虑到 `DTrace` 和 `ProbeVue` 在各自的操作系统中的巨大作用, 为 `Linux` 操作系统策划一个实现该功能的开源项目是势不可挡的. `SystemTap` 从 `2005` 年开始开发, 它提供与 `DTrace` 和 `ProbeVue` 类似的功能. 许多社区还进一步完善了它, 包括 `Red Hat`、`Intel`、`Hitachi` 和 `IBM` 等.

这些解决方案在功能上都是类似的, 在触发探针时使用探针和相关联的操作脚本.

[SystemTap 学习笔记 - 安装篇](https://segmentfault.com/a/1190000000671438)

[Linux 自检和 SystemTap 用于动态内核分析的接口和语言](https://www.ibm.com/developerworks/cn/linux/l-systemtap/)

[Brendan's blog Using SystemTap](http://dtrace.org/blogs/brendan/2011/10/15/using-systemtap/)

[内核调试神器SystemTap — 简介与使用（一）](http://blog.csdn.net/zhangskd/article/details/25708441)

[内核探测工具systemtap简介](http://www.cnblogs.com/hazir/p/systemtap_introduction.html)

[SystemTap Beginner](http://blog.csdn.net/kafeiflynn/article/details/6429976)

[使用systemtap调试linux内核](http://blog.csdn.net/heli007/article/details/7187748)

[Ubuntu Kernel Debuginfo](http://ddebs.ubuntu.com/pool/main/l/linux)

[Linux 下的一个全新的性能测量和调式诊断工具 Systemtap, 第 3 部分: Systemtap](https://www.ibm.com/developerworks/cn/linux/l-cn-systemtap3/)

# 4. kgdb && kgtp

## 4.1. kgdb

*	KDB 和 KGDB 合并, 并进入内核

`KGDB` 是大名鼎鼎的内核调试工具, 他是由 `KDB` 和 `KGDB` 项目合并而来.

`kdb` 是一个Linux系统的内核调试器, 它是由SGI公司开发的遵循GPL许可证的开放源码调试工具. `kdb` 嵌入在`Linux` 内核中. 为内核&&驱动程序员提供调试手段. 它适合于调试内核空间的程序代码. 譬如进行设备驱动程序调试. 内核模块的调试等.

`kgdb` 和 `kdb` 现在已经合并了. 对于一个正在运行的`kgdb` 而言, 可以使用 `gdbmonitor` 命令来使用 `kdb` 命令. 比如

```cpp
(gdb)gdb monitor ps -A
```

就可以运行 `kdb` 的 `ps` 命令了.

分析一下 `kdb` 补丁和合入主线的 `kdb` 有啥不同

`kdb`跟 `kgdb` 合并之后, 也可以使用 `kgdb` 的`IO` 驱动(比如键盘), 但是同时也 `kdb`也丧失了一些功能. 合并之后的`kdb`不在支持汇编级的源码调试. 因此它现在也是平台独立的.

1.	kdump和kexec已经被移除。

2.	从/proc/meninfo中获取的信息比以前少了。

3.	bt命令现在使用的是内核的backtracer，而不是kdb原来使用的反汇编。

4.	合并之后的kdb不在具有原来的反汇编（id命令）

总结一下 : `kdb` 和 `kgdb` 合并之后，系统中对这两种调试方式几乎没有了明显的界限，比如通过串口进行远程访问的时候，可以使用 `kgdb` 命令, 也可以使用 `kdb` 命令（使用gdb monitor实现）

## 4.2. KGTP

`KGTP` 是一个 实时 轻量级 `Linux` 调试器 和 跟踪器. 使用 `KGTP`

使用 `KGTP` 不需要在 `Linux` 内核上打 `PATCH` 或者重新编译, 只要编译KGTP模块并 `insmod` 就可以.

其让 `Linux` 内核提供一个远程 `GDB` 调试接口, 于是在本地或者远程的主机上的GDB可以在不需要停止内核的情况下用 `GDB tracepoint` 和其他一些功能 调试 和 跟踪 `Linux`.

即使板子上没有 `GDB` 而且其没有可用的远程接口, `KGTP` 也可以用离线调试的功能调试内核（见http://code.google.com/p/kgtp/wiki/HOWTOCN#/sys/kernel/debug/gtpframe和离线调试）。

KGTP支持 X86-32 ， X86-64 ， MIPS 和 ARM 。
KGTP在Linux内核 2.6.18到upstream 上都被测试过。
而且还可以用在 Android 上(见 [HowToUseKGTPinAndroid](http://code.google.com/p/kgtp/wiki/HowToUseKGTPinAndroid))

[github-KGTP](https://github.com/teawater/kgtp)

[KGTP内核调试使用](http://blog.csdn.net/djinglan/article/details/15335653)

[ KGTP中增加对GDB命令“set trace-buffer-size”的支持 - Week 5](http://blog.csdn.net/calmdownba/article/details/38659317)

# 5. perf

`Perf` 是用来进行软件性能分析的工具。
通过它, 应用程序可以利用 `PMU`, `tracepoint` 和内核中的特殊计数器来进行性能统计. 它不但可以分析指定应用程序的性能问题 (`per thread`). 也可以用来分析内核的性能问题, 当然也可以同时分析应用代码和内核，从而全面理解应用程序中的性能瓶颈.

最初的时候, 它叫做 `Performance counter`, 在 `2.6.31` 中第一次亮相. 此后他成为内核开发最为活跃的一个领域. 在 `2.6.32` 中它正式改名为 `Performance Event`, 因为 `perf` 已不再仅仅作为 `PMU` 的抽象, 而是能够处理所有的性能相关的事件.

使用 `perf`, 您可以分析程序运行期间发生的硬件事件，比如 `instructions retired` , `processor clock  cycles` 等; 您也可以分析软件事件, 比如 `Page Fault` 和进程切换。
这使得 `Perf` 拥有了众多的性能分析能力, 举例来说，使用 `Perf` 可以计算每个时钟周期内的指令数, 称为 `IPC`, `IPC` 偏低表明代码没有很好地利用 `CPU`.

`Perf` 还可以对程序进行函数级别的采样, 从而了解程序的性能瓶颈究竟在哪里等等. `Perf` 还可以替代 `strace`, 可以添加动态内核 `probe` 点. 还可以做 `benchmark` 衡量调度器的好坏.

人们或许会称它为进行性能分析的"瑞士军刀", 但我不喜欢这个比喻, 我觉得 `perf` 应该是一把世间少有的倚天剑.
金庸笔下的很多人都有对宝刀的癖好, 即便本领低微不配拥有, 但是喜欢, 便无可奈何. 我恐怕正如这些人一样, 因此进了酒馆客栈, 见到相熟或者不相熟的人, 就要兴冲冲地要讲讲那倚天剑的故事.

[Perf -- Linux下的系统性能调优工具，第 1 部分](https://www.ibm.com/developerworks/cn/linux/l-cn-perf1/index.html)

[perf Examples](http://www.brendangregg.com/perf.html)

改进版的perf, [Performance analysis tools based on Linux perf_events (aka perf) and ftrace
](https://github.com/brendangregg/perf-tools)

[Perf使用教程](http://blog.chinaunix.net/uid-10540984-id-3854969.html)

[linux下的内核测试工具——perf使用简介](http://blog.csdn.net/trochiluses/article/details/10261339)

[perf 移植](http://www.cnblogs.com/helloworldtoyou/p/5585152.html)

# 6. LTTng

`LTTng` 是一个 `Linux` 平台开源的跟踪工具, 是一套软件组件, 可允许跟踪 `Linux` 内核和用户程序, 并控制跟踪会话(开始/停止跟踪、启动/停止事件 等等). 这些组件被绑定如下三个包 :

| 包 | 描述 |
|:--:|:---:|
| LTTng-tools | 库和用于跟踪会话的命令行接口 |
| LTTng-modules | 允许用 `LTTng` 跟踪 `Linux` 的 `Linux` 内核模块 |
| LTTng-UST | 用户空间跟踪库 |

[Linux 平台开源的跟踪工具：LTTng](http://www.open-open.com/lib/view/open1413946397247.html)

[用 lttng 跟踪内核](http://blog.csdn.net/xsckernel/article/details/17794551)

[LTTng and LTTng project](http://blog.csdn.net/ganggexiongqi/article/details/6664331)

# 7. 参考资料

## 7.1. 系列文章来源

| CSDN | GitHub |
|:----:|:------:|
| [Linux内核调试的方式以及工具集锦](http://blog.csdn.net/gatieme/article/details/68948080) | [`LDD-LinuxDeviceDrivers/study/debug`](https://github.com/gatieme/LDD-LinuxDeviceDrivers/tree/master/study/debug) |

`奔跑吧Linux内核 第6章 内核调试`

## 7.2. 其他参考

https://www.cnblogs.com/alantu2018/p/8997149.html

https://www.osetc.com/archives/7236.html

[Linux内核调试方法](http://www.cnblogs.com/shineshqw/articles/2359114.html)

[choose-a-linux-traccer](http://www.brendangregg.com/blog/2015-07-08/choosing-a-linux-traccer.html), [中英文对照](http://www.oschina.net/translate/choossing-a-linux-tracer?cmp)

http://blog.csdn.net/bob_fly1984/article/details/51405856

http://www.verydemo.com/demo_c167_i62250.html

http://www.oschina.net/translate/dynamic-debug-howto?print

https://my.oschina.net/fgq611/blog/113249

http://www.fx114.net/qa-171-140555.aspx

http://www.fx114.net/qa-40-147583.aspx

http://www.fx114.net/qa-48-128913.aspx

https://my.oschina.net/fgq611/blog/113249

http://www.fx114.net/qa-120-128312.aspx

http://www.fx114.net/qa-259-116990.aspx