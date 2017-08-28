1. git pull时出现冲突 放弃本地修改，使远程库内容强制覆盖本地代码

```
git fetch --all //只是下载代码到本地，不进行合并操作

git reset --hard origin/master  //把HEAD指向最新下载的版本
```

2. 在 add 以后 commit 前撤销修改:

```
git reset <file> // 撤销提交单独文件

git reset        // unstage all due changes
```

3. add以及commit 前撤销对文件的修改:

```
git checkout -- README.md  // 注意, add添加后(同commit提交后)就无法通过这种方式撤销修改
```

4. 当前工作区内容已被修改，但是并未完成。而前面的分支上面有一个Bug，需要立即修复。可是又不想提交目前的修改，因为修改没有完成。但是，不提交的话，又没有办法checkout到前面的分支。

```
此时用Git Stash就相当于备份工作区了。

然后在Checkout过去修改，就能够达到保存当前工作区，并及时恢复的作用。
```

5. 删除某个远程分支

```
$ git push origin :master
# 等同于
$ git push origin --delete master
```

6. git log的通用配置命令

$ git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

7. 基于某个分支创建分支

```
$ git checkout <remote>/<branch> -b <branch> //设置跟踪关系

$ git pull origin auto-test-v0.9:autotest
```