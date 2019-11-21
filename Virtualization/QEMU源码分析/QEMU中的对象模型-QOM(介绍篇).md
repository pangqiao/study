
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [概述](#概述)
- [为什么QEMU中要实现对象模型](#为什么qemu中要实现对象模型)
  - [各种架构CPU的模拟和实现](#各种架构cpu的模拟和实现)
  - [模拟device与bus的关系](#模拟device与bus的关系)
- [QOM模型的数据结构](#qom模型的数据结构)
- [参考](#参考)

<!-- /code_chunk_output -->

# 概述

QEMU提供了一套面向对象编程的模型——QOM，即QEMU Object Module，几乎所有的设备如CPU、内存、总线等都是利用这一面向对象的模型来实现的。QOM模型的实现代码位于**qom/文件夹**下的文件中。

# 为什么QEMU中要实现对象模型

## 各种架构CPU的模拟和实现

QEMU中要实现对各种CPU架构的模拟，而且对于一种架构的CPU，比如X86\_64架构的CPU，由于包含的特性不同，也会有**不同的CPU模型**。

任何CPU中都有**CPU通用的属性**，同时也包含各自特有的属性。

为了便于模拟这些CPU模型，面向对象的编程模型是必不可少的。

## 模拟device与bus的关系

在**主板**上，**一个device！！！** 会通过**bus！！！** 与**其他的device！！！** 相连接，**一个device**上可以通过**不同的bus端口**连接到**其他的device**，而其他的device也可以进一步通过bus与其他的设备连接，同时一个bus上也可以连接多个device，这种**device连bus**、**bus连device的关系**，qemu是需要模拟出来的。

为了方便模拟设备的这种特性，面向对象的编程模型也是必不可少的。

# QOM模型的数据结构

这些数据结构中TypeImpl定义在**qom/object.c**中，**ObjectClass**、**Object**、**TypeInfo**定义在include/qom/object.h中。 

在include/qom/object.h的注释中，对它们的每个字段都有比较明确的说明，并且说明了QOM模型的用法。 

```c
struct TypeImpl
{
    const char *name;

    size_t class_size;  /*该数据类型所代表的类的大小*/

    size_t instance_size;  /*该数据类型产生的对象的大小*/

    /*类的 Constructor & Destructor*/
    void (*class_init)(ObjectClass *klass, void *data);
    void (*class_base_init)(ObjectClass *klass, void *data);
    void (*class_finalize)(ObjectClass *klass, void *data);

    void *class_data;

    /*实例的Contructor & Destructor*/
    void (*instance_init)(Object *obj);
    void (*instance_post_init)(Object *obj);
    void (*instance_finalize)(Object *obj);

    bool abstract;  /*表示类是否是抽象类*/

    const char *parent;  /*父类的名字*/
    TypeImpl *parent_type;  /*指向父类TypeImpl的指针*/

    ObjectClass *class;  /*该类型对应的类的指针*/

    int num_interfaces;  /*所实现的接口的数量*/
    InterfaceImpl interfaces[MAX_INTERFACES];
};
其中InterfaceImpl的定义如下，只是一个类型的名字
struct InterfaceImpl
{
    const char *typename;
};
```




# 参考

https://blog.csdn.net/u011364612/article/details/53485856