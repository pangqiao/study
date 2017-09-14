### 1. 默认配置

- 1.打开软件，选择编辑->启动设定

- 2.在其中添加自己的配置命令
 
### 2. 打开乱码

设置gvim

```
set encoding=utf-8
set fileencodings=utf-8,chinese,latin-1
if has("win32")
set fileencoding=chinese
else
set fileencoding=utf-8
endif
"解决菜单乱码
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim
"解决consle输出乱码
language messages zh_CN.utf-8
```