Linux下有时候我们需要知道一个进程在做什么，比如说程序不正常的时候，他到底在干吗？最直接的方法就是打印出他所有线程的调用栈，这样我们从栈再配合程序代码就知道程序在干吗了。

Linux下这个工具叫做pstack. 使用方法是

```
# pstack
Usage: pstack <process-id>
```

当然这个**被调查的程序**需要有**符号信息**。 比较雷人的是这个程序竟然是个shell脚本，核心实现是**gdb**的 `thread apply all bt`， 我们可以观摩下他的实现，这个我们做类似的程序提供了一个很好的思路：

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

祝大家玩的开心。