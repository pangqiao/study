
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. kvm forum 2017](#1-kvm-forum-2017)
- [2. 第一版 RFC](#2-第一版-rfc)
- [3. 设备描述](#3-设备描述)
  - [3.1. 整体介绍](#31-整体介绍)
  - [3.2. 虚拟拓扑的固件描述](#32-虚拟拓扑的固件描述)
  - [3.3. 设备探测和设备操作](#33-设备探测和设备操作)
    - [3.3.1. 概述](#331-概述)
    - [3.3.2. 功能位](#332-功能位)
    - [3.3.3. 设备配置布局](#333-设备配置布局)
    - [3.3.4. 设备初始化](#334-设备初始化)
    - [3.3.5. 设备操作](#335-设备操作)
      - [3.3.5.1. attach device](#3351-attach-device)
      - [3.3.5.2. detach device](#3352-detach-device)
      - [3.3.5.3. map region](#3353-map-region)
      - [3.3.5.4. unmap region](#3354-unmap-region)
  - [3.4. 将来内容](#34-将来内容)
- [4. Linux driver](#4-linux-driver)
- [5. KVM tool](#5-kvm-tool)
- [6. virtio-iommu on non-devicetree platforms](#6-virtio-iommu-on-non-devicetree-platforms)
- [7. VIOT](#7-viot)
- [8. virtio-iommu spec](#8-virtio-iommu-spec)

<!-- /code_chunk_output -->

这里主要讲一下作者最初的思想和相关实现

# 1. kvm forum 2017

virtio-iommu 最早是 2017 年提出来的

[2017] vIOMMU/ARM: Full Emulation and virtio-iommu Approaches by Eric Auger: https://www.youtube.com/watch?v=7aZAsanbKwI , 

https://events.static.linuxfound.org/sites/events/files/slides/viommu_arm_upload_1.pdf

# 2. 第一版 RFC

这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步建议. 它包含设备描述, Linux 驱动程序和 kvmtool 中的玩具实现.

virtio-iommu: a paravirtualized IOMMU

* [RFC 0/3]: a paravirtualized IOMMU, [spinics](https://www.spinics.net/lists/kvm/msg147990.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-1-jean-philippe.brucker__33550.5639938221$1491592770$gmane$org@arm.com/)
  * [RFC 1/3] virtio-iommu: firmware description of the virtual topology: [spinics](https://www.spinics.net/lists/kvm/msg147991.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-2-jean-philippe.brucker__38031.8755437203$1491592803$gmane$org@arm.com/)
  * [RFC 2/3] virtio-iommu: device probing and operations: [spinice](https://www.spinics.net/lists/kvm/msg147992.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-3-jean-philippe.brucker@arm.com/)
  * [RFC 3/3] virtio-iommu: future work: https://www.spinics.net/lists/kvm/msg147993.html

* [RFC PATCH linux] iommu: Add virtio-iommu driver, [lore kernel](https://lore.kernel.org/all/20170407192314.26720-1-jean-philippe.brucker@arm.com/), [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/)

* [RFC PATCH kvmtool 00/15] Add virtio-iommu, [lore kernel](https://lore.kernel.org/all/20170407192455.26814-1-jean-philippe.brucker@arm.com/)

# 3. 设备描述

## 3.1. 整体介绍

> cover letter: a paravirtualized IOMMU

这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步建议. 它包含设备描述, Linux 驱动程序和 kvmtool 中的玩具实现.

使用此原型, 您可以将来自模拟设备(virtio) 或 pass-through 设备(VFIO) 的 DMA 转换为 guest 内存.

最简单地, viommu 处理来自 guest 的 `map/unmap` 请求. "RFC 3/3"中提议的未来扩展将来会将 page tables 绑定到设备上.

半虚拟化的 IOMMU 中, 与完全模拟相比, 有许多优点. 它是便携式的, 可以重复使用不同的架构. 它比完全模拟更容易实现, 状态跟踪更少. 在某些情况下, 它可能会更有效率, 上下文切换到host的更少, 并且内核模拟的可能性也更少.

在 kvmtool 实现中, 考虑了两个主要场景

Scenario 1: a hardware device passed through twice via VFIO

场景一: 硬件设备通过 VFIO 透传两次

```
   MEM____pIOMMU________PCI device________________________       HARDWARE
            |     (2b)                                    \
  ----------|-------------+-------------+------------------\-------------
            |             :     KVM     :                   \
            |             :             :                    \
       pIOMMU drv         :         _______virtio-iommu drv   \    KERNEL
            |             :        |    :          |           \
          VFIO            :        |    :        VFIO           \
            |             :        |    :          |             \
            |             :        |    :          |             /
  ----------|-------------+--------|----+----------|------------/--------
            |                      |    :          |           /
            | (1c)            (1b) |    :     (1a) |          / (2a)
            |                      |    :          |         /
            |                      |    :          |        /   USERSPACE
            |___virtio-iommu dev___|    :        net drv___/
                                        :
  --------------------------------------+--------------------------------
                 HOST                   :             GUEST
```

(1)
* a. 虚拟机用户态有一个 net driver(比如 DPDK). 它通过 mmap 申请一个 buffer, 得到了虚拟地址(VA). 它会发送 **vfio** 请求(`VFIO_IOMMU_MAP_DMA`) 到虚拟机内核态 virtio-iommu driver 将 VA **映射**到 IOVA(可能 VA = IOVA).
* b. 通过 **virtio** (VIRTIO_IOMMU_T_MAP), 虚拟机内核态 viommu driver 将该 mapping 请求转发到host端的 viommu(用户态后端, 比如qemu).
* c. 通过 **vfio**, 后端 viommu 将请求转发到物理 IOMMU 上.

(2)
* a. 虚拟机用户态 driver 指示设备现在可以通过 IOVA 直接访问 buffer 了
* b. 设备发出的 IOVA 被物理 IOMMU 翻译成 物理地址(PA)

Scenario 2: a virtual net device behind a virtual IOMMU.

场景二: vIOMMU后的虚拟网卡设备

```
  MEM__pIOMMU___PCI device                                     HARDWARE
         |         |
  -------|---------|------+-------------+-------------------------------
         |         |      :     KVM     :
         |         |      :             :
    pIOMMU drv     |      :             :
             \     |      :      _____________virtio-net drv      KERNEL
              \_net drv   :     |       :          / (1a)
                   |      :     |       :         /
                  tap     :     |    ________virtio-iommu drv
                   |      :     |   |   : (1b)
  -----------------|------+-----|---|---+-------------------------------
                   |            |   |   :
                   |_virtio-net_|   |   :
                         / (2)      |   :
                        /           |   :                      USERSPACE
              virtio-iommu dev______|   :
                                        :
  --------------------------------------+-------------------------------
                 HOST                   :             GUEST
```

(1)
* a. 虚拟机内核态的 virtio-net driver 发送请求给 viommu 来 map the virtio ring and a buffer
* b. 通过 virtio, mapping 请求被转发到 host 端

(2)
* virtio-net 设备可以通过 IOMMU 来访问虚拟机内存

物理 iommu 和 viommu 是完全分离的. net driver 通过 DMA/IOMMU API 来 mapping 它的 buffer, buffers 在 virtio-net 和 tap 互相拷贝.

几个名词:

* pIOMMU: 物理 IOMMU, 控制来自物理设备的 DMA 访问
* vIOMMU: 虚拟 IOMMU(virtio-iommu), 控制着虚拟设备和物理设备 DMA 访问虚拟机内存
* GVA, GPA, HVA, HPA
* IOVA: I/O 虚拟地址. 在 guest os 中是 GVA.

## 3.2. 虚拟拓扑的固件描述

> virtio-iommu: firmware description of the virtual topology

与其他 virtio 设备不同, virtio-iommu 设备不能独立工作, 它与其他虚拟或分配的设备相连. 因此, 在设备操作之前, 我们需要定义一种方法, 让 guest 发现虚拟 IOMMU 及其它负责的设备.

host 必须通过 device-tree 或 ACPI 表给 guest 描述 IOMMU 和设备的关系.

vIOMMU 用 32 位 ID 来标识每个虚拟设备, 该文中称为"Device ID". "Device ID" 不一定是全系统唯一的, 但不会在单个 vIOMMU 中重复. 直通设备的 "Device ID" 不需要与物理 IOMMU 看到的 ID 一样.

> 这里的 "Device ID" 都是 vIOMMU 定义的

虚拟 IOMMU 仅使用 virtio-mmio 传输, 而不是 virtio-pci, 因为使用 PCI, IOMMU 接口本身就是一个 endpoint, 而现有的固件接口不允许描述 IOMMU <-> PCI endpoint之间的主端口之间的关系.

> The virtual IOMMU uses virtio-mmio transport exclusively, not virtio-pci, because with PCI the IOMMU interface would itself be an endpoint, and existing firmware interfaces don't allow to describe IOMMU<->master relations between PCI endpoints.

下图描述了系统中有两个 vIOMMU 翻译来自device请求的情况. vIOMMU 1 翻译两个 PCI domain, 其中每个 funciton 都有 16 位 requester ID.为了使 vIOMMU 能够区分针对每个域中的设备的 guest 请求, 其 "Device ID" 范围不能重叠. vIOMMU 2 翻译两个 PCI 域和一组平台设备.

为了能让 vIOMMU 区分出不同的 guest 请求, 这些请求的目标是某个 domain 中的设备. 单个 vIOMMU 中的 "Device ID" 不能重复.

```
                       Device ID    Requester ID
                  /       0x0           0x0      \
                 /         |             |        PCI domain 1
                /      0xffff           0xffff   /
        vIOMMU 1
                \     0x10000           0x0      \
                 \         |             |        PCI domain 2
                  \   0x1ffff           0xffff   /

                  /       0x0                    \
                 /         |                      platform devices
                /      0x1fff                    /
        vIOMMU 2
                \      0x2000           0x0      \
                 \         |             |        PCI domain 3
                  \   0x11fff           0xffff   /
```

> 物理平台上:
> 
> 同一个 PCI domain, Requester ID(可以认为是设备 BDF) 是不同的; 不同 PCI domain, Requester ID 可以相同
> 
> vIOMMU侧:
> 
> 同一个 vIOMMU 中的 Device ID 不能相同, 某一个 Device ID 会和物理平台上一个设备对应
> 不同 vIOMMU 中的 Device ID 可以相同

Device-tree 已经提供了一种方法来描述这种拓扑关系. 以 vIOMMU2 举例:

```
	/* The virtual IOMMU is described with a virtio-mmio node */
	viommu2: virtio@10000 {
		compatible = "virtio, mmio";
		reg = <0x10000 0x200>;
		dma-coherent;
		interrupts = <0x0 0x5 0x1>;
		
		#iommu-cells = <1>
	};
	
	/* Some platform device has Device ID 0x5 */
	somedevice@20000 {
		...
		
		iommus = <&viommu2 0x5>;
	};
	
	/*
	 * PCI domain 3 is described by its host controller node, along
	 * with the complete relation to the IOMMU
	 */
	pci {
		...
		/* Linear map between RIDs and Device IDs for the whole bus */
		iommu-map = <0x0 &viommu2 0x10000 0x10000>;
	};
```

更多细节, 见 `DT-IOMMU`

* https://www.kernel.org/doc/Documentation/devicetree/bindings/iommu/iommu.txt
* https://www.kernel.org/doc/Documentation/devicetree/bindings/pci/pci-iommu.txt

对于 ACPI 来说, 我们希望在 IO Remapping Table specification (IORT) 中添加新的 node 类型, 从而通过 ACPI 表来提供类似的机制来描述这个translation.

IORT: IO Remapping Table, DEN0049B, http://infocenter.arm.com/help/topic/com.arm.doc.den0049b/DEN0049B_IO_Remapping_Table.pdf

以下不是规范, 只是节点可能是什么的示例.

```
         Field      | Len.  | Off.  | Description
    ----------------|-------|-------|---------------------------------
     Type           | 1     | 0     | 5: paravirtualized IOMMU
     Length         | 2     | 1     | The length of the node.
     Revision       | 1     | 3     | 0
     Reserved       | 4     | 4     | Must be zero.
     Number of ID   | 4     | 8     |
       mappings     |       |       |
     Reference to   | 4     | 12    | Offset from the start of the
       ID Array     |       |       | IORT node to the start of its
                    |       |       | Array ID mappings.
                    |       |       |
     Model          | 4     | 16    | 0: virtio-iommu
     Device object  | --    | 20    | ASCII Null terminated string
       name         |       |       | with the full path to the entry
                    |       |       | in the namespace for this IOMMU.
     Padding        | --    | --    | To keep 32-bit alignment and
                    |       |       | leave space for future models.
                    |       |       |
     Array of ID    |       |       |
       mappings     | 20xN  | --    | ID Array.
```

操作系统解析 IORT 表, 以构建 IOMMU 与设备之间的 ID 关系表. ID 阵列用于查找 IOMMU ID 与 PCI 或平台设备之间的关系. 稍后, virtio-iommu 驱动程序通过"Device object name"字段找到相关的 LNRO0005 描述符, 并探测 virtio 设备以了解更多有关其功能的信息. 由于"IOMMU"的所有属性将在 virtio probe 期间获得, IORT 节点要尽量保持简单.

## 3.3. 设备探测和设备操作

> virtio-iommu: device probing and operations

在探测到了 virtio-iommu 设备并且 driver 知道要 IOMMU 管理的设备后, driver 可以开始向 virtio-iommu 设备发送请求.

此处描述的操作是简约的, 因此 vIOMMU 设备可以尽可能简单地实现, 并且可以通过功能位进行扩展.

1. 概述Overview
2. 功能位Feature bits
3. 设备配置布局Device configuration layout
4. 设备初始化Device initialization
5. 设备操作Device operations
   5.1. Attach device
   5.2. Detach device
   5.3. Map region
   5.4. Unmap region

### 3.3.1. 概述

Requests 是 guest 往 request virtqueue 中添加的小的缓冲 buffer. guest可以在 queue 中添加一批Requests, 并向设备发送通知(kick), 以便设备处理它们.

一个操作流程的例子:

* `attach(address space, device), kick`: 创建一个 address space 并且将 attach 一个 device 给它. kick
* `map(address space, virt, phys, size, flags)`: 给 GVA 和 GPA 创建一个 mapping 关系
* map, map, map, kick
* ...在这里, guest 中设备可以执行 DMA 操作访问新映射的内存
* `unmap(address space, virt, size)`: unmap, 然后再kick
* `detach(address space, device)`, kick

以下描述尝试使用与其他 virtio 设备相同的格式. 我们不会详细了解 virtio 传输(transport), 请参阅 `[VIRTIO-v1.0]` 了解更多信息.

> [VIRTIO-v1.0] Virtual I/O Device (VIRTIO) Version 1.0.  03 December 2013. Committee Specification Draft 01 / Public Review Draft 01. http://docs.oasis-open.org/virtio/virtio/v1.0/csprd01/virtio-v1.0-csprd01.html

一个快速提醒(reminder), Virtio(1.0)运输可以用下面流程来描述:

```
                             HOST  :  GUEST
                     (3)           :
                    .----- [available ring] <-----. (2)
                   /               :               \
                  v   (4)          :          (1)   \
            [device] <--- [descriptor table] <---- [driver]
                  \                :                 ^
                   \               :                /
                (5) '-------> [used ring] ---------'
                                   :            (6)
                                   :
```

(1) driver 有一堆带有效载荷(payload)的 buffers 要通过 virtio 来发送. 它会写 N 个 描述符(descriptors)来描述 N 个 sub-buffers, 并且将它们链接起来(形成描述符表), 第一个描述符(descriptor)就是这个链(chain)的头部(head).

(2) driver 将 head index 入队 "available ring".

(3) driver 通知设备. 由于 virtio-iommu 使用 MMIO, 通知是通过写消息给 doorbell 地址完成的. KVM 将其捕获并这个通知转发给 virtio 设备. 设备从 "available ring" 中出队 head index(头部索引).

(4) 设备读取链(chain)上的所有描述符, 处理 payload

(5) 设备将 head index 写入"used ring", 并且通过注入中断方式通知 guest

(6) driver 从 "used ring" 中 pop 这个 head, 然后选择性看是否读取 device 更新的 buffers.

### 3.3.2. 功能位

VIRTIO_IOMMU_F_INPUT_RANGE (0)

可用的虚拟地址范围在 input_range 中描述

VIRTIO_IOMMU_F_IOASID_BITS (1)

支持的 address space 数目在 ioasid_bits 中描述

VIRTIO_IOMMU_F_MAP_UNMAP (2)

map 和 unmap 请求是可用的. 这是为了让设备或驱动程序仅在我们引入该功能后实现页面表共享. 设备只能选择 F_MAP_UNMAP 或 F_PT_SHARING 之一. 目前, 必须始终设置此位.

VIRTIO_IOMMU_F_BYPASS (3)

当没有被 attach 到一个 address space时, IOMMU 管理的 device 能够访问虚拟机物理地址空间(GPA).

### 3.3.3. 设备配置布局

```cpp
struct virtio_iommu_config {
     u64 page_size_mask;
     struct virtio_iommu_range {
          u64 start;
          u64 end;
     } input_range;
     u8 ioasid_bits;
};
```

### 3.3.4. 设备初始化

1. page_size_mask 包含可以映射的所有页面大小的 bitmap.最低有效位集定义了 IOMMU 映射的页面粒度. mask 中的其他位是描述 IOMMU 可以合并为单个映射(页面块)的页面大小的提示.

IOMMU 支持的最小页面粒度没有下限. 如果设备通告它(`page_size_mask[0]=1`), 驱动程序一次映射一个字节是合法的.

page_size_mask 必须至少有一个 bit 设置

2. 如果有 VIRTIO_IOMMU_F_IOASID_BITS 功能, 则 ioasid_bits 包含 I/O Address space ID(map/unmap请求中使用的标识符)中支持的数目. 值等于 0 也是有效的, 仅仅表示支持单个地址空间(`2^0`? ).

如果没有 VIRTIO_IOMMU_F_IOASID_BITS 功能, address space ID 最多有 32 位(也就是说任何 address space ID 都是有效的).

3. 如果协商了 VIRTIO_IOMMU_F_INPUT_RANGE 功能, 则 input_range 包含 IOMMU 能够 translate 的虚拟地址范围. 任何访问此范围之外的虚拟地址的映射请求都将失败.

如果不协商该功能, 虚拟映射将跨越整个 64 位地址空间(start = 0, end = 0xffffffffffffffff)

4. 如果协商了 VIRTIO_IOMMU_F_BYPASS 功能, 所有 unattached 设备发出的内存访问也会被 IOMMU 允许且被 IOMMU 用特定方法进行 translate. 如果没有这个功能, 任何 unattached 设备的内存访问都会失败. 

> 允许设备绕过 iommu 的管理的意思, 所以这个功能支持的话, 没有被 attach 的设备也可以访问 guest physical address.

而如果通过 bypass 模式 attach 一个 device 到一个新的 address space, 那么这个设备的所有内存访问都会失败, 因为这时候 address space 还没有包含任何 mapping.

device 被 reset, 则不会被 attach 到任何 address space.

### 3.3.5. 设备操作

驱动程序在 request virtqueue (0) 上发送 requests, 通知设备并等待设备在 used ring 中返回具有状态的 request.

> 遵循 virtio transport 流程

所有请求被分成两部分: 一个 device-readable, 一个device-writeable.

因此, **每个请求**必须至少用**两个描述符**(descriptor)来描述, 如下图所示.

```
	31                       7      0
	+--------------------------------+ <------- RO descriptor
	|      0 (reserved)     |  type  |
	+--------------------------------+
	|                                |
	|            payload             |
	|                                | <------- WO descriptor
	+--------------------------------+
	|      0 (reserved)     | status |
	+--------------------------------+

	struct virtio_iommu_req_head {
		u8	type;
		u8	reserved[3];
	};

	struct virtio_iommu_req_tail {
		u8	status;
		u8	reserved[3];
	};
```

(关于格式选择的注意事项: 此格式强制将有效载荷(payload)拆分为两个 - 一个 read-only 的缓冲区, 一个 write-only. 这对于我们的目的来说是必要且充分的, 并且不会关闭未来扩展更复杂请求的大门, 例如夹在两个 RO 之间的 WO 字段. 由于 Virtio 1.0 ring 要求, 需要用两个描述链来描述一个这样的请求, 这些描述符可能更复杂, 无法高效实现, 但仍有可能. 设备和驱动程序都必须假定请求是分段的. )

type 字段可能是:

```
VIRTIO_IOMMU_T_ATTACH			1
VIRTIO_IOMMU_T_DETACH			2
VIRTIO_IOMMU_T_MAP			3
VIRTIO_IOMMU_T_UNMAP			4
```

下面定义了一些通用 status code. 对于无效请求, driver 不能假定返回一个特定的code. 除了总是意味着 "success" 的 0 之外, 其他返回值有助于故障排除.

```
VIRTIO_IOMMU_S_OK			0
 All good! Carry on.

VIRTIO_IOMMU_S_IOERR			1
 Virtio communication error 

VIRTIO_IOMMU_S_UNSUPP			2
 Unsupported request

VIRTIO_IOMMU_S_DEVERR			3
 Internal device error

VIRTIO_IOMMU_S_INVAL			4
 Invalid parameters

VIRTIO_IOMMU_S_RANGE			5
 Out-of-range parameters

VIRTIO_IOMMU_S_NOENT			6
 Entry not found

VIRTIO_IOMMU_S_FAULT			7
 Bad address
```

#### 3.3.5.1. attach device

```cpp
struct virtio_iommu_req_attach {
	le32	address_space;
	le32	device;
	le32	flags/reserved;
};
```

将设备 attach 到 address space. 对 guest 来讲, 每个 "address_space" 都是一个唯一的标识符('address_space' is an identifier unique to the guest). 如果 IOMMU 设备中不存在这个 address space, 则创建一个.

> 也就是说, 一个 guest 中的 address_space 是不同的, 类似于 domain 的概念.

对于 IOMMU 来说, 每个 "device" 都是一个唯一的标识符('device' is an identifier unique to the IOMMU). host 在 guest boot 期间向 guest 传达(communicate)了唯一的 device ID. 用于传达此 ID 的方法不属于此规范的范围, 但必须适用以下规则:

* 从 IOMMU 的角度来看, device ID 是唯一的. DMA transaction (DMA 事务) 不是由同一 IOMMU translate 的多个设备可能具有相同的设备 ID(因为 iommu 不是同一个). DMA transaction 可能由同一 IOMMU 翻译的设备必须具有不同的 device ID.

* 有时 host 无法完全隔离两个设备. 例如, 在传统的 PCI 总线上, 设备可以窥探(snoop)来自其邻居(neighbour)的 DMA transaction(DMA 事务). 在这种情况下, 主机必须向 guest 传达它不能将这些设备彼此隔离. 用于传达这个的方法不在本规范的范围. IOMMU driver 必须确保无法被 host 隔离的设备具有相同的 address space(也就是多个device不能隔离则必须被同一个 iommu 管理).

多个设备可以添加到相同的 address space.一个设备不能被 attach 到多个 address space(即使用 map/unmap 接口). 对于 SVM, 请参阅 page table 和 context table 共享建议.

如果设备已经 attach 到另一个 address space "old", 则它将被从 "old" address space 分离并 attach 到新地址空间. 在此请求完成后, 设备无法访问旧地址空间的映射.

设备要么返回 VIRTIO_IOMMU_S_OK, 要么返回错误状态. 我们建议以下错误状态, 这将有助于调试驱动程序.

NOENT: 未找到设备.

RANGE: address space 超出了 ioasid_bits 允许的范围.

#### 3.3.5.2. detach device

```cpp
struct virtio_iommu_req_detach {
	le32	device;
	le32	flags/reserved;
};
```

从 address space 中 detach device. 当此请求完成时, 设备就不能再访问该 address space 中的任何映射. 如果 device 没有被 attach 到任何地址空间, 则请求将成功返回.

在所有设备从一个地址空间 detach 后, 驱动程序可以将其 address space ID 重用于另一个地址空间.

NOENT: 未找到设备.

INVAL: 设备未连接到任何地址空间.

#### 3.3.5.3. map region

```cpp
struct virtio_iommu_req_map {
	le32	address_space;
	le64	phys_addr;
	le64	virt_addr;
	le64	size;
	le32	flags;
};

VIRTIO_IOMMU_MAP_F_READ		0x1
VIRTIO_IOMMU_MAP_F_WRITE	0x2
VIRTIO_IOMMU_MAP_F_EXEC		0x4
```

将一系列连续的虚拟地址映射到一系列连续的物理地址. 大小必须始终是初始化期间协商的页面粒度的倍数. phys_addr 和 virt_addr 必须在页面粒度上对齐. address space 必须是用 VIRTIO_IOMMU_T_ATTACH 创建的.

(virt_addr, size) 所定义的范围必须在 input_range 规定的范围内. (phys_addr, size) 定义的范围必须在 guest 物理地址空间内. 这包括了上下限制, 以及任何 carving 的 guest physical address 供 host 使用(例如 MSI doorbell). 主机使用本规范范围之外的固件机制设置了 guest 物理边界.

（请注意，此格式会阻止在单个请求（0x0 - 0xfff....ff） -> （0x0 - 0xfff...ff），因为它将得到一个 零大小。希望允许 VIRTIO_IOMMU_F_BYPASS 消除发出此类请求的需要。也不太可能符合前一段的物理范围限制）

（另一个注意事项是 flags: 物理 IOMMU 不可能支持所有可能的 flag 组合。例如，（W & !R） 或 （E & W） 可能无效。我还没有花时间设计一个聪明的方法来宣传支持和隐含（例如 "W 暗示 R"）标志或组合，但我至少可以尝试研究共同的模型。请记住，我们可能很快就会想要添加更多的标志，如 privileged，device，transient，shared等，无论这些将意味着什么）

只有 VIRTIO_IOMMU_F_MAP_UNMAP 协商成功这个请求才是可用的

INVAL: 无效 flags.

RANGE: virt_addr, phys_addr 或 range 不在协商期间规定的范围内. 比如, 没有基于页粒度对齐.

NOENT: address space 不存在

#### 3.3.5.4. unmap region

```cpp
struct virtio_iommu_req_unmap {
	le32	address_space;
	le64	virt_addr;
	le64	size;
	le32	reserved;
};
```

unmap 一段用 VIRTIO_IOMMU_T_MAP 映射的地址范围。这个 range 由virt_addr 和 size 定义，必须完全覆盖通过 MAP 请求创建的一个或多个连续映射。这个 range 覆盖的所有映射都已删除。驱动程序不应发送覆盖未映射区域的请求。

通过单个 MAP 请求, 我们定义了一个 mapping 作为一片虚拟区域。virt_addr 应与现有映射的开始地址完全匹配。range 的 end（virt_addr + size - 1）应与现有映射的 end 完全匹配。设备必须拒绝仅作用于部分映射区域的所有请求。如果请求的范围溢出映射区域之外，则设备的行为未定义。

规则定义如下:

```
	map(0, 10)
	unmap(0, 10) -> allowed

	map(0, 5)
	map(5, 5)
	unmap(0, 10) -> allowed

	map(0, 10)
	unmap(0, 5) -> forbidden

	map(0, 10)
	unmap(0, 15) -> undefined

	map(0, 5)
	map(10, 5)
	unmap(0, 15) -> undefined
```

（注意：这里 unmap 的语义与 VFIO 的 type1 v2 IOMMU API 兼容。这样，充当 guest 和 VFIO 之间调解的设备就不必保留内部mapping tree。它们比 VFIO 更严格一些，因为它们不允许 unmap 到映射区域之外。溢出(spilling)目前是"undefined"，因为它在大多数情况下应该有效，但我不知道是否值得在不只是将请求传输到 VFIO 的设备中增加复杂性。拆分映射是不允许的，但请参阅 3/3 中的轻松建议，以获得更宽松的语义）

此请求仅在 VIRTIO_IOMMU_F_MAP_UNMAP 已协商后提供。

NOENT: address space 不存在

FAULT: mapping 不存在

RANGE: 请求将拆分一个mapping

## 3.4. 将来内容

> virtio-iommu: future work



# 4. Linux driver

* [RFC PATCH linux] iommu: Add virtio-iommu driver, [lore kernel](https://lore.kernel.org/all/20170407192314.26720-1-jean-philippe.brucker@arm.com/), [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/)

virtio IOMMU 是一个半虚设备, 可以通过 virtio-mmio transport 发送 IOMMU 请求, 比如 map/unmap. 这个 driver 会实现上面讲到的 virtio-iommu 最初方案. 它会处理 attach, detach, map 和 unmap 请求.

大部分代码是在创建请求并通过 virtio 发生它们. 实现 IOMMU API 是比较简单的, 因为 virtio-iommu 的 MAP/UNMAP 接口几乎相同. 我放到了一个自定义的 map_sg() 函数中. 核心函数将发送一系列的 map 请求, 并且等待每个请求的返回. 这个优化避免在每个 map 后 yield to host，而是在 virtio ring 中准备一批请求，并 kick host 一次。

It must be applied on top of the probe deferral work for IOMMU, currently under discussion. 这允许早期驱动程序检测和设备探测分割开: 早期解析 device tree 或 ACPI 从而发现 IOMMU 负责的设备, 但是 IOMMU 本身需要等核心 virtio 模块加载后才能被探测.

目前, 启用 DEBUG 使得非常冗长，但在下一个版本中应该会更 calmer。

```diff
---
 drivers/iommu/Kconfig             |  11 +
 drivers/iommu/Makefile            |   1 +
 drivers/iommu/virtio-iommu.c      | 980 ++++++++++++++++++++++++++++++++++++++
 include/uapi/linux/Kbuild         |   1 +
 include/uapi/linux/virtio_ids.h   |   1 +
 include/uapi/linux/virtio_iommu.h | 142 ++++++
 6 files changed, 1136 insertions(+)
 create mode 100644 drivers/iommu/virtio-iommu.c
 create mode 100644 include/uapi/linux/virtio_iommu.h
```

* `drivers/iommu/Kconfig`, 增加了一个内核编译选项, guest kernel 启用
* `drivers/iommu/Makefile`, 使内核编译时增加一个 `.o` 文件
* `drivers/iommu/virtio-iommu.c`, 核心实现文件
* `include/uapi/linux/Kbuild`, linux-header 增加一个头文件
* `include/uapi/linux/virtio_ids.h`, 增加一个 virtio 类型
* `include/uapi/linux/virtio_iommu.h`, 头文件 


Discussion 1: Same physical address is mapped with two different virtual address

取决于是哪个驱动调用了 viommu. 任何设备驱动可以调用 DMA API, 进而调用了 iommu_map. 同一个 address space 中, 多个 IOVA 指向同一个 PA 是允许的.

https://lore.kernel.org/all/c19161b2-b32f-4039-67a2-633ee57bcd07@arm.com/

```
 virtnet_open
 try_fill_recv
 add_recvbuf_mergeable
 virtqueue_add_inbuf_ctx
 vring_map_one_sg
 dma_map_page
 __iommu_dma_map
```




# 5. KVM tool

[RFC PATCH kvmtool 00/15] Add virtio-iommu, [lore kernel](https://lore.kernel.org/all/20170407192455.26814-1-jean-philippe.brucker@arm.com/)

实现 virtio-iommu 设备并转换来自 vfio 和 virtio 设备的 DMA 流量. Virtio 需要一些 rework 来支持以页面粒度对 vring 和缓冲区进行分散-聚集访问。patch 3 实现了实际的 virtio-iommu 设备。

1. virtio: synchronize virtio-iommu headers with Linux
2. FDT: (re)introduce a dynamic phandle allocator
3. virtio: add virtio-iommu
4. Add a simple IOMMU
5. iommu: describe IOMMU topology in device-trees
6. irq: register MSI doorbell addresses
7. virtio: factor virtqueue initialization
8. virtio: add vIOMMU instance for virtio devices
9. virtio: access vring and buffers through IOMMU mappings
10. virtio-pci: translate MSIs with the virtual IOMMU
11. virtio: set VIRTIO_F_IOMMU_PLATFORM when necessary
12. vfio: add support for virtual IOMMU
13. virtio-iommu: debug via IPC
14. virtio-iommu: implement basic debug commands
15. virtio: use virtio-iommu when available


patch 3, virtio: add virtio-iommu

实现一个简单的 viommu 来处理虚拟机中的设备 address space.

四种操作:

* attach/detach: 虚拟机创建一个 address space, 使用一个唯一的 IOASID 来标识, 并且 attach 这个设备.
* map/unmap: 虚拟机在一个 address space 中创建一个 GVA-> GPA 映射. attach 到这个 address space 的设备能够访问这个 GVA.

每个子系统可以通过调用 register/unregister 来注册自己的 IOMMU. 为每个 IOMMU 分配了一个独有的 device-tree phandle. IOMMU 通过 virtqueue 接收 driver 的命令，并为**每个设备**提供一系列回调函数，允许为 pass-through 设备和 emulated 设备实行不同的 map/unmap 操作。

请注意，一个 guest 对应一个 vIOMMU 就足够了，这个的多个 viommu 模型只是在这里进行实验，从而允许不同的子系统提供不同的 vIOMMU 功能。

```cpp
static int viommu_handle_attach(struct viommu_dev *viommu,
				struct virtio_iommu_req_attach *attach)
{
    // 从 request 中获取 deviceid 和 ioasid
    u32 device_id	= le32_to_cpu(attach->device);
    u32 ioasid	= le32_to_cpu(attach->address_space);
    struct device_header *device = iommu_get_device(device_id);

    // 如果 ioas 不存在则创建一个
    ioas = viommu_find_ioas(viommu, ioasid);
    if (!ioas)  ioas = viommu_alloc_ioas(viommu, device, ioasid);

    // 如果设备之前已经关联了 ioas, 则从原有 detach
    if (vdev->ioas) ret = viommu_detach_device(viommu, vdev);

    // 每种设备自定义的 attach 方法
    ret = device->iommu_ops->attach(ioas->priv, device, 0);

    // 将设备添加到 ioas 的链表中
    viommu_ioas_add_device(ioas, vdev);

    // ioas 没有设备则释放掉这个 ioas
    if (ret && ioas->nr_devices == 0) viommu_free_ioas(viommu, ioas);
}
```

```cpp
static int viommu_handle_map(struct viommu_dev *viommu,
			     struct virtio_iommu_req_map *map)
{
    struct viommu_ioas *ioas;

    ioas = viommu_find_ioas(viommu, ioasid);

    // ioas->ops 等于第一次 attach 的 device 的 iommu_ops
    return ioas->ops->map(ioas->priv, virt_addr, phys_addr, size, prot);
}

static struct viommu_ioas *viommu_alloc_ioas(struct viommu_dev *viommu,
					     struct device_header *device,
					     u32 ioasid)
{
	struct rb_node **node, *parent = NULL;
	struct viommu_ioas *new_ioas, *ioas;
	// 设备的 iommu_ops
	struct iommu_ops *ops = device->iommu_ops;

	if (!ops || !ops->get_properties || !ops->alloc_address_space ||
	    !ops->free_address_space || !ops->attach || !ops->detach ||
	    !ops->map || !ops->unmap) {
		/* Catch programming mistakes early */
		pr_err("Invalid IOMMU ops");
		return NULL;
	}

	new_ioas = calloc(1, sizeof(*new_ioas));
	if (!new_ioas)
		return NULL;

	INIT_LIST_HEAD(&new_ioas->devices);
	mutex_init(&new_ioas->devices_mutex);
	new_ioas->id		= ioasid;
	new_ioas->ops		= ops;  // ioas 的 ops 初始化
	new_ioas->priv		= ops->alloc_address_space(device);

	rb_insert_color(&new_ioas->node, &viommu->address_spaces);

	return new_ioas;
}
```

patch 12: vfio: add support for virtual IOMMU

目前，所有 pass-through 设备必须访问相同的 guest 物理地址空间。注册 IOMMU，为设备提供单独的地址空间。方法是通过给每个 group 分配一个 container，并按需添加映射。

由于 guest 不能访问设备，除非这个设备被 attach 到 container，并且我们不能在运行时不重置设备就更改 container，因此此实现是有限的。要实现 bypass 模式，我们需要首先 map 整个 guest 物理内存，并在 attach 到新 address space 时取消所有内容的映射。设备也不可能连接到相同的地址空间，它们都有不同的页面表。



# 6. virtio-iommu on non-devicetree platforms

IOMMU 用来管理来自设备的内存访问. 所以 guest 需要在 endpoint 发起 DMA 之前初始化 IOMMU. 

这是一个已解决的问题: firmware 或 hypervisor 通过 DT 或 ACPI 表描述设备依赖关系, 并且 endpoint 的探测(probe)被推迟到 IOMMU 被 probe 后. 但是:

1. ACPI 每个 vendor 有一张表(DMAR 代表 Intel, IVRS 代表 AMD, IORT 代表 Arm). 在我看来, IORT 更容易扩展, 因为我们只需要引入一个新的 node type. Linux IORT 驱动程序中没有对 Arm 架构的依赖, 因此它可以很好地与 CONFIG_X86 配合使用.

然而, 有一些其他担心. 其他操作系统供应商觉得有义务实施这个新的节点, 所以Arm建议引入另一个ACPI表, 可以包装任何 DMAR, IVRS 和 IORT 扩展它与新的虚拟 node.此 VIOT 表规格的草稿可在 http://jpbrucker.net/virtio-iommu/viot/viot-v5.pdf

而且这可能会增加碎片化, 因为 guest 需要实施或修改他们对所有 DMAR , IVRS 和 IORT 的支持. 如果我们最终做 VIOT, 我建议把它限制在 IORT .

2. virtio 依赖 ACPI 或 DT. 目前 hypervisor (Firecracker, QEMU microsvm, kvmtool) 并没有实现.

建议将拓扑描述嵌入设备中.


# 7. VIOT

Virtual I/O Translation table (VIOT) 描述了半虚设备的 I/O 拓扑信息.

目前描述了 virtio-iommu 和它管理的设备的拓扑信息.

经过讨论:

* 对于 non-devicetree 平台, 应该使用 ACPI Table.
* 对于既没有 devicetree, 又没有 ACPI 的 platform, 可以在设备中内置一个使用大致相同格式的结构

# 8. virtio-iommu spec

virtio-iommu 设备管理多个 endpoints 的 DMA 操作.

它既可以作为物理 IOMMU 的代理来管理分配给虚拟机的物理设备(透传), 也可以作为一个虚拟 IOMMU 来管理模拟设备和半虚拟化设备.

virtio-iommu 驱动程序首先使用特定于平台的机制发现由 virtio-iommu 设备管理的 endpoints.然后 virtio-iommu 驱动发送请求为这些 endpoints 创建虚拟地址空间和虚拟地址到物理地址映射关系.

在最简单的形式中, virtio-iommu 支持四种请求类型:

1. 创建一个 domain 并且 attach 一个 endpoint 给它.

`attach(endpoint=0x8, domain=1)`

2. 创建 guest-visual address 到 guest-physical address 的 mapping 关系

`map(domain=1, virt_start=0x1000, virt_end=0x1fff, phys=0xa000, flags=READ)`

> Endpoint 0x8, 一个硬件 PCI endpoint, 假设 BDF 是 `00: 01.0`, 能够读取的一个虚拟机 GVA 范围是 `0x1000 ~ 0x1fff`, 而在这个范围的访问会被 vIOMMU 翻译到 HPA 范围是 `0xa000 ~`.

3. 移除 mapping 关系

`unmap(domain=1, virt_start=0x1000, virt_end=0x1fff)`

> Endpoint 0x8 对地址 `0x1000 ~ 0x1fff` 的访问会被拒绝.

4. detach 一个 endpoint 并且删除 domain

`detach(endpoint=0x8, domain=1)`

> 这里的 domain 就是一个 viommu, 类似于 vfio_domain 概念, 就是最初的 RFC 中的 vIOMMU 1/2