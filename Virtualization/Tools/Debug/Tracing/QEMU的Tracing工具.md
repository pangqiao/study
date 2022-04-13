
Qemu有自己的Trace框架并支持多个debug/trace后端包括: nop, dtrace, ftrace, log, simple, ust, 可以帮助我们分析Qemu中的问题. 关于这些backend的介绍, 可以看这个链接:  https://repo.or.cz/w/qemu/stefanha.git/blob_plain/refs/heads/tracing:/docs/tracing.txt , 如果现有的trace point不能满足你的需求, 里面还有介绍如何添加新的trace point. 这篇文章主要介绍一下Qemu内嵌的一个backend: Simple trace的使用, 它不需要安装任何其他软件就可以使用. 

1)编译qemu时要enable trace backend

$ ./configure --enable-trace-backends=simple --enable-debug --enable-kvm --target-list=x86_64-softmmu,x86_64-linux-user
$ make
$ make install
2)添加你想要trace的event

$ cat /tmp/events
virtio_blk_req_complete
virtio_blk_handle_write
virtio_blk_handle_read
3)启动虚拟机

$ qemu-system-x86_64 /root/CentOS---6.6-64bit---2015-03-06-a.qcow2 -smp 4 -m 4096 --enable-kvm -nographic -net nic -net tap,ifname=tap0,script=no,downscript=no -trace events=/tmp/events,file=trace.bin
其中, 在正常启动的的qemu程序中加入"-trace events=/tmp/events,file=trace.bin", 其中/tmp/events就是要跟踪的event, 而trace.bin就是trace产生的文件, 不能直接读, 而要通过工具来读. 
4)获取trace结果

$ ./scripts/simpletrace.py trace-events trace.bin
5)有些模块也实现了自己的pretty-print工具, 可以更方便的查看结果. 比如你trace了9p的模块, 可以通过以下工具查看. 

$ ./scripts/analyse-9p-simpletrace.py trace-events trace.bin




QEME是模拟处理器的自由软件, 可以实现虚拟机, Android的虚拟机就是使用QEMU实现的. QEMU中有一个trace模块, 可以对于一些函数进行跟踪, 例如qemu_malloc,  qemu_free等, 对于QEMU本身的调试很用帮助. 下面就介绍一些如何使用. 

1, 在configure的时候加入 --enable-trace-backend=simple 选项, 其中trace的方式有几种, 这里使用simple, 具体可以参考文档

2, 在trace-events文件中enable需要进行trace的函数, 这个文件中默认的都是disable的, 只要删除需要trace的函数前面的disable即可

3, make

4, 正常运行QEMU, 为了调试可以在运行QEMU的时候加入monitor功能, 即在运行的命令中加入 -monitor stdio, 这样就启动了monitor并且和用户在console中进行交互

5, 可以在console中运行(qemu)info trace-events 参考那些event已经被trace, 其中state为1的是已经enable的;  运行(qemu)info trace查看缓存的trace

6, 退出QEMU, 可以输入quit进行退出

7, 这样在当前目录下可以发现一个命名为trace-*的二进制文档即为trace的结果

8, 把`trace-*`和`trace-events`文件copy到 `qemu/script/` 目录下, 运行 `./simpletrace.py trace-events trace-*` 就可以得到格式化了得trace log了

当然除了trace-events定义的一些默认函数外, 依据例子也可以自己定义一些trace, 定义的规则符合c语言函数的命名规则, 在使用的文件中加入 #include "trace.h" , 需要trace的地方在name前加入trace_即可, 具体参考 qemu/trace-event 和 qemu/docs/tracing.txt文档. 

# 参考

https://blog.csdn.net/scaleqiao/article/details/50787340

https://blog.csdn.net/wenmang1977/article/details/8562678