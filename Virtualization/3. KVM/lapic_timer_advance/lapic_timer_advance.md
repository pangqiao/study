
guest的lapic是通过host上的hrtimer模拟的，guest的timer到期后，vCPU收到host上hrtimer interrupt(`apic_timer_fn`)，导致 vCPU vmexit，KVM把这个timer interrupt inject给guest，guest里最终感受到了timer fire的interrupt，这个过程比较长，等guest里感受到timer fire的时候，实际已经格外经历了上述虚拟化tax。 社区的advance lapic timer让guest的timer提前到期，这样加上虚拟化层的tax，期望guest感受到timer fire的时间与guest期望的timer到期时间接近。



通过hrtimer来模拟guest中tscdeadline timer，添加一个选项来提前到期，并在VM-entry时自旋忙等它实际的到期时间。

这允许在cyclictest测试（或任何需要严格计时有关计时器到期的情况）中实现低延迟。

注意：这个选项需要动态调整来为特定的硬件/guest组合找到合适的值。 
* 一种方法是衡量`apic_timer_fn`和`VM-entry`之间的平均延迟。
* 另一种方法是从1000ns开始，然后以500ns的增量**增加该值**，直到cyclictest的平均测试数停止减少。(until avg cyclictest numbers stop decreasing.)

```cpp
// 

```




# 社区相关patch

对tscdeadline hrtimer过期动态调整

KVM: x86: add option to advance tscdeadline hrtimer expiration, 涉及三个patch:
* KVM: x86: add method to test PIR bitmap vector 
* d0659d946be05e098883b6955d2764595997f6a4 , KVM: x86: add option to advance tscdeadline hrtimer expiration

相关的maillist如下

* v1: 
* v2: 
* v3: https://www.spinics.net/lists/kvm/msg111674.html
* v4: https://www.spinics.net/lists/kvm/msg111880.html
* v5: https://www.spinics.net/lists/kvm/msg111895.html
* v6: https://lore.kernel.org/kvm/20141223205841.410988818@redhat.com/


