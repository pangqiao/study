
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. Paper](#1-paper)
- [2. KVM Forum](#2-kvm-forum)
- [3. Linux](#3-linux)
- [4. qemu](#4-qemu)
- [5. cloud-hypervisor](#5-cloud-hypervisor)
- [6. maintainer info](#6-maintainer-info)

<!-- /code_chunk_output -->

# 1. Paper

vIOMMU: Efficient IOMMU Emulation, 2011

https://www.usenix.org/conference/usenixatc11/viommu-efficient-iommu-emulation

https://www.usenix.org/legacy/events/atc11/tech/final_files/Amit.pdf

# 2. KVM Forum

https://kvmforum2017.sched.com/event/BnoZ/viommuarm-full-emulation-and-virtio-iommu-approaches-eric-auger-red-hat-inc 


[2017] vIOMMU/ARM: Full Emulation and virtio-iommu Approaches by Eric Auger: https://www.youtube.com/watch?v=7aZAsanbKwI , 

https://events.static.linuxfound.org/sites/events/files/slides/viommu_arm_upload_1.pdf


# 3. Linux

KVM patchsets: https://patchwork.kernel.org/project/kvm/list/?submitter=Jean-Philippe%20Brucker&state=*&archive=both&param=2&page=3

virtio-iommu: a paravirtualized IOMMU

* [RFC 0/3]: a paravirtualized IOMMU, [spinics](https://www.spinics.net/lists/kvm/msg147990.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-1-jean-philippe.brucker__33550.5639938221$1491592770$gmane$org@arm.com/)
  * [RFC 1/3] virtio-iommu: firmware description of the virtual topology: [spinics](https://www.spinics.net/lists/kvm/msg147991.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-2-jean-philippe.brucker__38031.8755437203$1491592803$gmane$org@arm.com/)
  * [RFC 2/3] virtio-iommu: device probing and operations: [spinice](https://www.spinics.net/lists/kvm/msg147992.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-3-jean-philippe.brucker@arm.com/)
  * [RFC 3/3] virtio-iommu: future work: https://www.spinics.net/lists/kvm/msg147993.html

* [RFC PATCH linux] iommu: Add virtio-iommu driver, [lore kernel](https://lore.kernel.org/all/20170407192314.26720-1-jean-philippe.brucker@arm.com/), [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/)

* [RFC PATCH kvmtool 00/15] Add virtio-iommu, [lore kernel](https://lore.kernel.org/all/20170407192455.26814-1-jean-philippe.brucker@arm.com/) 

* RFC 0.4: https://www.spinics.net/lists/kvm/msg153881.html
  * [RFC] virtio-iommu v0.4 - IOMMU Device: https://www.spinics.net/lists/kvm/msg153882.html
  * [RFC] virtio-iommu v0.4 - Implementation notes: https://www.spinics.net/lists/kvm/msg153883.html

Add virtio-iommu driver

> (2017 ~ 2019): 前几个版本在 kvm 中, 后面的在 pci 中

* RFC: [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/), 
* RFC v2: [patchwork](https://patchwork.kernel.org/project/kvm/patch/20171117185211.32593-2-jean-philippe.brucker@arm.com/), 
* v1: https://www.spinics.net/lists/kvm/msg164322.html , https://patchwork.kernel.org/project/kvm/patch/20180214145340.1223-2-jean-philippe.brucker@arm.com/
* v2: https://www.spinics.net/lists/kvm/msg170655.html , https://patchwork.kernel.org/project/kvm/patch/20180621190655.56391-3-jean-philippe.brucker@arm.com/
* v3: https://patchwork.kernel.org/project/linux-pci/cover/20181012145917.6840-1-jean-philippe.brucker@arm.com/
* v4: https://patchwork.kernel.org/project/linux-pci/cover/20181115165234.43990-1-jean-philippe.brucker@arm.com/
* v5: https://patchwork.kernel.org/project/linux-pci/cover/20181122193801.50510-1-jean-philippe.brucker@arm.com/
* v6: https://patchwork.kernel.org/project/linux-pci/cover/20181211182104.18241-1-jean-philippe.brucker@arm.com/
* v7: [patchwork](https://patchwork.kernel.org/project/linux-pci/patch/20190115121959.23763-6-jean-philippe.brucker@arm.com/), 
* v8(Final version): [patchwork](https://patchwork.kernel.org/project/linux-pci/patch/20190530170929.19366-6-jean-philippe.brucker@arm.com/), 

Add virtio-iommu device specification(virtio-spce, https://github.com/oasis-tcs/virtio-spec/blob/master/virtio-iommu.tex): 

* https://lists.oasis-open.org/archives/virtio-comment/201901/msg00017.html

virtio-iommu on non-devicetree platforms/virtio-iommu on x86 and non-devicetree platforms/Add virtio-iommu built-in topology

> (2019 ~ 2020):
> 
> Hardware platforms usually describe the IOMMU topology using either device-tree pointers or vendor-specific ACPI tables.

* RFC: [virtio-iommu on non-devicetree platforms](https://patchwork.kernel.org/project/linux-pci/cover/20191122105000.800410-1-jean-philippe@linaro.org/), 
* v1: [patchwork](https://patchwork.kernel.org/project/linux-pci/cover/20200214160413.1475396-1-jean-philippe@linaro.org/), 
* v2: [patchwork](https://patchwork.kernel.org/project/linux-pci/cover/20200228172537.377327-1-jean-philippe@linaro.org/), 
* v3: [patchwork](https://patchwork.kernel.org/project/linux-pci/cover/20200821131540.2801801-1-jean-philippe@linaro.org/), 

Add support for ACPI VIOT

> (2021, linux-acpi), 给 acpi viot table 添加一个driver, 从而可以在non-devicetree 平台(比如x86)使用 virtio-iommu
* RFC: 
* V1: https://patchwork.kernel.org/project/linux-acpi/cover/20210316191652.3401335-1-jean-philippe@linaro.org/
* V2: https://patchwork.kernel.org/project/linux-acpi/cover/20210423113836.3974972-1-jean-philippe@linaro.org/
* v3: https://patchwork.kernel.org/project/linux-acpi/cover/20210602154444.1077006-1-jean-philippe@linaro.org/
* v4: https://patchwork.kernel.org/project/linux-acpi/cover/20210610075130.67517-1-jean-philippe@linaro.org/
* v5: https://patchwork.kernel.org/project/linux-acpi/cover/20210618152059.1194210-1-jean-philippe@linaro.org/

# 4. qemu

https://patchwork.kernel.org/project/qemu-devel/list/?state=*&q=virtio-iommu&archive=both&param=2&page=3


VIRTIO-IOMMU device

> 2017 ~ 2020, implements the QEMU virtio-iommu device.
> 必须 virtio-iommu on non-devicetree platforms 的 kernel patchset 合入才生效

* RFC v7: https://patchwork.kernel.org/project/qemu-devel/cover/1533586484-5737-1-git-send-email-eric.auger@redhat.com/
* v10: https://patchwork.kernel.org/project/qemu-devel/cover/20190730172137.23114-1-eric.auger@redhat.com/
* v15: https://patchwork.kernel.org/project/qemu-devel/cover/20200208120022.1920-1-eric.auger@redhat.com/
* v16: https://patchwork.kernel.org/project/qemu-devel/cover/20200214132745.23392-1-eric.auger@redhat.com/

virtio-iommu: VFIO integration (还未合入)

> 2017 ~ 2020. 
> This patch series allows PCI pass-through using virtio-iommu.

* RFC: https://patchwork.kernel.org/project/qemu-devel/patch/1499927922-32303-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v2: https://patchwork.kernel.org/project/qemu-devel/patch/1500017104-3574-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v3: https://patchwork.kernel.org/project/qemu-devel/patch/1503312534-6642-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v5: https://patchew.org/QEMU/20181127064101.25887-1-Bharat.Bhushan@nxp.com/
* 
* v10: https://patchwork.kernel.org/project/qemu-devel/cover/20201008171558.410886-1-jean-philippe@linaro.org/
* v11: https://patchwork.kernel.org/project/qemu-devel/cover/20201030180510.747225-1-jean-philippe@linaro.org/

virtio-iommu: Built-in topology and x86 support (还未合入)

> 2020

v1: https://patchwork.kernel.org/project/qemu-devel/cover/20200821162839.3182051-1-jean-philippe@linaro.org/




virtio-iommu: Add ACPI support (还未合入)

> 2021

* v1: https://patchwork.kernel.org/project/qemu-devel/cover/20210810084505.2257983-1-jean-philippe@linaro.org/
* v2: https://patchwork.kernel.org/project/qemu-devel/cover/20210903143208.2434284-1-jean-philippe@linaro.org/
* v3: https://patchwork.kernel.org/project/qemu-devel/cover/20210914142004.2433568-1-jean-philippe@linaro.org/
* v4: https://patchwork.kernel.org/project/qemu-devel/cover/20211001173358.863017-1-jean-philippe@linaro.org/


Add dynamic iommu backed bounce buffers

https://lwn.net/Articles/865617/

https://lwn.net/ml/linux-kernel/20210806103423.3341285-1-stevensd@google.com/

# 5. cloud-hypervisor

https://github.com/cloud-hypervisor/cloud-hypervisor.git


# 6. maintainer info

Jean-Philippe Brucker

author personal site: https://jpbrucker.net/

qemu branch: https://jpbrucker.net/git/qemu/log/?h=virtio-iommu/acpi

SPEC: https://jpbrucker.net/virtio-iommu/spec/