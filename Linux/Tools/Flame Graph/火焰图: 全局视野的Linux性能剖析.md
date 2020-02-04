
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

# 参考

https://mp.weixin.qq.com/s/Kz4tii8O4Nk-S4SV4kFYPA