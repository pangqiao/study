
参考：

https://github.com/Gerry-Lee/vim

### 1. 配置文件

参考当前目录下vimrc

### 2. 安装ctags

```
yum install ctags*
```

执行操作参照tags

### 3. 安装taglist

拷贝下面文件到相应目录

```
plugin/taglist.vim – taglist插件
doc/taglist.txt    - taglist帮助文件
```

### 4. cscope安装

源码编译安装
```
./configure
make
make install
```

然后根据cscope的路径修改vimrc配置文件

### 5. 安装SuperTag

第一步，下载supertab插件到任意目录

http://www.vim.org/scripts/script.php?script_id=1643

第二步，打开该插件

```
$ vim supertab.vmb
```

第三步，执行命令，作用是从文件中读取可执行命令（shell命令）来执行

```
:so %
```

### 6. 对库进行ctags

```
cd /usr/include
ctags -R ./
```

### 7. 针对Python空格

```
cd /usr/share/vim/vim74/ftplugin/
vim python.vim
```

添加

```
set tabstop=4
set shiftwidth=4
```

### 8.