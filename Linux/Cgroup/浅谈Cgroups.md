
说起容器监控，首先会想到通过 Cadvisor, Docker stats 等多种方式获取容器的监控数据，并同时会想到容器通过 Cgroups 实现对容器中的资源进行限制。但是这些数据来自哪里，并且如何计算的？答案是 Cgroups。最近在写 docker 容器监控组件，在深入 Cadvisor 和 Docker stats 源码发现数据都来源于 Cgroups。了解之余，并对 Cgroups 做下笔记。

# Cgroups 介绍

Cgroups 是 control groups 的缩写，是 Linux 内核提供的一种可以限制，记录，隔离进程组(process groups)所使用物理资源的机制。最初有 google 工程师提出，后来被整合进 Linux 的内核。

因此，Cgroups 为容器实现虚拟化提供了基本保证，是构建 Docker,LXC 等一系列虚拟化管理工具的基石。

# Cgroups 作用

* 资源限制(Resource limiting): Cgroups可以对进程组使用的资源总额进行限制。如对特定的进程进行内存使用上限限制，当超出上限时，会触发OOM。
* 优先级分配(Prioritization): 通过分配的CPU时间片数量及硬盘IO带宽大小，实际上就相当于控制了进程运行的优先级。
* 资源统计(Accounting): Cgroups可以统计系统的资源使用量，如CPU使用时长、内存用量等等，这个功能非常适用于计费。
* 进程控制(ControlCgroups): 可以对进程组执行挂起、恢复等操作。


# 参考

https://www.infoq.cn/article/FUOI4c3L0NpztXarhjNN