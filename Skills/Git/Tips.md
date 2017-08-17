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