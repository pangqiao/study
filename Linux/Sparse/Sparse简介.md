
# Sparse简介

Sparse 诞生于 2004 年, 是由 linux 之父开发的, 目的就是提供一个静态检查代码 的工具, 从而减少 linux 内核的隐患. 

其实在 Sparse 之前, 已经有了一个不错的**代码静态检查工具** (“SWAT”), 只不过这个工具不是免费软件, 使用上有一些限制. 所以 linus 还是自己开发了一个静态检查工具. 

Sparse 相关的资料可以参考下面链接：

- Sparse kernel Documentation: Documentation/dev-tools/sparse.rst

- Sparse kernel 中文文档: Documentation/translations/zh_CN/sparse.txt

- 2004年文章: [Finding kernel problems automatically](https://lwn.net/Articles/87538/)

- [linus sparse](https://yarchive.net/comp/linux/sparse.html)

# Sparse原理

Sparse通过 gcc 的扩展属性 `__attribute__` 以及自己定义的 `__context__` 来对代码进行静态检查.

这些属性如下(尽量整理的,可能还有些不全的地方):

宏名称 | 宏定义 | 检查点
---------|----------|---------
`__bitwise` | `__attribute__((bitwise))` | 确保变量是相同的位方式(比如 `bit-endian`, `little-endiandeng`)
`__user` | `__attribute__((noderef, address_space(1)))` | 指针地址必须在用户地址空间
`__kernel` | `__attribute__((noderef, address_space(0)))` | 指针地址必须在内核地址空间
`__iomem` | __attribute__((noderef, address_space(2))) | 指针地址必须在设备地址空间
`__safe` | __attribute__((safe)) | 变量可以为空
`__force` | __attribute__((force)) | 变量可以进行强制转换
`__nocast` | __attribute__((nocast)) | 参数类型与实际参数类型必须一致
`__acquires(x)` | __attribute__((context(x, 0, 1))) | 参数x 在执行前引用计数必须是0,执行后,引用计数必须为1
`__releases(x)` | `__attribute__((context(x, 1, 0)))` | 与 `__acquires(x)` 相反
`__acquire(x)` | `__context__(x, 1)` | 参数x 的引用计数 + 1
`__release(x)` | `__context__(x, -1) | 与 `__acquire(x)` 相反
`__cond_lock(x,c)` | `((c) ? ({ __acquire(x); 1; }) : 0)` | 参数c 不为0时,引用计数 



# Sparse安装

Sparse 是一个独立于 linux 内核源码的静态源码分析工具，开发者在使用 sparse 进行源码分析之前，确保 sparse 工具**已经安装**，如果没有安装，可以通过下面几个种 方法进行安装。

下载源码

```
git clone git://git.kernel.org/pub/scm/devel/sparse/sparse.git
```

编译安装

```
make
make install
```



# 参考

https://biscuitos.github.io/blog/SPARSE/

https://www.cnblogs.com/wang_yb/p/3575039.html