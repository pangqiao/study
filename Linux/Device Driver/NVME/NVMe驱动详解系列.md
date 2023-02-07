
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

`NVME_CORE`: 这是一个被动的选项。该选项在 `BLK_DEV_NVME`, `NVME_RDMA`, `NVME_FC` **使能**时候会**自动选上**，是 **nvme 核心基础**。

对应的代码是 `core.c` 和 `ioctl.c`, 产生的**模块**是 `nvme-core.ko`。

需要注意的是, 如果**使能**了配置: `NVME_VERBOSE_ERRORS`, `TRACING`, `NVME_MULTIPATH`, `BLK_DEV_ZONED`, `FAULT_INJECTION_DEBUG_FS`, `NVME_HWMON`, `NVME_AUTH`, 那么**模块** `nvme-core.ko` 会合入 `constants.c`, `trace.c`, `multipath.c`, `zns.c`, `fault_inject.c`, `hwmon.c` 和 `auth.c` **文件**, 这些是 NVMe 驱动的特点**可选择是否开启**。

```
config NVME_CORE
	tristate
	select BLK_DEV_INTEGRITY_T10 if BLK_DEV_INTEGRITY
```

```makefile
# 使能后对应的nvme-core.ko模块, 同时产生nvme-core-y
obj-$(CONFIG_NVME_CORE)||       |       += nvme-core.o
# nvme-core-y(nvme-core.ko模块)依赖 core.c 和 ioctl.c
nvme-core-y				+= core.o ioctl.o
# 如果使能了其他的, nvme-core-y 也会有其他的文件依赖
nvme-core-$(CONFIG_NVME_VERBOSE_ERRORS)	+= constants.o
nvme-core-$(CONFIG_TRACING)		+= trace.o
nvme-core-$(CONFIG_NVME_MULTIPATH)	+= multipath.o
nvme-core-$(CONFIG_BLK_DEV_ZONED)	+= zns.o
nvme-core-$(CONFIG_FAULT_INJECTION_DEBUG_FS)	+= fault_inject.o
nvme-core-$(CONFIG_NVME_HWMON)		+= hwmon.o
nvme-core-$(CONFIG_NVME_AUTH)		+= auth.o
```

`BLK_DEV_NVME`: 这个**选项开启**后会**自动选上** `NVME_CORE`，同时自身依赖 pci 和 block. 这个产生 `nvme.ko` 驱动**模块**, 用于直接**将 ssd 链接到 pci 或者 pcie**.

对应的代码是 `nvme.c` 和 `pci.c`，产生的**模块**是 `nvme.ko`.

```kconfig
# drivers/nvme/host/Kconfig
config BLK_DEV_NVME
	tristate "NVM Express block device"
	depends on PCI && BLOCK # 依赖
	select NVME_CORE # 自动选上NVME_CORE
```

```makefile
# 使能后对应的nvme.ko模块, 同时产生产生 nvme-y
obj-$(CONFIG_BLK_DEV_NVME)|     |       += nvme.o
# nvme-y(nvme.ko模块)依赖 pci.c
nvme-y					+= pci.o
```

`CONFIG_NVME_FABRICS`: 是这个**被动选项**。被 `NVME_RDMA` 和 `NVME_FC` 选择（当然，还有一些其他条件需要满足）。主要用于**支持 FC 协议**。

对应的文件是 `fabrics.c`

```
config NVME_FABRICS
        select NVME_CORE # 自动选上NVME_CORE
        tristate
```

```makefile
# 使能后对应的nvme-fabrics.ko模块, 同时产生 nvme-fabrics-y
obj-$(CONFIG_NVME_FABRICS)		+= nvme-fabrics.o
# nvme-fabrics-y(nvme-fabrics.ko模块)依赖 fabrics.c
nvme-fabrics-y                          += fabrics.o
```

`CONFIG_NVME_RDMA`: 这个驱动使得 `NVMe over Fabric` 可以**通过 RDMA 传输**(该选项还依赖于 `CONFIG_INFINIBAND`, `INFINIBAND_ADDR_TRANS` 和 `BLOCK`)。该选项会自动使能 `NVME_FABRICS`(它又会自动使能`NVME_CORE`), `SG_POOL`

对应的文件是 `rdma.c`

```
config NVME_RDMA
        tristate "NVM Express over Fabrics RDMA host driver"
        depends on INFINIBAND && INFINIBAND_ADDR_TRANS && BLOCK
        select NVME_FABRICS
        select SG_POOL
```

```makefile
# 使能后对应的nvme-rdma.ko模块, 同时产生 nvme-rdma-y
obj-$(CONFIG_NVME_RDMA)                 += nvme-rdma.o
# nvme-rdma-y(nvme-rdma.ko模块)依赖 rdma.c
nvme-rdma-y                             += rdma.o
```

`CONFIG_NVME_FC`: 这个驱动使得 `NVMe over Fabric` 可以**在 FC 传输**。该选项会自动使能 `NVME_FABRICS`(它又会自动使能`NVME_CORE`), `SG_POOL`.

```
config NVME_FC
        tristate "NVM Express over Fabrics FC host driver"
        depends on BLOCK # 依赖
        depends on HAS_DMA # 依赖
        select NVME_FABRICS # 自动选上
        select SG_POOL # 自动选上
```

```makefile
# 使能后对应的nvme-fc.ko模块, 同时产生 nvme-fc-y
obj-$(CONFIG_NVME_FC)                   += nvme-fc.o
# nvme-fc-y(nvme-fc.ko模块)依赖 fc.c
nvme-fc-y                               += fc.o
```

`CONFIG_NVME_TCP`: 

<table style="width:100%">
<caption>Description</caption>
  <tr>
    <th>
    模块
    </th>
    <th>
    依赖
    </th>
    <th>
    源码文件
    </th>
  </tr>
  <tr>
    <td>
    nvme-core.ko
    </td>
    <td>
    -
    </td>
    <td>
    core.c ioctl.c constants.c trace.c multipath.c zns.c fault_inject.c hwmon.c auth.c
    </td>
  </tr>
  <tr>
    <td>
    nvme.ko
    </td>
    <td>
    CONFIG_PCI, CONFIG_BLOCK
    </td>
    <td>
    pci.c
    </td>
  </tr>
  <tr>
    <td>
    nvme-fabirc.ko
    </td>
    <td>
    -
    </td>
    <td>
    fabrics.c
    </td>
  </tr>
  <td>
    nvme-rdma.ko
    </td>
    <td>
    CONFIG_INFINIBAND, CONFIG_INFINIBAND_ADDR_TRANS, CONFIG_BLOCK
    </td>
    <td>
    rdma.c
    </td>
  </tr>
</table>

配置完毕后，可以在内核代码根目录中执行make命令产生驱动。

```conf
#
# NVME Support
#
CONFIG_NVME_CORE=m
CONFIG_BLK_DEV_NVME=m
# CONFIG_NVME_MULTIPATH is not set
# CONFIG_NVME_HWMON is not set
CONFIG_NVME_FABRICS=m
# CONFIG_NVME_RDMA is not set
CONFIG_NVME_FC=m
# CONFIG_NVME_TCP is not set
CONFIG_NVME_TARGET=m
# CONFIG_NVME_TARGET_PASSTHRU is not set
CONFIG_NVME_TARGET_LOOP=m
# CONFIG_NVME_TARGET_RDMA is not set
CONFIG_NVME_TARGET_FC=m
# CONFIG_NVME_TARGET_FCLOOP is not set
# CONFIG_NVME_TARGET_TCP is not set
# end of NVME Support
```

```
# make M=drivers/nvme/host
  CC [M]  drivers/nvme/host/pci.o
  LD [M]  drivers/nvme/host/nvme.o
  MODPOST drivers/nvme/host/Module.symvers
  CC [M]  drivers/nvme/host/nvme.mod.o
  LD [M]  drivers/nvme/host/nvme.ko
```

编译后会产生所配置的驱动模块，我们本系列只覆盖 nvme.ko 这个驱动模板，当然另一个 `nvme-core.ko` 必须的。编译后可以通过 `make modules_install` 来安装。

然后可以通过 `modprobe nvme` 来加载驱动。

# PCI驱动注册和注销

现在使用的 **NVMe 设备**都是**基于 PCI的**，所以最后**设备**需要**连接**到内核中的 **pci 总线上**才能够使用。这也是为什么在上篇配置 nvme.ko 时会需要 pci.c 文件，在 Makefile 中有如下这一行的：

```
nvme-y    += pci.o
```

本篇主要针对 `pci.c` 文件的一部分内容进行分析（其实本系列涉及的代码内容就是在 `pci.c` 和 `core.c` 两个文件中）。

驱动的注册和注销，其实就是模块的初始化和退出函数

```cpp
module_init(nvme_init);
module_exit(nvme_exit);
```

nvme 驱动的注册和注销整体函数流程如下图所所示:

![2023-02-07-15-54-21.png](./images/2023-02-07-15-54-21.png)

## 驱动注册

模块注册函数是 `nvme_init`，非常简单，就是一个 `pci_register_driver` 函数

```cpp
static int __init nvme_init(void)
{
	BUILD_BUG_ON(sizeof(struct nvme_create_cq) != 64);
	BUILD_BUG_ON(sizeof(struct nvme_create_sq) != 64);
	BUILD_BUG_ON(sizeof(struct nvme_delete_queue) != 64);
	BUILD_BUG_ON(IRQ_AFFINITY_MAX_SETS < 2);
	BUILD_BUG_ON(DIV_ROUND_UP(nvme_pci_npages_prp(), NVME_CTRL_PAGE_SIZE) >
		     S8_MAX);

	return pci_register_driver(&nvme_driver);
}
```

注册了 `nvme_driver` 驱动，参数为结构体 `nvme_driver`，该结构体类型是 `pci_driver`。

```cpp
static struct pci_driver nvme_driver = {
    // 驱动的名字
	.name		= "nvme",
    // 设备与驱动的关联表，通过这个表内核可以知道哪些设备是通过这个驱动来工作的
	.id_table	= nvme_id_table,
    // 初始化函数, 该函数负责在驱动加载时候探测总线上的硬件设备并初始化设备
	.probe		= nvme_probe,
    // 当前驱动从内核移除时候被调用
	.remove		= nvme_remove,
    // 用于关闭设备
	.shutdown	= nvme_shutdown,
#ifdef CONFIG_PM_SLEEP
	.driver		= {
		.pm	= &nvme_dev_pm_ops,
	},
#endif
    // nvme的sriov操作函数
	.sriov_configure = pci_sriov_configure_simple,
    // 错误处理句柄
	.err_handler	= &nvme_err_handler,
};
```

而 `pci_register_driver` 是个宏，其实是 `__pci_register_driver` 函数，该函数会通过调用 `driver_register` 将要**注册的驱动结构体**放到**系统设备驱动链表**中，将其串成了一串。这里要注意的是pci_driver中包含了device_driver,而我们的驱动nvme_driver就是pci_driver类型。



# reference

https://blog.csdn.net/weixin_33728708/article/details/89700499