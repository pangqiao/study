

在 passthrough 两种 PCI 设备时候, 针对 configuration space header 来说

![2023-12-12-21-53-05.png](./images/2023-12-12-21-53-05.png)

对于 type 0 设备:

* 仅仅 command 寄存器(0x4 - 0x5) 和 status 寄存器(0x6 - 0x7) 是透传给 guest 的, 也就是说 guest 只能可读可写这两个物理寄存器, 否则只能访问虚拟寄存器

* 仅仅 command 寄存器(0x4 - 0x5), status 寄存器(0x6 - 0x7) 和 Base Address 寄存器(0x10 - 0x27) 这些是可写的, 也就是

![2023-12-12-21-52-40.png](./images/2023-12-12-21-52-40.png)

对于 type 1 设备:

* 

* 


具体实现类似:

```cpp
struct cfg_header_perm {
	/* For each 4-byte register defined in PCI config space header,
	 * there is one bit dedicated for it in pt_mask and ro_mask.
	 * For example, bit 0 for CFG Vendor ID and Device ID register,
	 * Bit 1 for CFG register Command and Status register, and so on.
	 *
	 * For each mask, only low 16-bits takes effect.
	 *
	 * If bit x is set the pt_mask, it indicates that the corresponding 4 Bytes register
	 * for bit x is pass through to guest. Otherwise, it's virtualized.
	 *
	 * If bit x is set the ro_mask, it indicates that the corresponding 4 Bytes register
	 * for bit x is read-only. Otherwise, it's writable.
	 */
	/* For type 0 device */
	uint32_t type0_pt_mask;
	uint32_t type0_ro_mask;
	/* For type 1 device */
	uint32_t type1_pt_mask;
	uint32_t type1_ro_mask;
};

static const struct cfg_header_perm cfg_hdr_perm = {
	/* Only Command (0x04-0x05) and Status (0x06-0x07) Registers are pass through */
	.type0_pt_mask = 0x0002U,
	/* Command (0x04-0x05) and Status (0x06-0x07) Registers and
	 * Base Address Registers (0x10-0x27) are writable */
	.type0_ro_mask = (uint16_t)~0x03f2U,
	/* Command (0x04-0x05) and Status (0x06-0x07) Registers and
	 * from Primary Bus Number to I/O Base Limit 16 Bits (0x18-0x33)
	 * are pass through
	 */
	.type1_pt_mask = 0x1fc2U,
	/* Command (0x04-0x05) and Status (0x06-0x07) Registers and
	 * Base Address Registers (0x10-0x17) and
	 * Secondary Status (0x1e-0x1f) are writable
	 * Note: should handle I/O Base (0x1c) specially
	 */
	.type1_ro_mask = (uint16_t)~0xb2U,
};

#define PCI_CFG_HEADER_LENGTH 0x40U
#define PCIR_BIOS	      0x30U

/*
 * @pre offset + bytes < PCI_CFG_HEADER_LENGTH
 */
static int32_t read_cfg_header(const struct pci_vdev *vdev,
		uint32_t offset, uint32_t bytes, uint32_t *val)
{
	int32_t ret = 0;
	uint32_t pt_mask;

	if ((offset == PCIR_BIOS) && is_quirk_ptdev(vdev)) {
		/* the access of PCIR_BIOS is emulated for quirk_ptdev */
		ret = -ENODEV;
	} else if (vbar_access(vdev, offset)) {
		/* bar access must be 4 bytes and offset must also be 4 bytes aligned */
		if ((bytes == 4U) && ((offset & 0x3U) == 0U)) {
			*val = pci_vdev_read_vcfg(vdev, offset, bytes);
		} else {
			*val = ~0U;
		}
	} else {
		if (is_bridge(vdev->pdev)) {
			pt_mask = cfg_hdr_perm.type1_pt_mask;
		} else {
			pt_mask = cfg_hdr_perm.type0_pt_mask;
		}

		if (bitmap32_test(((uint16_t)offset) >> 2U, &pt_mask)) {
			*val = pci_pdev_read_cfg(vdev->pdev->bdf, offset, bytes);

			/* MSE(Memory Space Enable) bit always be set for an assigned VF */
			if ((vdev->phyfun != NULL) && (offset == PCIR_COMMAND) &&
					(vdev->vpci != vdev->phyfun->vpci)) {
				*val |= PCIM_CMD_MEMEN;
			}
		} else {
			*val = pci_vdev_read_vcfg(vdev, offset, bytes);
		}
	}
	return ret;
}

/*
 * @pre offset + bytes < PCI_CFG_HEADER_LENGTH
 */
static int32_t write_cfg_header(struct pci_vdev *vdev,
		uint32_t offset, uint32_t bytes, uint32_t val)
{
	bool dev_is_bridge = is_bridge(vdev->pdev);
	int32_t ret = 0;
	uint32_t pt_mask, ro_mask;

	if ((offset == PCIR_BIOS) && is_quirk_ptdev(vdev)) {
		/* the access of PCIR_BIOS is emulated for quirk_ptdev */
		ret = -ENODEV;
	} else if (vbar_access(vdev, offset)) {
		/* bar write access must be 4 bytes and offset must also be 4 bytes aligned */
		if ((bytes == 4U) && ((offset & 0x3U) == 0U)) {
			vdev_pt_write_vbar(vdev, pci_bar_index(offset), val);
		}
	} else {
		if (offset == PCIR_COMMAND) {
#define PCIM_SPACE_EN (PCIM_CMD_PORTEN | PCIM_CMD_MEMEN)
			uint16_t phys_cmd = (uint16_t)pci_pdev_read_cfg(vdev->pdev->bdf, PCIR_COMMAND, 2U);

			if (((phys_cmd & PCIM_SPACE_EN) == 0U) && ((val & PCIM_SPACE_EN) != 0U)) {
				/* check whether need to restore BAR because some kind of reset */
				if (pdev_need_bar_restore(vdev->pdev)) {
					pdev_restore_bar(vdev->pdev);
				}

				/* check whether need to restore bridge mem/IO related registers because some kind of reset */
				if (dev_is_bridge) {
					vdev_bridge_pt_restore_space(vdev);
				}
			}
			/* check whether need to restore Primary/Secondary/Subordinate Bus Number registers because some kind of reset */
			if (dev_is_bridge && ((phys_cmd & PCIM_CMD_BUSEN) == 0U) && ((val & PCIM_CMD_BUSEN) != 0U)) {
				vdev_bridge_pt_restore_bus(vdev);
			}
		}

		if (dev_is_bridge) {
			ro_mask = cfg_hdr_perm.type1_ro_mask;
			pt_mask = cfg_hdr_perm.type1_pt_mask;
		} else {
			ro_mask = cfg_hdr_perm.type0_ro_mask;
			pt_mask = cfg_hdr_perm.type0_pt_mask;
		}

		if (!bitmap32_test(((uint16_t)offset) >> 2U, &ro_mask)) {
			if (bitmap32_test(((uint16_t)offset) >> 2U, &pt_mask)) {
				/* I/O Base (0x1c) and I/O Limit (0x1d) are read-only */
				if (!((offset == PCIR_IO_BASE) && (bytes <= 2)) && (offset != PCIR_IO_LIMIT)) {
					uint32_t value = val;
					if ((offset == PCIR_IO_BASE) && (bytes == 4U)) {
						uint16_t phys_val = (uint16_t)pci_pdev_read_cfg(vdev->pdev->bdf, offset, 2U);
						value = (val & PCIR_SECSTATUS_LINE_MASK) | phys_val;
					}
					pci_pdev_write_cfg(vdev->pdev->bdf, offset, bytes, value);
				}
			} else {
				pci_vdev_write_vcfg(vdev, offset, bytes, val);
			}
		}

		/* According to PCIe Spec, for a RW register bits, If the optional feature
		 * that is associated with the bits is not implemented, the bits are permitted
		 * to be hardwired to 0b. However Zephyr would use INTx Line Register as writable
		 * even this PCI device has no INTx, so emulate INTx Line Register as writable.
		 */
		if (offset == PCIR_INTERRUPT_LINE) {
			pci_vdev_write_vcfg(vdev, offset, bytes, (val & 0xfU));
		}

	}
	return ret;
}
```