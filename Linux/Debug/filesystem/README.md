

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

[Linux内核里的DebugFS](http://www.cnblogs.com/wwang/archive/2011/01/17/1937609.html)

[Debugging the Linux Kernel with debugfs](http://opensourceforu.com/2010/10/debugging-linux-kernel-with-debugfs/)

[debugfs-seq_file](http://lxr.free-electrons.com/source/drivers/base/power/wakeup.c)

[Linux Debugfs文件系统介绍及使用](http://blog.sina.com.cn/s/blog_40d2f1c80100p7u2.html)

[Linux 文件系统：procfs, sysfs, debugfs 用法简介](http://www.tinylab.org/show-the-usage-of-procfs-sysfs-debugfs/)

[用户空间与内核空间数据交换的方式(1)------debugfs](http://www.cnblogs.com/hoys/archive/2011/04/10/2011124.html)


[Linux 运用debugfs调试方法](http://www.xuebuyuan.com/1023006.html)


误删恢复

[linux 删除文件和目录与恢复详解](http://www.111cn.net/sys/linux/47629.htm)

<br>

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="知识共享许可协议" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a>本作品采用<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">知识共享署名-非商业性使用-相同方式共享 4.0 国际许可协议</a>进行许可, 转载请注明出处, 谢谢合作.
