
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 安装软件](#1-安装软件)
- [2. 下载 vim 配置](#2-下载-vim-配置)
- [3. 功能开启](#3-功能开启)
- [4. YouCompleteMe 设置](#4-youcompleteme-设置)
  - [4.1. rust 自定义支持](#41-rust-自定义支持)
  - [4.2. rust 自动支持](#42-rust-自动支持)
- [5. rust 支持](#5-rust-支持)

<!-- /code_chunk_output -->

参照: https://www.zhihu.com/people/tracyone/posts

# 1. 安装软件

```
apt-get install exuberant-ctags cscope git wmctrl fonts-powerline ccls build-essential cmake python3-dev libclang1 vim-gtk3 npm pip curl git
```

vim-gtk 可以让 vim 有 `+clipboard` feature 支持

fontconfig 用来安装字体库

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

## 4.1. rust 自定义支持

对于 rust 的支持编译, 可以看: https://blog.stdio.io/1103#method4

```
rustup +nightly component add rust-src rust-analyzer-preview
```

C-family 的支持, 没有用 `--rust-completer`, 因为该参数会使得 install.py/build.py 自动下载特定版本的 rustup toolchain

```
cd ~/.vim/bundle/YouCompleteMe
python3 install.py --clang-completer --system-libclang
```

然后配置 .vimrc，自定义 toolchain 目录

```
let g:ycm_rust_src_path = '/path/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src'
let g:ycm_rls_binary_path = '/path/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin'
let g:ycm_rustc_binary_path = '/path/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin'
```

## 4.2. rust 自动支持

YCM 目前已经不用 rls 了, 而是使用 rust-analyzer 作为工具链

所以可以安装使用

```
python3 install.py --clang-completer --system-libclang --rust-completer
```


# 5. rust 支持

https://blog.stdio.io/1103#method4