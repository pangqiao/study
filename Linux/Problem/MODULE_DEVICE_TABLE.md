
pci_device_id，PCI设备类型的标识符。在include/linux/mod_devicetable.h头文件中定义。

```cpp
// include/linux/mod_devicetable.h
struct pci_device_id {
        __u32 vendor, device;           /* Vendor and device ID or PCI_ANY_ID*/
        __u32 subvendor, subdevice;     /* Subsystem ID's or PCI_ANY_ID */
        __u32 class, class_mask;        /* (class,subclass,prog-if) triplet */
        kernel_ulong_t driver_data;     /* Data private to the driver */
};
```

PCI设备的**vendor**、**device**和**class**的值都是**预先定义**好的，通过这些参数可以**唯一确定设备厂商和设备类型**。这些PCI设备的标准值在`include/linux/pci_ids.h`头文件中定义。

`pci_device_id`需要导出到**用户空间**，使**模块装载系统**在**装载模块**时知道**什么模块**对应**什么硬件设备**。宏`MODULE_DEVICE_TABLE()`完成该工作。

设备id一般用数组形式。如：

```

```

例如

```cpp
static const struct x86_cpu_id vmx_cpu_id[] = {
    X86_FEATURE_MATCH(X86_FEATURE_VMX),
    {}
};
MODULE_DEVICE_TABLE(x86cpu, vmx_cpu_id);
```


# 参考

