
对于Nvme SSD，我们有的时候会用到ioctl系统调用，该调用的流程是怎样的呢?

首先，在注册 nvme 设备的时候(`nvme_probe`)，会注册 file operations

`/dev/nvme%d`

```cpp
static const struct file_operations nvme_dev_fops = {
    .owner          = THIS_MODULE,
    .open           = nvme_dev_open,
    .release        = nvme_dev_release,
    .unlocked_ioctl = nvme_dev_ioctl,
    .compat_ioctl   = compat_ptr_ioctl,
};
```

在 `nvme_dev_ioctl` 里，存在 switch 语句，列举 ioctl 的几种 cmd，其中我们主要关注的是: `NVME_IOCTL_ADMIN_CMD` 和 `NVME_IO_CMD`.

```cpp
// drivers/nvme/host/ioctl.c
long nvme_dev_ioctl(struct file *file, unsigned int cmd,
                unsigned long arg)
{
        struct nvme_ctrl *ctrl = file->private_data;
        void __user *argp = (void __user *)arg;

        switch (cmd) {
        case NVME_IOCTL_ADMIN_CMD:
                return nvme_user_cmd(ctrl, NULL, argp);
        case NVME_IOCTL_ADMIN64_CMD:
                return nvme_user_cmd64(ctrl, NULL, argp);
        case NVME_IOCTL_IO_CMD:
                return nvme_dev_user_cmd(ctrl, argp);
        case NVME_IOCTL_RESET:
                dev_warn(ctrl->device, "resetting controller\n");
                return nvme_reset_ctrl_sync(ctrl);
        case NVME_IOCTL_SUBSYS_RESET:
                return nvme_reset_subsystem(ctrl);
        case NVME_IOCTL_RESCAN:
                nvme_queue_scan(ctrl);
                return 0;
        default:
                return -ENOTTY;
        }
}
```

对于ssd的读写命令，显然是要走 NVME_IOCTL_IO_CMD 这一分支，该分支的函数主要做的事情是填充了 `nvme_command` c 命令：



