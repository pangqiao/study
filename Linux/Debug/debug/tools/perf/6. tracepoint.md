
# 用途

在内核的 tracepoint 中可以插入 hook function ，以追踪内核的执行流。

Perf 将 tracepoint 作为性能事件

module:function

# 使用方法

1. 使用perflist 查看当前系统支持的tracepoint
2. `perf top/record/stat –e module:function <other optiions>`

# 例子

统计程序使用的系统调用数:

```
./perf stat -e raw_syscalls:sys_enter ls
```

![2020-07-20-15-32-45.png](./images/2020-07-20-15-32-45.png)

ls 在执行期间共调用了 161 次系统调用