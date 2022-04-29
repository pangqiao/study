
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 下载qcow2镜像](#1-下载qcow2镜像)
- [2. 镜像密码修改](#2-镜像密码修改)
- [暂时启动guest](#暂时启动guest)
- [开启root账号ssh远程登录](#开启root账号ssh远程登录)
- [3. 扩大根分区](#3-扩大根分区)
  - [3.1. 磁盘整体扩容](#31-磁盘整体扩容)
  - [3.2. 查看磁盘扩容后状态](#32-查看磁盘扩容后状态)
  - [3.3. 进行分区扩展磁盘](#33-进行分区扩展磁盘)
  - [3.4. 删除根分区](#34-删除根分区)
  - [3.5. 创建分区](#35-创建分区)
  - [3.6. 保存退出并刷新分区](#36-保存退出并刷新分区)
  - [3.7. 查看磁盘分区和文件系统状态](#37-查看磁盘分区和文件系统状态)
  - [3.8. 刷新根分区](#38-刷新根分区)
- [4. 创建数据盘并使用](#4-创建数据盘并使用)
- [5. 修改镜像内容](#5-修改镜像内容)
- [6. 键盘输入设置](#6-键盘输入设置)
- [7. 虚拟机最终启动命令](#7-虚拟机最终启动命令)
- [8. 修改 grub](#8-修改-grub)
- [9. 防火墙](#9-防火墙)
- [10. vncserver](#10-vncserver)

<!-- /code_chunk_output -->

# 1. 下载qcow2镜像

根据ubuntu发行版, 找最新的下载

链接: https://cloud-images.ubuntu.com/

# 2. 镜像密码修改

qcow2 镜像改密码: https://leux.cn/doc/Debian%E5%AE%98%E6%96%B9qcow2%E9%95%9C%E5%83%8F%E4%BF%AE%E6%94%B9root%E5%AF%86%E7%A0%81.html

# 暂时启动guest

如果没有enable virtio 的话, 可以使用下面命令:

>qemu-system-x86_64 -name ubuntu -accel kvm -cpu host -m 32G -smp 48,sockets=1,cores=24,threads=2 ./ubuntu-22.04.qcow2 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic -full-screen

如果host上支持 virtio, 可以使用下面命令

> qemu-system-x86_64 -name ubuntu-hirsute --enable-kvm -cpu host -smp 4,sockets=1,cores=2,threads=2 -m 3G -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=./debian-10.12.2-20220419-openstack-amd64.qcow2,if=none,id=drive-virtio-disk1,format=qcow2,cache=none -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x3,drive=drive-virtio-disk1,id=virtio-disk1,bootindex=1 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic -full-screen

# 开启root账号ssh远程登录



# 3. 扩大根分区

Linux 扩容 / 根分区(LVM+非LVM)参照: https://zhuanlan.zhihu.com/p/83340525

磁盘空间扩容: https://blog.csdn.net/byn12345/article/details/88829984

## 3.1. 磁盘整体扩容

先将原有镜像备份

```
# qemu-img resize ubuntu_hirsute.qcow2 +18G

# qemu-img info ubuntu_hirsute.qcow2
image: ubuntu_hirsute.qcow2
file format: qcow2
virtual size: 20.2 GiB (21688745984 bytes)
disk size: 613 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16
```

建议直接扩大到50G

## 3.2. 查看磁盘扩容后状态

进入虚拟机命令如下

>
>/usr/bin/qemu-system-x86_64 -name ubuntu-hirsute --enable-kvm -cpu host -smp 4,sockets=1,cores=2,threads=2 -m 3G -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=/images/ubuntu_hirsute.qcow2,if=none,id=drive-virtio-disk0,format=qcow2,cache=none -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x3,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic -full-screen

```
lsblk
dh -TH
```

```
# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0       2:0    1    4K  0 disk
loop0     7:0    0 32.3M  1 loop /snap/snapd/12704
loop1     7:1    0 68.3M  1 loop /snap/lxd/21260
loop2     7:2    0 61.8M  1 loop /snap/core20/1081
sr0      11:0    1 1024M  0 rom
vda     252:0    0 20.2G  0 disk
├─vda1  252:1    0  2.1G  0 part /
├─vda14 252:14   0    4M  0 part
└─vda15 252:15   0  106M  0 part /boot/efi
```

```
# df -Th
Filesystem     Type   Size  Used Avail Use% Mounted on
tmpfs          tmpfs  299M  932K  298M   1% /run
/dev/vda1      ext4   2.0G  1.4G  614M  70% /
tmpfs          tmpfs  1.5G     0  1.5G   0% /dev/shm
tmpfs          tmpfs  5.0M     0  5.0M   0% /run/lock
tmpfs          tmpfs  4.0M     0  4.0M   0% /sys/fs/cgroup
/dev/vda15     vfat   105M  5.2M  100M   5% /boot/efi
tmpfs          tmpfs  299M  4.0K  299M   1% /run/user/0
```

## 3.3. 进行分区扩展磁盘

记住根分区起始位置和结束位置

```
fdisk /dev/vda
```

![images](./images/2021-08-24_10-23-27.png)

## 3.4. 删除根分区

切记一定不要保存！！！

```
Command (m for help): d
Partition number (1,14,15, default 15): 1

Partition 1 has been deleted.
```

## 3.5. 创建分区

创建分区, 分区号还是1, 注意分区起始位置, 不要删除ext4的签名

```
Command (m for help): n
Partition number (1-13,16-128, default 1): 1
First sector (34-42360798, default 227328):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (227328-42360798, default 42360798):

Created a new partition 1 of type 'Linux filesystem' and of size 20.1 GiB.
Partition #1 contains a ext4 signature.

Do you want to remove the signature? [Y]es/[N]o: N

Command (m for help): p

Disk /dev/vda: 50.2 GiB, 53901000704 bytes, 105275392 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: DF9A5BBC-1684-4689-84FE-51D6F821EEFC

Device      Start      End  Sectors  Size Type
/dev/vda1  227328 42360798 42133471 20.1G Linux filesystem
/dev/vda14   2048    10239     8192    4M BIOS boot
/dev/vda15  10240   227327   217088  106M EFI System
```

## 3.6. 保存退出并刷新分区

```
Command (m for help): w

The partition table has been altered.
Syncing disks.

root@ubuntu-vm:~# partprobe /dev/vda
```

## 3.7. 查看磁盘分区和文件系统状态

```
root@ubuntu-vm:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0       2:0    1    4K  0 disk
loop0     7:0    0 32.3M  1 loop /snap/snapd/12704
loop1     7:1    0 68.3M  1 loop /snap/lxd/21260
loop2     7:2    0 61.8M  1 loop /snap/core20/1081
sr0      11:0    1 1024M  0 rom
vda     252:0    0 20.2G  0 disk
├─vda1  252:1    0 20.1G  0 part /
├─vda14 252:14   0    4M  0 part
└─vda15 252:15   0  106M  0 part /boot/efi

root@ubuntu-vm:~# df -Th
Filesystem     Type   Size  Used Avail Use% Mounted on
tmpfs          tmpfs  299M  932K  298M   1% /run
/dev/vda1      ext4   2.0G  1.4G  614M  70% /
tmpfs          tmpfs  1.5G     0  1.5G   0% /dev/shm
tmpfs          tmpfs  5.0M     0  5.0M   0% /run/lock
tmpfs          tmpfs  4.0M     0  4.0M   0% /sys/fs/cgroup
/dev/vda15     vfat   105M  5.2M  100M   5% /boot/efi
tmpfs          tmpfs  299M  4.0K  299M   1% /run/user/0
```

* lsblk有变化, 这是磁盘的变化

* df没变化, 文件系统还没有变化

## 3.8. 刷新根分区

使用 resize2fs或xfs_growfs 对挂载目录在线扩容 

* resize2fs 针对文件系统ext2 ext3 ext4
* xfs_growfs 针对文件系统xfs

```
# resize2fs /dev/vda1
resize2fs 1.45.7 (28-Jan-2021)
Filesystem at /dev/vda1 is mounted on /; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 3
The filesystem on /dev/vda1 is now 5266683 (4k) blocks long.

root@ubuntu-vm:~# df -Th
Filesystem     Type   Size  Used Avail Use% Mounted on
tmpfs          tmpfs  299M  932K  298M   1% /run
/dev/vda1      ext4    20G  1.4G   19G   7% /
tmpfs          tmpfs  1.5G     0  1.5G   0% /dev/shm
tmpfs          tmpfs  5.0M     0  5.0M   0% /run/lock
tmpfs          tmpfs  4.0M     0  4.0M   0% /sys/fs/cgroup
/dev/vda15     vfat   105M  5.2M  100M   5% /boot/efi
tmpfs          tmpfs  299M  4.0K  299M   1% /run/user/0
```

# 4. 创建数据盘并使用

数据盘格式化并挂载: https://www.cnblogs.com/jyzhao/p/4778657.html

# 5. 修改镜像内容

通过 `qmeu-nbd` 工具

# 6. 键盘输入设置

ubuntu中启用page up/down进行补全功能: https://blog.csdn.net/jingtaohuang/article/details/109628105

`/etc/inputrc` 中这两行取消注释

```
# alternate mappings for "page up" and "page down" to search the history
"\e[5~": history-search-backward
"\e[6~": history-search-forward
```

# 7. 虚拟机最终启动命令

> ubuntu hirsute image -- quick start
> 
> /usr/bin/qemu-system-x86_64 -name ubuntu-hirsute --enable-kvm -cpu host -smp 4,sockets=1,cores=2,threads=2 -m 3G -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=/images/ubuntu_hirsute.qcow2,if=none,id=drive-virtio-disk0,format=qcow2,cache=none -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x3,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 -drive file=/images/data.qcow2,format=qcow2,if=none,id=drive-virtio-disk1,cache=none,aio=native -object iothread,id=iothread1 -device virtio-blk-pci,iothread=iothread1,scsi=off,bus=pci.0,addr=0x4,drive=drive-virtio-disk1,id=virtio-disk1 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic -full-screen

> ubuntu hirsute image -- daemonize start
>
>/usr/bin/qemu-system-x86_64  -name ubuntu-hirsute -machine pc-i440fx-hirsute,accel=kvm,usb=off,dump-guest-core=off -cpu host -m 4G -smp 4,sockets=1,cores=2,threads=2 -uuid 982ab310-b608-49f9-8e0f-afdf7fa3fdda -smbios type=1,serial=982ab310-b608-49f9-8e0f-afdf7fa3fdda,uuid=982ab310-b608-49f9-8e0f-afdf7fa3fdda -no-user-config -nodefaults -chardev socket,id=montest,server=on,wait=off,path=/tmp/mon_test -mon chardev=montest,mode=readline -rtc base=utc,clock=vm -global kvm-pit.lost_tick_policy=discard -no-hpet -no-shutdown -boot strict=on -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=/images/ubuntu_hirsute.qcow2,format=qcow2,if=none,id=drive-virtio-disk0,cache=none,aio=native -object iothread,id=iothread0 -device virtio-blk-pci,iothread=iothread0,scsi=off,bus=pci.0,addr=0x3,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 -drive file=/images/data.qcow2,format=qcow2,if=none,id=drive-virtio-disk1,cache=none,aio=native -object iothread,id=iothread1 -device virtio-blk-pci,iothread=iothread1,scsi=off,bus=pci.0,addr=0x4,drive=drive-virtio-disk1,id=virtio-disk1 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0 -vnc 0.0.0.0:1 -k en-us -device cirrus-vga,id=video0,bus=pci.0,addr=0x6 -device virtio-balloon-pci,id=balloon0,bus=pci.0,addr=0x7 -msg timestamp=on -daemonize

# 8. 修改 grub

```
# vim /etc/default/grub
// 选择的内核
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 5.4.129-02962-ge8dff
9ce0bd6d"
// 打开菜单
GRUB_TIMEOUT_STYLE=menu
// 超时 10s
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""

# update-grub
```

ubuntu修改默认启动内核: https://cdmana.com/2021/03/20210328153654881n.html

# 9. 防火墙

ufw disable

ufw status

# 10. vncserver

https://www.linode.com/docs/guides/install-vnc-on-ubuntu-21-04/


apt install tigervnc-standalone-server

https://blog.csdn.net/chen462488588/article/details/112237950

窗口太小: https://blog.csdn.net/teng_wu/article/details/103260703

tigervncserver -geometry 1280x1024 -localhost no -xstartup /usr/bin/xterm

tigervncserver -xstartup /usr/bin/mate-session -geometry 800x600 -localhost no

