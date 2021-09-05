
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 在线 PlayGroud](#1-在线-playgroud)
- [2. 本地安装 Rust](#2-本地安装-rust)
  - [2.1. 安装](#21-安装)
  - [2.2. 修改国内源](#22-修改国内源)
- [3. Docker 中使用 Rust](#3-docker-中使用-rust)
- [4. Rust IDE](#4-rust-ide)
- [5. 开发依赖工具](#5-开发依赖工具)
  - [5.1. Racer 代码补全](#51-racer-代码补全)
  - [5.2. RLS](#52-rls)
  - [5.3. cargo 插件](#53-cargo-插件)
    - [5.3.1. clippy](#531-clippy)
    - [5.3.2. rustfmt](#532-rustfmt)
    - [5.3.3. cargo fix](#533-cargo-fix)

<!-- /code_chunk_output -->

# 1. 在线 PlayGroud

官方在线 PlayGroud: https://play.rust-lang.org .

# 2. 本地安装 Rust

Rust 工具集包含两个重要组件:

* rustc, Rust 的编译器
* cargo, Rust 的包管理器, 包含构建工具和依赖管理.

Rust 工具集有三类版本:

* Nightly, "夜版". 日常开发的主分支.
* Beta, 测试版. 只包含 Nightly 中被标记为稳定的特性.
* Stable, 稳定版.

## 2.1. 安装

Rust 有一个安装工具: rustup. 类似于 Ruby 的 rbenv、Python 的 pyenv, Node 的 nvm.

安装 rustup:

```
curl https://sh.rustup.rs -sSf | sh
```

也可指定默认使用nightly版本

```
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
```

> 会下载了 rustup-init.sh 然后执行

此工具全平台通用.

rustup 会在 Cargo 目录下安装 rustc、cargo、rustup, 以及其他标准工具. Unix平台默认安装在 `$HOME/.cargo/bin`

检测:

```
rustc --version
```

rustup 可以帮助管理本地的多个编译器版本, 通过 rustup default 指定一个默认的 rustc 版本.

```
rustup default nightly
```

或

```
rustup default nightly-2018-05-12
```

rustup 会自动下载相应的编译器版本来安装.

## 2.2. 修改国内源

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

# 3. Docker 中使用 Rust

在 Dockerfile 中添加

```

```

如果你不想使用Nightly版本，可以将nightly换成stable。

如果你想指定固定的nightly版本，则可以再添加如下一行命令：

```
RUN rustup default nightly-2018-05-12
```

# 4. Rust IDE

比如 Visual Studio Code、IntelliJ IDEA等。

# 5. 开发依赖工具

## 5.1. Racer 代码补全



## 5.2. RLS

RLS 是Rust Language Server的简写，微软提出编程语言服务器的概念，将 IDE 的一些编程语言相关的部分由单独的服务器来实现，比如代码补全、跳转定义、查看文档等。这样，不同的IDE或编辑器只需要实现客户端接口即可。



## 5.3. cargo 插件

### 5.3.1. clippy

分析源码, 检查代码中的 Code Smell.

```
rustup component add clippy
```

### 5.3.2. rustfmt

统一代码风格

```
rustup component add rustfmt
```

### 5.3.3. cargo fix

cargo 自带子命令 cargo fix, 帮助开发者自动修复编译器中有警告的代码
