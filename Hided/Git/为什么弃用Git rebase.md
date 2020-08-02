> https://zhuanlan.zhihu.com/p/29682134?utm_medium=social&utm_source=ZHShareTargetIDMore

作者阐释了 git rebase 命令的原理和缺陷，rebase 会导致线性的历史没有分支。此外如果 rebase 过程中发生了冲突，还可能会引入更多的问题。作者推荐使用 git merge。

首先，讲述一下 merge 和 rebase 之间的差别。

我们首先来思考一下通过merge的话，我们创建了一个新的提交g表示两个分支的合并。提交图清晰的展现了发生了什么，我们可以从更大的 Git-repos 中看到熟悉的“火车轨道”轮廓。




