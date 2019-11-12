


# 安装软件

```
apt-get install ctags cscope git wmctrl fonts-powerline 
```

```
# yum install -y ctags cscope
```

fontconfig用来安装字体库

ttmkfdir用来搜索目录中所有的字体信息，并汇总生成fonts.scale文件

然后根据cscope的路径修改vimrc配置文件

# 安装字体

参照 Linux/Tools/字体




# 安装插件管理器Vim-Plug

https://github.com/junegunn/vim-plug

```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```




# 备份原有.vim和.vimrc

```
mv ~/.vim ~/.vim.orig
mv ~/.vimrc ~/.vimrc.orig
```

# 添加配置文件

```
git clone https://github.com/Gerry-Lee/VimConfig.git ~/.vim
ln -s ~/.vim/vimrc ~/.vimrc
```

# 安装插件

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/vundle
```

在vim执行“:BundleInstall”进行插件安装。

```
vim
:BundleInstall
```

参考当前目录下vimrc


# 对库进行ctags\+cscope

```
cd /usr/include
ctags -R ./
find . -name "*.h" -o -name "*.c" -o -name "*.cc" -o -name "*.cpp" > cscope.files
cscope -bq -i cscope.files
```

# 快捷键

- <F5> :TagbarToggle
- <F6> :NERDTreeToggle
- <F3> :GundoToggle
- <F4> :IndentGuidesToggle
- <C-F11> :!cscope -bRq
- <C-F12> :!ctags -R --c-kinds=+l+x+p --fields=+lS -I __THROW,__nonnull --extra=+ .

### 8.


参考：

https://github.com/ma6174/vim