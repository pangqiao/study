
char device redirected to /dev/pts/4 (label charserial0)

https://cloud.tencent.com/developer/article/1162147

https://blog.csdn.net/silvervi/article/details/77528916

https://blog.csdn.net/defeattroy/article/details/8849057


-chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0

1. host发, 查看guest
host写guest:

echo "root" > /dev/pts/4

host读guest重定向信息:

cat /dev/pts/4

2. guest发, host看
在guest中执行

echo love > /dev/ttyS0

在host中查看

cat /dev/pts/4


3. 通过串口工具访问

minicom

https://blog.csdn.net/IOT_SONG/article/details/79767254