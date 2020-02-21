
# pstack的简介

Linux下有时候我们需要知道一个进程在做什么，比如说程序不正常的时候，他到底在干吗？最直接的方法就是打印出他所有线程的调用栈，这样我们从栈再配合程序代码就知道程序在干吗了。

Linux下这个工具叫做pstack. 使用方法是

```
# pstack
Usage: pstack <process-id>
```

# pstack的实现

当然这个**被调查的程序**需要有**符号信息**。 

```bash
#!/bin/sh
 
if test $# -ne 1; then
    echo "Usage: `basename $0 .sh` <process-id>" 1>&2
    exit 1
fi
 
if test ! -r /proc/$1; then
    echo "Process $1 not found." 1>&2
    exit 1
fi
 
# GDB doesn't allow "thread apply all bt" when the process isn't
# threaded; need to peek at the process to determine if that or the
# simpler "bt" should be used.
 
backtrace="bt"
if test -d /proc/$1/task ; then
    # Newer kernel; has a task/ directory.
    if test `/bin/ls /proc/$1/task | /usr/bin/wc -l` -gt 1 2>/dev/null ; then
        backtrace="thread apply all bt"
    fi
elif test -f /proc/$1/maps ; then
    # Older kernel; go by it loading libpthread.
    if /bin/grep -e libpthread /proc/$1/maps > /dev/null 2>&1 ; then
        backtrace="thread apply all bt"
    fi
fi
 
GDB=${GDB:-/usr/bin/gdb}
 
if $GDB -nx --quiet --batch --readnever > /dev/null 2>&1; then
    readnever=--readnever
else
    readnever=
fi
 
# Run GDB, strip out unwanted noise.
$GDB --quiet $readnever -nx /proc/$1/exe $1 <<EOF 2>&1 |
$backtrace
EOF
/bin/sed -n \
    -e 's/^(gdb) //' \
    -e '/^#/p' \
    -e '/^Thread/p'
```

pstack其实是个Shell脚本，核心原理是**GDB**的**thread apply all bt**命令.

基本逻辑是通过**进程号**`process-id`来分析**是否使用了多线程**，同时使用**GDB Attach**到在跑进程上，最后**调用bt子命令**后**简单格式化输出**

# pstack的shell

## 基本命令的使用

* `test -d`，检查目录是否存在
* `test -f`，检查文件是否存在
* `grep -e`，用`grep -q -e`更好一些
* `sed -e s`，sed的替换命令

## Here Document

Here Document也是一种IO重定向，IO结束时会发EOF给GDB。

# pstack里的GDB

GDB的东西内容非常多，这里不展开，pstack里最核心的就是**调用GDB**，**attach到对应进程**，然后**执行bt命令**，如果程序是**多线程**就执行`thread apply all bt`命令，最后quit退出。

附带GDB文档的两个说明，第一个是关于attach的：

>The first thing GDB does after arranging to debug the specified process is to stop it.

看了这个应该就很容易明白为什么不能随便在生产环境中去attach一个正在运行的程序，如果attach上以后待着不动，程序就暂停了。

那为什么用pstack没啥事儿呢，原因是pstack执行了一个GDB的bt子命令后立即退出了，可是源代码里面没有执行quit，它是怎么退出的呢，看这个文档说明：

To exit GDB, use the quit command (abbreviated q), or type an end-of-file character (usually Ctrl-d).

Here Document IO重定向结束的标志是EOF，GDB读到了EOF自动退出了。