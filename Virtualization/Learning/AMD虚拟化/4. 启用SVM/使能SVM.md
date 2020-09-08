Enabling SVM


The VMRUN, VMLOAD, VMSAVE, CLGI, VMMCALL, and INVLPGA instructions can be used when the EFER.SVME is set to 1; otherwise, these instructions generate a #UD exception. The SKINIT and STGI instructions can be used when either the EFER.SVME bit is set to 1 or the feature flag CPUID Fn8000_0001_ECX[SKINIT] is set to 1; otherwise, these instructions generate a #UD exception.
Before enabling SVM, software should detect whether SVM can be enabled using the following algorithm:
if (CPUID Fn8000_0001_ECX[SVM] == 0) return SVM_NOT_AVAIL;
if (VM_CR.SVMDIS == 0) return SVM_ALLOWED;
if (CPUID Fn8000_000A_EDX[SVML]==0)
return SVM_DISABLED_AT_BIOS_NOT_UNLOCKABLE
// the user must change a platform firmware setting to enable SVM
else return SVM_DISABLED_WITH_KEY;
// SVMLock may be unlockable; consult platform firmware or TPM to obtain the
key.
For more information on using the CPUID instruction to obtain processor capability information, see Section 3.3, “Processor Feature Identification,” on page 63.


当`EFER.SVME`设置为1时，可以使用**VMRUN**，**VMLOAD**，**VMSAVE**，**CLGI**，**VMMCALL**和**INVLPGA**指令。否则，这些指令会产生`#UD`异常。

当`EFER.SVME`位**设置为1**或功能标志CPUID `Fn8000_0001_ECX[SKINIT]`设**置为1**时，可以使用`SKINIT`和`STGI`指令。否则，这些指令会产生`#UD`异常。

在启用SVM之前，软件要使用以下算法检测是否可以启用SVM：

```cpp
if (CPUID Fn8000_0001_ECX[SVM] == 0)
    return SVM_NOT_AVAIL;

if (VM_CR.SVMDIS == 0) 
    return SVM_ALLOWED;
if (CPUID Fn8000_000A_EDX[SVML]==0)
    return SVM_DISABLED_AT_BIOS_NOT_UNLOCKABLE
    // the user must change a platform firmware setting to enable SVM
else return SVM_DISABLED_WITH_KEY;
    // SVMLock may be unlockable; consult platform firmware or TPM to obtain the key.
```

有关使用CPUID指令获取处理器功能信息的更多信息，请参见第63页，第3.3节“处理器功能标识”。