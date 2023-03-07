
io_submit、io_setup和io_getevents是LINUX上的AIO系统调用。这有一个非常特别注意的地方——传递给 io_setup 的 aio_context 参数必须初始化为 0，在它的man手册里其实有说明，但容易被忽视，我就犯了这个错误，man说明如下：

> ctxp must not point to an  AIO context that already exists, and must be initialized to 0 prior to the call


系统调用功能原型

`io_setup` 初始化一个异步 IO 上下文. 参数 ctxp 用来描述异步 IO 上下文，参数 nr_events 表示小可处理的异步 IO 事件的个数

```cpp
int io_setup(unsigned nr_events, aio_context_t *ctxp);
```

`io_submit` 提交初始化好的异步 IO 事件. 其中 ctx 是上文的描述句柄，nr 表示提交的异步事件个数。iocbs 是异步事件的结构体。

```cpp
int io_submit(io_context_t ctx, long nr, struct iocb *iocbs[]);
```

`io_getevents` 获得已完成的异步 IO 事件. 其中参数 ctx 是上下文的句柄，nr 表示期望获得异步 IO 事件个数，events 用来存放已经完成的异步事件的数据，timeout 为超时事件。 

```cpp
int io_getevents(io_context_t ctx, long nr, struct io_event *events[], struct timespec *timeout);
```

`io_cancel` 取消一个未完成的异步 IO 操作

```cpp
int io_cancel(aio_context_t ctx_id, struct iocb *iocb, struct io_event *result);
```

`io_destroy` 用于销毁异步IO事件句柄. 

```cpp
int io_destroy(aio_context_t ctx);
```

内核的异步 IO 通常和 epoll 等IO多路复用配合使用来完成一些异步事件，那么就需要使用 epoll 来监听一个可以通知异步 IO 完成的描述符，那么就需要使用 eventfd 函数来获得一个这样的描述符。

```cpp
#define TEST_FILE "aio_test_file"
#define TEST_FILE_SIZE (127 * 1024)
#define NUM_EVENTS 128
#define ALIGN_SIZE 512
#define RD_WR_SIZE 1024

struct custom_iocb
{
    struct iocb iocb;
    int nth_request;
};

//异步IO的回调函数
void aio_callback(io_context_t ctx, struct iocb *iocb, long res, long res2)
{
    struct custom_iocb *iocbp = (struct custom_iocb *)iocb;

    printf("nth_request: %d, request_type: %s, offset: %lld, length: %lu, res: %ld, res2: %ld\n", iocbp->nth_request, (iocb->aio_lio_opcode == IO_CMD_PREAD) ? "READ" : "WRITE",iocb->u.c.offset, iocb->u.c.nbytes, res, res2);
}

int main(int argc, char *argv[])
{
    int efd, fd, epfd;
    io_context_t ctx;
    struct timespec tms;
    struct io_event events[NUM_EVENTS];
    struct custom_iocb iocbs[NUM_EVENTS];
    struct iocb *iocbps[NUM_EVENTS];
    struct custom_iocb *iocbp;
    int i, j, r;
    void *buf;
    struct epoll_event epevent;

    //创建用于获取异步事件的通知描述符
    efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (efd == -1) {
        perror("eventfd");
        return 2;
    }

    fd = open(TEST_FILE, O_RDWR | O_CREAT | O_DIRECT , 0644);
    if (fd == -1) {
        perror("open");
        return 3;
    }

    ftruncate(fd, TEST_FILE_SIZE);

    ctx = 0;
    //创建异步IO的句柄
    if (io_setup(8192, &ctx)) {
        perror("io_setup");
        return 4;
    }

    //申请空间
    if (posix_memalign(&buf, ALIGN_SIZE, RD_WR_SIZE)) {
        perror("posix_memalign");
        return 5;
    }

    printf("buf: %p\n", buf);
    for (i = 0, iocbp = iocbs; i < NUM_EVENTS; ++i, ++iocbp) {
        iocbps[i] = &iocbp->iocb;
        //设置异步IO读事件
        io_prep_pread(&iocbp->iocb, fd, buf, RD_WR_SIZE, i * RD_WR_SIZE);
        //关联通知描述符
        io_set_eventfd(&iocbp->iocb, efd);
        //设置回调函数
        io_set_callback(&iocbp->iocb, aio_callback);
        iocbp->nth_request = i + 1;
    }

    //提交异步IO事件
    if (io_submit(ctx, NUM_EVENTS, iocbps) != NUM_EVENTS) {
        perror("io_submit");
        return 6;
    }

    epfd = epoll_create(1);
    if (epfd == -1) {
        perror("epoll_create");
        return 7;
    }

    epevent.events = EPOLLIN | EPOLLET;
    epevent.data.ptr = NULL;

    if (epoll_ctl(epfd, EPOLL_CTL_ADD, efd, &epevent)) {

    perror("epoll_ctl");

    return 8;

    }

i = 0;

while (i < NUM_EVENTS) {

uint64_t finished_aio;

//监听通知描述符

if (epoll_wait(epfd, &epevent, 1, -1) != 1) {

perror("epoll_wait");

return 9;

}

//读取完成的异步IO事件个数

if (read(efd, &finished_aio, sizeof(finished_aio)) != sizeof(finished_aio)) {

perror("read");

return 10;

}

printf("finished io number: %"PRIu64"\n", finished_aio);

while (finished_aio > 0) {

tms.tv_sec = 0;

tms.tv_nsec = 0;

//获取完成的异步IO事件

r = io_getevents(ctx, 1, NUM_EVENTS, events, &tms);

if (r > 0) {

for (j = 0; j < r; ++j) {

//调用回调函数

//events[j].data的数据和设置的iocb结构体中的data数据是一致。

((io_callback_t)(events[j].data))(ctx, events[j].obj, events[j].res, events[j].res2);

}

i += r;

finished_aio -= r;

}

}

}

close(epfd);

free(buf);

io_destroy(ctx);

close(fd);

close(efd);

remove(TEST_FILE);

return 0;

}
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