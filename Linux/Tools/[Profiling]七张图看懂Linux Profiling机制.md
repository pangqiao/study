
# Linux profiling 手段一览

![2020-01-29-18-26-06.png](./images/2020-01-29-18-26-06.png)

为方便介绍，将 Linux Profiling 手段分为两大类：

- 软件埋点：

    - 手动埋点：主动调用 trace 函数来实现埋点。

    Android systrace 即是这样一个例子，如图 2 和 图 3 所示

    - 自动埋点：借助工具链，自动埋点，对函数的 entry 和 return 进行 hook。

    Linux ftrace 即是这样一个例子，图 4 简示了其实现原理

    - 动态埋点：运行时刻，在指定位置上加断点，断点触发时执行相应 handler。

    Handler 为注入内核的 eBPF 字节码

    Linux kprobe / uprobe 就是这样的例子，图 5 和 图 6 简示了 uprobe 以及 uretprobe 的实现原理

- 硬件统计

    - 计数累加：统计一段时间内，某个性能监控单元（PMU）的计数。

    例如：perf stat -e cache-misses -p PID，参见 brendangregg.com/perf.html ，Counting Events 一节

    函数接口：参见 libperf 的封装，fd = perf_event_open(...); read(fd, …)

    - 采样：计数达标，产生中断，伴随 Backtrace 对应到代码行。

    例如：perf record -F 99 -p PID sleep 10，以及对应图形化展示 FlameGraph

    函数接口：参见 perf_event_open，fd = perf_event_open(…); void *addr = mmap(…, fd, …);

图 7 简示了其实现原理

# Android systrace 工作原理

![2020-01-29-18-30-10.png](./images/2020-01-29-18-30-10.png)

- User space，分为两部分

    - 埋点处：通过嵌入代码中的 Trace API 调用，向 Linux kernel 的 tracing buffer 写日志。

    上图中，裸示了写 tracing buffer 的过程

    - atrace：读取 tracing buffer，存于磁盘文件，以免 tracing buffer 溢出丢失信息。

- Kernel space，通过 scheduler 嵌入的 tracepoint，将调度事件，写入 tracing buffer。

    tracing buffer 犹如一段 in-memory 的日志流，对齐了写入的各个标记和事件。

# Android atrace 输出文件及图形化展示

![2020-01-29-18-34-41.png](./images/2020-01-29-18-34-41.png)

atrace 转储的 tracing buffer 内容，以及载入到 Chrome 浏览器，进行图形化分析。

>Discuss：想象一个进程同时播放两段视频，视频解码库是多线程的，线程来自全局的 thread pool。通过 systrace，能区分这两个视频播放任务的 CPU 时间片吗？

# Linux ftrace 实现原理回顾

![2020-01-29-18-39-10.png](./images/2020-01-29-18-39-10.png)

- 通过 `gcc -pg` 选项，**编译**时，**函数开头**自动插入 `_mcount` 调用。

- `_mcount` 处：除了 hook entry ，还通过修改返回地址，来 hook return。

Linux kernel 热补丁方案，”kernel livepatch“，便借用了 ftrace 的原理：替换有漏洞的函数实现，从而实现热补丁。

更多关于 ftrace 使用，参考[「Advanced Features of Ftrace」](https://events.static.linuxfound.org/sites/events/files/slides/linuxconjapan-ftrace-2014.pdf)

# uprobe 的实现原理

![2020-01-29-18-43-37.png](./images/2020-01-29-18-43-37.png)

注：上图修改自 [dev.framing.life/tracing/kernel-and-user-probes-magic](https://dev.framing.life/tracing/kernel-and-user-probes-magic/)

指定位置上的指令，头部修改为软件中断指令（同时原指令存档他处）：

1. 当执行到该位置时，触发**软件中断**，陷入内核
2. 在内核，**执行**以 **eBPF 字节码**形式注入的 **Handler**
3. **单步执行原指令**
4. 修正寄存器和栈，回到**原有指令流**

>Discuss：这与 gdb 中设断点有什么区别？

>断点的 Handler 运行于 Kernel space，无需多次的 User space ↔ Kernel space 通信

>Discuss：用户空间注入的 Handler 在 Kernel space 执行，安全性如何保证？

>听说过 eBPF 吗？

简单介绍下 extended Berkeley Packet Filter（eBPF）

* 一种功能有限、沙箱化的字节码。
* 由 User space 注入到 Kernel space 执行。
* 基于 BPF 扩展。
* 原始的 BPF 用于网路包过滤，下面是一个 BPF 裸用的例子：


# 参考

https://tinylab.org/linux-profiling-methods-overview