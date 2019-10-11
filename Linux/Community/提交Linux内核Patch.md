
之前使用QEMU和GDB调试Linux内核（详见Linux/Debug/相关文章），最后使用内核提供的GDB扩展功能获取当前运行进程，发现内核已经不再使用thread\_info获取当前进程，而是使用Per-CPU变量。而且从内核4.9版本开始，thread\_info也不再位于内核栈底部，然而内核提供的辅助调试函数lx\_thread\_info()仍然通过内核栈底地址获取thread\_info，很明显这是个Bug，于是决定将其修复并提交一个内核Patch，提交后很快就得到内核维护人员的回应，将Patch提交到了内核主分支。

Linux内核Patch提交还是采用邮件列表方式，不过提供了自动化工具。

# Bug修复

Bug的原因已经很明确了，先看下问题代码scripts/gdb/linux/tasks.py：

```c
def get_thread_info(task):
    thread_info_ptr_type = thread_info_type.get_type().pointer()
    if utils.is_target_arch("ia64"):
        ...
    else:
        thread_info = task['stack'].cast(thread_info_ptr_type)
    return thread_info.dereference()
```

还是使用的老的流程，通过栈底地址获取thread_info。

从内核4.9版本开始，已将thread_info移到了task_struct(include\linux\sched.h)，而且一定是第一个字段：

```c
struct task_struct {
#ifdef CONFIG_THREAD_INFO_IN_TASK
    /*
     * For reasons of header soup (see current_thread_info()), this
     * must be the first element of task_struct.
     */
    struct thread_info      thread_info;
#endif
    ...
}
```

所以修复很简单，只需要判断task的第一个字段是否为thread_info，如果是，则直接将其返回；如果不是，还是走原先的流程：

```c
$ git diff ./
diff --git a/scripts/gdb/linux/tasks.py b/scripts/gdb/linux/tasks.py
index 1bf949c43b76..f6ab3ccf698f 100644
--- a/scripts/gdb/linux/tasks.py
+++ b/scripts/gdb/linux/tasks.py
@@ -96,6 +96,8 @@ def get_thread_info(task):
         thread_info_addr = task.address + ia64_task_size
         thread_info = thread_info_addr.cast(thread_info_ptr_type)
     else:
+        if task.type.fields()[0].type == thread_info_type.get_type():
+            return task['thread_info']
         thread_info = task['stack'].cast(thread_info_ptr_type)
     return thread_info.dereference()
```

# Git配置

添加用户和Email配置，用于git send-email发送Patch。

这里使用Gmail邮箱服务，在Linux项目.git/config配置中添加如下内容：

```conf
[user]
    name = Xi Kangjie
    email = imxikangjie@gmail.com
[sendemail]
    smtpEncryption = tls
    smtpServer = smtp.gmail.com
    smtpUser = imxikangjie@gmail.com
    smtpServerPort = 587
```

注意在Google账户配置中允许不够安全的应用登陆，否则后面发送Patch会收到如下警告：

# Patch生成

Bug修复后，先检查下代码是否符合规范：

```
$ ./scripts/checkpatch.pl --file scripts/gdb/linux/tasks.py 
total: 0 errors, 0 warnings, 137 lines checked

scripts/gdb/linux/tasks.py has no obvious style problems and is ready for submission.
```




https://consen.github.io/2018/01/19/submit-linux-kernel-patch/