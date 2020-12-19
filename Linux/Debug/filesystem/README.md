
# 用户空间与内核空间数据交换的文件系统

内核中有三个常用的**伪文件系统**: `procfs`, `debugfs`和`sysfs`.

| 文件系统 | 描述 |
|:--------:|:-------|
| procfs   | The proc filesystem is a pseudo-filesystem which provides an interface to kernel data structures. |
| sysfs    | The filesystem for exporting kernel objects. |
| debugfs  | Debugfs exists as a simple way for kernel developers to make information available to user space. |
| relayfs  | A significantly streamlined version of relayfs was recently accepted into the -mm kernel tree.    |

它们都用于Linux内核和用户空间的数据交换, 但是适用的场景有所差异：

* `procfs` 历史最早, 最初就是用来跟内核交互的唯一方式, 用来获取**处理器**、**内存**、**设备驱动**、**进程**等各种信息.

* `sysfs` 跟 `kobject` 框架紧密联系, 而 `kobject` 是为**设备驱动模型**而存在的, 所以 `sysfs` 是为**设备驱动**服务的.

* `debugfs` 从名字来看就是为 `debug` 而生, 所以更加灵活.

* `relayfs` 是一个快速的转发 `(relay)` 数据的文件系统, 它以其功能而得名. 它为那些需要从内核空间转发**大量数据**到用户空间的工具和应用提供了**快速有效的转发机制**.

# 2.1. procfs文件系统

* `ProcFs` 介绍

`procfs` 是比较老的一种用户态与内核态的数据交换方式, 内核的很多数据都是通过这种方式出口给用户的, 内核的很多参数也是通过这种方式来让用户方便设置的. 除了 `sysctl` 控制出口到 `/proc` 下的参数, `procfs` 提供的大部分内核参数是**只读**的. 

实际上, 很多应用严重地依赖于procfs, 因此它几乎是必不可少的组件. 前面部分的几个例子实际上已经使用它来出口内核数据, 但是并没有讲解如何使用, 本节将讲解如何使用`procfs`.

* 参考资料

[用户空间与内核空间数据交换的方式(2)------procfs](http://www.cnblogs.com/hoys/archive/2011/04/10/2011141.html)

# 2.2. sysfs文件系统

内核子系统或设备驱动可以**直接编译到内核**, 也可以编译成**模块**编译到内核, 使用前一节介绍的方法通过内核启动参数来向它们传递参数, 如果编译成模块, 则可以通过命令行在插入模块时传递参数, 或者在运行时, 通过 `sysfs` 来**设置或读取模块数据**.

`sysfs` 是一个基于内存的文件系统, 实际上它基于`ramfs`, `sysfs` 提供了一种把内核数据结构, 它们的属性以及属性与数据结构的联系开放给用户态的方式, 它与 `kobject` 子系统紧密地结合在一起, 因此**内核开发者不需要直接使用**它, 而是内核的**各个子系统使用它**. 用户要想使用 `sysfs` 读取和设置内核参数, 仅需装载 `sysfs` 就可以通过文件操作应用来读取和设置内核通过 `sysfs` 开放给用户的各个参数：

```bash
mkdir -p /sysfs
mount -t sysfs sysfs /sysfs
```

注意, 不要把 `sysfs` 和 `sysctl` 混淆, `sysctl` 是内核的一些**控制参数**, 其目的是方便用户对内核的行为进行控制, 而 `sysfs` 仅仅是把内核的 `kobject` 对象的层次关系与属性开放给用户查看, 因此 `sysfs` 的绝大部分是只读的, 模块作为一个 `kobject` 也被出口到 `sysfs`, 模块参数则是作为模块属性出口的, 内核实现者为模块的使用提供了更灵活的方式, 允许用户设置模块参数在 `sysfs` 的可见性并允许用户在编写模块时设置这些参数在 `sysfs` 下的访问权限, 然后用户就可以通过 `sysfs` 来查看和设置模块参数, 从而使得用户能在模块运行时控制模块行为.

[用户空间与内核空间数据交换的方式(6)------模块参数与sysfs](http://www.cnblogs.com/hoys/archive/2011/04/10/2011470.html)

# 2.3. debugfs文件系统

内核开发者经常需要向用户空间应用输出一些**调试信息**, 在稳定的系统中可能根本不需要这些调试信息, 但是在开发过程中, 为了搞清楚内核的行为, 调试信息非常必要, printk可能是用的最多的, 但它并不是最好的, 调试信息只是在开发中用于调试, 而 `printk` 将一直输出, 因此开发完毕后需要清除不必要的 `printk` 语句, 另外如果开发者希望用户空间应用能够改变内核行为时, `printk` 就无法实现.

因此, 需要一种新的机制, 那只有在需要的时候使用, 它在需要时通过在一个虚拟文件系统中创建一个或多个文件来向用户空间应用提供调试信息.

有几种方式可以实现上述要求：

* 使用 `procfs`, 在 `/proc` 创建文件输出调试信息, 但是 `procfs` 对于大于一个内存页(对于 `x86` 是 `4K`)的输出比较麻烦, 而且速度慢, 有时回出现一些意想不到的问题.
* 使用 `sysfs`( `2.6` 内核引入的新的虚拟文件系统), 在很多情况下, 调试信息可以存放在那里, 但是sysfs主要用于系统管理，它希望每一个文件对应内核的一个变量，如果使用它输出复杂的数据结构或调试信息是非常困难的.
* 使用 `libfs` 创建一个新的文件系统, 该方法极其灵活, 开发者可以为新文件系统设置一些规则, 使用 `libfs` 使得创建新文件系统更加简单, 但是仍然超出了一个开发者的想象.

为了使得开发者更加容易使用这样的机制, `Greg Kroah-Hartman` 开发了 `debugfs`(在 `2.6.11` 中第一次引入), 它是一个虚拟文件系统, 专门用于输出调试信息, 该文件系统非常小, 很容易使用, 可以在配置内核时选择是否构件到内核中, 在不选择它的情况下, 使用它提供的API的内核部分不需要做任何改动.

[用户空间与内核空间数据交换的方式(1)------debugfs](http://www.cnblogs.com/hoys/archive/2011/04/10/2011124.html)

[Linux驱动调试的Debugfs的使用简介](http://soft.chinabyte.com/os/110/12377610.shtml)

[Linux内核里的DebugFS](http://www.cnblogs.com/wwang/archive/2011/01/17/1937609.html)

[Debugging the Linux Kernel with debugfs](http://opensourceforu.com/2010/10/debugging-linux-kernel-with-debugfs/)

[debugfs-seq_file](http://lxr.free-electrons.com/source/drivers/base/power/wakeup.c)

[Linux Debugfs文件系统介绍及使用](http://blog.sina.com.cn/s/blog_40d2f1c80100p7u2.html)

[在 Linux 下用户空间与内核空间数据交换的方式, 第 2 部分: procfs、seq_file、debugfs和relayfs](http://www.ibm.com/developerworks/cn/linux/l-kerns-usrs2/)

[Linux 文件系统：procfs, sysfs, debugfs 用法简介](http://www.tinylab.org/show-the-usage-of-procfs-sysfs-debugfs/)


[Linux 运用debugfs调试方法](http://www.xuebuyuan.com/1023006.html)

误删恢复

[linux 删除文件和目录与恢复详解](http://www.111cn.net/sys/linux/47629.htm)

