
cpu idle 相关的指令有 HLT/PAUSE/MWAIT/UMWAT/TPAUSE.

Linux 内核中由 Scheduler 来判断 CPU 的工作量, 从而决定是否让 CPU idle. CPU 层面的手段很多, 但是 OS 层面只有一个抽象的概念即 idle.

那么, Scheduler 到底是如何判断当前工作量不饱满呢?

# 调度器中idle触发条件

Linux Scheduler 为每个 CPU 都维护有一个 RunQueue, 可以认为是一个任务列表, 当且仅当所有任务都不是 runnable 状态时, Scheduler 才会切换到 idle process. 同时可以通过 nohz/nohz_full 启动参数减少 tick 中断对 idle cpu 的干扰.

## idle进程

首个 idle 进程是 0 号进程转换的.

kernel 中所有进程都来自一个静态结构体 `struct task_struct init_task`, init_task 会转化成 idle 进程.



