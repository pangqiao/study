
# 概述

先看doc.

`Documentation/admin-guide/mm/memory-hotplug.rst`

# hot add

# hot remove

然后要想remove, 逻辑上是先offline(drivers/base/memory.c的memory_subsys_offline), 再remove(mm/memory_hotplug.c的remove_memory调用).

## offline

```cpp
memory_subsys_offline()
 ├─ struct memory_block mem= to_memory_block(dev);          // memory dev转换成 memory_block
 ├─ memory_block_change_state(mem, MEM_OFFLINE, MEM_ONLINE);   // 从online转换成offline
 |   └─ memory_block_action();
 |       ├─ nr_pages = PAGES_PER_SECTION * sections_per_block;  // 获取这个block包含的页数
 |       ├─ start_pfn = section_nr_to_pfn();                   // 获取起始pfn  
 |       └─ offline_pages(start_pfn, nr_pages);
 |           └─ __offline_pages(start_pfn, start_pfn + nr_pages);
 |               ├─ mem_hotplug_begin();
 |               ├─ walk_system_ram_range();    // memory blocks有hole(空洞)则不允许offline
 |               ├─ test_pages_in_a_zone(start_pfn, end_pfn);    // 所有页面必须在同一个zone
 |               ├─ node = zone_to_nid(zone);    // 获取node id
 |               ├─ start_isolate_page_range();    // 
 |               ├─ node_states_check_changes_offline();    // 
 |               ├─ memory_notify(MEM_GOING_OFFLINE, &arg);    // 
 |               ├─ notify_to_errno();    // 
 |               ├─ do {    // 
 |               ├─ while(ret);    // 
 |               └─ mem_hotplug_done();
 ├─ module_call_init(MODULE_INIT_MACHINE)
 ├─ switch(popt->index) case QEMU_OPTION_XXX // 解析 QEMU 参数
 ├─ socket_init()
 ├─ os_daemonize()
 ├─ configure_accelerator()                  // 启用 KVM 加速支持
 |   └─ kvm_init()                           // 【1】创建 KVM 虚拟机并获取对应的 fd
 |       ├─ kvm_ioctl(KVM_GET_API_VERSION)   // 检查 KVM API 版本
 |       ├─ kvm_ioctl(KVM_CREATE_VM)         // 创建虚拟机，并获取 vmfd
 |       ├─ kvm_check_extension()            // 与kvm交互, 检查特性支持
 |       ├─ kvm_arch_init()
 |       |   ├─ kvm_check_extension()        // 与kvm交互, 架构相关特性检查
 |       |   ├─ kvm_vm_ioctl(s, KVM_SET_IDENTITY_MAP_ADDR, &identity_base);        // 与kvm交互, 架构相关特性检查
 |       |   ├─ kvm_vm_ioctl(s, KVM_SET_TSS_ADDR, identity_base + 0x1000);        // 与kvm交互, 架构相关特性检查
 |       |   ├─ e820_add_entry(identity_base, 0x4000, E820_RESERVED);        // 
 |       ├─ kvm_irqchip_create()             // 创建中断管理
 |       |   ├─ kvm_check_extension(s, KVM_CAP_IRQCHIP)        // 检查irqchip功能
 |       |   ├─ kvm_vm_ioctl(s, KVM_CREATE_IRQCHIP);        // 与kvm交互, 架构相关特性检查
 |       └─ memory_listener_register(&kvm_memory_listener) // 注册 kvm_memory_listener
```

`Documentation/admin-guide/mm/memory-hotplug.rst`

`/sys/devices/system/memory/block_size_bytes`这个值好像是16进制大小?

https://blog.51cto.com/weiguozhihui/1568258