绑核场景，pvspinlock有一定开销，同时pause指令导致vm exit也会带来一定开销。

透传了HLT和PAUSE指令，能减少相应的vm exit开销。

[Question] About the behavior of HLT in VMX guest mode: https://www.spinics.net/lists/kvm/msg146319.html




kvm: better MWAIT emulation for guests
* v1: https://lkml.org/lkml/2017/3/9/799
* v2: 
* v3: https://www.mail-archive.com/linux-kernel@vger.kernel.org/msg1353006.html
* v4: 
* v5: https://patchwork.kernel.org/project/kvm/patch/1489612895-12799-1-git-send-email-mst@redhat.com/
* v6: https://patchwork.kernel.org/project/kvm/patch/1491911135-216950-1-git-send-email-agraf@suse.de/



提供了idea, 未被合入

KVM: Tie MWAIT/HLT/PAUSE interception to initially disabled capabilities
    * KVM: Don't enable MWAIT in guest by default
    * KVM: Add capability to not exit on HLT
    * KVM: Add capability to not exit on PAUSE
- v1: https://www.spinics.net/lists/kvm/msg159356.html
- v2: 


透传了MWAIT、HLT和PAUSE指令

[PATCH 1/3] KVM: X86: Provides userspace with a capability to not intercept MWAIT
[PATCH 2/3] KVM: X86: Provides userspace with a capability to not intercept HLT
[PATCH 3/3] KVM: X86: Provides userspace with a capability to not intercept PAUSE

v1: https://www.spinics.net/lists/kvm/msg165281.html
v2(最终合入的): https://lkml.org/lkml/2018/3/12/359

对patch的补充

* KVM: Documentation: Add disable pause exits to KVM_CAP_X86_DISABLE_EXITS
* KVM: X86: Provide a capability to disable cstate msr read intercepts
* KVM: X86: Emulate MSR_IA32_MISC_ENABLE MWAIT bit

https://patchwork.kernel.org/project/kvm/patch/1558418814-6822-1-git-send-email-wanpengli@tencent.com/