```
参考：
http://cn.linux.vbird.org/linux_basic/0510osloader_1.php

1. Linux 的启动流程分析
　　1.1 启动流程一览
　　1.2 BIOS, boot loader 与 kernel 加载
　　1.3 第一支程序 init 及配置档 /etc/inittab 与 runlevel
　　1.4 init 处理系统初始化流程 (/etc/rc.d/rc.sysinit)
　　1.5 启动系统服务与相关启动配置档 (/etc/rc.d/rc N & /etc/sysconfig)
　　1.6 使用者自订启动启动程序 (/etc/rc.d/rc.local)
　　1.7 根据 /etc/inittab 之配置，加载终端机或 X-Window 介面
　　1.8 启动过程会用到的主要配置档： /etc/modprobe.conf, /etc/sysconfig/*
　　1.9 Run level 的切换： runlevel, init
```

## 1. Linux 的启动流程分析

### 1.1 启动流程一览

在启动过程中，那个启动管理程序（Boot Loader）使用的软件可能不一样，目前各大Linux distributions主流是grub，但早期Linux默认使用LILO。