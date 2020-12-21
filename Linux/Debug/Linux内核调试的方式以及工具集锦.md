
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 意义](#1-意义)
- [2. 内核调试工具总结](#2-内核调试工具总结)
- [3. 用户空间与内核空间数据交换的文件系统](#3-用户空间与内核空间数据交换的文件系统)
- [4. printk](#4-printk)
- [5. ftrace && trace-cmd](#5-ftrace-trace-cmd)
  - [5.1. ftrace](#51-ftrace)
  - [5.2. trace-cmd](#52-trace-cmd)
- [6. Kprobe && systemtap](#6-kprobe-systemtap)
  - [6.1. 内核kprobe机制](#61-内核kprobe机制)
  - [6.2. 前端工具systemtap](#62-前端工具systemtap)
- [7. kgdb && kgtp](#7-kgdb-kgtp)
  - [7.1. kgdb](#71-kgdb)
  - [7.2. KGTP](#72-kgtp)
- [8. perf](#8-perf)
- [9. LTTng](#9-lttng)
- [10. 参考资料](#10-参考资料)
  - [10.1. 系列文章来源](#101-系列文章来源)
  - [10.2. 其他参考](#102-其他参考)

<!-- /code_chunk_output -->

# 1. 意义

这个文章主要目的有:

1. 宏观描述debug手段
2. 不同手段之间的关系, 比如

# 2. 内核调试工具总结

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

# 3. 用户空间与内核空间数据交换的文件系统

它们都用于Linux内核和用户空间的数据交换, 只是适用场景不同

见`./filesystem`

# 4. printk

用法和C语言应用程序中的 printf 使用类似

见`./printk`

# 5. ftrace && trace-cmd

见``

## 5.1. ftrace

ftrace 是 Linux当前版本中, 功能最强大的调试、跟踪手段.

提供了动态探测点(函数)和静态探测点(`tracepoint`).

## 5.2. trace-cmd

`trace-cmd` 和 开源的 `kernelshark`(GUI工具) 均是内核`Ftrace` 的前段工具, 用于分分析核性能.

# 6. Kprobe && systemtap

## 6.1. 内核kprobe机制

如何高效地调试内核?

1. `printk` 终归是毫无选择地全量输出, 某些场景下不实用, 可以使用`tracepoint`, **只有使能** `tracepoint` 机制的时候才输出.
2. `tracepoint`只是一些**静态锚点**, 有些锚点并不一定是你需要的, 但是你仍然需要自己部署`tracepoint`, **重新编译内核**. 
3. `kprobe`在运行的内核中**动态插入探测点**, 执行你**预定义的操作**.

kprobe是隐藏在诸多技术后的一个**基础组件**，例如`ftrace`、`perf`、`SystemTap`、`LTTng`, 还有最近非常火热的`ebpf`.

详细见`./kprobe`

## 6.2. 前端工具systemtap






# 7. kgdb && kgtp

## 7.1. kgdb

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

## 7.2. KGTP

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

# 8. perf

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

# 9. LTTng

`LTTng` 是一个 `Linux` 平台开源的跟踪工具, 是一套软件组件, 可允许跟踪 `Linux` 内核和用户程序, 并控制跟踪会话(开始/停止跟踪、启动/停止事件 等等). 这些组件被绑定如下三个包 :

| 包 | 描述 |
|:--:|:---:|
| LTTng-tools | 库和用于跟踪会话的命令行接口 |
| LTTng-modules | 允许用 `LTTng` 跟踪 `Linux` 的 `Linux` 内核模块 |
| LTTng-UST | 用户空间跟踪库 |

[Linux 平台开源的跟踪工具：LTTng](http://www.open-open.com/lib/view/open1413946397247.html)

[用 lttng 跟踪内核](http://blog.csdn.net/xsckernel/article/details/17794551)

[LTTng and LTTng project](http://blog.csdn.net/ganggexiongqi/article/details/6664331)

# 10. 参考资料

## 10.1. 系列文章来源

| CSDN | GitHub |
|:----:|:------:|
| [Linux内核调试的方式以及工具集锦](http://blog.csdn.net/gatieme/article/details/68948080) | [`LDD-LinuxDeviceDrivers/study/debug`](https://github.com/gatieme/LDD-LinuxDeviceDrivers/tree/master/study/debug) |

`奔跑吧Linux内核 第6章 内核调试`

## 10.2. 其他参考

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