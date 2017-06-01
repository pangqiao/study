# Unix/Linux平台可执行文件格式分析

```
http://www.ibm.com/developerworks/cn/linux/l-excutff/#
```


> 
本文讨论了 UNIX/LINUX 平台下三种主要的可执行文件格式：a.out（assembler and link editor output 汇编器和链接编辑器的输出）、COFF（Common Object File Format 通用对象文件格式）、ELF（Executable and Linking Format 可执行和链接格式）。首先是对可执行文件格式的一个综述，并通过描述 ELF 文件加载过程以揭示可执行文件内容与加载运行操作之间的关系。随后依此讨论了此三种文件格式，并着重讨论 ELF 文件的动态连接机制，其间也穿插了对各种文件格式优缺点的评价。最后对三种可执行文件格式有一个简单总结，并提出作者对可文件格式评价的一些感想。

### 可执行文件格式综述

相对于其它文件类型，可执行文件可能是一个操作系统中最重要的文件类型，因为它们是完成操作的真正执行者。可执行文件的大小、运行速度、资源占用情况以及可扩展性、可移植性等与文件格式的定义和文件加载过程紧密相关。研究可执行文件的格式对编写高性能程序和一些黑客技术的运用都是非常有意义的。

不管何种可执行文件格式，一些基本的要素是必须的，显而易见的，文件中应包含代码和数据。因为文件可能引用外部文件定义的符号（变量和函数），因此重定位信息和符号信息也是需要的。一些辅助信息是可选的，如调试信息、硬件信息等。基本上任意一种可执行文件格式都是按区间保存上述信息，称为段（Segment）或节（Section）。不同的文件格式中段和节的含义可能有细微区别，但根据上下文关系可以很清楚的理解，这不是关键问题。最后，可执行文件通常都有一个文件头部以描述本文件的总体结构。

相对可执行文件有三个重要的概念：编译（compile）、连接（link，也可称为链接、联接）、加载（load）。源程序文件被编译成目标文件，多个目标文件被连接成一个最终的可执行文件，可执行文件被加载到内存中运行。因为本文重点是讨论可执行文件格式，因此加载过程也相对重点讨论。下面是LINUX平台下ELF文件加载过程的一个简单描述。

```
1：内核首先读ELF文件的头部，然后根据头部的数据指示分别读入各种数据结构，找到标记为可加载（loadable）的段，并调用函数 mmap()把段内容加载到内存中。在加载之前，内核把段的标记直接传递给 mmap()，段的标记指示该段在内存中是否可读、可写，可执行。显然，文本段是只读可执行，而数据段是可读可写。这种方式是利用了现代操作系统和处理器对内存的保护功能。著名的Shellcode（ [参考资料17](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources) ）的编写技巧则是突破此保护功能的一个实际例子。

2：内核分析出ELF文件标记为 PT_INTERP 的段中所对应的动态连接器名称，并加载动态连接器。现代 LINUX 系统的动态连接器通常是 /lib/ld-linux.so.2，相关细节在后面有详细描述。

3：内核在新进程的堆栈中设置一些标记-值对，以指示动态连接器的相关操作。

4：内核把控制传递给动态连接器。

5：动态连接器检查程序对外部文件（共享库）的依赖性，并在需要时对其进行加载。

6：动态连接器对程序的外部引用进行重定位，通俗的讲，就是告诉程序其引用的外部变量/函数的地址，此地址位于共享库被加载在内存的区间内。动态连接还有一个延迟（Lazy）定位的特性，即只在"真正"需要引用符号时才重定位，这对提高程序运行效率有极大帮助。

7：动态连接器执行在ELF文件中标记为 .init 的节的代码，进行程序运行的初始化。在早期系统中，初始化代码对应函数 _init(void)(函数名强制固定)，在现代系统中，则对应形式为
void __attribute((constructor))
init_function(void)
{
……
}
其中函数名为任意。

8：动态连接器把控制传递给程序，从 ELF 文件头部中定义的程序进入点开始执行。在 a.out 格式和ELF格式中，程序进入点的值是显式存在的，在 COFF 格式中则是由规范隐含定义。

```

从上面的描述可以看出，加载文件最重要的是完成两件事情：加载程序段和数据段到内存；进行外部定义符号的重定位。重定位是程序连接中一个重要概念。我们知道，一个可执行程序通常是由一个含有 main() 的主程序文件、若干目标文件、若干共享库（Shared Libraries）组成。（注：采用一些特别的技巧，也可编写没有 main 函数的程序，请参阅[参考资料 2](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources)）一个C程序可能引用共享库定义的变量或函数，换句话说就是程序运行时必须知道这些变量/函数的地址。在静态连接中，程序所有需要使用的外部定义都完全包含在可执行程序中，而动态连接则只在可执行文件中设置相关外部定义的一些引用信息，真正的重定位是在程序运行之时。静态连接方式有两个大问题：如果库中变量或函数有任何变化都必须重新编译连接程序；如果多个程序引用同样的变量/函数，则此变量/函数会在文件/内存中出现多次，浪费硬盘/内存空间。比较两种连接方式生成的可执行文件的大小，可以看出有明显的区别。

---

### a.out 文件格式分析

a.out格式在不同的机器平台和不同的Unix操作系统上有轻微的不同，例如在MC680x0平台上有6个section。下面我们讨论的是最“标准”的格式。

a.out文件包含7个section，格式如下：


exec header（执行头部，也可理解为文件头部） | 
---|---
text segment（文本段） |
data segment(数据段) |
text relocations(文本重定位段) |
data relocations(数据重定位段) |
symbol table(符号表) |
string table(字符串表) |

执行头部的数据结构：

```
struct exec {
        unsigned long   a_midmag;    /* 魔数和其它信息 */
        unsigned long   a_text;      /* 文本段的长度 */
        unsigned long   a_data;      /* 数据段的长度 */
        unsigned long   a_bss;       /* BSS段的长度 */
        unsigned long   a_syms;      /* 符号表的长度 */
        unsigned long   a_entry;     /* 程序进入点 */
        unsigned long   a_trsize;    /* 文本重定位表的长度 */
        unsigned long   a_drsize;    /* 数据重定位表的长度 */
};
```

文件头部主要描述了各个 section 的长度，比较重要的字段是 a_entry（程序进入点），代表了系统在加载程序并初试化各种环境后开始执行程序代码的入口。这个字段在后面讨论的 ELF 文件头部中也有出现。由 a.out 格式和头部数据结构我们可以看出，a.out 的格式非常紧凑，只包含了程序运行所必须的信息（文本、数据、BSS），而且每个 section 的顺序是固定的。这种结构缺乏扩展性，如不能包含"现代"可执行文件中常见的调试信息，最初的 UNIX 黑客对 a.out 文件调试使用的工具是 adb，而 adb 是一种机器语言调试器！

a.out 文件中包含符号表和两个重定位表，这三个表的内容在连接目标文件以生成可执行文件时起作用。在最终可执行的 a.out 文件中，这三个表的长度都为 0。a.out 文件在连接时就把所有外部定义包含在可执行程序中，如果从程序设计的角度来看，这是一种硬编码方式，或者可称为模块之间是强藕和的。在后面的讨论中，我们将会具体看到ELF格式和动态连接机制是如何对此进行改进的。

a.out 是早期UNIX系统使用的可执行文件格式，由 AT&T 设计，现在基本上已被 ELF 文件格式代替。a.out 的设计比较简单，但其设计思想明显的被后续的可执行文件格式所继承和发扬。可以参阅 [参考资料 16](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources) 和阅读 [参考资料 15](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources) 源代码加深对 a.out 格式的理解。 [参考资料 12](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources) 讨论了如何在"现代"的红帽LINUX运行 a.out 格式文件。

---

### COFF文件格式分析

COFF 格式比 a.out 格式要复杂一些，最重要的是包含一个节段表(section table)，因此除了 .text，.data，和 .bss 区段以外，还可以包含其它的区段。另外也多了一个可选的头部，不同的操作系统可一对此头部做特定的定义。

COFF 文件格式如下：

File Header(文件头部) | 
---|---
Optional Header(可选文件头部) | 
Section 1 Header(节头部) |
……… |
Section n Header(节头部) |
Raw Data for Section 1(节数据) |
Raw Data for Section n(节数据) |
Relocation Info for Sect. 1(节重定位数据) |
Line Numbers for Sect. 1(节行号数据) |
Line Numbers for Sect. n(节行号数据) |
Symbol table(符号表) | 
String table(字符串表) |

文件头部的数据结构：

```
struct filehdr{
       unsigned short  f_magic;    /* 魔数 */
       unsigned short  f_nscns;    /* 节个数 */
       long            f_timdat;   /* 文件建立时间 */
       long            f_symptr;   /* 符号表相对文件的偏移量 */
       long            f_nsyms;    /* 符号表条目个数 */
       unsigned short  f_opthdr;   /* 可选头部长度 */
       unsigned short  f_flags;    /* 标志 */
   };
```

COFF 文件头部中魔数与其它两种格式的意义不太一样，它是表示针对的机器类型，例如 0x014c 相对于 I386 平台，而 0x268 相对于 Motorola 68000系列等。当 COFF 文件为可执行文件时，字段 f_flags 的值为 F_EXEC（0X00002），同时也表示此文件没有未解析的符号，换句话说，也就是重定位在连接时就已经完成。由此也可以看出，原始的 COFF 格式不支持动态连接。为了解决这个问题以及增加一些新的特性，一些操作系统对 COFF 格式进行了扩展。Microsoft 设计了名为 PE（Portable Executable）的文件格式，主要扩展是在 COFF 文件头部之上增加了一些专用头部，具体细节请参阅 [参考资料 18](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources)，某些 UNIX 系统也对 COFF 格式进行了扩展，如 XCOFF（extended common object file format）格式，支持动态连接，请参阅 [参考资料 5](http://www.ibm.com/developerworks/cn/linux/l-excutff/#resources)。

紧接文件头部的是可选头部，COFF 文件格式规范中规定可选头部的长度可以为 0，但在 LINUX 系统下可选头部是必须存在的。下面是LINUX下可选头部的数据结构：

```
typedef struct 
{
  		char   magic[2];            /* 魔数 */
  		char   vstamp[2];           /* 版本号 */
  		char   tsize[4];            /* 文本段长度 */
  		char   dsize[4];            /* 已初始化数据段长度 */
  		char   bsize[4];            /* 未初始化数据段长度 */
  		char   entry[4];            /* 程序进入点 */
  		char   text_start[4];       /* 文本段基地址 */
  		char   data_start[4];       /* 数据段基地址 */
}
COFF_AOUTHDR;
```

