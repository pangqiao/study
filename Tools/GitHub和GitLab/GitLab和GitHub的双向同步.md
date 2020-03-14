
# GitLab自动同步到GitHub

大致需要三步

1. 在**GitHub**上创建**私有访问Token**,token就是**只有一部分权限的密码**(和你的登录密码相比，你的**登录密码**拥有**完全的权限**), 所以本步骤可以不进行，直接使用github的登录密码也是可以的】【1-6步】

2. 需要在**github**上创建一个**空代码库**，提供**URL地址**，供gitlab使用【7步】

3. 在**GitLab**上**配置镜像地址**，完成同步【8-13步】

## 在GitHub上生成token

登录GitHub, 进入 `setting -> Develop settings -> Personal access tokens`

生成token, `generate new token`, 选择想要给新token赋予的权限

![2020-03-15-00-00-28.png](./images/2020-03-15-00-00-28.png)

保存生成的新的token到其他地方, 之后就看不到了, 因为这个相当于密码

![2020-03-15-00-05-31.png](./images/2020-03-15-00-05-31.png)

## 在GitHub上建立空仓库用来同步

生成空的项目后, 记录URL