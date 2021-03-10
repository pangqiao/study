
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 用途](#1-用途)
- [2. 使用方法](#2-使用方法)
- [3. 参数介绍](#3-参数介绍)
  - [3.1. 常用参数](#31-常用参数)
  - [3.2. 输出信息](#32-输出信息)
- [4. 例子](#4-例子)
  - [4.1. 性能剖析](#41-性能剖析)
  - [4.2. 静态追踪](#42-静态追踪)
- [5. 火焰图](#5-火焰图)

<!-- /code_chunk_output -->

# 1. 用途

记录**一段时间**内系统/进程的性能数据

执行一个**指定应用程序**并且记录性能数据(采样)到perf.data文件, 该文件可以使用`perf report`进行解析.

**采样的周期**以**事件的数量！！！来表示**，而**非基于时间**。当**目标事件计数溢出指定的数值！！！**，则**产生一个采样**。

此命令可以启动一个命令，并对其进行剖析，然后把剖析数据记录到文件（默认perf.data）。按`Ctrl - C`可以随时结束剖析。

此命令可以在线程、进程、CPU、全局级别进行剖析。

record, report, annotate是一组相关的命名，通常的使用流程是：

1. 在被剖析机器上调用record录制数据
2. 拷贝录制的perf.data，在任意机器上调用report、annotate进行分析

该命令**不是记录所有事件**，而是**进行采样**。默认情况下采样基于**cycle事件**，也就是**进行定期采样！！！**。

perf接口允许通过两种方式描述**采样周期**：

1. period：指定的**事件发生的次数**
2. frequency：**每秒**采集样本的**平均个数**

第一种对应`-c`参数, 该机制是由处理器实现的, 当**处理器达到这个阈值**才**中断内核**.

perf默认使用第二种，具体来说对应到`-F`选项。`-F 1000`表示1000Hz，也就是**每秒平均采样1000个**。内核会**动态的调整采样周期**，以**尽量满足需求**。

# 2. 使用方法

```
./perf --help record
```

```
perf record [-e <EVENT> | --event=EVENT] [-l] [-a] <command>
perf record [-e <EVENT> | --event=EVENT] [-l] [-a] -- <command> [<options>]
```

# 3. 参数介绍

参考stat子命令。

## 3.1. 常用参数

* `'-e'`: 指定性能事件, 默认是`cycles`
* `'-p'`: 指定待分析进程的 PID 
* `'-t'`: 指定待分析线程的 TID
* `'-a’`: 分析整个系统的性能(Default) 
* `'-c'`: 事件的采样周期
* `'-o'`: 指定输出文件(Default: perf.data) 
* `'-g'`: 记录函数间的调用关系
* `'-r <priority>'`: 将 perf top 作为实时任务，优先级为 `<priority>`
* `'-u <uid>'`: 只分析用户`<uid>`创建的进程

## 3.2. 输出信息

默认在当前目录下生成数据文件: perf.data


# 4. 例子

记录nginx进程的性能数据：

```
# perf record -p `pgrep -d ',' nginx`
```

记录**执行ls**时的**性能数据**：


```
# perf record ls -g
```

记录执行**ls**时的**系统调用**，可以知道**哪些系统调用最频繁**：

```
# perf record -e 'syscalls:sys_enter_*' ls
```

## 4.1. 性能剖析

以99HZ的频率剖析指定的命令，默认情况下工作在`Per-thread`模式

```
perf record -F 99 command
```

以99HZ的频率剖析指定的PID

```
perf record -F 99 -p PID
```

以99HZ的频率剖析指定的PID，持续10秒

```
perf record -F 99 -p PID sleep 10
```

以99HZ的频率剖析整个系统

```
perf record -F 99 -ag -- sleep 10
```

基于事件发生次数，而非采样频率来指定采样周期

```
perf record -e retired_instructions:u -c 2000
```

进行栈追踪（通过Frame Pointer）

```
perf record -F 99 -p PID -g -- sleep 10
```

进行栈追踪（通过DWARF）

```
perf record -F 99 -p PID --call-graph dwarf sleep 10
```

全局性栈追踪

```
perf record -F 99 -ag -- sleep 10  # 4.11之前
perf record -F 99 -g -- sleep 10   # 4.11之后
```
追踪某个容器的栈

```
perf record -F 99 -e cpu-clock --cgroup=docker/1d567f4393190204...etc... -a -- sleep 10
```

每发生10000次L1缓存丢失，进行一次采样

```
perf record -e L1-dcache-load-misses -c 10000 -ag -- sleep 5
```

每发生以100次最后级别的CPU缓存丢失，进行一次采用

```
perf record -e LLC-load-misses -c 100 -ag -- sleep 5 
```

采样内核指令

```
perf record -e cycles:k -a -- sleep 5 
```

采用用户指令

```
perf record -e cycles:u -a -- sleep 5
```

精确采样用户指令，基于PEBS

```
perf record -e cycles:up -a -- sleep 5 
```

## 4.2. 静态追踪

```
# 追踪新进程的创建
perf record -e sched:sched_process_exec -a
 
# 追踪上下文切换
perf record -e context-switches -a
perf record -e context-switches -c 1 -a
perf record -e context-switches -ag
# 追踪通过sched跟踪点的上下文切换
perf record -e sched:sched_switch -a
 
# 追踪CPU迁移
perf record -e migrations -a -- sleep 10
 
# 追踪所有connect调用（出站连接）
perf record -e syscalls:sys_enter_connect -ag
# 追踪所有accepts调用（入站连接）
perf record -e syscalls:sys_enter_accept* -ag
 
# 追踪所有块设备请求
perf record -e block:block_rq_insert -ag
# 追踪所有块设备发起和完成
perf record -e block:block_rq_issue -e block:block_rq_complete -a
# 追踪100KB（200扇区）以上的块操作完成
perf record -e block:block_rq_complete --filter 'nr_sector > 200'
# 追踪所有同步写操作的完成
perf record -e block:block_rq_complete --filter 'rwbs == "WS"'
# 追踪所有写操作的完成
perf record -e block:block_rq_complete --filter 'rwbs ~ "*W*"'
 
# 采样Minor faults（RSS尺寸增加）
perf record -e minor-faults -ag
perf record -e minor-faults -c 1 -ag
# 采样页面错误
perf record -e page-faults -ag
 
# 追踪所有Ext4调用，并把结果写入到非Ext4分区
perf record -e 'ext4:*' -o /tmp/perf.data -a 
 
# 追踪kswapd唤醒事件
perf record -e vmscan:mm_vmscan_wakeup_kswapd -ag
 
# 添加Node.js USDT 探针，要求Linux 4.10+
perf buildid-cache --add `which node`
# 跟踪Node.js http__server__request USDT事件
perf record -e sdt_node:http__server__request -a 
```

# 5. 火焰图

```
git clone https://github.com/cobblau/FlameGraph

```