
IRQ 是 PIC 时代的产物, 由于 ISA 设备通常是连接到固定的 PIC 管脚, 所以说一个设备的 IRQ 实际是指它**连接**的 **PIC 管脚号**. 每个 IRQ 线路都对应一个特定的中断请求, 这样 CPU 可以识别是哪个设备需要它的注意. IRQ 暗示着**中断优先级**, 例如 IRQ 0 比 IRQ 3 有着更高的优先级. 在传统的 x86 系统中, IRQ 是有限的, 通常有 16 个(IRQ0-IRQ15), 这会导致所谓的 IRQ 共享问题, 即多个设备可能需要使用同一个 IRQ. 当前进到 APIC 时代后, 或许是出于习惯, 人们仍习惯用 IRQ 表示一个设备的中断号, 但对于 **16 以下的 IRQ**, 它们可能**不再**与 IOAPIC 的**管脚对应**, 例如 PIT 此时接的是 2 号管脚. 




Pin 是**管脚号**, 通常它表示 **IOAPIC 的管脚**(前面说了, PIC 时代我们用 IRQ). Pin 的最大值受 **IOAPIC 管脚数限制**, 目前取值范围是 `[0, 23]`.

**GSI** 是 ACPI 引入的概念, 全称是 `Global System Interrupt`. 它为系统中**每个中断源**指定一个**唯一的中断号**.

有 3 个 IOAPIC: `IOAPIC 0 ~ 2`.

* IOAPIC0 有 **24** 个**管脚**, 其 `GSI base` 为 0, 每个管脚的 GSI = GSI base + pin, 故 IOAPIC0 的 GSI 范围为 `[0~23]`.

* IOAPIC1 有 16 个管脚, `GSI base` 为 24, **GSI** 范围为 `[24, 39]`, 依次类推.

ACPI 要求 ISA 的 16 个 IRQ 应该被 identify map 到 GSI 的 [0, 15].

**IRQ** 和 GSI 在 APIC 系统中常常被混用, 实际上对 **15 以上的 IRQ**, 它**和 GSI 相等**. 我们在谈到 IRQ 时, 一定要注意它所处的语境.

Vector 是 CPU 的概念, 是中断在 IDT 表中的索引. 每个 IRQ(或 GSI)都对应一个 Vector. 在 PIC 模式下, IRQ 对应的 vector = start vector + IRQ; 在 APIC 模式下, IRQ/GSI 的 vector 由操作系统分配.