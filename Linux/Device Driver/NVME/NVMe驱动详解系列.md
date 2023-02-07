
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

`CONFIG_NVME_RDMA`: 这个驱动使得 NVMe over Fabric 可以通过 RDMA 传输(该选项还依赖于 `CONFIG_INFINIBAND`, `INFINIBAND_ADDR_TRANS` 和 `BLOCK`)。该选项会自动使能 `NVME_FABRICS`(它又会自动使能`NVME_CORE`), `SG_POOL`

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

`CONFIG_NVME_FC`: 这个驱动使得 NVMe over Fabric 可以在 FC 传输。该选项会自动使能 `NVME_FABRICS`(它又会自动使能`NVME_CORE`), `SG_POOL`

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

```
make M=drivers/nvme/host

make -j8 CONFIG_KVM=m CONFIG_KVM_INTEL=m -C `pwd` M=`pwd`/arch/x86/kvm modules
```


# reference

https://blog.csdn.net/weixin_33728708/article/details/89700499