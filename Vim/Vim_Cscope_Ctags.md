转载自 http://easwy.com/blog/archives/vim-cscope-ctags/

接下来，就可以在vim里读代码了。

不过在使用过程中，发现无法找到C\+\+的类、函数定义、调用关系。仔细阅读了cscope的手册后发现，原来cscope在产生索引文件时，只搜索类型为C, lex和yacc的文件(后缀名为.c, .h, .l, .y)，C++的文件根本没有生成索引。不过按照手册上的说明，cscope支持c\+\+和Java语言的文件。

于是按照cscope手册上提供的方法，先产生一个文件列表，然后让cscope为这个列表中的每个文件都生成索引。

为了方便使用，编写了下面的脚本来更新cscope和ctags的索引文件：

```
#!/bin/sh

find . -name "*.h" -o -name "*.c" -o -name "*.cc" > cscope.files
cscope -bkq -i cscope.files
ctags -R
```

- 首先使用find命令，查找当前目录及子目录中所有后缀名为”.h”, “.c”和”.cc”的文件，并把查找结果重定向到文件cscope.files中。

- 然后cscope根据cscope.files中的所有文件，生成符号索引文件。

- 最后一条命令使用ctags命令，生成一个tags文件，在vim中执行”:help tags”命令查询它的用法。它可以和cscope一起使用。

目前只能在unix系列操作系统下使用cscope，虽然也有windows版本的cscope，不过还有很多bug。

cscope的主页在：http://cscope.sourceforge.net/

在vim的网站上，有很多和cscope相关的插件，可以去找一下你有没有所感兴趣的。