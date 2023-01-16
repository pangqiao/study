
linux线程私有数据 --- TSD池

# 背景

**进程内**的**所有线程共享进程的数据空间**，所以**全局变量**为**所有线程共有**。

在某些场景下，**线程**需要保存自己的**全局变量私有数据**，这种特殊的变量仅在线程内部有效。

如常见的 errno，它返回标准的错误码。errno 不应该是一个局部变量。几乎每个函数都应该可以访问他，但他又不能作为是一个全局变量。否则在一个线程里输出的很可能是另一个线程的出错信息.

这时可以**创建线程私有数据**(`Thread-specific Data`, TSD) 来解决。在线程内部，私有数据可以被线程的各个接口访问，但**对其他线程屏蔽**。

# 原理

线程私有数据采用了**一键多值**技术，即一个key对应多个值。访问数据都是通过键值来访问的，好像是对一个变量进行访问，其实是在访问不同的数据。

使用线程私有数据时，需要对**每个线程**创建一个**关联 的key**，linux中主要有四个接口来实现：

1. `pthread_key_create`: 创建一个键

> https://blog.csdn.net/qixiang2013/article/details/126126112

```cpp
int pthread_key_create(pthread_key_t *key, void (*destr_function) (void*));
```

首先从 linux 的 TSD 池中分配一项，然后将其值赋给 key 供以后访问使用。接口的第一个参数是指向参数的指针，第二参数是函数指针，如果该指针不为空，那么在线程执行完毕退出时，已 key 指向的内容为入参调用 `destr_function()`, 释放分配的缓冲区以及其他数据。

key 被创建之后，因为是**全局变量**，所以**所有的线程**都可以访问。**各个线程**可以根据需求往 key 中，**填入不同的值**，这就相当于提供了一个**同名而值不同**的**全局变量**，即一键多值.

一键多值依靠的一个结构体数组，即

```cpp
static struct pthread_key_struct pthread_keys[PTHREAD_KEYS_MAX] ={{0,NULL}};
```

`PTHREAD_KEYS_MAX` 值为 1024

`pthread_key_struct` 的定义为：

```cpp
struct pthread_key_struct
{
  /* Sequence numbers.  Even numbers indicated vacant entries.  Note
     that zero is even.  We use uintptr_t to not require padding on
     32- and 64-bit machines.  On 64-bit machines it helps to avoid
     wrapping, too.  */
  uintptr_t seq;

  /* Destructor for the data.  */
  void (*destr) (void *);
};
```

创建一个 TSD，相当于将结构体数组的某一个元素的 seq 值设置为为“`in_use`”, 并将其索引返回给 `*key`，然后设置 `destr_function()` 为 `destr()`。`pthread_key_create` 创建一个**新的线程**私有数据 key 时，系统会搜索其**所在进程**的 key 结构数组，找出一个未使用的元素，将其索引赋给 `*key`。

2. pthread_setspecific: 为指定键值设置线程私有数据

```cpp
int pthread_setspecific(pthread_key_t key, const void *pointer);
```

该接口将指针 pointer 的值(指针值而非其指向的内容)与 key 相关联，用 pthread_setspecific 为一个键指定新的线程数据时，线程必须释放原有的数据用以回收空间。

3. pthread_getspecific：从指定键读取线程的私有数据

```cpp
void * pthread_getspecific(pthread_key_t key);
```

4. pthread_key_delete：删除一个键

```cpp
void * pthread_getspecific(pthread_key_t key);
```

该接口用于删除一个键，功能仅仅是将该 key在结构体数组pthread_keys对应的元素设置为“un_use”, 与该 key 相关联的线程数据是不会被释放的，因此线程私有数据的释放必须在键删除之前。

# 一般流程

1、创建一个键

2、为一个键设置线程私有数据

3、从一个键读取线程私有数据 `void *pthread_getspecific(pthread_key_t key);`

4、线程退出（退出时，会调用 destructor 释放分配的缓存，参数是 key 所关联的数据）

5、删除一个键




# reference

https://www.cnblogs.com/smarty/p/4046215.html
