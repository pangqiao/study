
# 简介

火焰图（Flame Graph）是由Linux性能优化大师Brendan Gregg发明的，和所有其他的trace和profiling方法不同的是，Flame Graph以一个全局的视野来看待时间分布，它从底部往顶部，列出所有可能的调用栈。

其他的呈现方法，一般只能列出单一的调用栈或者非层次化的时间分布。

## 火焰图示例

以典型的分析CPU时间花费到哪个函数的`on-cpu`火焰图为例来展开。

CPU火焰图中的**每一个方框**是**一个函数**，**方框的长度**，代表了它的**执行时间**，所以越宽的函数，执行越久。火焰图的**楼层每高一层**，就是**更深一级的函数被调用**，**最顶层的函数**，是**叶子函数**。

![2020-02-04-21-54-49.png](./images/2020-02-04-21-54-49.png)

## 生成过程

火焰图的生成过程是：

1. 先trace系统，获取系统的profiling数据 
2. 用脚本来绘制

系统的profiling数据获取，可以选择最流行的perf record，而后把采集的数据进行加工处理，绘制为火焰图。

其中第二步的绘制火焰图的脚本程序，通过如下方式获取:

```
git clone https://github.com/brendangregg/FlameGraph
```

# 火焰图案例

直接从最简单的例子开始说起, 代码如下:

```cpp
c(){
    for(int i=0;i<1000;i++);
}

b(){
    for(int i=0;i<1000;i++);
    c();
}

a(){
    for(int i=0;i<1000;i++);
    b();
}
```

则这三个函数，在火焰图中呈现的样子为：

![2020-02-04-23-11-42.png](./images/2020-02-04-23-11-42.png)

`a()`的`2/3`的时间花在`b()`上面，而`b()`的`1/3`的时间花在`c()`上面。很多个这样的`a->b->c`的火苗堆在一起，就构成了火焰图。

![2020-02-04-23-12-28.png](./images/2020-02-04-23-12-28.png)

进一步理解火焰图的最好方法仍然是通过一个实际的案例，下面的程序创建2个线程，两个线程的handler都是`thread_fun()`，之后`thread_fun()`调用`fun_a()`、`fun_b()`、`fun_c()`，而`fun_a()`又会调用`fun_d()`：

```cpp
#include <pthread.h>

func_d(){
    int i;
    for(i=0;i<50000;i++);
}

func_a(){
    int i;
    for(i=0;i<100000;i++);
    func_d();
}

func_b(){
    int i;
    for(i=0;i<200000;i++);
}

func_c()
{
    int i;
    for(i=0;i<300000;i++);
}

void* thread_fun(void* param)
{
    while(1) {
        int i;
        for(i=0;i<100000;i++);
        
        func_a();
        func_b();
        func_c();
    }
}

int main(void)
{
    pthread_t tid1,tid2;
    int ret;
    
    ret=pthread_create(&tid1,NULL,thread_fun,NULL);
    if(ret==-1){
        ...
    }
    
    ret=pthread_create(&tid2,NULL,thread_fun,NULL);
    ...
    
    if(pthread_join(tid1,NULL)!=0){
        ...
    }
    
    if(pthread_join(tid2,NULL)!=0){
        ...
    }
    
    return 0;
}
```

# 参考

https://mp.weixin.qq.com/s/Kz4tii8O4Nk-S4SV4kFYPA