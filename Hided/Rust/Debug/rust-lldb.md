
Rust 会使用 DWARF 格式在 binary 中嵌入调试信息，所以可以使用一些通用的调试工具，比如 GDB 和 LLDB。Rust 提供了 `rust-gdb` 和 `rust-lldb` 两个命令用于调试，其相比原生的 gdb 和 lldb 添加了一些方便调试的脚本

下面来初步的了解 rust-lldb 的使用，rustup 会安装 rust-lldb，但不会安装 lldb，需要自行安装

LLDB 的命令结构如下

```
<noun> <verb> [-options [option-value]] [argument [argument...]]
```

```rust

fn binary_search(nums: Vec<i32>, target: i32) -> i32 {
    let mut size = nums.len();

    if size == 0 {
        return -1;
    }

    let mut base = 0usize;

    while size > 1 {
        let half = size / 2;
        let mid = base + half;

        if nums[mid] <= target {
            base = mid;
        }
        size = size - half;
    }

    if nums[base] == target {
        return base as i32;
    }
    return -1;
}


fn main() {
    assert_eq!(binary_search(vec![1, 4, 7, 10, 16, 19], 10), 3);
}
```

cargo build 默认会以 debug 模式进行构建，所以含有用于调试的 symbol，需要注意的是 `cargo install` 会以 release 模式构建，需要 `cargo install --debug`

通过 rust-lldb 命令加载可执行文件(或者在 REPL 中通过 file 载入)，进入 LLDB 的 REPL。比如

`rust-lldb -- target/debug/<bin-name> first_arg`

启动时会显示

```
(lldb) settings set -- target.run-args  "first_arg"
```

字样，参数会存在 target.run-args 中，可以在 REPL 中重置命令行参数

```
(lldb) settings set target.run-args "arg1"
(lldb) settings show target.run-args
target.run-args (array of strings) =
  [0]: "arg1"
(lldb) settings append target.run-args "arg2"
(lldb) settings show target.run-args
target.run-args (array of strings) =
  [0]: "arg1"
  [1]: "arg2"
```

gui 命令可以进入 GUI，可以借助 [voltron](https://github.com/snare/voltron) 获得更改的体验

通过 b 命令来设置断点。b 命令是对于 GDB 中 break 命令的模拟，并不是 LLDB 中的 breakpoint 的 alias。breakpoint set -n <func name> 设置支持补全，breakpoint set -f <文件路径>--line 15 在指定的行设置断点