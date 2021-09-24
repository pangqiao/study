
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 安装软件](#1-安装软件)
- [2. 下载 vim 配置](#2-下载-vim-配置)
- [3. 功能开启](#3-功能开启)
- [4. YouCompleteMe 设置](#4-youcompleteme-设置)
  - [4.1. rust 支持](#41-rust-支持)
- [Rust](#rust)
- [reference](#reference)

<!-- /code_chunk_output -->

参照: https://www.zhihu.com/people/tracyone/posts

# 1. 安装软件

```
apt-get install exuberant-ctags cscope git wmctrl fonts-powerline ccls build-essential cmake python3-dev libclang1 vim-gtk3 npm pip curl git
```

vim-gtk 可以让 vim 有 `+clipboard` feature 支持, vim-nox 没有

# 2. 下载 vim 配置

```
git clone https://github.com/haiwei-li/vinux.git ~/.vim
```

# 3. 功能开启

打开任意文件，会下载一部分插件，然后 `<SPC>fe`, 输入 all, 打开所有的，会自动下载插件

结束后，修改 `~/.vim/feature.vim`, 关闭番茄时钟

```
let g:feat_enable_fun=0
```

# 4. YouCompleteMe 设置

补全功能使用了 YouCompleteMe, 但是这个比较难以编译，所以只是安装没有编译.

YouCompleteMe 相关设置在 `rc/complete.vim` 中

安装参考: https://github.com/ycm-core/YouCompleteMe#linux-64-bit

```
apt install build-essential cmake python3-dev libclang1
```

```
git submodule update --init --recursive
```

两种方式支持 rust

## 4.1. rust 支持

安装依赖

```
rustup +nightly component add rust-src rust-analyzer-preview
```

* rust-src 是 rust-analyzer 源码

* rust-analyzer-preview 是 rust-analyzer binary 文件


YCM 目前已经不用 rls 了, 而是使用 rust-analyzer 作为工具链(Rust 社区也是如此)

所以可以安装使用

```
python3 install.py --clang-completer --system-libclang --rust-completer
```

会自动下载 rust-analyzer binary 文件到 `third_party/ycmd/third_party/rust-analyzer/bin/rust-analyzer`

配置

```
// rc/rust.vim
// 不自定义就会使用上面默认路径
let g:ycm_rust_toolchain_root = '/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu'
let g:ycm_rust_src_path = '/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src'
```

当然可以将 rust-analyzer 放到 PATH.

# Rust

持续更新: https://www.yuque.com/zhoujiping/programming/rust-vim-settings

![2021-09-24-17-45-12.png](./images/2021-09-24-17-45-12.png)

![2021-09-24-17-24-45.png](./images/2021-09-24-17-24-45.png)

rust.vim: 提供 Rust 文件检测、语法高亮、格式设置与语法检测工具 Syntastic 集成等功能

Racer: Rust Auto-Complete-er, 代码补全. `racer-rust/vim-racer` 已经停止开发, 不建议使用



# reference

Rust：vim 环境配置: 


https://blog.stdio.io/1103#method4

https://github.com/rust-lang/rust.vim

