    - [3.3.3. viommu 设备配置信息](#333-viommu-设备配置信息)
  - [3.4. 未来要进行的工作](#34-未来要进行的工作)
slide: https://events.static.linuxfound.org/sites/events/files/slides/viommu_arm_upload_1.pdf
这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步说明. 它包含设备描述, Linux 驱动程序和 kvmtool 中的粗略实现.
场景一: 硬件设备通过 VFIO 透传
与其他 virtio 设备不同, virtio-iommu 设备不能独立工作, 它与其他虚拟或分配的设备相连. 因此, 在设备操作之前, 我们需要定义一种方法, 让 guest 发现虚拟 IOMMU 及其它管理的设备.
操作系统解析 IORT 表, 以构建 IOMMU 与设备之间的 ID 关系表. ID Array 用于查找 IOMMU ID 与 PCI 或平台设备之间的关系. 稍后, virtio-iommu 驱动程序通过"Device object name"字段找到相关的 LNRO0005 描述符, 并探测 virtio 设备以了解更多有关其功能的信息. 由于"IOMMU"的所有属性将在 virtio probe 期间获得, IORT 节点要尽量保持简单.
3. 设备配置信息Device configuration layout
### 3.3.3. viommu 设备配置信息
1. page_size_mask 包含可以 map 的所有页面大小的 bitmap. 最低有效位集定义了 IOMMU map 的页面粒度. mask 中的其他位是描述 IOMMU 可以合并为单个映射(页面块)的页面大小的提示.
IOMMU 支持的最小页面粒度没有下限. 如果设备通告它(`page_size_mask[0]=1`), 驱动程序一次 map 一个字节是合法的.
## 3.4. 未来要进行的工作
大部分代码是在创建请求并通过 virtio 发送它们. 实现 IOMMU API 是比较简单的, 因为 virtio-iommu 的 MAP/UNMAP 接口几乎相同. 我放到了一个自定义的 map_sg() 函数中. 核心函数将发送一系列的 map 请求, 并且等待每个请求的返回. 这个优化避免在每个 map 后 yield to host, 而是在 virtio ring 中准备一批请求, 并 kick host 一次.
几个核心结构体
```diff
diff --git a/drivers/iommu/virtio-iommu.c b/drivers/iommu/virtio-iommu.c
new file mode 100644
index 000000000000..1cf4f57b7817
--- /dev/null
+++ b/drivers/iommu/virtio-iommu.c
@@ -0,0 +1,980 @@
+#include <uapi/linux/virtio_iommu.h>
+
+struct viommu_dev {
+	struct iommu_device		iommu;
+	struct device			*dev;
+	struct virtio_device		*vdev;
+
+	struct virtqueue		*vq;
+	struct list_head		pending_requests;
+	/* Serialize anything touching the vq and the request list */
+	spinlock_t			vq_lock;
+
+	struct list_head		list;
+
+	/* Device configuration */
+	u64				pgsize_bitmap;
+	u64				aperture_start;
+	u64				aperture_end;
+};
+
+struct viommu_mapping {
+	phys_addr_t			paddr;
+	struct interval_tree_node	iova;
+};
+
+struct viommu_domain {
+	struct iommu_domain		domain;
+	struct viommu_dev		*viommu;
+	struct mutex			mutex;
+	u64				id;
+
+	spinlock_t			mappings_lock;
+	struct rb_root			mappings;
+
+	/* Number of devices attached to this domain */
+	unsigned long			attached;
+};
+
+struct viommu_endpoint {
+	struct viommu_dev		*viommu;
+	struct viommu_domain		*vdomain;
+};
+
+struct viommu_request {
+	struct scatterlist		head;
+	struct scatterlist		tail;
+
+	int				written;
+	struct list_head		list;
+};
+
+/* TODO: use an IDA */
+static atomic64_t viommu_domain_ids_gen;
+
+#define to_viommu_domain(domain) container_of(domain, struct viommu_domain, domain)
+
```
* `struct viommu_dev`: viommu 设备.
* `struct viommu_mapping`: 一个mapping, iova -> gpa
* `struct viommu_domain`: 一个 address space. domain 指向 VM domain(per VM); viommu 指向 viommu 设备;
* `struct viommu_endpoint`: 由 viommu 管理的一个设备. `viommu` 指向所属的 viommu 设备; `vdomain` 指向所 attached 的 address space
* `struct viommu_request`: viommu 请求. 
```diff
diff --git a/include/uapi/linux/virtio_iommu.h b/include/uapi/linux/virtio_iommu.h
new file mode 100644
index 000000000000..ec74c9a727d4
--- /dev/null
+++ b/include/uapi/linux/virtio_iommu.h
+#ifndef _UAPI_LINUX_VIRTIO_IOMMU_H
+#define _UAPI_LINUX_VIRTIO_IOMMU_H

+__packed
+struct virtio_iommu_config {
+	/* Supported page sizes */
+	__u64					page_sizes;
+	struct virtio_iommu_range {
+		__u64				start;
+		__u64				end;
+	} input_range;
+	__u8 					ioasid_bits;
+};
+
+__packed
+struct virtio_iommu_req_head {
+	__u8					type;
+	__u8					reserved[3];
+};
+
+__packed
+struct virtio_iommu_req_tail {
+	__u8					status;
+	__u8					reserved[3];
+};
+
+__packed
+struct virtio_iommu_req_attach {
+	struct virtio_iommu_req_head		head;
+
+	__le32					address_space;
+	__le32					device;
+	__le32					reserved;
+
+	struct virtio_iommu_req_tail		tail;
+};
+
......
+
+union virtio_iommu_req {
+	struct virtio_iommu_req_head		head;
+
+	struct virtio_iommu_req_attach		attach;
+	struct virtio_iommu_req_detach		detach;
+	struct virtio_iommu_req_map		map;
+	struct virtio_iommu_req_unmap		unmap;
+};
+
+#endif

* `struct virtio_iommu_config`: viommu 配置信息. page_sizes 表示 viommu 支持 map 的页面大小; input_range 表示 viommu 能够 translate 的虚拟地址范围; ioasid_bits 表示支持的 address space 的数目.
* `struct virtio_iommu_req_XXX`: 某种请求. 按照前面说的格式组织.

virtio-iommu driver 模块初始化相关代码