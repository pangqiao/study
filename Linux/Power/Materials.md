蜗窝科技: http://www.wowotech.net/sort/pm_subsystem

Linux电源管理子系统: https://www.cnblogs.com/LoyenWang/category/1528950.html


CPU电源管理pstate cstate: https://www.cnblogs.com/hugetong/p/12176618.html

pstate: https://huataihuang.gitbooks.io/cloud-atlas/content/os/linux/kernel/cpu/intel_pstate.html

turbo boost, pstate cstate: https://huataihuang.gitbooks.io/cloud-atlas/content/os/linux/kernel/cpu/intel_turbo_boost_and_pstate.html

nohz_full: https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/performance_tuning_guide/sect-red_hat_enterprise_linux-performance_tuning_guide-cpu-configuration_suggestions

无滴答内核: https://www.thinbug.com/q/1265020

Linux 3.10完全无滴嗒特性详解: https://blog.csdn.net/yiyeguzhou100/article/details/50748373

nohz_full 提供一种动态的无时钟设置,在内核"CONFIG_NO_HZ_FULL=y"的前提下, 指定哪些CPU核心可以进入完全无滴答状态. 配置了CONFIG_NO_HZ_FULL=y后, 当cpu上只有一个任务在跑的时候, 不发送调度时钟中断到此cpu也就是减少调度时钟中断, 不中断空闲CPU, 从而可以减少耗电量和减少系统抖动. 默认情况下所有的cpu都不会进入这种模式, 需要通过nohz_full参数指定那些cpu进入这种模式. 

Intel Turbo Boost技术和intel_pstate: https://huataihuang.gitbooks.io/cloud-atlas/content/os/linux/kernel/cpu/intel_turbo_boost_and_pstate.html