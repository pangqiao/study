
# Kconfig的格式

下面截取/drivers/net下的Kconfig文件中的部分内容：

```kconfig
# Network device configuration
menuconfig NETDEVICES
        default y if UML
        depends on NET
        bool "Network device support"
        ---help---
          You can say N here if you don't intend to connect your Linux box to any other computer at all.
……
config DM9000
        tristate "DM9000 support"
        depends on ARM || BLACKFIN || MIPS
        select CRC32
        select MII
        ---help---
          Support for DM9000 chipset.
 
          To compile this driver as a module, choose M here.  The module will be called dm9000.
……
source "drivers/net/arcnet/Kconfig"
source "drivers/net/phy/Kconfig"
```

Kconfig按照一定的格式来书写，menuconfig程序可以识别这种格式，然后从中提取出有效信息组成menuconfig中的菜单项。将来在做驱动移植等工作时，有时需要自己添加Kconfig中的一个配置项来将某个设备驱动添加到内核的配置项目中，这时候就需要对Kconfig的配置项格式有所了解，否则就不会添加。

menuconfig：表示菜单（本身属于一个菜单中的项目，但是他又有子菜单项目）、config表示菜单中的一个配置项（本身并没有子菜单下的项目）。一个menuconfig后面跟着的所有config项就是这个menuconfig的子菜单。这就是Kconfig中表示的目录关系。

NETDEVICES：menuconfig或者config后面空格隔开的大写字母表示的类似于 NETDEVICES 的就是这个配置项的配置项名字，这个字符串前面添加CONFIG_后就构成了“.config”文件中的配置项名字。

source：内核源码目录树中每一个Kconfig都会用source引入其所有子目录下的Kconfig，从而保证了所有的Kconfig项目都被包含进menuconfig中。这个也说明了：如果你自己在linux内核中添加了一个文件夹，一定要在这个文件夹下创建一个Kconfig文件，然后在这个文件夹的上一层目录的Kconfig中source引入这个文件夹下的Kconfig文件。

tristate：意思是三态（3种状态，对应Y、N、M三种选择方式），意思就是这个配置项可以被三种选择。

bool：是要么真要么假（对应Y和N）。意思是这个配置项只能被2种选择。

depends：意思是本配置项依赖于另一个配置项。如果那个依赖的配置项为Y或者M，则本配置项才有意义；如果依赖的哪个配置项本身被设置为N，则本配置项根本没有意义。depends项会导致make menuconfig的时候找不到一些配置项。所以在menuconfig中如果找不到一个选项，但是这个选项在Kconfig中却是有的，则可能的原因就是这个配置项依赖的一个配置项是不成立的。depends依赖的配置项可以是多个，还可以有逻辑运算。这种时候只要依赖项目运算式子的结果为真则依赖就成立。

select：表示depends on的值有效时，下面的select也会成立，将相应的内容选上。

default：表示depends on的值有效时，下面的default也会成立，将相应的选项选上，有三种选项，分别对应y，n，m。

help：帮助信息，解释这个配置项的含义，以及如何去配置他。

# Kconfig和.config文件和Makefile三者的关联

配置项被配置成Y、N、M会影响“.config”文件中的CONFIG_XXX变量的配置值。“.config”中的配置值（=y、=m、没有）会影响最终的编译链接过程。如果=y则会被编入（built-in），如果=m会被单独连接成一个”.ko”模块，如果没有则对应的代码不会被编译。那么这是怎么实现的？都是通过makefile实现的。

如makefile中：`obj-$(CONFIG_DM9000) += dm9000.o`， 

如果`CONFIG_DM9000`变量值为y，则obj += dm9000.o，因此dm9000.c会被编译；如果CONFIG_DM9000变量未定义，则dm9000.c不会被编译。如果CONFIG_DM9000变量的值为m则会被连接成“.ko”模块。



# 参考

https://blog.csdn.net/prike/article/details/79334609