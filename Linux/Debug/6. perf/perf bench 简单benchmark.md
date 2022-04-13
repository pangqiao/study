
perf bench作为benchmark工具的通用框架，包含sched/mem/numa/futex等子系统，all可以指定所有。

perf bench可用于评估系统sched/mem等特定性能。

perf bench sched: 调度器和IPC机制。包含messaging和pipe两个功能。

perf bench mem: 内存存取性能。包含memcpy和memset两个功能。

perf bench numa: NUMA架构的调度和内存处理性能。包含mem功能。

perf bench futex: futex压力测试。包含hash/wake/wake-parallel/requeue/lock-pi功能。

perf bench all: 所有bench测试的集合


# perf bench sched all

测试messaging和pipi两部分性能。

## sched messaging评估进程调度和核间通信

sched message 是从经典的测试程序 hackbench 移植而来，用来衡量调度器的性能，overhead 以及可扩展性。

该 benchmark 启动 N 个 reader/sender 进程或线程对，通过 IPC(socket 或者 pipe) 进行并发的读写。一般人们将 N 不断加大来衡量调度器的可扩展性。

sched message 的用法及用途和 hackbench 一样，可以通过修改参数进行不同目的测试: 

```
-g, --group <n> Specify number of groups

-l, --nr_loops <n> Specify the number of loops to run (default: 100)

-p, --pipe Use pipe() instead of socketpair()

-t, --thread Be multi thread instead of multi process
```

测试结果: 

```
[root@xx perf]# perf bench sched all
# Running sched/messaging benchmark...
# 20 sender and receiver processes per group
# 10 groups == 400 processes run

     Total time: 3.291 [sec]

# Running sched/pipe benchmark...
# Executed 1000000 pipe operations between two processes

     Total time: 17.844 [sec]

      17.844464 usecs/op
          56039 ops/sec
```

使用pipe()和socketpair()对测试影响: 

```
[root@xx perf]# perf bench sched messaging
# Running 'sched/messaging' benchmark:
# 20 sender and receiver processes per group
# 10 groups == 400 processes run

     Total time: 3.299 [sec]

[root@xx perf]# perf bench sched messaging -p
# Running 'sched/messaging' benchmark:
# 20 sender and receiver processes per group
# 10 groups == 400 processes run

     Total time: 0.341 [sec]
```

可见socketpair()性能要明显低于pipe()。

## sched pipe评估pipe性能

sched pipe 从 Ingo Molnar 的 pipe-test-1m.c 移植而来。当初 Ingo 的原始程序是为了测试不同的调度器的性能和公平性的。

其工作原理很简单，两个进程互相通过 pipe 拼命地发 1000000 个整数，进程 A 发给 B，同时 B 发给 A。因为 A 和 B 互相依赖，因此假如调度器不公平，对 A 比 B 好，那么 A 和 B 整体所需要的时间就会更长。

```
[root@xx perf]# perf bench sched pipe
# Running 'sched/pipe' benchmark:
# Executed 1000000 pipe operations between two processes

     Total time: 17.812 [sec]

      17.812659 usecs/op
          56139 ops/sec
```

# perf bench mem all

该测试衡量 不同版本的memcpy/memset/ 函数处理一个 1M 数据的所花费的时间，转换成吞吐率。

```
[root@iu perf]# perf bench mem all
```

# perf bench futex

Futex是一种用户态和内核态混合机制，所以需要两个部分合作完成，linux上提供了sys_futex系统调用，对进程竞争情况下的同步处理提供支持。

所有的futex同步操作都应该从用户空间开始，首先创建一个futex同步变量，也就是位于共享内存的一个整型计数器。

当进程尝试持有锁或者要进入互斥区的时候，对futex执行"down"操作，即原子性的给futex同步变量减1。如果同步变量变为0，则没有竞争发生， 进程照常执行。

如果同步变量是个负数，则意味着有竞争发生，需要调用futex系统调用的futex_wait操作休眠当前进程。

当进程释放锁或 者要离开互斥区的时候，对futex进行"up"操作，即原子性的给futex同步变量加1。如果同步变量由0变成1，则没有竞争发生，进程照常执行。

如果加之前同步变量是负数，则意味着有竞争发生，需要调用futex系统调用的futex_wake操作唤醒一个或者多个等待进程。

```
[root@iu perf]# perf bench futex all
```



# 参考

https://www.cnblogs.com/arnoldlu/p/6241297.html