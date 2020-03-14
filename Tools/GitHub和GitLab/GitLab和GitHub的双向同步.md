
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

生成空的项目后, 记录URL, 类似

```
https://github.com/haiwei-li/test.git
```

## 在GitLab上配置镜像地址

登录GitLab, 进入需要同步的项目, 进入 `settings -> repository -> Mirroring repositories`, 填写GitHub的空代码库地址

注意地址需要添加用户名(自然是为了和token对应)

原本URL是

```
https://github.com/haiwei-li/test.git
```

这里要填写的是

```
https://haiwei-li@github.com/haiwei-li/test.git
```

密码处 填写的就是上面获取的token。

如果github中创建的是公有的仓库，可以尝试自己的**github的登录密码**填写此处，以或许更多更完整的权限