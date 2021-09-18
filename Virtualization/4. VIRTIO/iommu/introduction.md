
# kvm forum 2017




1. 最初

virtio-iommu: a paravirtualized IOMMU

第一版 RFC: https://www.spinics.net/lists/kvm/msg147990.html

主要目的是将 模拟设备(virtio) 或 pass-through 设备(VFIO) 的 DMA 翻译成 guest memory

包含三部分内容:

* 一个 device 的 description
* Linux 的 driver
* kvmtool 中的简单实现


Scenario 1: a hardware device passed through twice via VFIO

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



```
(1) a. Guest userspace is running a net driver (e.g. DPDK). It allocates a
       buffer with mmap, obtaining virtual address VA. It then send a
       VFIO_IOMMU_MAP_DMA request to map VA to an IOVA (possibly VA=IOVA).
    b. The maping request is relayed to the host through virtio
       (VIRTIO_IOMMU_T_MAP).
    c. The mapping request is relayed to the physical IOMMU through VFIO.

(2) a. The guest userspace driver can now instruct the device to directly
       access the buffer at IOVA
    b. IOVA accesses from the device are translated into physical
       addresses by the IOMMU.
```




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
