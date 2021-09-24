
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 安装软件](#1-安装软件)
- [2. 下载 vim 配置](#2-下载-vim-配置)
- [3. 功能开启](#3-功能开启)
- [4. YouCompleteMe 设置](#4-youcompleteme-设置)
  - [4.1. rust 支持](#41-rust-支持)
- [Rust](#rust)
  - [语法增强](#语法增强)
  - [代码片段](#代码片段)
  - [代码 补全 | 检查 | 跳转 利器](#代码-补全-检查-跳转-利器)
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

## 4.1. rust 支持

* rust 源码: rust src
* 补全工具: rust analyzer

> YCM使用了 rust analyzer, 所以不依赖 racer? 不用安装 racer?? `cargo install racer`

YCM 目前已经不用 rls 了, 而是使用 rust-analyzer 作为工具链(因为 Rust 社区决定使用 rust-analyzer)

所以直接安装使用

```
python3 install.py --clang-completer --system-libclang --rust-completer
```

* 自动下载 rust-analyzer binary 到 `./third_party/ycmd/third_party/rust-analyzer/bin/rust-analyzer`
* 自动下载 rust src 到 `./third_party/ycmd/third_party/rust-analyzer/bin/rust-analyzer/lib/rustlib/src/rust/src`

YCM 不需要额外配置, 自动识别这两个

当然, 你可以指定自己的 toolchain

下载:

```
rustup +nightly component add rust-src rust-analyzer-preview
```

* rust-src 是 rust 源码, 代码补全需要源码的. 安装在 `/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src/`
* rust-analyzer-preview 是 rust-analyzer binary 文件, 安装在 `/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/` 下面

修改 vimrc

```
// 指定 toolchain root
let g:ycm_rust_toolchain_root = '/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu'
```

YCM 已经没有这个配置项了

```
let g:ycm_rust_src_path = '/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src'
```

# Rust

持续更新: https://www.yuque.com/zhoujiping/programming/rust-vim-settings

![2021-09-24-17-45-12.png](./images/2021-09-24-17-45-12.png)

![2021-09-24-17-24-45.png](./images/2021-09-24-17-24-45.png)

## 语法增强

rust.vim: 提供 Rust 文件检测、语法高亮、格式设置与语法检测工具 Syntastic 集成等功能

```
" === rust.vim 配置 ===
syntax enable
filetype plugin indent on
" 保存时代码自动格式化
let g:rustfmt_autosave = 1

" 手动调用格式化， Visual 模式下局部格式化，Normal 模式下当前文件内容格式化
" 有时候代码有错误时，rust.vim 不会调用格式化，手动格式化就很方便
vnoremap <leader>ft :RustFmtRange<CR>
nnoremap <leader>ft :RustFmt<CR>
" 设置编译运行 (来自 rust.vim，加命令行参数则使用命令 `:RustRun!`)
nnoremap <M-r> :RustRun<CR>
" 使用 `:verbose nmap <M-t>` 检测 Alt-t是否被占用
" 使用 `:verbose nmap` 则显示所有快捷键绑定信息
nnoremap <M-t> :RustTest<CR>
```

## 代码片段

> Always async, never slows you down. 始终保持异步，永不减慢您的速度



## 代码 补全 | 检查 | 跳转 利器

https://rust-analyzer.github.io/manual.html#vimneovim



Racer: Rust Auto-Complete-er, 代码补全. 而 vim 下的 `racer-rust/vim-racer` 插件已经停止开发, 不建议使用. 应该改用LSP插件（vim-lsp，nvim-lspconfig）, 补全用 YCM 是否就可以了?



# reference

Rust：vim 环境配置: 


https://blog.stdio.io/1103#method4

https://github.com/rust-lang/rust.vim

