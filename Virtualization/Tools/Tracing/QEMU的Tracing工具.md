
Qemu有自己的Trace框架并支持多个debug/trace后端包括：nop, dtrace, ftrace, log, simple, ust，可以帮助我们分析Qemu中的问题。关于这些backend的介绍，可以看这个链接： https://repo.or.cz/w/qemu/stefanha.git/blob_plain/refs/heads/tracing:/docs/tracing.txt ，如果现有的trace point不能满足你的需求，里面还有介绍如何添加新的trace point。这篇文章主要介绍一下Qemu内嵌的一个backend：Simple trace的使用，它不需要安装任何其他软件就可以使用。

1）编译qemu时要enable trace backend

$ ./configure --enable-trace-backends=simple --enable-debug --enable-kvm --target-list=x86_64-softmmu,x86_64-linux-user
$ make
$ make install
2）添加你想要trace的event

$ cat /tmp/events
virtio_blk_req_complete
virtio_blk_handle_write
virtio_blk_handle_read
3）启动虚拟机

$ qemu-system-x86_64 /root/CentOS---6.6-64bit---2015-03-06-a.qcow2 -smp 4 -m 4096 --enable-kvm -nographic -net nic -net tap,ifname=tap0,script=no,downscript=no -trace events=/tmp/events,file=trace.bin
其中，在正常启动的的qemu程序中加入"-trace events=/tmp/events,file=trace.bin"，其中/tmp/events就是要跟踪的event，而trace.bin就是trace产生的文件，不能直接读，而要通过工具来读。
4）获取trace结果

$ ./scripts/simpletrace.py trace-events trace.bin
5）有些模块也实现了自己的pretty-print工具，可以更方便的查看结果。比如你trace了9p的模块，可以通过以下工具查看。

$ ./scripts/analyse-9p-simpletrace.py trace-events trace.bin

# 参考

https://blog.csdn.net/scaleqiao/article/details/50787340