例如

```cpp
static const struct x86_cpu_id vmx_cpu_id[] = {
    X86_FEATURE_MATCH(X86_FEATURE_VMX),
    {}
};
MODULE_DEVICE_TABLE(x86cpu, vmx_cpu_id);
```


