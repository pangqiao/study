
# kernel module存放在哪里

linux自带了很多kernel module文件, 这些文件一般以 .ko 或 .ko.xz 文件结尾,存放在 `/lib/modules/$(uname -r)` 目录中。

```
$ ll /lib/modules/$(uname -r)
total 6328
drwxr-xr-x  5 root root    4096 6月   2 16:11 ./
drwxr-xr-x  5 root root    4096 6月   9 06:24 ../
lrwxrwxrwx  1 root root      40 5月  18 23:44 build -> /usr/src/linux-headers-5.13.0-44-generic/
drwxr-xr-x  2 root root    4096 5月  18 23:44 initrd/
drwxr-xr-x 15 root root    4096 6月   2 16:09 kernel/
-rw-r--r--  1 root root 1490749 6月   2 16:11 modules.alias
-rw-r--r--  1 root root 1461121 6月   2 16:11 modules.alias.bin
-rw-r--r--  1 root root   10124 5月  18 23:44 modules.builtin
-rw-r--r--  1 root root   25802 6月   2 16:11 modules.builtin.alias.bin
-rw-r--r--  1 root root   12611 6月   2 16:11 modules.builtin.bin
-rw-r--r--  1 root root   79337 5月  18 23:44 modules.builtin.modinfo
-rw-r--r--  1 root root  689983 6月   2 16:11 modules.dep
-rw-r--r--  1 root root  949679 6月   2 16:11 modules.dep.bin
-rw-r--r--  1 root root     330 6月   2 16:11 modules.devname
-rw-r--r--  1 root root  238468 5月  18 23:44 modules.order
-rw-r--r--  1 root root    1274 6月   2 16:11 modules.softdep
-rw-r--r--  1 root root  666558 6月   2 16:11 modules.symbols
-rw-r--r--  1 root root  806768 6月   2 16:11 modules.symbols.bin
drwxr-xr-x  3 root root    4096 6月   2 16:09 vdso/
```