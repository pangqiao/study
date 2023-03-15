
对于Nvme SSD，我们有的时候会用到ioctl系统调用，该调用的流程是怎样的呢?

首先，在注册 nvme 设备的时候(`nvme_probe`)，会注册 file operations

/dev/nvme%d

```cpp

```