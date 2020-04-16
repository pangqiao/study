

call、ret指令，本质上还是汇编『跳转指令』，它们都用于修改IP，或同时修改CS和IP；这两个指令经常被用来实现子程序的设计

call和ret指令都是转移指令，它们都修改IP，或同时修改CS和IP。它们经常被共同用来实现子程序的设计。

# 1. call指令

当执行**call指令**时，进行两步操作：

1）将**当前的IP**或**CS和IP**压入栈中

2）转移

call指令**不能实现短转移**，它的书写格式同**jmp指令**

依据标号进行转移的call指令

语法格式：call 标号

汇编解释：(1) push IP (2) jmp near ptr 标号

依据目的地址在指令中的call指令

语法格式：call far ptr 标号

汇编解释：(1) push CS (2) push IP (3) jmp far ptr 标号

转移地址在寄存器中的call指令

语法格式：call 16位reg

汇编解释：(1) push IP (2) jmp 16位reg

转移地址在内存中的call指令

语法格式一：call word ptr 内存单元地址

汇编解释一：(1) push IP (2) jmp word ptr 内存单元地址

语法格式二：call dword ptr 内存单元地址

汇编解释二：(1) push CS (2) push IP (3) jmp dword ptr 内存单元地址

# 2. ret指令和retf指令

- **ret指令**用栈中的数据，修改**IP**的内容，从而实现**近转移**
- **retf**指令用栈的数据，修改**CS和IP**的内容，从而实现**远转移**

CPU执行**ret指令**时，相当于进行：

```
pop IP
```
CPU执行**retf指令**时，相当于进行：

```
pop IP
pop CS
```

