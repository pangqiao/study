
tools/perf/Documentation/perf-ftrace.txt

https://blog.csdn.net/lovelycheng/article/details/78348405

在perf中实现了一个ftrace的功能，其实就是把ftrace的功能集成在perf工具中进行显示。由于原先操作debugfs的接口还是要操作几个文件来配合使用的，比如:

a) 设置/sys/kernel/debug/tracing/current_tracer。
b) 打开开关/sys/kernel/debug/tracing/tracing_on。
c) 运行待测程序。
d) 关闭开关/sys/kernel/debug/tracing/tracing_on
e) 获取结果：/sys/kernel/debug/tracing/trace

有的时候我们用debugfs接口时都需要写一个脚本来获取，因此全部集中在perf中操作和显示，相对来讲效率是稍微提升了一些。

目前tracer只支持function和function_graph，后续会陆续增加。难道后续perf有可能会把debugfs的功能全部集中到perf？不可想象。干脆把proc也集中好了，目前好像pert top就是干这个的。

perf ftrace -f function_graph usleep 123456

perf ftrace -t function_graph -a -- insmod ipi_benchmark.ko > after_perf_ftrace


参考：

https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=d01f4e8db22cf4d04f6c86351d959b584eb1f5f7

https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=b05d1093987a78695766b71a2d723aa65b5c25c5

https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=ec347870a9d423a4b88657d6a85b5163b3f949ee
