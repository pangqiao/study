
# kvm forum 2017




1. 最初

virtio-iommu: a paravirtualized IOMMU

第一版 RFC: [spinics](https://www.spinics.net/lists/kvm/msg147990.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-1-jean-philippe.brucker__33550.5639938221$1491592770$gmane$org@arm.com/) 

这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步建议。 它包含设备描述、Linux 驱动程序和 kvmtool 中的玩具实现。 使用此原型，您可以将来自模拟设备(virtio) 或 pass-through 设备(VFIO) 的 DMA 转换为 guest 内存。

最简单地, viommu 处理来自 guest 的 `map/unmap` 请求。"RFC 3/3"中提议的未来扩展将来应允许 page tables 绑定到设备上。

半虚拟化的 IOMMU 中，与完全模拟相比，有许多优点。它是便携式的，可以重复使用不同的架构。它比完全模拟更容易实现，状态跟踪更少。在某些情况下，它可能会更有效率，上下文切换到host的更少，并且内核模拟的可能性也更少。

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

场景二: 

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




# virtio-iommu on non-devicetree platforms

IOMMU 用来管理来自设备的内存访问. 所以 guest 需要在 endpoint 发起 DMA 之前初始化 IOMMU. 

这是一个已解决的问题：firmware 或 hypervisor 通过 DT 或 ACPI 表描述设备依赖关系，并且 endpoint 的探测(probe)被推迟到 IOMMU 被 probe 后。但是：

1. ACPI 每个 vendor 有一张表（DMAR 代表 Intel，IVRS 代表 AMD，IORT 代表 Arm）。在我看来，IORT 更容易扩展，因为我们只需要引入一个新的 node type。 Linux IORT 驱动程序中没有对 Arm 架构的依赖，因此它可以很好地与 CONFIG_X86 配合使用。

然而，有一些其他担心. 其他操作系统供应商觉得有义务实施这个新的节点，所以Arm建议引入另一个ACPI表，可以包装任何 DMAR，IVRS 和 IORT 扩展它与新的虚拟 node。此 VIOT 表规格的草稿可在 http://jpbrucker.net/virtio-iommu/viot/viot-v5.pdf

而且这可能会增加碎片化, 因为 guest 需要实施或修改他们对所有 DMAR 、 IVRS 和 IORT 的支持。如果我们最终做 VIOT， 我建议把它限制在 IORT 。

2. virtio 依赖 ACPI 或 DT. 目前 hypervisor (Firecracker, QEMU microsvm, kvmtool) 并没有实现.

建议将拓扑描述嵌入设备中。


# VIOT

Virtual I/O Translation table (VIOT) 描述了半虚设备的 I/O 拓扑信息.

目前描述了 virtio-iommu 和它管理的设备的拓扑信息.

经过讨论:

* 对于 non-devicetree 平台, 应该使用 ACPI Table.
* 对于既没有 devicetree, 又没有 ACPI 的 platform, 可以在设备中内置一个使用大致相同格式的结构

# virtio-iommu spec

virtio-iommu 设备管理多个 endpoints 的 DMA 操作.

它既可以作为物理 IOMMU 的代理来管理分配给虚拟机的物理设备(透传)，也可以作为一个虚拟 IOMMU 来管理模拟设备和半虚拟化设备。

virtio-iommu 驱动程序首先使用特定于平台的机制发现由 virtio-iommu 设备管理的 endpoints。然后 virtio-iommu 驱动发送请求为这些 endpoints 创建虚拟地址空间和虚拟地址到物理地址映射关系.

在最简单的形式中，virtio-iommu 支持四种请求类型：

1. 创建一个 domain 并且 attach 一个 endpoint 给它.

`attach(endpoint=0x8, domain=1)`

2. 创建 guest-visual address 到 guest-physical address 的 mapping 关系

`map(domain=1, virt_start=0x1000, virt_end=0x1fff, phys=0xa000, flags=READ)`

3. 移除 mapping 关系

`unmap(domain=1, virt_start=0x1000, virt_end=0x1fff)`

4. detach 一个 endpoint 并且删除 domain

`detach(endpoint=0x8, domain=1)`

