
# 简介

要使用 KGDB 来调试内核，首先需要修改 config 配置文件，打开相应的配置，配置内核启动参数，甚至修改串口驱动添加 poll 支持，然后才能通过串口远程调试内核。

# 配置内核

## 基本配置

在内核配置文件 `.config` 中，需要打开如下选项：

配置项 | 说明
------- | -------
CONFIG_KGDB | 加入KGDB支持
CONFIG_KGDB_SERIAL_CONSOLE | 使KGDB通过串口与主机通信(打开这个选项，默认会打开CONFIG_CONSOLE_POLL和CONFIG_MAGIC_SYSRQ)
CONFIG_KGDB_KDB | 加入KDB支持
CONFIG_DEBUG_KERNEL | 包含驱动调试信息
CONFIG_DEBUG_INFO | 使内核包含基本调试信息
CONFIG_DEBUG_RODATA=n | 关闭这个，能在只读区域设置断点

## 可选选项

配置项 | 说明
------- | -------
CONFIG_PANIC_TIMEOUT=5 |  
CONFIG_BOOTPARAM_SOFTLOCKUP_PANIC_VALUE=1 |  
CONFIG_BOOTPARAM_HUNG_TASK_PANIC_VALUE=1 |  
CONFIG_S3C2410_WATCHDOG_ATBOOT=0 |  
CONFIG_FRAME_POINTER | 使KDB能够打印更多的栈信息
CONFIG_KALLSYMS | 加入符号信息
CONFIG_KDB_KEYBOARD | 如果是通过目标版的键盘与KDB通信，需要把这个打开，且键盘不能是USB接口
CONFIG_KGDB_TESTS |  


# 参考

https://tinylab.org/kgdb-debugging-kernel/