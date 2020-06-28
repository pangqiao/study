cat /sys/module/kvm_intel/parameters/preemption_timer

一、什么是Preemption Timer

Preemption Timer是一种可以周期性使VM触发VMEXIT的一种机制。即设置了Preemption Timer之后，可以使得虚拟机在指定的TSC cycle之后产生一次VMEXIT并设置对应的exit_reason，trap到VMM中。该机制很少被社区的开发者使用，甚至连Linux KVM部分代码中连该部分的处理函数都没有，只是定义了相关的宏（这些宏还是在nested virtualization中使用的）。

使用Preemption Timer时需要注意下面两个问题：
在旧版本的Intel CPU中Preemption Timer是不精确的。在Intel的设计中，Preemption Timer应该是严格和TSC保持一致，但是在Haswell之前的处理器并不能严格保持一致。
Preemption Timer只有在VCPU进入到Guest时（即进入non-root mode）才会开始工作，在VCPU进入VMM时或者VCPU被调度出CPU时，其值都不会有变化。

二、如何使用Preemption Timer

Preemption Timer在VMCS中有三个域需要设置：
Pin-Based VM-Execution Controls，Bit 6，“Activate VMX preemption timer”： 该位如果设置为1，则打开Preemption Timer；如果为0，则下面两个域的设置均无效。该位在Kernel代码中对应的宏为PIN_BASED_VMX_PREEMPTION_TIMER。
VM-Exit Controls，Bit 22，”Save VMX preemption timer value“： 如果该位设置为1，则在每次VMEXIT的时候都会将已经消耗过的value存在VMCS中；如果设置为0，则在每次VMEXIT之后，Preemption Value都会被设置成初始值。该位在Kernel代码中对应的宏为VM_EXIT_SAVE_VMX_PREEMPTION_TIMER。
VMX-preemption timer value：这个域是VMCS中的一个域，存储Preemption Value。这是一个32bit的域，设置的值是每次VMENTER时的值，在VM运行的过程中逐渐减少。如果设置了Save VMXpreemption timer value，那么在退出时会更新该域为新的值，可以根据两次的差来计算虚拟机运行的多少个TSC cycle。在Kernel对用的宏为VMX_PREEMPTION_TIMER_VALUE。
和Preemption Timer相关的文档参见Intel Manual 3C卷 [1]，25.5.1和26.6.4，以及全文搜索"Preemption Timer"得到的相关内容。

在使用时，需要首先设置Activate VMX preemption timer和VMX-preemption timer value，如果需要VMEXIT时保存preemption value的话，需要设置Save VMX preemption timer value，这样在VM因为其他原因退出的时候不会重置preemption value。

Preemption Timer一个可能的使用环境是：需要让VM定期的产生VMEXIT，那么上述三个域都需要设置。注意：在由Preemption Timer Time-out产生的VMEXIT中，是需要重置VMX preemption timer value的。

Preemption Timer相关的的VMEXIT reason号是52，参考Intel Manual 3C Table C-1 [1]，"VMX-preemption timer expired. The preemption timer counted down to zero"。


三、Preemption Timer count down频率的计算

Preemption Timer频率的计算可以参考Intel Manual 3C [1]的"25.5.1 VMX-Preemption Timer"，在这里我给出一个简单的算法，首先明确如下几个名词：
PTTR（Preemption Timer TSC Rate）：在MSR IA32_VMX_MISC的后五位中，存储着一个5 bit的数据，代表着Preemption Timer TSC Rate。该rate表示TSC count down多少次会导致Preemption Timer Value count down一次，所以我成为“Rate”。
PTV（Preemption Timer Value）：在VMCS的VMX-preemption timer value域中设置的值
CPI（Cycle Per Instruction）：每个CPU指令需要消耗的CPU周期。在Intel架构中的Ideal CPI大约是0.25 [2]，但是在一般的应用中都会比这个值大一些。（注：CPI小于1的原因是多发射和超流水线结构）。
IPP（Instructions per Preemption）：Preemption Timer从开始设置到产生相关的VMEXIT时，VCPU执行了多少条CPU指令。
在这里我给出一个简单的计算方法：

IPP = PTV * PTTR / CPI

根据上述公式，可以简单的计算PTV和IPP之间的关系，根据每个Preemption中执行的指令数目来决定设置多大的Preemption Timer Value。
————————————————
版权声明：本文为CSDN博主「yzt356」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/xelatex_kvm/article/details/17761415