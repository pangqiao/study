
![2022-05-25-09-24-26.png](./images/2022-05-25-09-24-26.png)

# eventfd初始化

Linux 继承了 UNIX "everything is a file" 的思想, **所有打开的文件**都有**一个 fd** 与之对应, 与 QEMU 一样, 很多程序都是**事件驱动**的, 也就是 `select`/`poll`/`epoll` 等**系统调用**在一组 **fd** 上进行**监听**, 当 fd 状态**发生变化**时, 应用程序调用对应的事件处理函数. 事件来源可以有很多种, 如**普通文件**、**socket**、**pipe**等. 但是有的时候需要的**仅仅**是一个**事件通知**, **没有**对应的**具体实体**, 这个时候就可以直接使用 eventfd 了.

eventfd **本质**上是一个**系统调用**, 创建一个**事件通知fd**, 在内核内部创建一个 **eventfd 对象**, 可以用来实现**进程之间**的**等待**/**通知**机制, 内核**也**可以利用 eventfd **通知用户态事件**.

eventfd系统调用的定义

```cpp
SYSCALL_DEFINE2(eventfd2, unsigned int, count, int, flags)
{
	return do_eventfd(count, flags);
}

SYSCALL_DEFINE1(eventfd, unsigned int, count)
{
	return do_eventfd(count, 0);
}
```

内核定义了 2 种 eventfd 相关的系统调用, 分别为 eventfd 和 eventfd2, 二者的区别在于, eventfd 系统调用的 flags 的 flags 参数为 0.

eventfd 和 eventfd2 系统调用都调用了 `do_eventfd`.

```cpp
do_eventfd
=> ctx = kmalloc(sizeof(*ctx), GFP_KERNEL)
=> kref_init(&ctx->kref)
=> init_waitqueue_head(&ctx->wqh)
=> ctx->count = count;
   ctx->flags = flags;
		ctx->id = ida_simple_get(&eventfd_ida, 0, 0, GFP_KERNEL);
=> fd = anon_inode_getfd("[eventfd]", &eventfd_fops, ctx,
			      O_RDWR | (flags & EFD_SHARED_FCNTL_FLAGS));
=> return fd;
```

上面是 do_eventfd 的主要框架, 接下来具体来看.

# eventfd_ctx

ctx 是一个 eventfd_ctx 结构, 该结构的形式如下：

```cpp
struct eventfd_ctx {
	struct kref kref;
	wait_queue_head_t wqh;
	__u64 count;
	unsigned int flags;
	int id;
};
```

在一个eventfd上执行write系统调用, 会向count加上被写入的值, 并唤醒等待队列wqh中的元素. 内核中的eventfd_signal函数也会增加count的值并唤醒wqh中的元素.

在eventfd上执行read系统调用, 会向用户空间返回count的值, 并且该eventfd对应的eventfd_ctx结构中的count会被清0.

剩下的kref、flags、id这3个变量在后面介绍.

do_eventfd为eventfd_ctx分配了空间, 即ctx = kmalloc(sizeof(*ctx), GFP_KERNEL).

## kref

eventfd_ctx中的kref是一个内核中的通用变量, 一般插入到结构体中, 用于记录该结构体被内核各处引用的次数, 当kref->refcount为0时, 该结构体不再被引用, 需要进行释放.

kref_init(&ctx->kref)将eventfd_ctx->kref.refcount值置为了1, 表明eventfd_ctx正在一处代码中使用.

## count、flags、id

eventfd_ctx中count的值在前面介绍过, 对eventfd写则会增加count并唤醒等待队列元素, 对eventfd读则向用户空间返回count值并清count值为0, event_signal()也会增加count并唤醒等待队列元素.

flags由调用eventfd2的调用者传入(eventfd的flags恒为0),

flags的可能取值为EFD_CLOEXEC、EFD_NONBLOCK、EFD_SEMAPHORE三者的任意或组合.

* EFD_CLOEXEC

```
#define EFD_CLOEXEC O_CLOEXEC
```

EFD_CLOEXEC flag 本质上为 O_CLOEXEC.

O_CLOEXEC 即执行时关闭标志. 进程中每个打开的文件描述符都有一个执行时关闭标志, 如果设置此标志, 则在进程调用exec时关闭该文件描述符.

O_CLOEXEC 可以方便我们关闭无用的文件描述符.

例如, 当父进程fork出一个子进程时, 子进程是父进程的副本, 获得父进程的数据空间、堆和栈的副本, 当然也包括父进程打开的文件描述符. 一般情况下, fork之后我们会调用exec执行另一个程序, 此时会用全新的程序替换子进程的context(即堆、栈、数据空间等), 此时之前运行父/子进程打开的文件描述符肯定也不存在了, 我们丢失了这些文件描述符的reference, 但之前被打开的文件依旧处于open状态, 成了系统的负担.

通常在简单系统中, 我们可以在fork出一个子进程之后, 在子进程中关闭这些已经打开, 但不需要的文件描述符. 但是, 在复杂系统中, 在我们fork出子进程的那一刻, 我们并不知道已经有多少文件处于open状态, 一一在子进程中清理难度很大, 如果能在fork出子进程前, 父进程打开某个文件时就约定好, 在我fork出一个子进程后, 执行exec时, 就关闭该打开的文件, 因此close-on-exec,也就是O_CLOEXEC flag, 是打开的文件描述符中的一个标志位.

返回到eventfd话题中, 因为eventfd本质上是一个文件描述符, 打开后也会占用系统资源, 因此也拥有与O_CLOEXEC相同的EFD_CLOEXEC标志.

* EFD_NONBLOCK

```
#define EFD_NONBLOCK O_NONBLOCK
```

EFD_NONBLOCK的实质为O_NONBLOCK, 对于设置该flag的文件描述符, 任何打开文件并返回文件描述符的系统调用都不会阻塞进程, 即如果无法获取文件描述符则立即范返回.

在eventfd机制中, 使用该flag的目的是能够让fcntl系统调用作用于文件文件描述符上时得到与相关系统调用的相同的结果.

* EFD_SEMAPHORE

提供一种类似于信号量的机制, 用于当从eventfd读取内容时的机制保护.

## id

id即eventfd的id, 用于唯一标识一个eventfd.

do_eventfd(count,flags)

通过以上的知识铺垫, eventfd和eventfd2系统调用的处理过程就很清晰了.

1. 分配一个eventfd_ctx结构用于存储eventfd相关信息
2. 设置eventfd_ctx->kref中的值为1, 表明内核正在引用该eventfd
3. 初始化eventfd_ctx结构中的等待队列
4. 为eventfd_ctx结构中的count(读写eventfd时要操作的量)赋上系统调用传入的count
5. 为eventfd_ctx结构中的id通过Linux提供的ida机制申请一个id
6. 最后通过anon_inode_getfd创建一个文件实例, 该文件的操作方法为eventfd_fops, fd->private_data为eventfd_ctx, 文件实例名为eventfd.
7. 返回该文件实例的文件描述符

# 使用eventfd

## eventfd操作方法

在eventfd初始化的过程中, 为eventfd注册了一组操作函数.

```cpp
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

读eventfd动作由eventfd_read函数提供支持, 只有在eventfd_ctx->count大于0的情况下, eventfd才是可读的, 此时调用eventfd_ctx_do_read对eventfd_ctx的count进行处理, 如果eventfd_ctx->flags中的EFD_SEMAPHORE置位, 就将eventfd->count减一(因为semaphore只有0和1两个值, 因此该操作即为置0操作)；如果eventfd_ctx->flags中的EFD_SEMAPHORE为0, 就将eventfd_ctx->count减去自身, 即置eventfd_ctx->count为0, 也是对count变量的置0操作.

如果eventfd_ctx->count等于0, 即该eventfd当前不可读, 此时如果检查eventfd_ctx->flags中的O_NONBLOCK没有置位, 那么将发起读eventfd动作的进程放入属于eventfd_ctx的等待队列, 并重新调度新的进程运行.

如果eventfd_ctx->count大于0, 就将该count置0, 激活正在等待队列中等待的EPOLLOUT进程.
如果eventfd_ctx->count等于0且该eventfd提供阻塞标志, 就将读进程放入等待队列中.

## 写eventfd

写eventfd动作由eventfd_write函数提供支持, 该函数中, ucnt获得了想要写入eventfd的值, 通过判断ULLONG_MAX - eventfd_ctx->count 与ucnt的值大小, 确认eventfd中还有足够空间用于写入, 如果有足够空间用于写入, 就在eventfd_ctx->count的基础上加上ucnt变为新的eventfd_ctx->count, 并激活在等待队列中等待的读/POLLIN进程.

如果没有足够空间用于写入, 则将写进程放入属于eventfd_ctx的等待队列.

## Poll eventfd

Poll(查询)eventfd动作由eventfd_poll函数提供支持, 该函数中定义了一个poll结构的events, 如果eventfd的count大于0, 则eventfd可读, 且events中的POLLIN置位. 如果eventfd的count与ULLONG_MAX之间的差使eventfd至少能写入1, 则该eventfd可写, 且events中的POLLOUT置位.

## eventfd的通知方案

从上面的eventfd操作方法可以看出有两种通知方案:

1. 进程poll eventfd的POLLIN事件, 如果在某个时间点, 其它进程或内核向eventfd写入一个值, 即可让poll eventfd的进程返回.
2. 进程poll eventfd的POLLOUT事件, 如果在某个时间点, 其它进程或内核读取eventfd, 即可让poll eventfd的进程返回.

Linux内核使用第一种通知方案, 即进程poll eventfd的POLLIN事件, Linux提供了功能与eventfd_write类似的eventfd_signal函数, 用于触发对poll eventfd的进程的通知.

# reference

source: https://www.cnblogs.com/haiyonghao/p/14440737.html

关于文件描述符的close-on-exec标志位: https://blog.csdn.net/Leeds1993/article/details/52724428

IDA原理: https://biscuitos.github.io/blog/IDA/