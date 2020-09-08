
virtual machine monitor (VMM), 也被称为 hypervisor, 是软件, 能够控制多个guest运行在一个物理机上执行.

`host` 代指VMM的执行上下文.

`World switch`代指host和guest的切换.

从本质上讲, VMM通过 intercepting (拦截)和 emulating(模拟)方式工作的.