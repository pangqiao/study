# Summary

* 设备模型
  * 设备类型注册
  * 设备类型初始化
  * 设备实例化
  * DeviceClass实例化细节
  * 面向对象的设备模型
  * 接口
  * 类型、对象和接口之间的转换
  * PCDIMM
    * PCDIMM类型
    * PCDIMM实例
    * 插入系统
    * 创建ACPI表
    * NVDIMM
* 地址空间
  * 从初始化开始
  * MemoryRegion
  * AddressSpace Part1
  * FlatView
  * RAMBlock
  * AddressSpace Part2](address_space/06-AddressSpace2.md)
  * [眼见为实](address_space/07-witness.md)
  * [添加MemoryRegion](address_space/08-commit_mr.md)
* [APIC](apic/00-advance_interrupt_controller.md)
  * [纯Qemu模拟](apic/01-qemu_emulate.md)
  * [Qemu/kernel混合模拟](apic/02-qemu_kernel_emulate.md)
  * [APICV](apic/03-apicv.md)
* [Live Migration](lm/00-lm.md)
  * [从用法说起](lm/01-migrate_command_line.md)
  * [整体架构](lm/02-infrastructure.md)
  * [VMStateDescription](lm/03-vmsd.md)
  * [内存热迁移](lm/04-ram_migration.md)
  * [postcopy](lm/05-postcopy.md)
* [FW_CFG](fw_cfg/00-qmeu_bios_guest.md)
  * [规范解读](fw_cfg/01-spec.md)
  * [Linux Guest](fw_cfg/02-linux_guest.md)
  * [SeaBios](fw_cfg/03-seabios.md)
* [Machine](machine/00-mt.md)
  * [MachineType](machine/01-machine_type.md)
  * [PCMachine](machine/02-pc_machine.md)
* [CPU](cpu/00-vcpu.md)
  * [TYPE_CPU](cpu/01-type_cpu.md)
  * [X86_CPU](cpu/02-x86_cpu.md)
* [MemoryBackend](memory_backend/00-memory_backend.md)
  * [MemoryBackend类层次结构](memory_backend/01-class_hierarchy.md)
  * [MemoryBackend初始化流程](memory_backend/02-init_flow.md)
