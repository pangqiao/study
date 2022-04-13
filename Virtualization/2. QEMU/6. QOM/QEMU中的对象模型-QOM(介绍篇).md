
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [概述](#概述)
- [为什么QEMU中要实现对象模型](#为什么qemu中要实现对象模型)
  - [各种架构CPU的模拟和实现](#各种架构cpu的模拟和实现)
  - [模拟device与bus的关系](#模拟device与bus的关系)
- [QOM模型的数据结构](#qom模型的数据结构)
  - [TypeImpl: 对数据类型的抽象数据结构](#typeimpl对数据类型的抽象数据结构)
  - [ObjectClass: 是所有类的基类](#objectclass-是所有类的基类)
  - [Object: 是所有对象的base Object](#object-是所有对象的base-object)
  - [TypeInfo](#typeinfo)
- [怎样使用QOM模型创建新类型](#怎样使用qom模型创建新类型)
- [参考](#参考)

<!-- /code_chunk_output -->

# 概述

QEMU提供了一套面向对象编程的模型——QOM，即QEMU Object Module，几乎所有的设备如CPU、内存、总线等都是利用这一面向对象的模型来实现的. QOM模型的实现代码位于**qom/文件夹**下的文件中. 

# 为什么QEMU中要实现对象模型

## 各种架构CPU的模拟和实现

QEMU中要实现对各种CPU架构的模拟，而且对于一种架构的CPU，比如X86\_64架构的CPU，由于包含的特性不同，也会有**不同的CPU模型**. 

任何CPU中都有**CPU通用的属性**，同时也包含各自特有的属性. 

为了便于模拟这些CPU模型，面向对象的编程模型是必不可少的. 

## 模拟device与bus的关系

在**主板**上，**一个device！！！** 会通过**bus！！！** 与**其他的device！！！** 相连接，**一个device**上可以通过**不同的bus端口**连接到**其他的device**，而其他的device也可以进一步通过bus与其他的设备连接，同时一个bus上也可以连接多个device，这种**device连bus**、**bus连device的关系**，qemu是需要模拟出来的. 

为了方便模拟设备的这种特性，面向对象的编程模型也是必不可少的. 

# QOM模型的数据结构

这些数据结构中TypeImpl定义在**qom/object.c**中，**ObjectClass**、**Object**、**TypeInfo**定义在include/qom/object.h中.  

在include/qom/object.h的注释中，对它们的每个字段都有比较明确的说明，并且说明了QOM模型的用法.  

## TypeImpl: 对数据类型的抽象数据结构

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

## ObjectClass: 是所有类的基类

```c
typedef struct TypeImpl *Type;

struct ObjectClass
{
    /*< private >*/
    Type type;  /**/
    GSList *interfaces;

    const char *object_cast_cache[OBJECT_CLASS_CAST_CACHE];
    const char *class_cast_cache[OBJECT_CLASS_CAST_CACHE];

    ObjectUnparent *unparent;
};
```

## Object: 是所有对象的base Object

```c
struct Object
{
    /*< private >*/
    ObjectClass *class;
    ObjectFree *free;  /*当对象的引用为0时，清理垃圾的回调函数*/
    GHashTable *properties; /*Hash表记录Object的属性*/
    uint32_t ref;    /*该对象的引用计数*/
    Object *parent;
};
```

## TypeInfo

是用户用来定义一个Type的工具型的数据结构，用户定义了一个TypeInfo，然后调用type_register(TypeInfo )或者type_register_static(TypeInfo )函数，就会生成相应的TypeImpl实例，将这个TypeInfo注册到全局的TypeImpl的hash表中. 

```c
/*TypeInfo的属性与TypeImpl的属性对应，
实际上qemu就是通过用户提供的TypeInfo创建的TypeImpl的对象
*/
struct TypeInfo
{
    const char *name;
    const char *parent;

    size_t instance_size;
    void (*instance_init)(Object *obj);
    void (*instance_post_init)(Object *obj);
    void (*instance_finalize)(Object *obj);

    bool abstract;
    size_t class_size;

    void (*class_init)(ObjectClass *klass, void *data);
    void (*class_base_init)(ObjectClass *klass, void *data);
    void (*class_finalize)(ObjectClass *klass, void *data);
    void *class_data;

    InterfaceInfo *interfaces;
};
```

# 怎样使用QOM模型创建新类型

使用QOM模型**创建新类型**时，需要用到以上的**OjectClass**、**Object**和**TypeInfo**. 

关于QOM的用法，在include/qom/object.h一开始就有一长串的注释，这一长串的注释说明了创建新类型时的各种用法. 我们下面是对这些用法的简要说明. 

1. 从最简单的开始，创建一个最小的type:

```c
#include "qdev.h"

#define TYPE_MY_DEVICE "my-device"

// 用户需要定义新类型的类和对象的数据结构
// 由于不实现父类的虚拟函数，所以直接使用父类的数据结构作为子类的数据结构
// No new virtual functions: we can reuse the typedef for the
// superclass.
typedef DeviceClass MyDeviceClass;
typedef struct MyDevice
{
	DeviceState parent;  //父对象必须是该对象数据结构的第一个属性，以便实现父对象向子对象的cast

	int reg0, reg1, reg2;
} MyDevice;

static const TypeInfo my_device_info = {
	.name = TYPE_MY_DEVICE,
	.parent = TYPE_DEVICE,
	.instance_size = sizeof(MyDevice),  //必须向系统说明对象的大小，以便系统为对象的实例分配内存
};

//向系统中注册这个新类型
static void my_device_register_types(void)
{
	type_register_static(&my_device_info);
}
type_init(my_device_register_types)
```

2. 为了方便编程，对于每个新类型，都会定义由**ObjectClass**动态cast到MyDeviceClass的方法，也会定义由Object动态cast到MyDevice的方法. 以下涉及的函数`OBJECT_GET_CLASS`、`OBJECT_CLASS_CHECK`、`OBJECT_CHECK`都在include/qemu/object.h中定义. 

```c
#define MY_DEVICE_GET_CLASS(obj) \
    OBJECT_GET_CLASS(MyDeviceClass, obj, TYPE_MY_DEVICE)
#define MY_DEVICE_CLASS(klass) \
	OBJECT_CLASS_CHECK(MyDeviceClass, klass, TYPE_MY_DEVICE)
#define MY_DEVICE(obj) \
	OBJECT_CHECK(MyDevice, obj, TYPE_MY_DEVICE)
```

3. 如果我们在定义新类型中，实现了父类的虚拟方法，那么需要定义新的class的初始化函数，并且在TypeInfo数据结构中，给TypeInfo的class\_init字段赋予该初始化函数的函数指针. 

```c
#include "qdev.h"

void my_device_class_init(ObjectClass *klass, void *class_data)
{
	DeviceClass *dc = DEVICE_CLASS(klass);
	dc->reset = my_device_reset;
}

static const TypeInfo my_device_info = {
	.name = TYPE_MY_DEVICE,
	.parent = TYPE_DEVICE,
	.instance_size = sizeof(MyDevice),
	.class_init = my_device_class_init, /*在类初始化时就会调用这个函数，将虚拟函数赋值*/
};
```

4. 当我们需要从一个类创建一个派生类时，如果需要覆盖 类原有的虚拟方法，派生类中，可以增加相关的属性将类原有的虚拟函数指针保存，然后给虚拟函数赋予新的函数指针，保证父类原有的虚拟函数指针不会丢失. 

```c
typedef struct MyState MyState;
  typedef void (*MyDoSomething)(MyState *obj);

  typedef struct MyClass {
      ObjectClass parent_class;

      MyDoSomething do_something;
  } MyClass;

  static void my_do_something(MyState *obj)
  {
      // do something
  }

  static void my_class_init(ObjectClass *oc, void *data)
  {
      MyClass *mc = MY_CLASS(oc);

      mc->do_something = my_do_something;
  }

  static const TypeInfo my_type_info = {
      .name = TYPE_MY,
      .parent = TYPE_OBJECT,
      .instance_size = sizeof(MyState),
      .class_size = sizeof(MyClass),
      .class_init = my_class_init,
  };

  typedef struct DerivedClass {
      MyClass parent_class;

      MyDoSomething parent_do_something;
  } DerivedClass;

  static void derived_do_something(MyState *obj)
  {
      DerivedClass *dc = DERIVED_GET_CLASS(obj);

      // do something here
      dc->parent_do_something(obj);
      // do something else here
  }

  static void derived_class_init(ObjectClass *oc, void *data)
  {
      MyClass *mc = MY_CLASS(oc);
      DerivedClass *dc = DERIVED_CLASS(oc);

      dc->parent_do_something = mc->do_something;
      mc->do_something = derived_do_something;
  }

  static const TypeInfo derived_type_info = {
      .name = TYPE_DERIVED,
      .parent = TYPE_MY,
      .class_size = sizeof(DerivedClass),
      .class_init = derived_class_init,
  };
```




# 参考

https://blog.csdn.net/u011364612/article/details/53485856