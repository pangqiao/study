
SPEC: https://jpbrucker.net/virtio-iommu/spec/



使用VirtIO标准实现不同虚拟化组件的跨管理程序兼容性，有一个虚拟IOMMU设备现在由Linux 5.3内核中的工作驱动程序支持。


VirtIO规范提供了v0.8规范中的虚拟IOMMU设备，该规范与平台无关，并以有效的方式管理来自仿真或物理设备的直接存储器访问。


Linux VirtIO-IOMMU驱动程序的修补程序自去年以来一直在浮动，而本周最后一个Linux 5.3内核合并窗口已经排队等待登陆。 这个VirtIO IOMMU驱动程序将作为下一个内核的VirtIO/Vhost修复/功能/性能工作的一部分。


QEMU正在等待补丁来支持这个VirtIO IOMMU功能。


