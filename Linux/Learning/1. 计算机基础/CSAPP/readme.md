
# 书籍介绍

《Computer System A Programmer's Perspective》

本质上并不是操作系统书籍, 它会让你对整个计算机系统有一个组织体系上的认识. CMU导论的教材.

中文名《深入理解计算机系统》, 是汇编+计组+操作系统+计网等的一个大杂烩。它不会在某一个知识点给你非常深入的讲解。

介绍: https://www.zhihu.com/question/20402534/answer/1670374116

英文原著高于翻译版本. 英文版本和中文版本对着这读

## homework

书上的练习题一定要配合着阅读做完。课本自带了练习题的答案，当然除此之外还有家庭作业，大家可以根据自己的能力，选做一些家庭作业的题。

《CSAPP》（第三版）答案合集: https://blog.csdn.net/swy_swy_swy/article/details/105313825

附件有家庭作业答案.

练习题大家一定要好好做。这个是帮助大家理解书本知识最好的方法，csapp里面的练习题设计的都非常好。做练习题的时候就会知道自己哪几个知识点不熟悉，然后回头再看，在独立完成练习题，效果是最好的，

## 实验实践

这本书的精华我个人觉得就在于cmu精心设计的几个实验。如果大家能认真做完这些实验，真的会收获非常多，不仅是对计算机知识的提示，对于编程能力，debug能力，动手能力都有非常大的帮助。

下面简单介绍一下这几个实验。

* dadaLab, 要求大家用限制好的位运算完成它要求的操作
* bombLab, 要求大家根据提示阅读汇编代码，输入对应的正确输入拆掉炸弹，如果输入错误炸弹就会爆炸整个实验就会失败。这个实验的整体设定和难度安排都非常有意思，强烈建议大家必做 
* attackLab, 要求大家利用缓冲区溢出，来进行攻击模拟当黑客的感觉，同时可以学会如何预防这些攻击手段
* cacheLab, 要求大家模拟实现一个cache和对矩阵转置进行优化，如何能够写出一个满分的代码，非常有挑战性
* shellLab, 要求大家实现一个简易的shell程序。这个实验需要考虑信号并发会出现的一些问题。
* mallocLab需要大家实现一个malloc程序。帮助大家理解内存分配和管理
* proxyLab要求写一个支持HTML的多线程Server。可以帮助熟悉Unix网络编程与多线程的控制与同步。

可以去cmu的官网下载和实现这些实验: http://csapp.cs.cmu.edu/3e/labs.html

csapp全8个实验的记录: https://www.zhihu.com/column/c_1325107476128473088

# 课程

## CMU

CMU的经典课程: https://www.bilibili.com/video/BV1iW411d7hd, 注意看评论中信息

课件: http://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/schedule.html

## 南京大学

计算机系统基础

这门课的教材就是csapp的压缩改良本土化版本。不过它的架构是用的IA-32

课程链接: https://www.icourse163.org/course/NJU-1001625001

课程实验: https://nju-projectn.github.io/ics-pa-gitbook/ics2019/

## 上交

计算机组成与系统结构

课程: https://www.icourse163.org/course/SJTU-1206676848

相应的csapp学习网站, 有slides和homework: https://ipads.se.sjtu.edu.cn/courses/ics/schedule.shtml