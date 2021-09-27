
# kvm forum 2017




1. 最初

virtio-iommu: a paravirtualized IOMMU

# 第一版 RFC

* [RFC 0/3]: a paravirtualized IOMMU, [spinics](https://www.spinics.net/lists/kvm/msg147990.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-1-jean-philippe.brucker__33550.5639938221$1491592770$gmane$org@arm.com/)
  * [RFC 1/3] virtio-iommu: firmware description of the virtual topology: [spinics](https://www.spinics.net/lists/kvm/msg147991.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-2-jean-philippe.brucker__38031.8755437203$1491592803$gmane$org@arm.com/)
  * [RFC 2/3] virtio-iommu: device probing and operations: [spinice](https://www.spinics.net/lists/kvm/msg147992.html), lore kernel
  * [RFC 3/3] virtio-iommu: future work: https://www.spinics.net/lists/kvm/msg147993.html

## 整体介绍

> cover letter: a paravirtualized IOMMU

这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步建议. 它包含设备描述, Linux 驱动程序和 kvmtool 中的玩具实现. 使用此原型, 您可以将来自模拟设备(virtio) 或 pass-through 设备(VFIO) 的 DMA 转换为 guest 内存.

最简单地, viommu 处理来自 guest 的 `map/unmap` 请求. "RFC 3/3"中提议的未来扩展将来应允许 page tables 绑定到设备上.

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
* a. 虚拟机用户态有一个 net driver(比如 DPDK). 它通过 mmap 申请一个 buffer, 得到了虚拟地址(VA); 然后发送 **vfio** 请求(`VFIO_IOMMU_MAP_DMA`) 到虚拟机内核态 virtio-iommu driver 将 VA **映射**到 IOVA(可能 VA = IOVA).
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

## 虚拟拓扑的固件描述

> virtio-iommu: firmware description of the virtual topology

与其他 virtio 设备不同, virtio-iommu 不能独立工作, 它与其他虚拟或分配的设备相连. 因此, 在设备操作之前, 我们需要定义一种方法, 让 guest 发现虚拟 IOMMU 及其它负责的设备.

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

> 物理平台上
> 同一个 PCI domain, Requester ID(可以认为是设备 BDF) 是不同的; 不同 PCI domain, Requester ID 可以相同
> vIOMMU侧
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

## 设备探测和设备操作

> virtio-iommu: device probing and operations

在探测到了 virtio-iommu 设备并且 driver 知道要 IOMMU 管理的设备后, driver 可以开始向 virtio-iommu 设备发送请求. 此处描述的操作是简约的, 因此 vIOMMU 设备可以尽可能简单地实现, 并且可以通过功能位进行扩展.

1. 概述Overview
2. 功能位Feature bits
3. 设备配置布局Device configuration layout
4. 设备初始化Device initialization
5. 设备操作Device operations
   5.1. Attach device
   5.2. Detach device
   5.3. Map region
   5.4. Unmap region

### 概述

Requests 是 guest 往 request virtqueue 中添加的小的缓冲 buffer. guest可以在 queue 中添加一批Requests, 并向设备发送通知(kick), 以便设备处理它们.

一个操作流程的例子:

* `attach(address space, device), kick`: 创建一个 address space 并且将 attach 一个 device 给它.
* `map(address space, virt, phys, size, flags)`: 给 GVA 和 GPA 创建一个 mapping 关系(在 address space 中? )
* map, map, map, kick
* ...在这里, guest 中设备可以执行 DMA 到新映射的内存
* `unmap(address space, virt, size)`: unmap, 然后再kick
* `detach(address space, device)`, kick

以下描述尝试使用与其他 virtio 设备相同的格式. 我们不会详细了解 virtio 传输(transport), 请参阅 `[VIRTIO-v1.0]` 了解更多信息.

> [VIRTIO-v1.0] Virtual I/O Device (VIRTIO) Version 1.0.  03 December 2013. Committee Specification Draft 01 / Public Review Draft 01. http://docs.oasis-open.org/virtio/virtio/v1.0/csprd01/virtio-v1.0-csprd01.html

作为快速提醒(reminder), Virtio(1.0)运输可以用下面流程来描述:

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

(1) driver 有一堆带有效载荷(payload)的 buffers 要通过 virtio 来发送。它会写 N 个 描述符(descriptors)来描述 N 个 sub-buffers, 并且将它们链接起来(形成描述符表), 第一个描述符(descriptor)就是这个链(chain)的头部(head).

(2) driver 将 head index 入队"available ring"。

(3) driver 通知设备. 由于 virtio-iommu 使用 MMIO，通知是通过写消息给 doorbell 地址完成的。KVM 将其捕获并这个通知转发给 virtio 设备。设备从"available ring"中出队head index(头部索引)。

(4) 设备读取链(chain)上的所有描述符, 处理 payload

(5) 设备将 head index 写入"used ring", 并且通过注入中断方式通知 guest

(6) driver 从 "used ring" 中 pop 这个 head, 然后选择性看是否读取 device 更新的 buffers。




## 将来内容

> virtio-iommu: future work















# virtio-iommu on non-devicetree platforms

IOMMU 用来管理来自设备的内存访问. 所以 guest 需要在 endpoint 发起 DMA 之前初始化 IOMMU. 

这是一个已解决的问题: firmware 或 hypervisor 通过 DT 或 ACPI 表描述设备依赖关系, 并且 endpoint 的探测(probe)被推迟到 IOMMU 被 probe 后. 但是:

1. ACPI 每个 vendor 有一张表(DMAR 代表 Intel, IVRS 代表 AMD, IORT 代表 Arm). 在我看来, IORT 更容易扩展, 因为我们只需要引入一个新的 node type. Linux IORT 驱动程序中没有对 Arm 架构的依赖, 因此它可以很好地与 CONFIG_X86 配合使用.

然而, 有一些其他担心. 其他操作系统供应商觉得有义务实施这个新的节点, 所以Arm建议引入另一个ACPI表, 可以包装任何 DMAR, IVRS 和 IORT 扩展它与新的虚拟 node.此 VIOT 表规格的草稿可在 http://jpbrucker.net/virtio-iommu/viot/viot-v5.pdf

而且这可能会增加碎片化, 因为 guest 需要实施或修改他们对所有 DMAR , IVRS 和 IORT 的支持. 如果我们最终做 VIOT, 我建议把它限制在 IORT .

2. virtio 依赖 ACPI 或 DT. 目前 hypervisor (Firecracker, QEMU microsvm, kvmtool) 并没有实现.

建议将拓扑描述嵌入设备中.


# VIOT

Virtual I/O Translation table (VIOT) 描述了半虚设备的 I/O 拓扑信息.

目前描述了 virtio-iommu 和它管理的设备的拓扑信息.

经过讨论:

* 对于 non-devicetree 平台, 应该使用 ACPI Table.
* 对于既没有 devicetree, 又没有 ACPI 的 platform, 可以在设备中内置一个使用大致相同格式的结构

# virtio-iommu spec

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