
# 背景简介

最近两周在忙活 Linux Lab V0.2 RC1，其中一个很重要的目标是添加国产龙芯处理器支持。

在添加龙芯 ls2k 平台的过程中，来自龙芯的张老师已经准备了 **vmlinux** 和 **dtb**，还需要添加**配置文件**和**源代码**，但源码中**默认的配置编译完无法启动**，所以需要找一个**可复用的内核配置文件**。

在张老师准备的内核 **vmlinux** 中，确实有一个 /**proc/config.gz**，说明**内核配置文件**已经**编译到内核**了，但是由于内核**没有配置 nfs**，尝试了几次没 dump 出来。

当然，其实也可以用 `zcat /proc/config.gz` 打印到**控制台**，然后再**复制出来**，这个时候要把控制台的 scrollback lines 设置大一些，但是没那么方便。

# 极速体验

这里讨论另外一个方法，这是张老师分享的一个小技巧，那就是直接用 **Linux 内核源码**下的**小工具**：`script/extract-ikconfig`。

```
$ cd /path/to/linux-kernel
$ scripts/extract-ikconfig /path/to/vmlinux
```

执行完的结果跟 zcat 一致，需要保存到文件，可以这样：

```
$ scripts/extract-ikconfig /path/to/vmlinux > kconfig
```

需要注意的是，这个前提是**配置内核**时要开启 `CONFIG_IKCONFIG` 选项。而如果要拿到 `/proc/config.gz`，还得打开 `CONFIG_IKCONFIG_PROC`。

```
-> General setup                                                     
    -> Kernel .config support (IKCONFIG [=y])
        -> Enable access to .config through /proc/config.gz (IKCONFIG_PROC [=y])
```

# 原理分析

大概的原理我们来剖析一下。

## Makefile

初始化 `KCONFIG_CONFIG`：

```
KCONFIG_CONFIG ?= .config
```

## kernel/Makefile

把 .config 用 gzip 压缩了一份，放到了 kernel/config_data.gz：

# 参考

https://tinylab.org/extract-kernel-config-from-vmlinux/