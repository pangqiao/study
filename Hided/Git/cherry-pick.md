
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [作用](#作用)
- [基本用法](#基本用法)
- [转移多个提交](#转移多个提交)

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



http://www.ruanyifeng.com/blog/2020/04/git-cherry-pick.html
