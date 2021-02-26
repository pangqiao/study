

官方文档: `Documentation/dev-tools/kselftest.rst`

```
yum install libcap-devel -y

yum install libmount-devel -y

yum install libcap-ng-devel -y

yum install libmnl-devel -y



```


`tools/testing/selftests/kvm`

make O=/tmp/kselftest TARGETS=kvm kselftest

make -C tools/testing/selftests TARGETS=kvm

make -C tools/testing/selftests TARGETS=kvm run_tests

make -C tools/testing/selftests TARGETS=kvm O=/tmp/kselftest run_tests

```
# selftests: kvm: cr4_cpuid_sync_test
ok 1 selftests: kvm: cr4_cpuid_sync_test
# selftests: kvm: evmcs_test
ok 2 selftests: kvm: evmcs_test
# selftests: kvm: get_cpuid_test
ok 3 selftests: kvm: get_cpuid_test
# selftests: kvm: hyperv_cpuid
ok 4 selftests: kvm: hyperv_cpuid
# selftests: kvm: kvm_pv_test
# testing msr: MSR_KVM_SYSTEM_TIME (0x12)
# testing msr: MSR_KVM_SYSTEM_TIME_NEW (0x4b564d01)
# testing msr: MSR_KVM_WALL_CLOCK (0x11)
# testing msr: MSR_KVM_WALL_CLOCK_NEW (0x4b564d00)
# testing msr: MSR_KVM_ASYNC_PF_EN (0x4b564d02)
# testing msr: MSR_KVM_STEAL_TIME (0x4b564d03)
# testing msr: MSR_KVM_PV_EOI_EN (0x4b564d04)
# testing msr: MSR_KVM_POLL_CONTROL (0x4b564d05)
# testing msr: MSR_KVM_ASYNC_PF_INT (0x4b564d06)
# testing msr: MSR_KVM_ASYNC_PF_ACK (0x4b564d07)
# testing hcall: KVM_HC_KICK_CPU (5)
# testing hcall: KVM_HC_SEND_IPI (10)
# testing hcall: KVM_HC_SCHED_YIELD (11)
ok 5 selftests: kvm: kvm_pv_test
# selftests: kvm: mmio_warning_test
# Unrestricted guest must be disabled, skipping test
ok 6 selftests: kvm: mmio_warning_test # SKIP
# selftests: kvm: platform_info_test
ok 7 selftests: kvm: platform_info_test
# selftests: kvm: set_sregs_test
ok 8 selftests: kvm: set_sregs_test
# selftests: kvm: smm_test
ok 9 selftests: kvm: smm_test
# selftests: kvm: state_test
ok 10 selftests: kvm: state_test
# selftests: kvm: vmx_preemption_timer_test
# Stage 2: L1 PT expiry TSC (3203883728) , L1 TSC deadline (3203711168)
# Stage 2: L2 PT expiry TSC (3203752774) , L2 TSC deadline (3203772704)
ok 11 selftests: kvm: vmx_preemption_timer_test
# selftests: kvm: svm_vmcall_test
# nested SVM not enabled, skipping test
ok 12 selftests: kvm: svm_vmcall_test # SKIP
# selftests: kvm: sync_regs_test
ok 13 selftests: kvm: sync_regs_test
# selftests: kvm: userspace_msr_exit_test
# To run the instruction emulated tests set the module parameter 'kvm.force_emulation_prefix=1'
ok 14 selftests: kvm: userspace_msr_exit_test
# selftests: kvm: vmx_apic_access_test
ok 15 selftests: kvm: vmx_apic_access_test
# selftests: kvm: vmx_close_while_nested_test
ok 16 selftests: kvm: vmx_close_while_nested_test
# selftests: kvm: vmx_dirty_log_test
ok 17 selftests: kvm: vmx_dirty_log_test
# selftests: kvm: vmx_set_nested_state_test
ok 18 selftests: kvm: vmx_set_nested_state_test
# selftests: kvm: vmx_tsc_adjust_test
# IA32_TSC_ADJUST is -4294972682 (-1 * TSC_ADJUST_VALUE + -5386).
# IA32_TSC_ADJUST is -4294972682 (-1 * TSC_ADJUST_VALUE + -5386).
# IA32_TSC_ADJUST is -8589944490 (-2 * TSC_ADJUST_VALUE + -9898).
# IA32_TSC_ADJUST is -8589944490 (-2 * TSC_ADJUST_VALUE + -9898).
ok 19 selftests: kvm: vmx_tsc_adjust_test
# selftests: kvm: xapic_ipi_test
# Halter vCPU thread started
# vCPU thread running vCPU 0
# Halter vCPU thread reported its APIC ID: 0 after 1 seconds.
# IPI sender vCPU thread started. Letting vCPUs run for 3 seconds.
# vCPU thread running vCPU 1
# Test successful after running for 3 seconds.
# Sending vCPU sent 252652 IPIs to halting vCPU
# Halting vCPU halted 252652 times, woke 252651 times, received 252651 IPIs.
# Halter APIC ID=0
# Sender ICR value=0xa5 ICR2 value=0
# Halter TPR=0 PPR=0 LVR=0x50014
# Migrations attempted: 0
# Migrations completed: 0
ok 20 selftests: kvm: xapic_ipi_test
# selftests: kvm: xss_msr_test
ok 21 selftests: kvm: xss_msr_test
# selftests: kvm: debug_regs
ok 22 selftests: kvm: debug_regs
# selftests: kvm: tsc_msrs_test
ok 23 selftests: kvm: tsc_msrs_test
# selftests: kvm: vmx_pmu_msrs_test
ok 24 selftests: kvm: vmx_pmu_msrs_test
# selftests: kvm: xen_shinfo_test
ok 25 selftests: kvm: xen_shinfo_test
# selftests: kvm: xen_vmcall_test
ok 26 selftests: kvm: xen_vmcall_test
# selftests: kvm: demand_paging_test
# Testing guest mode: PA-bits:ANY, VA-bits:48,  4K pages
# guest physical test memory offset: 0xfffbffff000
# Finished creating vCPUs and starting uffd threads
# Started all vCPUs
# All vCPU threads joined
# Total guest execution time: 3.512797457s
# Overall demand paging rate: 32252.069411 pgs/sec
ok 27 selftests: kvm: demand_paging_test
# selftests: kvm: dirty_log_test
# Test iterations: 32, interval: 10 (ms)
# Testing Log Mode 'dirty-log'
# Testing guest mode: PA-bits:ANY, VA-bits:48,  4K pages
# guest physical test memory offset: 0xfffbfffc000
# Dirtied 1024 pages
# Total bits checked: dirty (82798), clear (8043759), track_next (16209)
# Testing Log Mode 'clear-log'
# Testing guest mode: PA-bits:ANY, VA-bits:48,  4K pages
# guest physical test memory offset: 0xfffbfffc000
# Dirtied 1024 pages
# Total bits checked: dirty (310374), clear (7816183), track_next (2263)
# Testing Log Mode 'dirty-ring'
# Testing guest mode: PA-bits:ANY, VA-bits:48,  4K pages
# guest physical test memory offset: 0xfffbfffc000
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 1 collected 787 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 2 collected 31907 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 3 collected 706 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 4 collected 605 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 5 collected 594 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 6 collected 594 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 7 collected 597 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 8 collected 593 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 9 collected 603 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 10 collected 601 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 11 collected 603 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 12 collected 597 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 13 collected 605 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 14 collected 601 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 15 collected 606 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 16 collected 608 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 17 collected 604 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 18 collected 601 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 19 collected 605 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 20 collected 607 pages
# Notifying vcpu to continue
# vcpu stops because vcpu is kicked out...
# vcpu continues now.
# Iteration 21 collected 206 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 22 collected 604 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 23 collected 609 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 24 collected 604 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 25 collected 606 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 26 collected 607 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 27 collected 607 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 28 collected 600 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 29 collected 605 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 30 collected 609 pages
# vcpu stops because vcpu is kicked out...
# Notifying vcpu to continue
# vcpu continues now.
# Iteration 31 collected 610 pages
# vcpu stops because dirty ring is full...
# vcpu continues now.
# Dirtied 32768 pages
# Total bits checked: dirty (49891), clear (8076666), track_next (1787)
ok 28 selftests: kvm: dirty_log_test
# selftests: kvm: dirty_log_perf_test
# Test iterations: 2
# Testing guest mode: PA-bits:ANY, VA-bits:48,  4K pages
# guest physical test memory offset: 0xfffbffff000
# Populate memory time: 3.617061946s
# Enabling dirty logging time: 0.000198858s
#
# Iteration 1 dirty memory time: 1.000660899s
# Iteration 1 get dirty log time: 0.000061152s
# Iteration 1 clear dirty log time: 0.034312797s
# Iteration 2 dirty memory time: 0.088427035s
# Iteration 2 get dirty log time: 0.000008981s
# Iteration 2 clear dirty log time: 0.034301493s
# Disabling dirty logging time: 0.050827172s
# Get dirty log over 2 iterations took 0.000070133s. (Avg 0.000035066s/iteration)
# Clear dirty log over 2 iterations took 0.068614290s. (Avg 0.034307145s/iteration)
ok 29 selftests: kvm: dirty_log_perf_test
# selftests: kvm: kvm_create_max_vcpus
# KVM_CAP_MAX_VCPU_ID: 1023
# KVM_CAP_MAX_VCPUS: 288
# Testing creating 288 vCPUs, with IDs 0...287.
# Testing creating 288 vCPUs, with IDs 735...1022.
ok 30 selftests: kvm: kvm_create_max_vcpus
# selftests: kvm: memslot_modification_stress_test
# Testing guest mode: PA-bits:ANY, VA-bits:48,  4K pages
# guest physical test memory offset: 0xfffbffff000
# Finished creating vCPUs
# Started all vCPUs
# All vCPU threads joined
ok 31 selftests: kvm: memslot_modification_stress_test
# selftests: kvm: set_memory_region_test
# Testing KVM_RUN with zero added memory regions
# Allowed number of memory slots: 32764
# Adding slots 0..32763, each memory region with 2048K size
# Testing MOVE of in-use region, 10 loops
# Testing DELETE of in-use region, 10 loops
ok 32 selftests: kvm: set_memory_region_test
# selftests: kvm: steal_time
ok 33 selftests: kvm: steal_time
make[1]: Leaving directory '/data/build/linux/tools/testing/selftests/kvm'
make: Leaving directory '/data/build/linux/tools/testing/selftests'
```
