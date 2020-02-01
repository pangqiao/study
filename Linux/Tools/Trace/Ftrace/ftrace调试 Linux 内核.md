
# 简介

## ftrace

ftrace 是 Linux 内核中提供的一种调试工具。使用 ftrace 可以对内核中发生的事情进行跟踪，这在调试 bug 或者分析内核时非常有用。

## 本文概述

本系列文章对 ftrace 进行了介绍，分为三部分。本文是第一部分，介绍了内核相关的编译选项、用户态访问 ftrace 的接口、ftrace 的数据文件，并对 ftrace 提供的跟踪器的用途进行了介绍，以使读者更好的了解和使用该工具。

## 主要用途

ftrace 是内建于 Linux 内核的跟踪工具，从 2.6.27 开始加入主流内核。使用 ftrace 可以调试或者分析内核中发生的事情。

ftrace 提供了**不同的跟踪器**，以用于**不同的场合**，比如跟踪**内核函数调用**、对**上下文切换**进行跟踪、查看**中断被关闭的时长**、跟踪**内核态中的延迟**以及**性能问题**等。

系统开发人员可以使用 ftrace 对内核进行**跟踪调试**，以找到内核中出现的问题的根源，方便对其进行修复。

另外，对内核感兴趣的读者还可以通过 ftrace 来观察**内核中发生的活动**，了解内核的**工作机制**。

# ftrace内核编译选项

使用 ftrace ，首先要将其**编译进内核**。

## 内核源码编译选项

内核源码目录下的 `kernel/trace/Makefile` 文件给出了 ftrace 相关的**编译选项**。

清单 1. ftrace 相关的配置选项列表:

```
CONFIG_FUNCTION_TRACER 
CONFIG_FUNCTION_GRAPH_TRACER 
CONFIG_CONTEXT_SWITCH_TRACER 
CONFIG_NOP_TRACER 
CONFIG_SCHED_TRACER 
...
```

ftrace 相关的配置选项比较多，针对不同的跟踪器有各自对应的配置选项。不同的选项有不同的依赖关系，内核源码目录下的 `kernel/trace/Kconfig` 文件描述了这些**依赖关系**。读者可以参考 `Makefile` 文件和 `Konfig` 文件，然后选中自己所需要的跟踪器。

## make menuconfig配置项

通常在配置内核时，使用 `make menuconfig` 会更直观一些。

以 2.6.33.1 版本的内核为例，要将 ftrace 编译进内核，可以选中 Kernel hacking （图 1 ）下的 Tracers 菜单项（图 2 ）。

图 1. Kernel hacking:

![2020-02-01-12-21-40.png](./images/2020-02-01-12-21-40.png)

图 2. Tracers:

![2020-02-01-12-22-24.png](./images/2020-02-01-12-22-24.png)

进入 Tracers 菜单下，可以看到内核支持的跟踪器列表。如图 3 所示，这里选中了所有的跟踪器，读者可以根据自己的需要选中特定的跟踪器。

图 3. 内核支持的跟踪器列表:

![2020-02-01-13-11-34.png](./images/2020-02-01-13-11-34.png)

这里要注意，如果是在 32 位 x86 机器上，编译时不要选中 General setup 菜单项（图 4 ）下的 Optimize for size 选项（图 5 ），否则就无法看到图 3 中的 `Kernel Function Graph Tracer` 选项。这是因为在 Konfig 文件中，针对 32 位 x86 机器，表项 `FUNCTION_GRAPH_TRACER` 有一个特殊的依赖条件：

```
depends on !X86_32 || !CC_OPTIMIZE_FOR_SIZE
```

图 4. General setup

![2020-02-01-13-18-46.png](./images/2020-02-01-13-18-46.png)

图 5. Optimize for size

![2020-02-01-13-47-09.png](./images/2020-02-01-13-47-09.png)

# debugfs支持

## 内核编译选项

ftrace 通过 **debugfs** 向**用户态**提供了**访问接口**，所以还需要将 debugfs 编译进内核。

激活对 debugfs 的支持，可以直接编辑内核配置文件 `.config` ，设置 `CONFIG_DEBUG_FS=y` ；或者在 `make menuconfig` 时到 `Kernel hacking` 菜单下选中对 debugfs 文件系统的支持，如图 6 所示。

图 6. debugfs 编译选项

![2020-02-01-14-45-08.png](./images/2020-02-01-14-45-08.png)

配置完成后，**编译安装新内核**，然后**启动到新内核**。 

注意，激活 ftrace 支持后，编译内核时会使用编译器的 `-pg` 选项，这是在 `kernel/trace/Makefile` 文件中定义的，如清单 2 所示。

清单 2. 激活编译选项 -pg

```
ifdef CONFIG_FUNCTION_TRACER 
ORIG_CFLAGS := $(KBUILD_CFLAGS) 
KBUILD_CFLAGS = $(subst -pg,,$(ORIG_CFLAGS)) 
... 
endif 
...
```

使用 `-pg` 选项会在编译得到的内核映像中加入大量的调试信息。一般情况下，只是在开发测试阶段激活 ftrace 支持，以调试内核，修复 bug 。最终用于发行版的内核则会关闭 `-pg` 选项，也就无法使用 ftrace。



# 参考

https://www.cnblogs.com/jefree/p/4438982.html