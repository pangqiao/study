
cpu idle 相关的指令有 HLT/PAUSE/MWAIT/UMWAT/TPAUSE.

Linux 内核中由 Scheduler 来判断 CPU 的工作量, 从而决定是否让 CPU idle. CPU 层面的手段很多, 但是 OS 层面只有一个抽象的概念即 idle.

那么, Scheduler 到底是如何判断当前工作量不饱满呢?

# 调度器中idle触发条件

Linux Scheduler 为每个 CPU 都维护有一个 RunQueue, 可以认为是一个任务列表, 当且仅当所有任务都不是 runnable 状态时, Scheduler 才会切换到 idle process. 同时可以通过 nohz/nohz_full 启动参数减少 tick 中断对 idle cpu 的干扰.

## idle进程

首个 idle 进程是 0 号进程转换的.

kernel 中所有进程都来自一个静态结构体 `struct task_struct init_task`, init_task 会转化成 idle 进程.

`rest_init()` -> `cpu_startup_entry()` -> `while(1) do_idle()`

在smp系统中 core0 以外的其它core 也会通过 `start_secondary` 函数最终产生0号进程且调用 `cpu_startup_entry` 来进入idle loop之中.

# CPU的各种手段

## X86

### HLT

这是初代的idle 指令, 于486DX时代引入. 首先只有在ring0的特权级别才能执行HLT指令, 同时执 行的效果是 CPU 进入了C1/C1E state(参考ACPI标准)。严格说起来只能算是摸鱼0.1v。APIC/BUS /CACHE 都是照常运转, 只要中断发生, CPU工人立即就要回到产线继续搬砖。C1E 稍微又优待了CPU点, 停止内部时钟又降了压, 比较体贴。

### PAUSE

这个也是非常早期的指令(Pentium 4)许可CPU 工人打个盹,大概从几个到几十个cycles吧(各代CPU有差异)。为什么要打盹呢?其实主要是要降低CPU工人在特定情况下(spin-lock)给内存控制器带来的压力,与其让CPU工人阻塞了内存控器, 不如让他打个盹吧。在最近的几代Xeon之上还附带了降低功耗的buff。

### MWAIT/MONITOR

新一代CPU架构师回顾了前辈的设计, 觉得CPU工人的权力完全没有得到充分的照顾, 应该给予更进一步的休息机会乃至真正的躺平!而且唤醒的条件又多了一个, 除了中断这种强唤醒模式以外, 又加了内存的CacheLine Invalidate唤醒。你的邻居CPU 除了敲门以外还多了拿橡皮筋弹窗户玻璃的渠道。首先这两条指令也只能在ring0 级别执行, 首先是调用MONITOR 地址范围, 其次是MWAIT 进入休眠，一旦该地址的内存被任何其它的主体修改, 则唤醒CPU工人起来继续搬砖。同时这次最大的改进是可以通过MWAIT 进入各种不同的Cstate。其中C6 是我心目中真正的躺平 CPU 电压可以归0同时cache 也停, 实至名归啊。

最常见的C State 状态详细描述

<table style="width:100%">
  <tr>
    <th>
    Cstate
    </th>
    <th>
    配置
    </th>
    <th>
    Address
    </th>
    <th>
    地址
    </th>
  </tr>
  <tr>
    <td>
    设备<b>类型</b>。<br>
    <li><b>0b0000</b>对应<b>EP</b>;</li>
    <li><b>0b0000</b>对应<b>EP</b>;</li>
    该字段只读.
    </td>
    <td>
    Person
    </td>
    <td>
    Person
    </td>
    <td>
    Person
    </td>
  </tr>
  <tr>
    <td rowspan="2">
    获取
    </td>
    <td rowspan="2">
    L1CD
    </td>
    <td>
    stage1
    </td>
    <td>
    OAS
    </td>
  </tr>
  <tr>
    <td>
    IPA
    </td>
    <td>
    IAS
    </td>
  </tr>
</table>