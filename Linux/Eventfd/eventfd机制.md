
![2022-05-25-09-24-26.png](./images/2022-05-25-09-24-26.png)

# 背景

## 事件驱动

Linux 继承了 UNIX "everything is a file" 的思想, **所有打开的文件**都有**一个 fd** 与之对应.

与 QEMU 一样, 很多程序都是**事件驱动**的, 也就是通过 `select`/`poll`/`epoll` 等**系统调用**在一组 **fd** 上进行**监听**, 当 fd 状态**发生变化**时, **应用程序**调用对应的**事件处理函数**.

**事件来源**可以有很多种, 如**普通文件**、**socket**、**pipe**等. 但是有的时候需要的**仅仅**是一个**事件通知**, **没有**对应的**具体实体**, 这个时候就可以直接使用 **eventfd** 了.

## eventfd

eventfd **本质**上是一个**系统调用**, 创建一个**事件通知 fd**, 在内核内部创建一个 **eventfd 对象**, 可以用来实现**进程之间**的**等待**/**通知**机制, 内核**也**可以利用 eventfd **通知用户态事件**.

> 系统调用都是从**用户态**到**内核态**的访问

# eventfd初始化

## 系统调用的定义

内核定义了 2 种 eventfd **相关的系统调用**, 分别为 `eventfd` 和 `eventfd2`, 二者的区别在于, eventfd 系统调用的 flags 参数为 0.

```cpp
// fs/eventfd.c
SYSCALL_DEFINE2(eventfd2, unsigned int, count, int, flags)
{
	return do_eventfd(count, flags);
}

SYSCALL_DEFINE1(eventfd, unsigned int, count)
{
	return do_eventfd(count, 0);
}
```

两个系统调用都调用了 `do_eventfd`. 其中就是对 `struct eventfd_ctx` 的初始化

## eventfd_ctx

该结构如下: 

```cpp
struct eventfd_ctx {
	struct kref kref;
	wait_queue_head_t wqh;
	__u64 count;
	unsigned int flags;
	int id;
};
```

### count和wqh

* 在**一个 eventfd** 上执行 **write 系统调用**, 会向 `count` **加上被写入的值**, 并**唤醒等待队列 wqh** 中的元素;
* **内核**中的 `eventfd_signal` 函数**也**会**增加** count 的值并唤醒 wqh 中的元素;
* 在 eventfd 上执行 **read 系统调用**, 会向 **用户空间！！！** 返回 count 的值, 并且该 eventfd 对应的 `eventfd_ctx` 结构中的 **count 会被清 0**.

`do_eventfd` 为 `eventfd_ctx` 分配了空间, 即 `ctx = kmalloc(sizeof(*ctx), GFP_KERNEL)`.

### kref

`eventfd_ctx` 中的 kref 是一个内核中的**通用变量**, 一般插入到结构体中, 用于记录**该结构体**被**内核**各处**引用的次数**, 当 `kref->refcount` 为0时, 该结构体**不再被引用**, 需要**进行释放**.

`kref_init(&ctx->kref)` 将 `eventfd_ctx->kref.refcount` 值**初始化为了 1**, 表明 `eventfd_ctx` 正在一处代码中使用.

### count、flags、id

`eventfd_ctx` 中 `count` 的值在前面介绍过:

* 对 eventfd 写则会增加 count 并唤醒等待队列元素;
* 对 eventfd 读则向用户空间返回 count 值并清 count 值为0;
* `event_signal()` 也会增加 count 并唤醒等待队列元素.

flags 由**系统调用 eventfd2** 的调用者传入(eventfd 的 flags 恒为0), 可能取值为 `EFD_CLOEXEC`、`EFD_NONBLOCK`、`EFD_SEMAPHORE` 三者的任意或组合.

```cpp
// include/linux/eventfd.h
#define EFD_SEMAPHORE (1 << 0)
#define EFD_CLOEXEC O_CLOEXEC
#define EFD_NONBLOCK O_NONBLOCK

#define EFD_SHARED_FCNTL_FLAGS (O_CLOEXEC | O_NONBLOCK)
#define EFD_FLAGS_SET (EFD_SHARED_FCNTL_FLAGS | EFD_SEMAPHORE)
```

* `EFD_CLOEXEC`

```cpp
#define EFD_CLOEXEC O_CLOEXEC
```

`EFD_CLOEXEC` flag 本质上为 `O_CLOEXEC`, `close-on-exec`.

`O_CLOEXEC` 即**执行时关闭**标志. 进程中**每个打开的文件描述符！！！** 都有一个**执行时关闭标志**, 如果设置此标志, 则在**进程**调用 **exec** 时**关闭该文件描述符**.

O_CLOEXEC 可以方便我们**关闭无用的文件描述符**.

例如, 当**父进程** **fork** 出一个**子进程**时, **子进程**是父进程的**副本**, 获得父进程的**数据空间**、**堆**和**栈**的**副本**, 当然也包括**父进程打开的文件描述符**. 一般情况下, fork 之后我们会**调用 exec 执行另一个程序**, 此时会用全新的程序**替换**子进程的 **context**(即**堆**、**栈**、**数据空间**等), 此时之前运行父/子进程打开的文件描述符肯定也不存在了, 我们丢失了这些文件描述符的reference, 但**之前被打开的文件依旧处于open状态**, 成了系统的负担.

通常在简单系统中, 我们可以在 fork 出一个子进程之后, 在**子进程**中**关闭**这些已经打开但不需要的文件描述符. 但是, 在复杂系统中, 在我们 fork 出子进程的那一刻, 我们并**不知道**已经有**多少文件处于open状态**, 一一在子进程中清理难度很大, 如果能**在 fork 出子进程前**, **父进程打开某个文件时**就约定好, 在我 fork 出一个子进程后, 执行 exec 时, 就关闭该打开的文件, 因此 `close-on-exec`,也就是 `O_CLOEXEC` flag, 是打开的文件描述符中的一个标志位.

返回到 eventfd 话题中, 因为 **eventfd** 本质上是一个**文件描述符**, 打开后也会**占用系统资源**, 因此也拥有与 O_CLOEXEC 相同的 `EFD_CLOEXEC` 标志.

* `EFD_NONBLOCK`

```cpp
#define EFD_NONBLOCK O_NONBLOCK
```

`EFD_NONBLOCK` 的实质为 `O_NONBLOCK`, 对于设置该 flag 的文件描述符, **任何打开文件并返回文件描述符**的**系统调用**都**不会阻塞进程**, 即如果**无法获取文件描述符**则**立即返回**.

在 eventfd 机制中, 使用该 flag 的目的是能够让 **fcntl 系统调用**作用于文件文件描述符上时得到与相关系统调用的相同的结果.

* `EFD_SEMAPHORE`

提供一种**类似于信号量的机制**, 用于当从 eventfd **读取内容**时的**机制保护**.

### id

id 即 eventfd 的id, 用于**唯一标识**一个 **eventfd**.

## do_eventfd

```cpp
do_eventfd(count,flags)
```

`do_eventfd` 的主要框架.

```cpp
do_eventfd
=> ctx = kmalloc(sizeof(*ctx), GFP_KERNEL)
=> kref_init(&ctx->kref)
=> init_waitqueue_head(&ctx->wqh)
=> ctx->count = count;
=> ctx->flags = flags;
=> ctx->id = ida_simple_get(&eventfd_ida, 0, 0, GFP_KERNEL);
=> fd = anon_inode_getfd("[eventfd]", &eventfd_fops, ctx, O_RDWR | (flags & EFD_SHARED_FCNTL_FLAGS));
=> return fd;
```

通过以上的知识铺垫, eventfd 和 eventfd2 系统调用的处理过程就很清晰了.

1. 分配一个 `eventfd_ctx` 结构用于存储 eventfd 相关信息
2. 设置 `eventfd_ctx->kref` 中的值为 1, 表明**内核正在引用该 eventfd**
3. 初始化 `eventfd_ctx` 结构中的等待队列
4. 为 `eventfd_ctx` 结构中的 **count**(读写 eventfd 时要操作的量)**赋上**系统调用**传入的 count**
5. 为 `eventfd_ctx` 结构中的 id 通过 Linux 提供的 **ida 机制**申请一个 id
6. 最后通过 `anon_inode_getfd` 创建一个文件实例, **该文件**的**操作方法**为 `eventfd_fops`, `fd->private_data` 为 **eventfd_ctx**, **文件实例名**`为eventfd`.
7. 返回该文件实例的**文件描述符**

# 使用eventfd

## eventfd操作方法

在 eventfd 初始化的过程中, 为 eventfd 注册了一组**操作函数**.

```cpp
// fs/eventfd.c
static const struct file_operations eventfd_fops = {
#ifdef CONFIG_PROC_FS
	.show_fdinfo	= eventfd_show_fdinfo,
#endif
	.release	= eventfd_release,
	.poll		= eventfd_poll,
	.read		= eventfd_read,
	.write		= eventfd_write,
	.llseek		= noop_llseek,
};
```

## 读eventfd

读 eventfd 动作由 `eventfd_read` 函数提供支持, 只有在 `eventfd_ctx->count` **大于0**的情况下, eventfd **才是可读的**, 然后调用 `eventfd_ctx_do_read` 对 `eventfd_ctx` 的 **count** 进行处理:

* 如果 `eventfd_ctx->flags` 中的 `EFD_SEMAPHORE` **置位**, 就将 `eventfd_ctx->count` **减一**(因为 semaphore 只有 0 和 1 **两个值**, 因此该操作即为**置 0 操作**);
* 如果 `eventfd_ctx->flags` 中的 `EFD_SEMAPHORE` 为**0**, 就将 `eventfd_ctx->count` **减去自身**, 即**置** `eventfd_ctx->count` 为 **0**, 也是对 **count** 变量的**置 0 操作**.

如果 `eventfd_ctx->count` 等于**0**, 即该 eventfd **当前不可读**, 此时如果检查 `eventfd_ctx->flags` 中的 `O_NONBLOCK` **没有置位**, 那么将发起读 eventfd 动作的进程放入属于 `eventfd_ctx` 的等待队列, 并重新调度新的进程运行.

如果 `eventfd_ctx->count`大于0, 就将该 count 置0, 激活正在等待队列中等待的 EPOLLOUT 进程.
如果 `eventfd_ctx->count` 等于0且该 eventfd 提供阻塞标志, 就将读进程放入等待队列中.

## 写eventfd

写 eventfd 动作由 eventfd_write 函数提供支持, 该函数中, ucnt 获得了想要写入 eventfd 的值, 通过判断 `ULLONG_MAX - eventfd_ctx->count` 与 ucnt 的值大小, 确认 eventfd 中还有足够空间用于写入, 如果有足够空间用于写入, 就在 `eventfd_ctx->count` 的基础上加上 ucnt 变为新的 `eventfd_ctx->count`, 并激活在等待队列中等待的 读/POLLIN 进程.

如果没有足够空间用于写入, 则将写进程放入属于 `eventfd_ctx` 的等待队列.

## Poll eventfd

Poll(查询) eventfd 动作由 `eventfd_poll` 函数提供支持, 该函数中定义了一个 poll 结构的 events, 如果 eventfd 的 count 大于 0, 则 eventfd 可读, 且 events 中的 POLLIN 置位. 如果 eventfd 的 count 与 ULLONG_MAX 之间的差使 eventfd 至少能写入 1, 则该 eventfd 可写, 且 events 中的 POLLOUT 置位.

## eventfd的通知方案

从上面的 eventfd 操作方法可以看出有两种通知方案:

1. 进程 poll eventfd 的 POLLIN 事件, 如果在某个时间点, 其它进程或内核向 eventfd 写入一个值, 即可让 poll eventfd 的进程返回.
2. 进程 poll eventfd 的 POLLOUT 事件, 如果在某个时间点, 其它进程或内核读取 eventfd, 即可让 poll eventfd 的进程返回.

Linux 内核使用第一种通知方案, 即进程 poll eventfd 的 POLLIN 事件, Linux 提供了功能与 eventfd_write 类似的 eventfd_signal 函数, 用于触发对 poll eventfd 的进程的通知.

# reference

source: https://www.cnblogs.com/haiyonghao/p/14440737.html

关于文件描述符的close-on-exec标志位: https://blog.csdn.net/Leeds1993/article/details/52724428

IDA原理: https://biscuitos.github.io/blog/IDA/