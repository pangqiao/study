参考内核文档: `Documentation/admin-guide/mm/numa_memory_policy.rst`

memory policy是决定在NUMA系统上从哪个节点分配内存的策略, 它是一类提供给能更好利用NUMA系统进行内存分配的应用程序使用的编程接口, 

请不要将它和cpusets混淆, 后者是一种限定哪些process可以从该节点进行内存分配的管理机制, 当一个task同时存在两种机制时, cpuset优先. 



Linux分四种类型policy, 分别是: 

- `System Default Policy`, 它是在没用应用下面其他policy时的**默认policy**, 具体行为是: **系统启动过程中**, 采用**interleave策略**分配内存, 即在所有**可满足需求的节点**上**交叉分配**, 防止启动时在**某个节点上负载过重**；在**系统启动后**, 采用**local allocation**, 即在task运行的cpu所在的node上进行内存分配.

- `Task/Process Policy`, 它是**task用来制定其内存分配时的策略**, 如果**没有定义**, 将fall back到system default policy. fork()等可继承(inheritable), 父进程创建子进程时可以建立policy, 见`Memory Policy APIs <memory_policy_apis>`节. 多线程任务, 只有拥有policy的线程以及该线程创建的子线程才有task policy. 任务策略仅适用于在安装策略后分配的页面

- `VMA Policy`, 它是针对在**某段VMA进行内存分配**时策略, 如果没有定义, 将fall back到Task/Process Policy, 如果Task/Process Policy没有定义, 递归fall back到system default policy. 

- `Shared Policy`, 它是制定在分配某个内存对象时的policy, 这个内存对象可能被多个task共享, 而VMA policy只限定某个task的某段VMA. 挂在这个shared对象上的所有tasks会遵循这个policy.



Linux 内存分配方法包含三部分: `mode`, `optional mode flags`, `an optional set of nodes`. 

mode决定**policy**的**具体行为**, the optional mode flags决定**mode的行为**, an optional set of nodes可以看做是以上行为的参数. 

`struct mempolicy`来实现memory policy.

mode有四种: 

* Default Mode--MPOL_DEFAULT, 

* MPOL_BIND, 它指定在**哪几个节点**上进行内存分配. 

* MPOL_PREFERRED, 它指定首先在**preferred的节点**上进行内存分配, 如果失败再搜索其他节点. 

* MPOL_INTERLEAVED, 它指定在**an optional set of nodes几个节点**上, **以页为单位**, **交叉分配内存**. 



optional mode flags: 

- MPOL_F_STATIC_NODES:  该标志指定, **在policy定义后**, 如果task或VMA设置的可分配nodes发生了改变, 用户传递过来的nodemask**不应被remap**. 
- MPOL_F_RELATIVE_NODES:  和上个flag相反, 该情况时, 用户传递过来的**nodemask**应**被remap**. 



Linux为内存分配策略提供了三个APIs: 

- 设置内存分配策略

```
    long set_mempolicy(int mode, const unsigned long *nmask, unsigned long maxnode);
```

- Get内存分配策略及相关信息, flags决定mode的行为是get哪些信息

```
    long get_mempolicy(int *mode, const unsigned long *nmask, unsigned long maxnode, void *addr, int flags);
```

- 安装内存分配策略

```
    long mbind(void *start, unsigned long len, int mode, const unsigned long *nmask, unsigned long maxnode,
     unsigned flags);
```

命令行工具: 

+ set the task policy for a specified program via set_mempolicy(2), fork(2) and exec(2)
+ set the shared policy for a shared memory segment via mbind(2)
