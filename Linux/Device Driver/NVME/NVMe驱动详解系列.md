
# 源码和编译

## 模块源码

源码在 `drivers/nvme` 下面，主要有两个文件夹，一个是 host, 一个是 target.

* targets 文件夹用于将 nvme 设备作为磁盘导出, 供外部使用;

* host 文件夹实现将 nvme 设备供本系统使用, 不会对外使用, 意味着外部系统不能通过网络或者光纤来访问我们的NVMe磁盘。


若配置NVME target 还需要工具nvmetcli工具。



# reference

https://blog.csdn.net/weixin_33728708/article/details/89700499