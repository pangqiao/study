
1. 最初

virtio-iommu: a paravirtualized IOMMU

第一版 RFC: https://www.spinics.net/lists/kvm/msg147990.html

主要目的是将 模拟设备(virtio) 或 pass-through 设备(VFIO) 的 DMA 翻译成 guest memory

包含三部分内容:

* 一个 device 的 description
* Linux 的 driver
* kvmtool 中的简单实现

