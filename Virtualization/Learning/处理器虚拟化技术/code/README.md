书籍相关网址: http://www.mouseos.com/books/vt/source.html

简介:
    《处理器虚拟化技术》一书的内容围绕 VMX（Virtual-Machine Extensions） 架构展开讲解，它是 Intel® VT-x 技术的实现。注意，本书并不涉及 AMD-v 方面的任何知识，将来有机会时，我会在网站另外补充关于 AMD-v 方面的篇章。
    全书共分为7章，篇章虽然不多，但份量不轻！吸引了前作的经验，书的整体结构也比前作要好得多，可读性也增强了。
 
感悟:
    通过学习 Intel® VT-x 技术的 VMX 架构知识，让我自己对整个 x86/x64 体系有了更深入的了解！可以这样说，不了解 VMX 架构，就不能深入了解 x86/x64 体系！因为，在处理器的虚拟化技术里需要使有全方位的体系知识，对处理器在非常细节上地方进行虚拟化处理！
    编写本书比《x86/x64探索及编程》用了更多的时间，其中许多时间花在编码方面。虽然比较累，也挺辛苦，但是值得的！
目录:
    点击 这里 查看完整的目录。
例子清单:
    示例1-1：建立一个空项目，测试基础平台
    示例1-2：使用调试记录功能观察信息
    示例2-1：列举出其中一个处理器VMX提供的能力信息
    示例3-1：使用 guest与host相同的环境，测试 guest
    示例4-1：观察注入事件下，单步调试与数据断点#DB的delivery
    示例4-2：VMM利用MTF对guest进行单步调试
    示例5-1：测试无条件与有条件产生VM-exit的CPUID与RDTSC指令
    示例5-2：测试优先级高于VM-exit的异常
    示例6-1：使用实模式的guest，并启用EPT机制
    示例7-1：实现对SYSENTER指令的监控
    示例7-2：实现guest的任务切换
    示例7-3：使用EPT机制实现local APIC虚拟化
    示例7-4：拦截INT指令，并帮助guest完成中断delivery
    示例7-5：实现外部中断转发，处理CPU1 guest的键盘中断
编译代码：
    所有的例子都可以编译为 32 位或者 64 位！
    如果不需要编译 guest 端代码，则使用下面的命令行选项：
•	build：编译为 32 位模块
•	build -D__X64：编译为 64 位模块
    如果编译 guest 端代码，则使用下面的命令行选项：
•	build -DGUEST_ENABLE：host 与 guest 端都为 32 位模块
•	build -DGUEST_ENABLE -D__X64：host 端为 64 位模块，guest 端为 32 位模块
•	build -DGUEST_ENABLE -D__X64 -DGUEST_X64：host 与 guest 端都为 64 位模块


源码及工具下载:
文件	描述	下载
sources.rar	包括了本书所有章节的完整源码以及工具(已关闭)	点击下载
x86-II.rar	修正 bug 的版本, 只开放下载这个版本(x86版本)	点击下载

源码修正说明:
书籍编写时，是基于第1代core I5的CPU M520处理器上，原代码在这个处理器上正常运行的。由于读者反映在较新CPU的 vmware 运行错误! 经检查测试，原版本的源码存在 page 方面的设计 bug。新版本的代码将修正这个错误，并将部分代码进行修改!!
使用源码时，必要时请根据书上的说明，使用 build 工具重新编译书中例子
注意：x64 代码还没修正,　请暂时不要使用 -D__X64 参数为 64 位代码，请等待修正 x64 代码, 我会尽快处理 x64 的 bug!!!
由此对读者朋友们造成了困扰, 在此，我感到万分抱歉!

源码包使用说明:

•	将 sources.rar 解压后，有下面的目录：
1.	common 目录：存放所有例子共用的代码。包括：boot.asm，setup.asm，proteced.asm 以及 long.asm
2.	inc 目录：存放各个模块的头文件。
3.	lib 目录：存放代码使用的库代码。包括：crt.asm, crt64.asm, page32.asm, page64.asm 等等，以及 VMX, Guest 模块代码
4.	chapXX 目录：从 chap01 到 chap07 共 7 个目录。它们下面还有若干子目录，存放相对应章节下的例子，例如：chap01\ex1-1 目录代表第1章的例子1
•	在例子代码目录里（例如 chap04\ex4-1\），一般有下面的文件：
1.	build.bat 文件：这是编译工具（DOS批处理文件），用来编译源码。
2.	bs 文件：这是 bochs 2.6.2 使用的配置文件（如果因 bochs 版本不同而不能使用，请自行检查 bochs 的版本或者读者自行配置）。
3.	c.img 文件：这是硬盘映像文件，大小为 1M，可以在 bochs 里启动；或者直接将它写入 U 盘（从0扇区开始写），在真实机器里启动
4.	config.txt 文件：这是 merge 工具使用的配置文件（写入映像文件的配置）
5.	demo.img 文件：这是软盘映像文件，大小为1.44M，可以在 bochs 和 vmware 里启动使用。
6.	ex.asm 文件：这是例子的主体源代码文件（它将嵌在 common\protected.asm 或者 common\long.asm 文件内）。
7.	ex.inc 文件：它是 ex.asm 文件的头文件（有些例子不存在）。

编译代码：
    所有的例子都可以编译为 32 位或者 64 位，使用 build 工具！
    如果不需要编译 guest 端代码，则使用下面的命令行选项：
•	build：编译为 32 位模块
•	build -D__X64：编译为 64 位模块
    如果编译 guest 端代码，则使用下面的命令行选项：
•	build -DGUEST_ENABLE：host 与 guest 端都为 32 位模块
•	build -DGUEST_ENABLE -D__X64：host 端为 64 位模块，guest 端为 32 位模块
•	build -DGUEST_ENABLE -D__X64 -DGUEST_X64：host 与 guest 端都为 64 位模块

