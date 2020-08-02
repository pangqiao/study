
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [作用](#作用)
- [基本用法](#基本用法)
- [转移多个提交](#转移多个提交)
- [配置项](#配置项)

<!-- /code_chunk_output -->

# 作用

对于**多分支**的**代码库**，将代码从**一个分支**转移到**另一个分支**是常见需求。

这时分两种情况。

- 一种情况是，你需要**另一个分支的所有代码变动**，那么就采用**合并**（**git merge**）。
- 另一种情况是，你只需要**部分代码变动**（某几个提交），这时可以采用 `Cherry pick`。

将指定的提交（commit）应用于其他分支, 但是会**产生新的commit**.

# 基本用法

```
git cherry-pick <commitHash>
```

上面命令就会**将指定的提交commitHash**，应用于**当前分支**。这会在当前分支**产生一个新的提交**，当然它们的哈希值会不一样。

举例来说，代码仓库有master和feature两个分支。

```
    a - b - c - d   Master
         \
           e - f - g Feature
```

现在将**提交f**应用到**master分支**。

```
# 切换到 master 分支
$ git checkout master

# Cherry pick 操作
$ git cherry-pick f
```

上面的操作完成以后，代码库就变成了下面的样子。

```
    a - b - c - d - f   Master
         \
           e - f - g Feature
```

从上面可以看到，master分支的末尾增加了一个提交f。

`git cherry-pick`命令的**参数**，不一定是提交的哈希值，**分支名**也是可以的，表示转移**该分支的最新提交**。

```
$ git cherry-pick feature
```

上面代码表示将feature分支的**最近一次提交**，转移到当前分支。

# 转移多个提交

Cherry pick 支持一次转移多个提交。

```
$ git cherry-pick <HashA> <HashB>
```


上面的命令将 A 和 B **两个提交**应用到**当前分支**。这会在当前分支生成**两个对应的新提交**。

如果想要转移**一系列的连续提交**，可以使用下面的简便语法。

```
$ git cherry-pick A..B
```

上面的命令可以转移**从 A 到 B 的所有提交**。它们必须按照正确的顺序放置：**提交 A 必须早于提交 B**，否则命令将失败，但不会报错。

注意，使用上面的命令，**提交 A** 将**不会包含**在 Cherry pick 中。如果要包含提交 A，可以使用下面的语法。

```
$ git cherry-pick A^..B
```

# 配置项

git cherry-pick命令的常用配置项如下。

（1）`-e`，`--edit`

打开外部编辑器，**编辑提交信息**。

（2）`-n`，`--no-commit`

**只更新工作区**和**暂存区**，**不产生新的提交**。

（3）-x

在提交信息的末尾追加一行(cherry picked from commit ...)，方便以后查到这个提交是如何产生的。

（4）-s，--signoff

在提交信息的末尾追加一行操作者的签名，表示是谁进行了这个操作。


http://www.ruanyifeng.com/blog/2020/04/git-cherry-pick.html
