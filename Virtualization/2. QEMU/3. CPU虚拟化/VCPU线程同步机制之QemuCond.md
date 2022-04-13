

QEMU互斥量条件，由 `pthread_cond_t` 承担，需要初始化和销毁，条件本身需要互斥量保护

```cpp
// include/qemu/thread-posix.h
#include <pthread.h>
struct QemuCond {
    pthread_cond_t cond;
    bool initialized;
};
```

QemuCond因为一般是动态分的，所以通过`pthread_cond_init`来初始化QemuCond

```cpp
void qemu_cond_init(QemuCond *cond)
{
    int err;

    err = pthread_cond_init(&cond->cond, NULL);
    if (err)
        error_exit(err, __func__);
}
```

通过`pthread_cond_destroy`来销毁QemuCond

void qemu_cond_destroy(QemuCond *cond)
{
    int err;

    err = pthread_cond_destroy(&cond->cond);
    if (err)
        error_exit(err, __func__);
}



/*
 * 通过QemuMutex保护QemuCond，使用pthread_cond_wait等待QemuCond条件被通知后才返回，
 * 注意QemuCond只是通知机制，真正的条件需要在外部的循环里面进行判断，见后面的例子
 * 注意这里没有超时时间限定
 */
void qemu_cond_wait(QemuCond *cond, QemuMutex *mutex)
{
    int err;

    err = pthread_cond_wait(&cond->cond, &mutex->lock);
    if (err)
        error_exit(err, __func__);
}


/*
 * 通过pthread_cond_signal唤醒等待QemuCond的单个线程
 */
void qemu_cond_signal(QemuCond *cond)
{
    int err;

    err = pthread_cond_signal(&cond->cond);
    if (err)
        error_exit(err, __func__);
}

/*
 * 通过pthread_cond_broadcast唤醒等待QemuCond的所有线程
 */
void qemu_cond_broadcast(QemuCond *cond)
{
    int err;

    err = pthread_cond_broadcast(&cond->cond);
    if (err)
        error_exit(err, __func__);
}


使用示例

/* 主线程等待qemu_cond_signal通知主线程 */
static void qemu_kvm_start_vcpu(CPUState *cpu)
{
    //创建VPU对于的qemu线程，线程函数是qemu_kvm_cpu_thread_fn
    qemu_thread_create(cpu->thread, thread_name, qemu_kvm_cpu_thread_fn,
                       cpu, QEMU_THREAD_JOINABLE);

    //如果线程没有创建成功，则一直在此处循环阻塞. 说明多核vcpu的创建是顺序的
    // 注意: 使用QemuCond的一个特点，在while循环中判断真正的条件，因为可能其他线程也被唤醒，如果条件不满足，继续等待
    while (!cpu->created) {
        qemu_cond_wait(&qemu_cpu_cond, &qemu_global_mutex);
    }
}


/* VCPU线程在将VCPU成功建立后，通过qemu_cond_signal通知主线程，主线程才会返回创建下一个VCPU*/
static void *qemu_kvm_cpu_thread_fn(void *arg)
{

    //初始化VCPU
    r = kvm_init_vcpu(cpu); 

    qemu_kvm_init_cpu_signals(cpu);

    /* signal CPU creation */
    cpu->created = true; //标志VCPU创建完成，和上面判断是qemu_kvm_start_vcpu对应的
    //发送qemu_cond_signal不需要对mutex持锁
    qemu_cond_signal(&qemu_cpu_cond); 

    ....
}

# 参考

https://blog.csdn.net/leoufung/article/details/48781179