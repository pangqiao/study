
```
  4)               |  handle_ept_misconfig [kvm_intel]() {
  4)               |    kvm_io_bus_write [kvm]() {
  4)               |      __kvm_io_bus_write [kvm]() {
  4)               |        kvm_io_bus_get_first_dev [kvm]() {
  4)   0.269 us    |          kvm_io_bus_sort_cmp [kvm]();
  4)   1.134 us    |        }
  4)               |        ioeventfd_write [kvm]() {
  4)               |          eventfd_signal() {
  4)   0.322 us    |            _raw_spin_lock_irqsave();
  4)               |            __wake_up_locked_key() {
  4)               |              __wake_up_common() {
  4)               |                pollwake() {
  4)               |                  default_wake_function() {
  4)               |                    try_to_wake_up() {
  4)   0.276 us    |                      _raw_spin_lock_irqsave();
  4)               |                      select_task_rq_fair() {
  4)   0.340 us    |                        available_idle_cpu();
  4)   0.667 us    |                      }
  4)               |                      ttwu_queue_wakelist() {
  4)               |                        __smp_call_single_queue() {
  4)   0.538 us    |                          send_call_function_single_ipi();
  4)   0.927 us    |                        }
  4)   1.274 us    |                      }
  4)   0.111 us    |                      _raw_spin_unlock_irqrestore();
  4)   3.466 us    |                    }
  4)   3.876 us    |                  }
  4)   4.087 us    |                }
  4)   4.885 us    |              }
  4)   5.155 us    |            }
  4)   0.283 us    |            _raw_spin_unlock_irqrestore();
  4)   6.175 us    |          }
  4)   6.528 us    |        }
  4)   8.876 us    |      }
  4)   9.626 us    |    }
  4)               |    kvm_skip_emulated_instruction [kvm]() {
  4)   0.126 us    |      vmx_get_rflags [kvm_intel]();
  4)               |      vmx_skip_emulated_instruction [kvm_intel]() {
  4)               |        skip_emulated_instruction [kvm_intel]() {
  4)   0.107 us    |          vmx_cache_reg [kvm_intel]();
  4)   0.105 us    |          vmx_set_interrupt_shadow [kvm_intel]();
  4)   0.583 us    |        }
  4)   0.782 us    |      }
  4)   1.396 us    |    }
  4) + 12.841 us   |  }
```
