
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [所有CPU的基类](#所有cpu的基类)
  - [CPUClass](#cpuclass)
  - [CPUState](#cpustate)
- [参考](#参考)

<!-- /code_chunk_output -->

CPU也是一种设备，因此CPU类继承自Device类. CPU这种设备相比其他设备来说种类非常繁杂. 首先，CPU有着不同的架构，而对于每一种架构的CPU来说，随着时间的推移，CPU厂商也会给该架构的CPU不断地增加新特性和更新换代，这种更新换代造成该架构的CPU也有了各种不同的CPU模型. 

以x86 CPU为例，QEMU中可以支持的CPU的模型就包括以下几种，我们可以通过qemu-system-x86_64 \-cpu \?命令查看QEMU支持的X86 CPU类型. 其中一些CPU模型是QEMU自己定义的，另外一些类型则是直接来自厂商. 其中host类型是指将物理机上的CPU特性全部暴露给虚拟机，这样可以全面发挥CPU的性能，但是另一方面，由于全部特性被暴露给虚拟机，会造成具有不同特性的CPU架构或CPU模型的物理机之间动态迁移虚拟机会变得不可靠. 

如此众多的CPU架构、CPU模型，而**CPU架构**、**CPU模型**天然具有**父类和子类的关系**. 使用面向对象编程模型对它们进行设计是再合适不过了. 但是目前对于X86CPU中不同的CPU模型(其他的架构没有仔细看)，QEMU只是使用一个描述X86CPU定义的数据结构的数组来表示的. QEMU的代码注释中说明，**未来**要将**所有的CPU模型**最终定义为**X86CPU的子类**. 

```
x86           qemu64  QEMU Virtual CPU version 2.5+
x86           phenom  AMD Phenom(tm) 9550 Quad-Core Processor
x86         core2duo  Intel(R) Core(TM)2 Duo CPU     T7700  @ 2.40GHz
x86            kvm64  Common KVM processor
x86           qemu32  QEMU Virtual CPU version 2.5+
x86            kvm32  Common 32-bit KVM processor
x86          coreduo  Genuine Intel(R) CPU           T2600  @ 2.16GHz
x86              486
x86          pentium
x86         pentium2
x86         pentium3
x86           athlon  QEMU Virtual CPU version 2.5+
x86             n270  Intel(R) Atom(TM) CPU N270   @ 1.60GHz
x86           Conroe  Intel Celeron_4x0 (Conroe/Merom Class Core 2)
x86           Penryn  Intel Core 2 Duo P9xxx (Penryn Class Core 2)
x86          Nehalem  Intel Core i7 9xx (Nehalem Class Core i7)
x86         Westmere  Westmere E56xx/L56xx/X56xx (Nehalem-C)
x86      SandyBridge  Intel Xeon E312xx (Sandy Bridge)
x86        IvyBridge  Intel Xeon E3-12xx v2 (Ivy Bridge)
x86    Haswell-noTSX  Intel Core Processor (Haswell, no TSX)
x86          Haswell  Intel Core Processor (Haswell)
x86  Broadwell-noTSX  Intel Core Processor (Broadwell, no TSX)
x86        Broadwell  Intel Core Processor (Broadwell)
x86       Opteron_G1  AMD Opteron 240 (Gen 1 Class Opteron)
x86       Opteron_G2  AMD Opteron 22xx (Gen 2 Class Opteron)
x86       Opteron_G3  AMD Opteron 23xx (Gen 3 Class Opteron)
x86       Opteron_G4  AMD Opteron 62xx class CPU
x86       Opteron_G5  AMD Opteron 63xx class CPU
x86             host  KVM processor with all supported host features (only available in KVM mode)
```

# 所有CPU的基类

要定义所有CPU的基类，需要定义CPU的类的数据结构和CPU的对象的数据结构，然后给对应的TypeInfo中的函数指针赋值即可. 

其中**CPU类的数据结构**名为**CPUClass**、**CPU对象**的数据结构名为**CPUState**，它们被定义在include/qom/cpu.h中，而**对应的TypeInfo的赋值工作**则在**qom/cpu.c**中进行. 

这里只说明CPUClass、CPUState数据结构. 

## CPUClass

CPUClass的数据结构如下，其中最主要的内容，是与CPU相关的大量的回调函数，通过给这些回调函数的指针赋值，**对应的CPUState**就可以**调用这些函数**实现相应的功能. 

```c
typedef struct CPUClass {
    /*< private >*/
    DeviceClass parent_class;   //父类是Device类
    /*< public >*/

    //回调函数
    ObjectClass *(*class_by_name)(const char *cpu_model);
    void (*parse_features)(CPUState *cpu, char *str, Error **errp);

    void (*reset)(CPUState *cpu);
    int reset_dump_flags;
    bool (*has_work)(CPUState *cpu);
    void (*do_interrupt)(CPUState *cpu);
    CPUUnassignedAccess do_unassigned_access;
    void (*do_unaligned_access)(CPUState *cpu, vaddr addr,
                                int is_write, int is_user, uintptr_t retaddr);
    bool (*virtio_is_big_endian)(CPUState *cpu);
    int (*memory_rw_debug)(CPUState *cpu, vaddr addr,
                           uint8_t *buf, int len, bool is_write);
    void (*dump_state)(CPUState *cpu, FILE *f, fprintf_function cpu_fprintf,
                       int flags);
    void (*dump_statistics)(CPUState *cpu, FILE *f,
                            fprintf_function cpu_fprintf, int flags);
    int64_t (*get_arch_id)(CPUState *cpu);
    bool (*get_paging_enabled)(const CPUState *cpu);
    void (*get_memory_mapping)(CPUState *cpu, MemoryMappingList *list,
                               Error **errp);
    void (*set_pc)(CPUState *cpu, vaddr value);
    void (*synchronize_from_tb)(CPUState *cpu, struct TranslationBlock *tb); //该函数与tcg相关，不必看
    int (*handle_mmu_fault)(CPUState *cpu, vaddr address, int rw,
                            int mmu_index);
    hwaddr (*get_phys_page_debug)(CPUState *cpu, vaddr addr);
    int (*gdb_read_register)(CPUState *cpu, uint8_t *buf, int reg);
    int (*gdb_write_register)(CPUState *cpu, uint8_t *buf, int reg);
    void (*debug_excp_handler)(CPUState *cpu);

    int (*write_elf64_note)(WriteCoreDumpFunction f, CPUState *cpu,
                            int cpuid, void *opaque);
    int (*write_elf64_qemunote)(WriteCoreDumpFunction f, CPUState *cpu,
                                void *opaque);
    int (*write_elf32_note)(WriteCoreDumpFunction f, CPUState *cpu,
                            int cpuid, void *opaque);
    int (*write_elf32_qemunote)(WriteCoreDumpFunction f, CPUState *cpu,
                                void *opaque);

    const struct VMStateDescription *vmsd;  //该数据结构记录CPU中的重要数据，在热迁移过程中对CPU重要数据进行传输
    int gdb_num_core_regs;
    const char *gdb_core_xml_file;
    bool gdb_stop_before_watchpoint;

    void (*cpu_exec_enter)(CPUState *cpu);
    void (*cpu_exec_exit)(CPUState *cpu);
    bool (*cpu_exec_interrupt)(CPUState *cpu, int interrupt_request);

    void (*disas_set_info)(CPUState *cpu, disassemble_info *info);
} CPUClass;
```

## CPUState

CPUState是**CPU对象**的数据结构，**一个CPUState**就表示**一个虚拟机的CPU**. 在QEMU中，任何CPU的操作的大部分都是对以CPUState形式出现的CPU来进行的. 

```c
struct CPUState {
    /*< private >*/
    DeviceState parent_obj;    //继承自Device对象
    /*< public >*/

    int nr_cores;             //CPU的核数
    int nr_threads;           //CPU每核的线程数
    int numa_node;            //CPU有几个numa node

    struct QemuThread *thread;   //该CPU对应的线程
#ifdef _WIN32
    HANDLE hThread;
#endif
    int thread_id;               //线程id
    uint32_t host_tid;
    bool running;               //CPU是否正在运行
    struct QemuCond *halt_cond;   //cpu停止运行所使用的条件变量，用于通知该CPU
    bool thread_kicked;          
    bool created;      
    bool stop;
    bool stopped;
    bool crash_occurred;
    bool exit_request;        
    uint32_t interrupt_request;
    int singlestep_enabled;
    int64_t icount_extra;
    sigjmp_buf jmp_env;

    QemuMutex work_mutex;
    struct qemu_work_item *queued_work_first, *queued_work_last;

    //CPU对应的地址空间
    CPUAddressSpace *cpu_ases;
    AddressSpace *as;

    //这个数据结构保存该CPU的段寄存器、FPU等信息，x86对应的数据结构是CPUX86State，读者可在target-i386/cpu.h中看到
    void *env_ptr; /* CPUArchState */

    //以下变量与TCG相关，不必看    
    struct TranslationBlock *current_tb;
    struct TranslationBlock *tb_jmp_cache[TB_JMP_CACHE_SIZE];

    //用于调试的变量
    struct GDBRegisterState *gdb_regs;
    int gdb_num_regs;
    int gdb_num_g_regs;
    QTAILQ_ENTRY(CPUState) node;

    /* ice debug support */
    QTAILQ_HEAD(breakpoints_head, CPUBreakpoint) breakpoints;

    QTAILQ_HEAD(watchpoints_head, CPUWatchpoint) watchpoints;
    CPUWatchpoint *watchpoint_hit;

    void *opaque;

    /* In order to avoid passing too many arguments to the MMIO helpers,
     * we store some rarely used information in the CPU context.
     */
    uintptr_t mem_io_pc;
    vaddr mem_io_vaddr;

    //与kvm相关的变量
    int kvm_fd;    //kvm在创建CPU时，给每个CPU分配eventfd，该变量用于保存这个文件描述符
    bool kvm_vcpu_dirty;
    struct KVMState *kvm_state;
    struct kvm_run *kvm_run;
    /* TODO Move common fields from CPUArchState here. */
    int cpu_index; /* used by alpha TCG */
    uint32_t halted; /* used by alpha, cris, ppc TCG */
    union {
        uint32_t u32;
        icount_decr_u16 u16;
    } icount_decr;
    uint32_t can_do_io;
    int32_t exception_index; /* used by m68k TCG */

    /* Used to keep track of an outstanding cpu throttle thread for migration
     * autoconverge
     */
    bool throttle_thread_scheduled;  //跟踪CPU运行，当热迁移时可以自动减慢CPU运行速度，保证热迁移顺利完成. 

    /* Note that this is accessed at the start of every TB via a negative
       offset from AREG0.  Leave this field at the end so as to make the
       (absolute value) offset as small as possible.  This reduces code
       size, especially for hosts without large memory offsets.  */
    uint32_t tcg_exit_req;
};
```



# 参考

https://blog.csdn.net/u011364612/article/details/53559178