
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [现状](#现状)
  - [系统磁盘使用情况](#系统磁盘使用情况)
  - [系统设备信息](#系统设备信息)
- [方式一: 增加磁盘数](#方式一-增加磁盘数)
  - [VMware Fusion设置](#vmware-fusion设置)
  - [CentOS虚拟机设置](#centos虚拟机设置)
    - [添加新的挂载点](#添加新的挂载点)
    - [扩大LV: 仅使用于用了LVM的更分区](#扩大lv-仅使用于用了lvm的更分区)
      - [磁盘分区](#磁盘分区)
      - [格式化文件系统](#格式化文件系统)

<!-- /code_chunk_output -->
# 现状

## 系统磁盘使用情况 

查看当前系统正在使用的磁盘以及挂载点

```
# df -h
文件系统                 容量  已用  可用 已用% 挂载点
/dev/mapper/centos-root   38G   34G  4.1G   90% /
devtmpfs                 893M     0  893M    0% /dev
tmpfs                    910M     0  910M    0% /dev/shm
tmpfs                    910M   11M  899M    2% /run
tmpfs                    910M     0  910M    0% /sys/fs/cgroup
/dev/sda2                 10G  218M  9.8G    3% /boot
/dev/sda1                200M   12M  189M    6% /boot/efi
tmpfs                    182M  4.0K  182M    1% /run/user/42
tmpfs                    182M   28K  182M    1% /run/user/0
```

根分区容量不够了

## 系统设备信息

```
# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   50G  0 disk
├─sda1            8:1    0  200M  0 part /boot/efi
├─sda2            8:2    0   10G  0 part /boot
└─sda3            8:3    0 39.8G  0 part
  ├─centos-root 253:0    0 37.8G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sr0              11:0    1 1024M  0 rom
```

显然, sda1、sda2、sdb3、centos\-root、centos\-swap都是sda分出来的分区,

```
# pvs
  PV         VG     Fmt  Attr PSize  PFree
  /dev/sda3  centos lvm2 a--  39.80g 4.00m
# pvdisplay
  --- Physical volume ---
  PV Name               /dev/sda3
  VG Name               centos
  PV Size               39.80 GiB / not usable 2.00 MiB
  Allocatable           yes
  PE Size               4.00 MiB
  Total PE              10189
  Free PE               1
  Allocated PE          10188
  PV UUID               XjIX0W-DgVi-sG34-8bcM-YhIX-sIXc-hB0UW1

# vgs
  VG     #PV #LV #SN Attr   VSize  VFree
  centos   1   2   0 wz--n- 39.80g 4.00m
# vgdisplay
  --- Volume group ---
  VG Name               centos
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               39.80 GiB
  PE Size               4.00 MiB
  Total PE              10189
  Alloc PE / Size       10188 / <39.80 GiB
  Free  PE / Size       1 / 4.00 MiB
  VG UUID               qeJ63E-4HtZ-ti1z-SHA0-wZSB-9BL9-o5yXvJ

# lvs
  LV   VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root centos -wi-ao---- <37.80g
  swap centos -wi-ao----   2.00g
# lvdisplay
  --- Logical volume ---
  LV Path                /dev/centos/root
  LV Name                root
  VG Name                centos
  LV UUID                aN7JXG-kZue-7Gds-LO8g-dyw3-s2zD-YBVv2I
  LV Write Access        read/write
  LV Creation host, time localhost, 2019-08-13 17:36:12 +0800
  LV Status              available
  # open                 1
  LV Size                <37.80 GiB
  Current LE             9676
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0

  --- Logical volume ---
  LV Path                /dev/centos/swap
  LV Name                swap
  VG Name                centos
  LV UUID                MRi9C1-PzeG-aB6n-4z45-DjZD-mZuU-jfX8SY
  LV Write Access        read/write
  LV Creation host, time localhost, 2019-08-13 17:36:12 +0800
  LV Status              available
  # open                 2
  LV Size                2.00 GiB
  Current LE             512
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:1
```





# 方式一: 增加磁盘数

## VMware Fusion设置

关闭虚拟机后, 增加磁盘

"虚拟机" "设置" "添加设备" "新硬盘"

![2019-09-13-22-15-48.png](./images/2019-09-13-22-15-48.png)

![2019-09-13-22-16-21.png](./images/2019-09-13-22-16-21.png)

设置好需要添加的硬盘信息，点击【应用】添加磁盘。

至此, VMware Fusion设置完成

## CentOS虚拟机设置

查看系统磁盘使用情况

```
# df -h
文件系统                 容量  已用  可用 已用% 挂载点
/dev/mapper/centos-root   38G   34G  4.1G   90% /
devtmpfs                 893M     0  893M    0% /dev
tmpfs                    910M     0  910M    0% /dev/shm
tmpfs                    910M   11M  900M    2% /run
tmpfs                    910M     0  910M    0% /sys/fs/cgroup
/dev/sda2                 10G  218M  9.8G    3% /boot
/dev/sda1                200M   12M  189M    6% /boot/efi
tmpfs                    182M   12K  182M    1% /run/user/42
tmpfs                    182M     0  182M    0% /run/user/0
```

查看设备信息

```
# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   50G  0 disk
├─sda1            8:1    0  200M  0 part /boot/efi
├─sda2            8:2    0   10G  0 part /boot
└─sda3            8:3    0 39.8G  0 part
  ├─centos-root 253:0    0 37.8G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sdb               8:16   0   20G  0 disk
sr0              11:0    1 1024M  0 rom
```

显然, sda1、sda2、sdb3、centos\-root、centos\-swap都是sda分出来的分区, 而 sdb 就是刚创建的磁盘，它有20G的空间

### 添加新的挂载点



### 扩大LV: 仅使用于用了LVM的更分区

因为根分区使用了LVM技术, 所以可以通过增加PV容量来扩容根分区

#### 磁盘分区

先将新磁盘分区, 这里分一个就可以

使用Linux的fdisk分区工具给磁盘/dev/sdb分区，更可以根据提示输入m查看帮助信息，再输入n(表示增加分区)，回车后输入p(创建主分区)，回车后partition number输入1，回车会提示输入分区的start值，end值。都默认即可(即当前能使用的所有空间)，回车后输入w进行保存，分区划分完毕(增加了20G空间)。

```
# fdisk /dev/sdb
欢迎使用 fdisk (util-linux 2.23.2)。

更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。

Device does not contain a recognized partition table
使用磁盘标识符 0x84ce2f97 创建新的 DOS 磁盘标签。

命令(输入 m 获取帮助)：p

磁盘 /dev/sdb：21.5 GB, 21474836480 字节，41943040 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x84ce2f97

   设备 Boot      Start         End      Blocks   Id  System

命令(输入 m 获取帮助)：n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): p
分区号 (1-4，默认 1)：
起始 扇区 (2048-41943039，默认为 2048)：
将使用默认值 2048
Last 扇区, +扇区 or +size{K,M,G} (2048-41943039，默认为 41943039)：
将使用默认值 41943039
分区 1 已设置为 Linux 类型，大小设为 20 GiB

命令(输入 m 获取帮助)：t
已选择分区 1
Hex 代码(输入 L 列出所有代码)：L

 0  空              24  NEC DOS         81  Minix / 旧 Linu bf  Solaris
 1  FAT12           27  隐藏的 NTFS Win 82  Linux 交换 / So c1  DRDOS/sec (FAT-
 2  XENIX root      39  Plan 9          83  Linux           c4  DRDOS/sec (FAT-
 3  XENIX usr       3c  PartitionMagic  84  OS/2 隐藏的 C:  c6  DRDOS/sec (FAT-
 4  FAT16 <32M      40  Venix 80286     85  Linux 扩展      c7  Syrinx
 5  扩展            41  PPC PReP Boot   86  NTFS 卷集       da  非文件系统数据
 6  FAT16           42  SFS             87  NTFS 卷集       db  CP/M / CTOS / .
 7  HPFS/NTFS/exFAT 4d  QNX4.x          88  Linux 纯文本    de  Dell 工具
 8  AIX             4e  QNX4.x 第2部分  8e  Linux LVM       df  BootIt
 9  AIX 可启动      4f  QNX4.x 第3部分  93  Amoeba          e1  DOS 访问
 a  OS/2 启动管理器 50  OnTrack DM      94  Amoeba BBT      e3  DOS R/O
 b  W95 FAT32       51  OnTrack DM6 Aux 9f  BSD/OS          e4  SpeedStor
 c  W95 FAT32 (LBA) 52  CP/M            a0  IBM Thinkpad 休 eb  BeOS fs
 e  W95 FAT16 (LBA) 53  OnTrack DM6 Aux a5  FreeBSD         ee  GPT
 f  W95 扩展 (LBA)  54  OnTrackDM6      a6  OpenBSD         ef  EFI (FAT-12/16/
10  OPUS            55  EZ-Drive        a7  NeXTSTEP        f0  Linux/PA-RISC
11  隐藏的 FAT12    56  Golden Bow      a8  Darwin UFS      f1  SpeedStor
12  Compaq 诊断     5c  Priam Edisk     a9  NetBSD          f4  SpeedStor
14  隐藏的 FAT16 <3 61  SpeedStor       ab  Darwin 启动     f2  DOS 次要
16  隐藏的 FAT16    63  GNU HURD or Sys af  HFS / HFS+      fb  VMware VMFS
17  隐藏的 HPFS/NTF 64  Novell Netware  b7  BSDI fs         fc  VMware VMKCORE
18  AST 智能睡眠    65  Novell Netware  b8  BSDI swap       fd  Linux raid 自动
1b  隐藏的 W95 FAT3 70  DiskSecure 多启 bb  Boot Wizard 隐  fe  LANstep
1c  隐藏的 W95 FAT3 75  PC/IX           be  Solaris 启动    ff  BBT
1e  隐藏的 W95 FAT1 80  旧 Minix
Hex 代码(输入 L 列出所有代码)：8e
已将分区“Linux”的类型更改为“Linux LVM”

命令(输入 m 获取帮助)：p

磁盘 /dev/sdb：21.5 GB, 21474836480 字节，41943040 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x84ce2f97

   设备 Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    41943039    20970496   8e  Linux LVM

命令(输入 m 获取帮助)：w
The partition table has been altered!

Calling ioctl() to re-read partition table.
正在同步磁盘。
```

重启Linux

#### 格式化文件系统

想要使用该分区, 必须先格式为


```
# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   70G  0 disk
├─sda1            8:1    0  200M  0 part /boot/efi
├─sda2            8:2    0   10G  0 part /boot
└─sda3            8:3    0 39.8G  0 part
  ├─centos-root 253:0    0 37.8G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sr0              11:0    1 1024M  0 rom
```

```
# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   70G  0 disk
├─sda1            8:1    0  200M  0 part /boot/efi
├─sda2            8:2    0   10G  0 part /boot
└─sda3            8:3    0 39.8G  0 part
  ├─centos-root 253:0    0 37.8G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sr0              11:0    1 1024M  0 rom
```
```
# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   70G  0 disk
├─sda1            8:1    0  200M  0 part /boot/efi
├─sda2            8:2    0   10G  0 part /boot
└─sda3            8:3    0 39.8G  0 part
  ├─centos-root 253:0    0 37.8G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sr0              11:0    1 1024M  0 rom
```
```

```

https://www.jianshu.com/p/38eaf0c0a77d