
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