
io_submit、io_setup和io_getevents是LINUX上的AIO系统调用。这有一个非常特别注意的地方——传递给 io_setup 的 aio_context 参数必须初始化为 0，在它的man手册里其实有说明，但容易被忽视，我就犯了这个错误，man说明如下：

> ctxp must not point to an  AIO context that already exists, and must be initialized to 0 prior to the call


系统调用功能原型

`io_setup` 为当前进程初始化一个异步 IO 上下文. 参数 ctxp 用来描述异步 IO 上下文，参数 nr_events 表示小可处理的异步 IO 事件的个数

```cpp
int io_setup(unsigned nr_events, aio_context_t *ctxp);
```

`io_submit` 提交一个或者多个异步 IO 事件. 其中 ctx 是上文的描述句柄，nr 表示提交的异步事件个数。iocbs 是异步事件的结构体。

```cpp
int io_submit(io_context_t ctx, long nr, struct iocb *iocbs[]);
```

`io_getevents` 获得已完成的异步 IO 事件. 

```cpp
int io_getevents(io_context_t ctx, long nr, struct io_event *events[], struct timespec *timeout);
```

`io_cancel` 取消一个未完成的异步 IO 操作

```cpp
int io_cancel(aio_context_t ctx_id, struct iocb *iocb, struct io_event *result);
```

`io_destroy` 从当前进程删除一个异步 IO 上下文

```cpp
int io_destroy(aio_context_t ctx);
```

完整示例如下：

```cpp
int main()
{
        io_context_t ctx;
        unsigned nr_events = 10;
        memset(&ctx, 0, sizeof(ctx));  // It's necessary，这里一定要的
        int errcode = io_setup(nr_events, &ctx);
        if (errcode == 0)
                printf("io_setup successn");
        else
                printf("io_setup error: :%d:%sn", errcode, strerror(-errcode));

        // 如果不指定O_DIRECT，则io_submit操作和普通的read/write操作没有什么区别了，将来的LINUX可能
        // 可以支持不指定O_DIRECT标志
        int fd = open("./direct.txt", O_CREAT|O_DIRECT|O_WRONLY, S_IRWXU|S_IRWXG|S_IROTH);
        printf("open: %sn", strerror(errno));

        char* buf;
        errcode = posix_memalign((void**)&buf, sysconf(_SC_PAGESIZE), sysconf(_SC_PAGESIZE));
        printf("posix_memalign: %sn", strerror(errcode));

        strcpy(buf, "hello xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");

        struct iocb *iocbpp = (struct iocb *)malloc(sizeof(struct iocb));
        memset(iocbpp, 0, sizeof(struct iocb));

        iocbpp[0].data           = buf;
        iocbpp[0].aio_lio_opcode = IO_CMD_PWRITE;
        iocbpp[0].aio_reqprio    = 0;
        iocbpp[0].aio_fildes     = fd;

        iocbpp[0].u.c.buf    = buf;
        iocbpp[0].u.c.nbytes = page_size;//strlen(buf); // 这个值必须按512字节对齐
        iocbpp[0].u.c.offset = 0; // 这个值必须按512字节对齐

        // 提交异步操作，异步写磁盘
        int n = io_submit(ctx, 1, &iocbpp);
        printf("==io_submit==: %d:%sn", n, strerror(-n));

        struct io_event events[10];
        struct timespec timeout = {1, 100};
        // 检查写磁盘情况，类似于epoll_wait或select
        n = io_getevents(ctx, 1, 10, events, &timeout);
        printf("io_getevents: %d:%sn", n, strerror(-n));

        close(fd);
        io_destroy(ctx);
        return 0;
}
```

```cpp
struct iocb {
       /* these are internal to the kernel/libc. */
       __u64   aio_data;       /* data to be returned in event's data */用来返回异步IO事件信息的空间，类似于epoll中的ptr。
       __u32   PADDED(aio_key, aio_reserved1); /* the kernel sets aio_key to the req # */
       /* common fields */
       __u16   aio_lio_opcode; /* see IOCB_CMD_ above */
       __s16   aio_reqprio;      // 请求的优先级
       __u32   aio_fildes;        //  文件描述符
       __u64   aio_buf;           // 用户态缓冲区
       __u64   aio_nbytes;      // 文件操作的字节数
       __s64   aio_offset;       // 文件操作的偏移量

       /* extra parameters */
       __u64   aio_reserved2;  /* TODO: use this for a (struct sigevent *) */
       __u64   aio_reserved3;
}; /* 64 bytes */

struct io_event {
       __u64           data;          /* the data field from the iocb */ // 类似于epoll_event中的ptr
       __u64           obj;            /* what iocb this event came from */ // 对应的用户态iocb结构体指针
       __s64           res;            /* result code for this event */ // 操作的结果，类似于read/write的返回值
       __s64           res2;          /* secondary result */
};
```