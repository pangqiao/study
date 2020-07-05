Kernel Timer Systems: https://elinux.org/Kernel_Timer_Systems

Linux时间子系统: https://www.cnblogs.com/arnoldlu/p/7126290.html

Linux时钟管理: https://www.ibm.com/developerworks/cn/linux/l-cn-timerm/index.html

Linux时间子系统: http://www.wowotech.net/timer_subsystem/time_subsystem_index.html

时间子系统: https://blog.csdn.net/flaoter/article/details/77413163

hrtimer的用例: https://blog.csdn.net/fuyuande/article/details/82193600

Linux Time: http://kernel.meizu.com/linux-time.html

使用: https://blog.csdn.net/qq_37858386/article/details/85784994

https://www.cnblogs.com/suzhou/archive/2013/06/04/3638986.html

操作系统时钟从作用上分为两种: 计时和定时器

硬件方面，x86 主流平台，计时靠tsc，定时靠local apic timer。

软件方面，linux, 低精度，高精度，先低精度然后切换到高精度。
