
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

# 参考

https://tinylab.org/linux-profiling-methods-overview