
# 数据结构

## SVM 结构体

```cpp
// arch/x86/include/asm/svm.h
struct vmcb {
        struct vmcb_control_area control;
        u8 reserved_control[1024 - sizeof(struct vmcb_control_area)];
        struct vmcb_save_area save;
} __packed;
```

* `struct vmcb_control_area control`: 各种控制位
* `u8 reserved_control[1024 - sizeof(struct vmcb_control_area)]`: 1024字节的大小限制
* `struct vmcb_save_area save`: 保存guest状态

## 控制区域

```cpp
// arch/x86/include/asm/svm.h
struct __attribute__ ((__packed__)) vmcb_control_area {
        u32 intercepts[MAX_INTERCEPT];
        u32 reserved_1[15 - MAX_INTERCEPT];
        u16 pause_filter_thresh;
        u16 pause_filter_count;
        u64 iopm_base_pa;
        u64 msrpm_base_pa;
        u64 tsc_offset;
        u32 asid;
        u8 tlb_ctl;
        u8 reserved_2[3];
        u32 int_ctl;
        u32 int_vector;
        u32 int_state;
        u8 reserved_3[4];
        u32 exit_code;
        u32 exit_code_hi;
        u64 exit_info_1;
        u64 exit_info_2;
        u32 exit_int_info;
        u32 exit_int_info_err;
        u64 nested_ctl;
        u64 avic_vapic_bar;
        u8 reserved_4[8];
        u32 event_inj;
        u32 event_inj_err;
        u64 nested_cr3;
        u64 virt_ext;
        u32 clean;
        u32 reserved_5;
        u64 next_rip;
        u8 insn_len;
        u8 insn_bytes[15];
        u64 avic_backing_page;  /* Offset 0xe0 */
        u8 reserved_6[8];       /* Offset 0xe8 */
        u64 avic_logical_id;    /* Offset 0xf0 */
        u64 avic_physical_id;   /* Offset 0xf8 */
};
```