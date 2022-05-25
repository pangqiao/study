
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 背景](#1-背景)
- [2. KVM](#2-kvm)
  - [2.1. 数据结构](#21-数据结构)
  - [2.2. 注册流程](#22-注册流程)
  - [2.3. 触发流程](#23-触发流程)
- [3. QEMU](#3-qemu)
  - [3.1. 数据结构](#31-数据结构)
  - [3.2. 注册流程](#32-注册流程)

<!-- /code_chunk_output -->

# 1. 背景

Guest 一个完整的 IO 流程包括从虚拟机内部到 KVM, 再到 QEMU, 并由 QEMU 最终进行分发, IO 完成之后的原路返回. 这样的一次路径称为**同步 IO**, 即指 Guest 需要等待 IO 操作的结果才能继续运行, 但是存在这样一种情况, 即某次 IO 操作只是作为一个通知事件, 用于通知 `QEMU/KVM` 完成另一个具体的 IO, 这种情况下没有必要像普通 IO 一样等待数据完全写完, 只需要触发通知并等待具体 IO 完成即可. 

ioeventfd 正是为 IO 通知提供机制的东西, QEMU 可以将虚拟机特定地址关联一个 eventfd, 对该 eventfd 进行 POLL, 并利用 `ioctl(KVM_IOEVENTFD)` 向KVM注册这段特定地址, 当 Guest 进行 IO 操作 exit 到 kvm 后, kvm 可以判断本次 exit 是否发生在这段特定地址中, 如果是, 则直接调用 `eventfd_signal` 发送信号到对应的 eventfd, 导致 QEMU 的监听循环返回, 触发具体的操作函数, 进行普通 IO 操作. 这样的一次 IO 操作相比于不使用 ioeventfd 的 IO 操作, 能节省一次在 QEMU 中分发 IO 请求和处理 IO 请求的时间. 




eventfd 是内核实现的高效线程通信机制, 还适合于内核与用户态的通信, KVM模块利用 eventfd 实现了 KVM 和 qemu 的高效通信机制 ioeventfd.

> Linux\Eventfd\Linux的eventfd机制.md
> 
分为 KVM 的实现和 qemu 的使用两部分.

# 2. KVM

## 2.1. 数据结构

ioeventfd 是内核kvm模块向qemu提供的一个 vm ioctl 命令字 KVM_IOEVENTFD, 对应调用 kvm_vm_ioctl 函数, 原型如下:

```cpp
// "include/linux/kvm_host.h"
int kvm_ioeventfd(struct kvm *kvm, struct kvm_ioeventfd *args);
```

这个命令字的功能是将一个 **eventfd** 绑定到**一段客户机的地址空间**, 这个空间可以是 **mmio**, 也可以是 **pio**. 当 **guest 写**这段地址空间时, 会触发 `EPT_MISCONFIGURATION` **缺页异常**, **KVM** 处理时如果发现这段地址落在了**已注册的 ioeventfd 地址区间**里, 会通过**写关联 eventfd 通知 qemu**, 从而**节约**一次**内核态到用户态的切换开销**. 用户态传入的参数如下:

```cpp
// "include/uapi/linux/kvm.h"
struct kvm_ioeventfd {
	__u64 datamatch;
	__u64 addr;        /* legal pio/mmio address */
	__u32 len;         /* 1, 2, 4, or 8 bytes; or 0 to ignore length */
	__s32 fd;
	__u32 flags;
	__u8  pad[36];
};
```

* datamatch: 如果 flags 设置了 `KVM_IOEVENTFD_FLAG_DATAMATCH`, 只有当客户机向 addr 地址写入的值与 datamatch 值相等, 才会触发event
* fd: eventfd 关联的fd, eventfd_ctx 的结构在初始化时被放在了 file 结构的 private_data 中, 首先通过 fd 从进程的 fd 表中可以找到 file 结构, 顺藤摸瓜可以找到 eventfd_ctx, 从这里能够看出, eventfd 的用法是**用户态**注册好 evenfd 并获得 fd, 然后将 fd 和感兴趣的地址区间封装成 `kvm_ioeventfd` 结构体作为参数, 调用 `ioctl KVM_IOEVENTFD` **命令字**, 注册到kvm

用户态信息 `kvm_ioeventfd` 需要转化成内核态存放, 当 guest 写地址时找到对应的结构体, 触发 event, ioeventfd 内核态结构体基于 eventfd, 如下:

```cpp
// "virt/kvm/eventfd.c"
struct _ioeventfd {
	struct list_head     list;
	u64                  addr;
	int                  length;
	struct eventfd_ctx  *eventfd;
	u64                  datamatch;
	struct kvm_io_device dev;
	u8                   bus_idx;
	bool                 wildcard;
};
```

* addr: 客户机PIO/MMIO地址, 当客户机向该地址写入数据时触发event
* length: 客户机向该地址写入数据时数据的长度, 当length为0时, 忽略写入数据的长度
* eventfd: 关联的eventfd
* datamatch: 用户态程序设置的match data, 当ioeventfd被设置了KVM_IOEVENTFD_FLAG_DATAMATCH, 只有满足客户机写入的值等于datamatch的条件时才触发event
* dev: VM-Exit退出时调用dev->ops的write操作, 对应ioeventfd_write
* bus_idx: 客户机的地址被分为了4类, MMIO, PIO, VIRTIO_CCW_NOTIFY, FAST_MMIO, bus_idx用来区分注

用户态下发 KVM_IOEVENTFD 命令字最终会生成 `_ioeventfd` 结构体, 存放在内核中, 由于它是**和一个虚机关联的**, 因此被放到了 kvm 结构体中维护, kvm 结构体中有两个字段, 存放了 ioeventfd 相关的信息, 如下:

```cpp
// "include/linux/kvm_host.h"
struct kvm {
	......
	struct kvm_io_bus __rcu *buses[KVM_NR_BUSES];
#ifdef CONFIG_HAVE_KVM_EVENTFD
	struct list_head ioeventfds;
#endif
	......
}

// "include/linux/kvm_host.h"
struct kvm_io_bus {
	int dev_count;
	int ioeventfd_count;
	struct kvm_io_range range[];
};

// "include/linux/kvm_host.h"
enum kvm_bus {
	KVM_MMIO_BUS,
	KVM_PIO_BUS,
	KVM_VIRTIO_CCW_NOTIFY_BUS,
	KVM_FAST_MMIO_BUS,
	KVM_NR_BUSES
};
```

* buses: kvm中将ioeventfd注册的地址分为4类, 每类地址可以认为有独立的地址空间, 它们被抽象成 4个 bus 上的地址. 分别是 kvm_bus 所列出的 MMIO, PIO, VIRTIO_CCW_NOTIFY, FAST_MMIO, MMIO 和 FAST_MMIO 的区别是, MMIO需要检查写入地址的值长度是否和 ioeventfd 指定的长度相等, FAST_MMIO 不需要检查. ioeventfd 的地址信息被放在 kvm_io_bus 的range中;
* ioeventfds: ioeventfd的整个信息通过list成员被链接到了ioeventfds中

相关数据结构之间的关系:

![2022-05-22-22-40-24.png](./images/2022-05-22-22-40-24.png)

## 2.2. 注册流程

KVM_IOEVENTFD ioctl 命令字的主要功能是在 kvm 上注册这个 ioevent, 最终目的是将 ioevenfd 信息添加到 kvm 结构的 buses 和 ioeventfds 两个成员中, 注册流程如下:

```cpp

kvm_vm_ioctl() -> (case KVM_IOEVENTFD) -> kvm_ioeventfd() -> kvm_assign_ioeventfd()

// "virt/kvm/eventfd.c"
static int
kvm_assign_ioeventfd(struct kvm *kvm, struct kvm_ioeventfd *args)
{
	enum kvm_bus              bus_idx;
	......
	bus_idx = ioeventfd_bus_from_flags(args->flags); /* 1 */
	ret = kvm_assign_ioeventfd_idx(kvm, bus_idx, args); /* 2 */
	......
```

* 1: 首先根据地址所属总线类型, 找到总线索引, 方便在 `kvm->buses` 数组中找到 kvm_io_bus 结构
* 2: 注册 ioeventfd, 将用户态的信息拆解, 封装成内核态的 `kvm_io_bus` 和 `_ioeventfd` 结构, 保存到 kvm 结构体的对应成员

跟踪kvm_assign_ioeventfd_idx主要流程:

```cpp
// "virt/kvm/eventfd.c"
static int kvm_assign_ioeventfd_idx(struct kvm *kvm,
				enum kvm_bus bus_idx,
				struct kvm_ioeventfd *args)
{
	struct eventfd_ctx *eventfd;
	struct _ioeventfd *p;
	......
	eventfd = eventfd_ctx_fdget(args->fd); /* 1 */
	p = kzalloc(sizeof(*p), GFP_KERNEL_ACCOUNT); /* 2 */
	INIT_LIST_HEAD(&p->list);
	p->addr    = args->addr;
	p->bus_idx = bus_idx;
	p->length  = args->len;
	p->eventfd = eventfd;

	kvm_iodevice_init(&p->dev, &ioeventfd_ops); /* 3 */
	kvm_io_bus_register_dev(kvm, bus_idx, p->addr, p->length, &p->dev); /* 4 */
	kvm_get_bus(kvm, bus_idx)->ioeventfd_count++; /* 5 */
	list_add_tail(&p->list, &kvm->ioeventfds);
	......
}
static const struct kvm_io_device_ops ioeventfd_ops = {
	.write      = ioeventfd_write,
	.destructor = ioeventfd_destructor,
};
```

* 1: 根据 fd 从进程的描述符表中找到 struct file 结构, 从 `file->private_data` 取出 eventfd_ctx
* 2: 使用用户态传入的 kvm_ioeventfd 初始化一个 _ioeventfd 结构
* 3: 设置 _ioeventfd 的钩子函数, 当虚机写内存缺页时, KVM 首先尝试触发 p->dev 中的 write 函数, 检查缺页地址是否满足 ioeventfd 触发条件
* 4: 将 `_ioeventfd` 中的地址信息和钩子函数封装成 kvm_io_range, 放到 kvm->buses 的range[]数组中. 之后kvm在处理缺页就可以查询到缺页地址是否在已注册的 ioeventfd 的地址区间
* 5: 更新 ioeventfd 的计数, 将ioeventfd放到kvm的ioeventfds链表中, 维护起来

## 2.3. 触发流程

当 kvm 检查 `VM-Exit` 退出原因, 如果是缺页引起的退出并且原因是 EPT misconfiguration, 首先检查缺页的物理地址是否落在已注册 ioeventfd 的物理区间, 如果是, 调用对应区间的 write 函数. 虚机触发缺页的流程如下:

```cpp
vmx_handle_exit
	kvm_vmx_exit_handlers[exit_reason](vcpu)
		handle_ept_misconfig
```

缺页流程处理函数:

```cpp
// "arch/x86/kvm/vmx/vmx.c"
static int handle_ept_misconfig(struct kvm_vcpu *vcpu)
{
	gpa_t gpa;
	gpa = vmcs_read64(GUEST_PHYSICAL_ADDRESS); /* 1 */
	if (!is_guest_mode(vcpu) &&
	    !kvm_io_bus_write(vcpu, KVM_FAST_MMIO_BUS, gpa, 0, NULL)) { /* 2 */
		trace_kvm_fast_mmio(gpa);
		return kvm_skip_emulated_instruction(vcpu);
	}

	return kvm_mmu_page_fault(vcpu, gpa, PFERR_RSVD_MASK, NULL, 0); /* 3 */
}
```

* 1: 从 VMCS 结构中读取引发缺页的虚机物理地址
* 2: 首先尝试**触发 ioeventfd**, 如果成功, eventfd 会通知用户态 qemu, 因此不需要退到用户态, 触发 ioeventfd 之后再次进入客户态就行了
* 3: 如果引发缺页的地址不在 ioeventfd 监听范围内, 进行缺页处理, 这里的实现我们跳过, 重点分析触发 ioeventfd 的情形

分析如何触发eventfd流程:

```cpp
// "virt/kvm/kvm_main.c"
int kvm_io_bus_write(struct kvm_vcpu *vcpu, enum kvm_bus bus_idx, gpa_t addr,
		     int len, const void *val)
{
	......
	range = (struct kvm_io_range) { /* 4 */
		.addr = addr,
		.len = len,
	};

	bus = srcu_dereference(vcpu->kvm->buses[bus_idx], &vcpu->kvm->srcu); /* 5 */
	r = __kvm_io_bus_write(vcpu, bus, &range, val); /* 6 */
	......
}
EXPORT_SYMBOL_GPL(kvm_io_bus_write);
```

* 4: 将引发缺页的物理地址封装成 `kvm_io_range` 格式, 方便与以在总线上注册的 range 进行对比
* 5: 根据物理地址类型找到该类型所在的地址总线, 这个总线上记录这所有在该总线上注册的 ioeventfd 的地址区间
* 6: 对比总线上的地址区间和引发缺页的物理地址区间, 如果缺页地址区间落在的总线上的地址区间里, 调用对应的 write 函数触发 eventfd

最终, 客户机的缺页流程会调用 `kvm_io_device->write()` 函数触发 eventfd, 看下它的具体实现:

```cpp
// "virt/kvm/eventfd.c"
//
/* MMIO/PIO writes trigger an event if the addr/val match */
static int ioeventfd_write(struct kvm_vcpu *vcpu, struct kvm_io_device *this, gpa_t addr,
		int len, const void *val)
{
	struct _ioeventfd *p = to_ioeventfd(this); /* 7 */

	if (!ioeventfd_in_range(p, addr, len, val)) /* 8 */
		return -EOPNOTSUPP;

	eventfd_signal(p->eventfd, 1); /* 9 */
	return 0;
}
```

* 7: 根据从 bus 总线上取下的 `range[]`, 取出其dev成员, 由于dev结构体是 `_ioeventfd` 的一个成员, 通过 container 转化可以取出 `_ioeventfd`
* 8: 检查缺页物理地址和 range 中注册的地址是否匹配
* 9: 取出 `_ioeventfd` 中的 `eventfd_ctx` 结构体, 往它维护的计数器中加1

`eventfd_signal` 实现如下:

```cpp
// "fs/eventfd.c"
//
/**
 * eventfd_signal - Adds @n to the eventfd counter.
 * @ctx: [in] Pointer to the eventfd context.
 * @n: [in] Value of the counter to be added to the eventfd internal counter.
 *          The value cannot be negative.
 *
 * This function is supposed to be called by the kernel in paths that do not
 * allow sleeping. In this function we allow the counter to reach the ULLONG_MAX
 * value, and we signal this as overflow condition by returning a EPOLLERR
 * to poll(2).
 *
 * Returns the amount by which the counter was incremented.  This will be less
 * than @n if the counter has overflowed.
 */
__u64 eventfd_signal(struct eventfd_ctx *ctx, __u64 n)
{
	......
	current->in_eventfd_signal = 1;
	if (ULLONG_MAX - ctx->count < n) /* 10 */
		n = ULLONG_MAX - ctx->count;
	ctx->count += n; /* 11 */
	if (waitqueue_active(&ctx->wqh)) /* 12 */
		wake_up_locked_poll(&ctx->wqh, EPOLLIN);
	current->in_eventfd_signal = 0;
	......
}
EXPORT_SYMBOL_GPL(eventfd_signal);
```

* 10: 首先判断下**计数器**是否即将溢出. 如果计数器加上 1 之后溢出了, 让计数器直接等于最大值, 内核态写eventfd与用户态有所区别, 它不允许阻塞, 因此当计数器溢出时直接设置其为最大值
* 11: 增加计数器的值
* 12: **唤醒**阻塞在 eventfd 上的**读线程**, 如果计数器原来为0, 有读线程阻塞在这个 eventfd 上, 那么此时计数器加1后, 就可以唤醒这些线程

# 3. QEMU

传统的QEMU设备模拟, 当虚机访问到 pci 的配置空间或者 BAR 空间时, 会触发缺页异常而 `VM-Exit`, kvm 检查到虚机访问的是用户 QEMU模拟 的用户态设备的空间, 这是 IO 操作, 会退出到用户态交给 QEMU 处理. 梳理整个流程, 需要经过**两次 cpu 模式切换**, 一次是**非根模式**到**根模式**, 一次是**内核态**到**用户态**. 分析内核态切换到用户态的原因, 是**kvm没有模拟这个设备**, 处理不了这种情况才退出到用户态让QEMU处理, 但还有一种解决方法就是让 kvm 通知 QEMU, 把要处理 IO 这件事情通知到 QEMU 就可以了, 这样就节省了一个内核态到用户态的开销.

如果以这样的方式实现, 假设虚机所有 IO 操作 kvm 都一股脑儿通知 QEMU, 那 QEMU 也不知道到底是哪个设备需要处理, 所以需要一个东西作为 QEMU 和 KVM 之间通知的载体, 当 QEMU 模拟一个设备时, 首先将这个设备的物理地址空间信息摘出来, 对应关联一个回调函数, 然后传递给 KVM, 其目的是告知 KVM, 当虚机内部有访问该物理地址空间的动作时, KVM 调用 QEMU 关联的回调函数通知 QEMU, 这样就能实现针对具体物理区间的通知. 这个实现就是 ioeventfd.

## 3.1. 数据结构

以virtio磁盘为例, virtio磁盘是一个pci设备, 它有pci空间, 这些空间的内存都是QEMU模拟的, 当虚机写这些pci空间时, QEMU需要做对应的处理, 在virtio磁盘初始化成功后, 它就会将自己的地址空间信息提取出来, 封装成ioeventfd, 通过ioctl命令字传递给KVM, ioeventfd中包含一个QEMU提前通过eventfd创建好的fd, KVM通知QEMU是就往这个fd中写1. 以下就是这个ioeventfd的结构, 具体含义见前面的分析.

```cpp
// linux-headers/linux/kvm.h
struct kvm_ioeventfd {
	__u64 datamatch;
	__u64 addr;        /* legal pio/mmio address */
	__u32 len;         /* 1, 2, 4, or 8 bytes; or 0 to ignore length */
	__s32 fd;
	__u32 flags;
	__u8  pad[36];
};
```

QEMU 是通过 MemoryRegion 来进行**虚机内存管理**的, 一个 MR 可以对应一段虚机的内存区间, MR 结构中有两个成员与 ioeventfd 相关:

```cpp
// include/exec/memory.h
struct MemoryRegion {
    ......
    unsigned ioeventfd_nb; /* 1 */
    MemoryRegionIoeventfd *ioeventfds; /* 1 */
    ......
```

* 1: 表示 MR 对应的地址区间中有多少个 ioeventfd
* 2: MR 中包含的 ioeventfds 数组, 每注册一个 ioeventfd, 不只 KVM会有记录, QEMU 也会有记录

`MemoryRegionIoeventfd` 具体结构如下:

```cpp
// softmmu/memory.c
struct MemoryRegionIoeventfd {
    AddrRange addr; /* 3 */
    bool match_data; /* 4 */
    uint64_t data;
    EventNotifier *e; /* 5 */
};
```

* 3: 虚机物理地址空间, 用户告知KVM, 当虚机写这个空间时通知QEMU
* 4: 是否匹配写入的值, 如果 match_data 这个为真, 只有当写入 addr 地址的值为 data 时, KVM 才通知 QEMU
* 5: 当满足上面的所有条件后, KVM 通过增加 `EventNotifier->wfd` 对应的内核计数器, 通知 QEMU

## 3.2. 注册流程

QEMU 注册 ioeventfd 的时间点是在 virtio 磁盘驱动初始化成功之后, 流程如下:

```cpp
static void virtio_ioport_write(void *opaque, uint32_t addr, uint32_t val)
{
	switch (addr) {
	case VIRTIO_PCI_STATUS:
		/* 前端驱动想device_status字段写入DRIVER_OK, 表明驱动初始化完成 */
		if (val & VIRTIO_CONFIG_S_DRIVER_OK) {
            virtio_pci_start_ioeventfd(proxy);
        }
  	......
}
```

`virtio_pci_start_ioeventfd` 之后走到`virtio_blk_data_plane_start`, 这个函数会针对 virtio 磁盘的**每个队列**都设置**一个 ioeventfd**, 从这里可以看出, virtio 数据到达的通知针对每个队列都是独立的:

```cpp
virtio_pci_start_ioeventfd
	virtio_bus_start_ioeventfd(&proxy->bus)
		vdc->start_ioeventfd(vdev)
			vdc->start_ioeventfd = virtio_blk_data_plane_start
int virtio_blk_data_plane_start(VirtIODevice *vdev)
{
	......
 	/* Set up virtqueue notify */
    for (i = 0; i < nvqs; i++) { /* 为virtio磁盘的每个队列都设置一个ioeventfd */
        r = virtio_bus_set_host_notifier(VIRTIO_BUS(qbus), i, true);
    }
	......
}
```

`virtio_bus_set_host_notifier` 具体实现如下:

```cpp
int virtio_bus_set_host_notifier(VirtioBusState *bus, int n, bool assign)
{
	......
	EventNotifier *notifier = virtio_queue_get_host_notifier(vq); /* 1 */
	r = event_notifier_init(notifier, 1); /* 2 */
	k->ioeventfd_assign(proxy, notifier, n, true); /* 3 */
	......
}
```

* 1: 每个 virtio 队列关联一个 eventfd, eventfd 的 fd 被存放到 `VirtQueue->host_notifier` 中, 这里把它取出来, 用于初始化并传递给KVM
* 2: 初始化 EventNotifier, 将 eventfd 对应的计数器设置为1
* 3: 注册 ioeventfd, 最终会通过 ioctl 命令字 KVM_IOEVENTFD 注册到KVM

ioeventfd关联一段内存空间, 由于QEMU每有地址空间变化, 都会影响全部的地址空间, QEMU要统一更新地址空间的视图, 包括flatview和ioeventfd的更新. ioeventfd_assign对应virtio_pci_ioeventfd_assign, 流程如下:

```cpp
virtio_pci_ioeventfd_assign
	memory_region_add_eventfd
void memory_region_add_eventfd(MemoryRegion *mr,
                               hwaddr addr,
                               unsigned size,
                               bool match_data,
                               uint64_t data,
                               EventNotifier *e)
{
	......
    MemoryRegionIoeventfd mrfd = { /* 4 */
        .addr.start = int128_make64(addr),
        .addr.size = int128_make64(size),
        .match_data = match_data,
        .data = data,
        .e = e,
    };
    mr->ioeventfds[i] = mrfd;
	memory_region_transaction_commit(); /* 5 */
	......
}
```

* 4: 封装地址信息并将其添加到 MR 的 ioeventfds 数组上
* 5: 检查根 MR 下面的每个子 MR, 搜集所有的 ioeventfd, 统一注册

`memory_region_transaction_commit` 最终走到系统调用, 下发ioctl命令字给 KVM, 注册 ioeventfd

```cpp
memory_region_transaction_commit
	address_space_update_ioeventfds
		address_space_add_del_ioeventfds
			MEMORY_LISTENER_CALL(as, eventfd_add, Reverse, &section, fd->match_data, fd->data, fd->e);
				kvm_io_ioeventfd_add
					kvm_set_ioeventfd_pio
						kvm_vm_ioctl(kvm_state, KVM_IOEVENTFD, &kick)
```

