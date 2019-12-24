
# Sparse简介

Sparse 诞生于 2004 年, 是由 linux 之父开发的, 目的就是提供一个静态检查代码 的工具, 从而减少 linux 内核的隐患. 

其实在 Sparse 之前, 已经有了一个不错的**代码静态检查工具** (“SWAT”), 只不过这个工具不是免费软件, 使用上有一些限制. 所以 linus 还是自己开发了一个静态检查工具. 

Sparse 相关的资料可以参考下面链接：

- Sparse kernel Documentation: Documentation/dev-tools/sparse.rst

- Sparse kernel 中文文档: Documentation/translations/zh_CN/sparse.txt

- 2004年文章: [Finding kernel problems automatically](https://lwn.net/Articles/87538/)

- [linus sparse](https://yarchive.net/comp/linux/sparse.html)

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