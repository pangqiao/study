https://blog.packagecloud.io/how-to-extract-and-disassmble-a-linux-kernel-image-vmlinuz/

通过 extract-vmlinux 脚本进行

可以获取最新的

```
wget -O extract-vmlinux https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/scripts/extract-vmlinux
```

也可以安装

```
sudo apt-get install linux-headers-$(uname -r)
```

decompress and extrac 