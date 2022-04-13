
ACPI Table 与 Windows 的关系， 犹如 Device Tree 与 embedded-Linux 的关系. 

ACPI SPEC定义了`ACPI-compatible OS`与**BIOS**之间的**接口**，**ACPI Tables就是BIOS提供给OS的硬件配置数据**，包括系统硬件的电源管理和配置管理. 

BIOS在**POST过程**中，将RSDP存在0xE0000--0xFFFFF的内存空间中，然后Move RSDT/XSDT, FADT, DSDT到ACPI Recleam Area, Move FACS到ACPI NVS Area，最后填好表的Entry链接和Checksum. 

控制权交给OS之后，由OS来开启ACPI Mode，首先在内存中搜寻ACPI Table，然后写ACPI_Enable到SMI_CMD，SCI_EN也会被HW置起来. 

ACPI Tables根据存储的位置，可以分为: 

1).  RSDP位于F段，用于OSPM搜索ACPI Table，RSDP可以定位其他所有ACPI Table

2).  FACS位于ACPI NVS内存，用于系统进行S3保存的恢复指针，内存为NV Store

3). 剩下所有ACPI Table都位于ACPI Reclaim内存，进入OS后，内存可以释放

ACPI Table根据版本又分为1.0B，2.0，3.0，4.0. 

2.0以后，支持了64-bit的地址空间，因此几个重要的Table会不大一样，比如: RSDP，RSDT，FADT，FACS. 简单的列举一下不同版本的ACPI Table: 

1) ACPI 1.0B: RSDP1，RSDT，FADT1，FACS1，DSDT，MADT，SSDT，HPET，MCFG等

2) ACPI 3.0 : RSDP3，RSDT，XSDT，FADT3，FACS3，DSDT，MADT，HPET，MCFG，SSDT等

以系统支持ACPI3.0为例子，说明系统中ACPI table之间的关系如图: 

