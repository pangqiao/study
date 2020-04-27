
# 概述

先看doc.

`Documentation/admin-guide/mm/memory-hotplug.rst`

# hot add

# hot remove

然后要想remove, 逻辑上是先offline(drivers/base/memory.c的memory_subsys_offline), 再remove(mm/memory_hotplug.c的remove_memory调用).

## offline

```cpp

```

`Documentation/admin-guide/mm/memory-hotplug.rst`

`/sys/devices/system/memory/block_size_bytes`这个值好像是16进制大小?

https://blog.51cto.com/weiguozhihui/1568258