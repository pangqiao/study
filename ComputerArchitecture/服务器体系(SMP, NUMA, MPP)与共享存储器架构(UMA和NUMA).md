参照：

http://blog.csdn.net/gatieme/article/details/52098615

## 1. 3种系统架构与2种存储器共享方式

### 1.1 架构概述

从系统架构来看，目前的商用服务器大体可以分为三类

- 对称多处理器结构(SMP：Symmetric Multi-Processor)

- 非一致存储访问结构(NUMA：Non-Uniform Memory Access)

- 海量并行处理结构(MPP：Massive Parallel Processing)。

共享存储型多处理机有两种模型

- 均匀存储器存取（Uniform-Memory-Access，简称UMA）模型

- 非均匀存储器存取（Nonuniform-Memory-Access，简称NUMA）模型

而我们后面所提到的COMA和ccNUMA都是NUMA结构的改进

### 1.2 SMP(Symmetric Multi-Processor)

所谓对称多处理器结构，是指服务器中多个CPU对称工作，无主次或从属关系。

各CPU共享相同的物理内存，每个 CPU访问内存中的任何地址所需时间是相同的，因此SMP也被称为一致存储器访问结构(UMA：Uniform Memory Access)

对SMP服务器进行扩展的方式包括增加内存、使用更快的CPU、增加CPU、扩充I/O(槽口数与总线数)以及添加更多的外部设备(通常是磁盘存储)。

SMP服务器的主要特征是共享，系统中所有资源(CPU、内存、I/O等)都是共享的。也正是由于这种特征，导致了SMP服务器的主要问题，那就是它的扩展能力非常有限。

对于SMP服务器而言，每一个共享的环节都可能造成SMP服务器扩展时的瓶颈，而最受限制的则是内存。由于每个CPU必须通过相同的内存总线访问相同的内存资源，因此随着CPU数量的增加，内存访问冲突将迅速增加，最终会造成CPU资源的浪费，使CPU性能的有效性大大降低。实验证明，SMP服务器CPU利用率最好的情况是2至4个CPU

![config](images/2.png)

图中，物理存储器被所有处理机均匀共享。所有处理机对所有存储字具有相同的存取时间，这就是为什么称它为均匀存储器存取的原因。每台处理机可以有私用高速缓存,外围设备也以一定形式共享

