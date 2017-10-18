```
1. Linux 的启动流程分析
　　1.1 启动流程一览
　　1.2 BIOS, boot loader 与 kernel 加载：lsinitrd
　　1.3 第一支程序 systemd 及配置档 default.target进入开机程序分析
　　1.4 systemd 执行sysinit.target 初始化系统、basic.target 准备系统
　　1.5 systemd启动multi-user.target服务：相容的rc.local、getty.target启动
　　1.6 systemd启动graphical.target底下的服务
　　1.7 开机过程会用的主要设置
```

## 1. Linux 的启动流程分析

### 1.1 启动流程一览

在启动过程中，那个启动管理程序（**Boot Loader**）使用的软件可能不一样，目前各大Linux distributions主流是grub2，但早期Linux默认使用LILO或者grub1。

首先硬件会主动读取BIOS或者URFI BIOS来载入硬件信息并进行硬件系统的自我检测，之后系统主动读取第一个可启动的装置（BIOS配置），此时就可以读取Boot loader了。

Boot Loader可以指定使用哪个核心文件来启动，并实际加载kernel到内存中解压缩与运行，kernel会检测所有硬件信息、加载适当的驱动程序来使整部主机开始运行。

主机系统开始运行后，此时Linux才会调用外部程序开始准备软件运行的环境，并实际加载所有系统运行的所需的软件程序。最后，OS开始等待登录和操作。

简单来说，系统启动流程如下：

1. 加载BIOS的硬件信息并进行自我检测，并根据配置获取第一个可启动的装置（硬盘、光驱、PXE等）；

2. 读取并运行第一个启动装置中MBR的Boot Loader（即grub、grub2、LILO等）；

3. 根据Boot Loader的配置加载kernel，kernel会检测硬件和加载驱动程序；

4. 硬件驱动成功后，kernel会主动调用systemd程序，并以default.target流程开机；

    - systemd执行sysinit.target初始化系统及basic.target准备OS；
    
    - systemd启动multi-user.target下的服务；
    
    - systemd执行multi-user.target下的/etc/rc.d/rc.local程序；
    
    - systemd执行multi-user.target下的getty.target以及登录服务；
    
    - systemd执行graphical需要的服务。

下面分别来讲。

### 1.2 BIOS, boot loader 与 kernel 加载

BIOS：无论传统BIOS或UEFI BIOS都称为BIOS；

MBR：分割表有传统的MBR以及新式GPT，不过GPT也保留了一块相容MBR的块。因此，下面说的在安装boot loader的部分，也称MBR！MBR就代表了该磁盘最前面的可安装boot loader的那块。

#### 1.2.1 BIOS、开机自检与MBR/GPT

首先让系统载入BIOS，并通过BIOS程序载入CMOS的信息，并且由CMOS内的设置值取得主机的各项硬件设置。例如CPU与周边设备的沟通时脉、启动装置的搜寻顺序、硬盘的大小与类型、系统时间、各周边设备的I/O地址、以及与CPU沟通的IRQ等信息。

获取这些信息后，BIOS会进行自我测试（**Power-on Self Test，POST**）。然后开始运行硬件检测的初始化，并配置PnP装置，之后再定义出可启动的装置顺序，然后读取启动装置的数据（MBR相关任务开始）。

由于不同OS的文件系统格式不同，所以必须要一个启动管理程序来处理核心文件加载（load）的问题，这个启动管理程序就是Boot Loader。Boot Loader会安装在在启动装置的第一个扇区（sector）内，也就是MBR（Mater Boot Record）。

既然核心文件需要loader来读取，每个OS的loader都不相同，BIOS是如何读取MBR内的loader呢？其实BIOS是通过硬件的INT 13中断来读取MBR内容的，也就是说只要BIOS能检测你的磁盘，那就有办法通过INT 13通道读取磁盘的第一sector的MBR。

注：每个磁盘的第一个sector内含有446 bytes的MBR区域，那如果有两个磁盘呢？这个就看BIOS的配置。

#### 1.2.2 Boot Loader的功能

主要用来认识OS的文件格式并加载kernel到memory中，不同OS的boot loader不同。那多OS呢？

每个文件系统（FileSystem）会保留一块启动扇区（boot sector）提供OS安装boot loader，而通常OS会默认安装一份loader到根目录所在的文件系统的boot loader上。

![boot loader 安装在 MBR, boot sector 与操作系统的关系](images/1.png)

每个OS会安装一套boot loader到自己的文件系统中（即每个filesystem左下角的方框）。而Linux在安装时候可以选择将boot loader安装到MBR，也可不安装。若安装到MBR，理论上在MBR和boot sector都会有一份boot loader程序。而Windows会将MBR和boot sector都装一份boot loader！

虽然各个OS都可以安装一份boot loader到boot sector中，这样OS可以通过透过自己的boot loader来加载核心了。问题是系统的MBR只有一个！怎么运行boot sector里面的loader？

boot loader功能如下：

- 提供菜单：使用者可以选择不同启动项目，即多重启动；

- 加载核心文件：直接指向可启动的程序区段来开始操作系统；

- 转交到其他loader：将启动管理功能转交给其他loader负责。

具有菜单功能，所以可以选择不同核心来启动。而由于具有控制权转交功能，因此可以加载其他boot sector的loader！不过windows的loader默认没有控制权转交功能，因此不能使用Windows 的 loader 来加载 Linux 的 loader。所以先装 Windows 再装 Linux 。

![启动管理程序的菜单功能与控制权转交功能示意图](images/2.png)

如上图，MBR 使用 Linux 的 grub 这个启动管理程序，并且里面假设已经有了三个菜单， 第一个菜单可以直接指向 Linux 的核心文件并且直接加载核心来启动；第二个菜单可以将启动管理程序控制权交给 Windows 来管理，此时 Windows 的 loader 会接管启动流程，这个时候他就能够启动 windows 了。第三个菜单则是使用 Linux 在 boot sector 内的启动管理程序，此时就会跳出另一个 grub 的菜单啦！

#### 1.2.3 加载核心侦测硬件与 initrd 的功能

boot loader 开始读取核心文件后，接下来， Linux 就会将核心解压缩到主内存当中，并且利用核心的功能，开始测试与驱动各个周边装置，包括储存装置、CPU、网络卡、声卡等等。kernel不一定会使用 BIOS 侦测到的硬件信息！也就是说，核心此时才开始接管 BIOS 后的工作了。 那么核心文件在哪里啊？一般来说，是 /boot/vmlinuz ！

```
[root@study ~]# ls --format=single-column -F /boot
config-3.10.0-229.el7.x86_64                <==此版本核心被核心编译时选择的功能与模块配置项
grub/                                       <==旧版 grub1 ，不用管这个目录了！
grub2/                                      <==开机管理程序grub2相关目录
initramfs-0-rescue-309eb890d3d95ec7a.img    <==用来救援的操作系统
initramfs-3.10.0-229.el7.x86_64.img         <==正常开机的操作系统
initramfs-3.10.0-229.el7.x86_64kdump.img    <==kernel有问题时用到的操作系统
System.map-3.10.0-229.el7.x86_64            <==核心功能放置到内存位址的对应表
vmlinuz-0-rescue-309eb890d09543d95ec7a*     <==救援用的核心文件
vmlinuz-3.10.0-229.el7.x86_64*              <==核心文件
```

