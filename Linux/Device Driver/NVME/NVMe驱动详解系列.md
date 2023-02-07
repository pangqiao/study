
# 源码和编译

## 模块源码

源码在 `drivers/nvme` 下面，主要有两个文件夹，一个是 host, 一个是 target.

* targets 文件夹用于将 nvme 设备作为磁盘导出, 供外部使用;

* host 文件夹实现将 nvme 设备供本系统使用, 不会对外使用, 意味着外部系统不能通过网络或者光纤来访问我们的 NVMe 磁盘。

若配置NVME target 还需要工具 nvmetcli 工具: http://git.infradead.org/users/hch/nvmetcli.git

我们这个系列主要针对host,关于target将来有机会再做进一步分析。所以后续所有文件都是位于drviers/nvme/host中。

## 模块诞生

先来看下 `drviers/nvme/host` 目录中的Makefile，具体如下。根据内核中的参数配置，最多会有 7 个模块。

```makefile
# SPDX-License-Identifier: GPL-2.0

ccflags-y				+= -I$(src)

# 7个模块
obj-$(CONFIG_NVME_CORE)			+= nvme-core.o
obj-$(CONFIG_BLK_DEV_NVME)		+= nvme.o
obj-$(CONFIG_NVME_FABRICS)		+= nvme-fabrics.o
obj-$(CONFIG_NVME_RDMA)			+= nvme-rdma.o
obj-$(CONFIG_NVME_FC)			+= nvme-fc.o
obj-$(CONFIG_NVME_TCP)			+= nvme-tcp.o
obj-$(CONFIG_NVME_APPLE)		+= nvme-apple.o

nvme-core-y				+= core.o ioctl.o
nvme-core-$(CONFIG_NVME_VERBOSE_ERRORS)	+= constants.o
nvme-core-$(CONFIG_TRACING)		+= trace.o
nvme-core-$(CONFIG_NVME_MULTIPATH)	+= multipath.o
nvme-core-$(CONFIG_BLK_DEV_ZONED)	+= zns.o
nvme-core-$(CONFIG_FAULT_INJECTION_DEBUG_FS)	+= fault_inject.o
nvme-core-$(CONFIG_NVME_HWMON)		+= hwmon.o
nvme-core-$(CONFIG_NVME_AUTH)		+= auth.o

nvme-y					+= pci.o

nvme-fabrics-y				+= fabrics.o

nvme-rdma-y				+= rdma.o

nvme-fc-y				+= fc.o

nvme-tcp-y				+= tcp.o

nvme-apple-y				+= apple.o
```

其中 `ccflags-y` 是**编译标记**，会被正常的 cc 调用，指定了 `$(CC)` **编译时候的选项**，这里**只是**将内核源码的**头文件包含进去**。 其中 `$(src)` 是指向**内核根目录**中 Makefile 所在的目录，包含**模块**需要的一些**头文件**。

我们看下决定模块是否编译的 7 个配置参数：

`NVME_CORE`: 这是一个被动的选项。该选项在 `BLK_DEV_NVME`, `NVME_RDMA`, `NVME_FC` **使能**时候会**自动选上**，是 **nvme 核心基础**。对应的代码是 core.c, 产生的**模块**是 `nvme-core.ko`。另外。这里需要注意的是, 如果**使能**了配置: `NVME_VERBOSE_ERRORS`, `TRACING`, `NVME_MULTIPATH`, `BLK_DEV_ZONED`, `FAULT_INJECTION_DEBUG_FS`, `NVME_HWMON`, `NVME_AUTH`, 那么**模块** `nvme-core.ko` 会被合入 `constants.c`, `trace.c`, `multipath.c`, `zns.c`, `fault_inject.c`, `hwmon.c` 和 `auth.c` 文件, 这些是 NVMe 驱动的特点**可选择是否开启**。

`BLK_DEV_NVME`: 这个**选项开启**后会**自动选上** `NVME_CORE`，同时自身依赖pci和block.这个产生nvme.ko驱动用于直接将ssd链接到pci或者pcie.对应的代码是nvme.c和pci.c，产生的模块是nvme.ko.




# reference

https://blog.csdn.net/weixin_33728708/article/details/89700499