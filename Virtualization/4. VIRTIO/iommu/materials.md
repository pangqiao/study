
Virtio-IOMMU 驱动程序现在使用 Linux 5.14 内核的 x86/x86_64硬件工作。 是 Virtio - Iommu 驱动程序 （合并在 Linux 5.3）， 在几年前在树外工作后， 最初专注于 AArch64 的准虚拟 Iommu 硬件。现在，2021 年 Linux 5.14 的 VirtIO-IOMMU 代码也已调整为适用于 x86 英特尔/AMD 硬件。Virtio-IOMMU 可以处理模拟和准虚拟化设备的管理。ACPI 虚拟 I/O 翻译表 （VIOT） 用于描述准虚拟平台的拓扑，在此案例中，x86 用于描述 virtio-iommu 和端点之间的关系。 Linux 5.14 的 IOMMU 更改还包括 Arm SMMU 更新、英特尔 VT-d 现在支持异步嵌套功能以及各种其他改进。还有一个新的是"amd_iommu=force_enable"内核启动选项，用于在通常有问题的平台上强制 IOMMU。



Virtio IOMMU 是一种半虚拟化设备，允许通过 virtio-mmio 发送 IOMMU 请求，如map/unmap。

使用VirtIO标准实现不同虚拟化组件的跨管理程序兼容性，有一个虚拟IOMMU设备现在由Linux 5.3内核中的工作驱动程序支持。


VirtIO规范提供了v0.8规范中的虚拟IOMMU设备，该规范与平台无关，并以有效的方式管理来自仿真或物理设备的直接存储器访问。


Linux VirtIO-IOMMU驱动程序的修补程序自去年以来一直在浮动，而本周最后一个Linux 5.3内核合并窗口已经排队等待登陆。 这个VirtIO IOMMU驱动程序将作为下一个内核的VirtIO/Vhost修复/功能/性能工作的一部分。

QEMU正在等待补丁来支持这个VirtIO IOMMU功能。




virtio-iommu 最早是 2017 年提出来的

[2017] vIOMMU/ARM: Full Emulation and virtio-iommu Approaches by Eric Auger: https://www.youtube.com/watch?v=7aZAsanbKwI , 

https://events.static.linuxfound.org/sites/events/files/slides/viommu_arm_upload_1.pdf

SPEC: https://jpbrucker.net/virtio-iommu/spec/



KVM patchsets: https://patchwork.kernel.org/project/kvm/list/?submitter=Jean-Philippe%20Brucker&state=*&archive=both&param=2&page=3




virtio-iommu: a paravirtualized IOMMU

> 2017, This is the initial proposal for a paravirtualized IOMMU device using virtio transport. It contains a description of the device, a Linux driver,and a toy implementation in kvmtool. 
> 
> With this prototype, you can translate DMA to guest memory from emulated (virtio), or passed-through (VFIO) devices.
> 
> To understand the virtio-iommu, I advise to first read introduction and motivation, then skim through implementation notes and finally look at the device specification.

* [RFC 0/3] : https://www.spinics.net/lists/kvm/msg147990.html
  * [RFC 1/3] virtio-iommu: firmware description of the virtual topology: https://www.spinics.net/lists/kvm/msg147991.html
  * [RFC 2/3] virtio-iommu: device probing and operations: https://www.spinics.net/lists/kvm/msg147992.html
  * [RFC 3/3] virtio-iommu: future work: https://www.spinics.net/lists/kvm/msg147993.html
* RFC 0.4: https://www.spinics.net/lists/kvm/msg153881.html
  * [RFC] virtio-iommu v0.4 - IOMMU Device: https://www.spinics.net/lists/kvm/msg153882.html
  * [RFC] virtio-iommu v0.4 - Implementation notes: https://www.spinics.net/lists/kvm/msg153883.html


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





Add virtio-iommu driver

> (2017 ~ 2019): 前几个版本在 kvm 中, 后面的在 pci 中

* RFC: https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/
* RFC v2: https://patchwork.kernel.org/project/kvm/patch/20171117185211.32593-2-jean-philippe.brucker@arm.com/
* v1: https://www.spinics.net/lists/kvm/msg164322.html , https://patchwork.kernel.org/project/kvm/patch/20180214145340.1223-2-jean-philippe.brucker@arm.com/
* v2: https://www.spinics.net/lists/kvm/msg170655.html , https://patchwork.kernel.org/project/kvm/patch/20180621190655.56391-3-jean-philippe.brucker@arm.com/
* v3: https://patchwork.kernel.org/project/linux-pci/cover/20181012145917.6840-1-jean-philippe.brucker@arm.com/
* v4: https://patchwork.kernel.org/project/linux-pci/cover/20181115165234.43990-1-jean-philippe.brucker@arm.com/
* v5: https://patchwork.kernel.org/project/linux-pci/cover/20181122193801.50510-1-jean-philippe.brucker@arm.com/
* v6: https://patchwork.kernel.org/project/linux-pci/cover/20181211182104.18241-1-jean-philippe.brucker@arm.com/
* v7: https://patchwork.kernel.org/project/linux-pci/patch/20190115121959.23763-6-jean-philippe.brucker@arm.com/
* v8: https://patchwork.kernel.org/project/linux-pci/patch/20190530170929.19366-6-jean-philippe.brucker@arm.com/
* v9: 



Add virtio-iommu device specification(virtio-spce, https://github.com/oasis-tcs/virtio-spec/blob/master/virtio-iommu.tex): 

* https://lists.oasis-open.org/archives/virtio-comment/201901/msg00017.html





virtio-iommu on non-devicetree platforms

> (2019 ~ 2020):
> 
> Hardware platforms usually describe the IOMMU topology using either device-tree pointers or vendor-specific ACPI tables.

* RFC: [virtio-iommu on non-devicetree platforms](https://patchwork.kernel.org/project/linux-pci/cover/20191122105000.800410-1-jean-philippe@linaro.org/)
* v1: https://patchwork.kernel.org/project/linux-pci/cover/20200214160413.1475396-1-jean-philippe@linaro.org/
* v2: https://patchwork.kernel.org/project/linux-pci/cover/20200228172537.377327-1-jean-philippe@linaro.org/
* 


Add virtio-iommu built-in topology

> 2020

v3: https://patchwork.kernel.org/project/linux-pci/cover/20200821131540.2801801-1-jean-philippe@linaro.org/


Add support for ACPI VIOT

> (2021, linux-acpi), 给 acpi viot table 添加一个driver, 从而可以在non-devicetree 平台(比如x86)使用 virtio-iommu
* RFC: 
* V1: https://patchwork.kernel.org/project/linux-acpi/cover/20210316191652.3401335-1-jean-philippe@linaro.org/
* V2: https://patchwork.kernel.org/project/linux-acpi/cover/20210423113836.3974972-1-jean-philippe@linaro.org/
* v3: https://patchwork.kernel.org/project/linux-acpi/cover/20210602154444.1077006-1-jean-philippe@linaro.org/
* v4: https://patchwork.kernel.org/project/linux-acpi/cover/20210610075130.67517-1-jean-philippe@linaro.org/
* v5: https://patchwork.kernel.org/project/linux-acpi/cover/20210618152059.1194210-1-jean-philippe@linaro.org/
* v6: 




qemu:

https://patchwork.kernel.org/project/qemu-devel/list/?state=*&q=virtio-iommu&archive=both&param=2&page=3


VIRTIO-IOMMU device

> 2017 ~ 2020, implements the QEMU virtio-iommu device.
> 必须 virtio-iommu on non-devicetree platforms 的 kernel patchset 合入才生效

* RFC v7: https://patchwork.kernel.org/project/qemu-devel/cover/1533586484-5737-1-git-send-email-eric.auger@redhat.com/
* v10: https://patchwork.kernel.org/project/qemu-devel/cover/20190730172137.23114-1-eric.auger@redhat.com/
* v15: https://patchwork.kernel.org/project/qemu-devel/cover/20200208120022.1920-1-eric.auger@redhat.com/
* v16: https://patchwork.kernel.org/project/qemu-devel/cover/20200214132745.23392-1-eric.auger@redhat.com/





virtio-iommu: VFIO integration

> 2017 ~ 2020. 
> This patch series allows PCI pass-through using virtio-iommu.

* RFC: https://patchwork.kernel.org/project/qemu-devel/patch/1499927922-32303-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v2: https://patchwork.kernel.org/project/qemu-devel/patch/1500017104-3574-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v3: https://patchwork.kernel.org/project/qemu-devel/patch/1503312534-6642-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v5: https://patchew.org/QEMU/20181127064101.25887-1-Bharat.Bhushan@nxp.com/
* 
* v10: https://patchwork.kernel.org/project/qemu-devel/cover/20201008171558.410886-1-jean-philippe@linaro.org/
* v11: https://patchwork.kernel.org/project/qemu-devel/cover/20201030180510.747225-1-jean-philippe@linaro.org/




virtio-iommu: Built-in topology and x86 support

> 2020

v1: https://patchwork.kernel.org/project/qemu-devel/cover/20200821162839.3182051-1-jean-philippe@linaro.org/




virtio-iommu: Add ACPI support (还未合入)

> 2021

* v1: https://patchwork.kernel.org/project/qemu-devel/cover/20210810084505.2257983-1-jean-philippe@linaro.org/
* v2: https://patchwork.kernel.org/project/qemu-devel/cover/20210903143208.2434284-1-jean-philippe@linaro.org/
* v3: https://patchwork.kernel.org/project/qemu-devel/cover/20210914142004.2433568-1-jean-philippe@linaro.org/




dump viot

use viot details

