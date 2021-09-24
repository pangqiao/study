
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 社区](#1-社区)
- [2. 在线 PlayGroud](#2-在线-playgroud)
- [3. 本地安装 Rust](#3-本地安装-rust)
  - [3.1. 安装](#31-安装)
  - [3.2. 环境变量](#32-环境变量)
  - [3.3. 多版本](#33-多版本)
  - [3.4. rust 升级](#34-rust-升级)
  - [3.5. Rust 卸载](#35-rust-卸载)
  - [3.6. 国内源](#36-国内源)
- [4. Docker 中使用 Rust](#4-docker-中使用-rust)
- [5. Rust IDE](#5-rust-ide)
- [6. 开发依赖工具](#6-开发依赖工具)
  - [6.1. Racer 代码补全](#61-racer-代码补全)
  - [6.2. RLS](#62-rls)
  - [rust-analyzer](#rust-analyzer)
    - [VS Code](#vs-code)
  - [6.3. cargo 插件](#63-cargo-插件)
    - [6.3.1. clippy](#631-clippy)
    - [6.3.2. rustfmt](#632-rustfmt)
    - [6.3.3. cargo fix](#633-cargo-fix)

<!-- /code_chunk_output -->

# 1. 社区

快速配置: https://www.rust-lang.org/learn/get-started

# 2. 在线 PlayGroud

在线 Rust 不用安装: [PlayGroud](https://play.rust-lang.org)

# 3. 本地安装 Rust

Rust 工具集包含两个重要组件:

* rustc, Rust 的编译器
* cargo, Rust 的包管理器, 包含构建工具和依赖管理.

Rust 工具集有三类版本:

* Nightly, "夜版". 日常开发的主分支.
* Beta, 测试版. 只包含 Nightly 中被标记为稳定的特性.
* Stable, 稳定版.

## 3.1. 安装

Rust 有一个安装工具: rustup. 类似于 Ruby 的 rbenv、Python 的 pyenv, Node 的 nvm.

安装 rustup:

```
curl https://sh.rustup.rs -sSf | sh
```

也可指定默认使用nightly版本

```
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
```

> 会下载了 rustup-init.sh 然后 sh 执行

此工具全平台通用.

## 3.2. 环境变量

rustup 会在 `$HOME/.cargo/bin` 目录下安装 rustc、cargo、rustup, 以及其他标准工具. 通常将这个目录加入 PATH 环境变量中.

检测:

```
rustc --version
```

## 3.3. 多版本

rustup 可以帮助管理本地的多个编译器版本.

```
rustup show
```

rustup default 查看默认的编译器版本

```
# rustup default
stable-x86_64-unknown-linux-gnu (default)
```

通过 rustup default 指定一个默认的 rustc 版本.

```
rustup default nightly
```

或

```
rustup default nightly-2018-05-12
```

指定日期, rustup 会自动下载相应的编译器版本来安装.

## 3.4. rust 升级

rust 社区更新很频繁. 不定期需要更新下.

```
rustup update
```

## 3.5. Rust 卸载

```
rustup self uninstall
```

## 3.6. 国内源

Rustup 的服务器可以修改成 中国科学技术(USTC) 的 Rustup 镜像.

1. 设置环境变量

```
export RUSTUP_DIST_SERVER=http://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=http://mirrors.ustc.edu.cn/rust-static/rustup
```

2. 设置cargo使用的国内镜像

在`CARGO_HOME`目录下（默认是`～/.cargo`）建立一个名叫config的文件，内容如下：

```
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
```

# 4. Docker 中使用 Rust

在 Dockerfile 中添加

```dockerfile
FROM phusion/baseimage
ENV RUSTUP_HOME=/rust
ENV CARGO_HOME=/cargo
ENV PATH=/cargo/bin:/rust/bin:$PATH
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
```

如果你不想使用Nightly版本，可以将nightly换成stable。

如果你想指定固定的nightly版本，则可以再添加如下一行命令：

```
RUN rustup default nightly-2018-05-12
```

# 5. Rust IDE

比如 Visual Studio Code、IntelliJ IDEA等。

# 6. 开发依赖工具

## 6.1. Racer 代码补全

Racer(Rust Auto-Complete-er) 是 Rust 代码补全库.

```
cargo install racer

// 使用 nightly 版源码编译安装
rustup run nightly cargo install racer
```

racer 工具会被安装在 `$HOME/.cargo/bin/` 下面

代码补全需要**标准库源码**. 以前需要手动下载并定期更新, 现在通过 rustup

```
rustup component add rust-src
```

然后配置环境变量(rust 源码):

```
export RUST_SRC_APTH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
```

## 6.2. RLS

RLS 是Rust Language Server的简写，微软提出编程语言服务器的概念，将 IDE 的一些编程语言相关的部分由单独的服务器来实现，比如代码补全、跳转定义、查看文档等。这样，**不同的IDE或编辑器只需要实现客户端接口**即可。

依赖 racer 来实现, 所以需要配置 racer 的环境变量

## rust-analyzer


Rust Analyzer：一款旨在带来优秀 IDE 体验的编译器: https://www.infoq.cn/article/lvLv4lmcMzTDg7ZTOMdY, 2020 年 2 月 13 日

RA 是一个模块化编译器前端, 目的是为了带来优秀的 Rust IDE 体验, 不依赖 racer?

rust-analyzer 将取代 RLS.

> 理论上, 针对所有编辑器, 只需要安装 rust-analyzer binary 就能直接工作. 但是目前有些编辑器还是需要特定的配置.

> rust-analyzer 也是需要标准库源码的, 不存在的话会自动安装, 也可以手动添加 `rustup component add rust-src`

更多细节: https://rust-analyzer.github.io/manual.html

### VS Code

目前 VS Code 已完美支持, 直接下载 rust-analyzer, 会和官方 Rust 冲突, 卸载官方的即可

## 6.3. cargo 插件

### 6.3.1. clippy

分析源码, 检查代码中的 Code Smell.

```
rustup component add clippy
```

### 6.3.2. rustfmt

统一代码风格

```
rustup component add rustfmt
```

### 6.3.3. cargo fix

cargo 自带子命令 cargo fix, 帮助开发者自动修复编译器中有警告的代码
