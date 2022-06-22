https://cloud.tencent.com/developer/article/1439068

首先，按照下面链接里的内容，下载对应的内核源码仓库。

https://wiki.ubuntu.com/Kernel/Dev/KernelGitGuide

如果觉得链接里的内容太长了，可以试下如下命令。

```
git clone git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/$(lsb_release -cs)

git clone https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/$(lsb_release -cs)
```

lsb_release -cs

该命令会根据你当前的Ubuntu版本下载对应的内核代码。

如果这个命令没报错，说明一切顺利，只要等待下载完成就行了。

Ubuntu内核代码下载完成之后，默认为master分支。该分支通常并不是精确对应到我们当前运行的Ubuntu版本，所以我们要切换分支。


