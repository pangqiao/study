
源码: https://git.kernel.dk/cgit/fio/

git://git.kernel.dk/fio.git

https://git.kernel.dk/fio.git

Fio 的入口函数在 `fio.c` 的 main 函数，其结构如下所示:

```cpp
int main(int argc, char *argvO, char *envp0) {
    if(initialize_fio(envp)) // libfio.c 文件————进行 fio 初始化，有 64 位对齐、大端小端模式、hash、文件锁等
        return 1;
    if(fio_server_create_sk_key()) // server.c 文件－为线程创建私有数据 TSD
        goto done;
    if(parse_options(argc,argv)) // read-to-pipe-async 文件 - 解析 main 函数的参数
        goto done_key;
    fio_time_init(); // 初始化时钟相关
    if(nr_clients){
        set_genesis_time();
        if(fio_start_all_clients()) // 与一些驱动进行远程连接操作，例如 SPKD
            goto done_key;
        ret=fio_hanuie_clienis(&tio_cliei.t_ops);
    ｝else
        ret=fio_backend(NULL); // backend.c 文件 fio 逻辑走向，开始处理问题
}
```

`fio_server_create_sk_key()` 函数是为线程创建私有数据，关于线程私有数据的概念可以参考 TSD池

```cpp
// server.c
int fio_server_create_sk_key(void)
{
    if (pthread_key_create(&sk_out_key, NULL)) {
            log_err("fio: can't create sk_out backend key\n");
            return 1;
    }

    pthread_setspecific(sk_out_key, NULL);
    return 0;
}
```

接下来, `fio_backend()` 函数 —— `backend.c` 文件：

```cpp
// backend.c
int fio_backend(struct sk_out *sk_out)
{
    ...... // 加载文件、mmap 映射、锁初始化、获取时间、创建helper线程
    run_threads(sk_out); // 会建立主要的I0线程
    ...... // 用于一些变量的销毁、环境的收尾
}
```

该函数中最主要的是 `run_threads(sk_out)` 函数，该函数会根据需要要启动 jobs 和处理 jobs

```cpp
// backend.c
static void run_threads(struct sk_out *sk_out)
{
    ...... // 在io线程之前设置其他线程、设置信号量、缓冲、检查挂载、设置文件处理顺序、修改线程状态
    while (todo) {
        for_each_td(td, i) {
            ......
            if (td->o.use_thread) {
                ......
            } else {
                pid_t pid;
                void *eo;
                dprint(FD_PROCESS, "will fork\n");
                eo = td->eo;
                read_barrier();
                pid = fork();
                if (!pid) {
                    int ret;

                    ret = (int)(uintptr_t)thread_main(fd); // 建立IO提交过程
                    _exit(ret);
                } else if (i == fio_debug_jobno)
                        *fio_debug_jobp = pid;
                free(eo);
                free(fd);
                fd = NULL;
            }
            dprint(FD_MUTEX, "wait on startup_sem\n");
            if (fio_sem_down_timeout(startup_sem, 10000)) {
                log_err("fio: job startup hung? exiting.\n");
                fio_terminate_threads(TERMINATE_ALL, TERMINATE_ALL);
                fio_abort = true;
                nr_started--;
                free(fd);
                break;
            }
        ...... // 线程状态收尾
}
```

最关键的是 `thread_main(fd)` 函数，其主要是建立了 10 提交过程;

```cpp
// backend.c
static void *thread_main(void *data)
{
    ...... // 获取任务 pid,初始化时钟、锁，设置 uid,设置优先级（会影响内存分配），参数转换／初始化，
    while (keep_running(td)) {
        ......
        if (td->o.verify_only && td_write(td))
            verify_bytes = do_dry_run(td);
        else {
            do_io(td, bytes_done); // 进行IO的提交和处理过程
            if (!ddir_rw_sum(bytes_done)) {
                fio_mark_td_terminate(td);
                verify_bytes = 0;
            } else {
                verify_bytes = bytes_done[DDIR_WRITE] +
                                bytes_done[DDIR_TRIM];
            }
        }
    }
    ...... //超时保护，线程竞争锁，err处理
}
```

在该函数中，最重要的是 do_io(td,bytes_done)这个函数，其进行10的提交和进一步的处理：

```cpp
static void do_io(struct thread_data *td, uint64_t *bytes_done)
{
    ...... // 写模式字节数计算、10异常判断、验证end_io、记录IO动作
    
```





