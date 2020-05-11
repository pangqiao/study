使用mce-inject工具，但是您需要加载mce_inject内核模块。

```
modprobe mce_inject
```

内核选项是

```
CONFIG_X86_MCE_INJECT
```

接下来，您需要下载mce_inject工具的源代码，安装依赖项并编译它：

```
$ git clone https://github.com/andikleen/mce-inject.git
$ sudo apt-get install flex bison
$ cd mce-inject
$ make
```

# 参考

https://www.cnblogs.com/muahao/p/6003910.html

https://www.oracle.com/technetwork/cn/articles/servers-storage-admin/fault-management-linux-2005816-zhs.html


