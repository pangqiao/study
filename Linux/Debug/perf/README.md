
不用看各处的资料, 专注官方资料以及命令的help就够了

* 内核中perf文档: linux tree/tools/perf/Documentation/* , 里面既有详细描述, 又有案例介绍
* 命令的help: 基本属于上一部分的子集
* https://perf.wiki.kernel.org/index.php/Main_Page, perf的官方内核wiki主页
* Brendan Gregg 的博客: http://www.brendangregg.com/perf.html
* 在commit信息或当时的patchset讨论情况中也会有一些信息以及命令怎么使用

这个更好: 描述更详细, 且有示例
```
perf --help XXX
```

这个属于快速帮助

```
perf XXX -h
```



https://www.cnblogs.com/arnoldlu/p/6241297.html, 剩余子命令的使用

动态追踪: https://blog.arstercz.com/introduction_to_linux_dynamic_tracing/