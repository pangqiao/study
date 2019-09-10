
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [相关链接](#相关链接)
- [SIGs](#sigs)
- [Kubernetes Developer Guide](#kubernetes-developer-guide)
  - [开发以及贡献代码到Kuberentes project的流程](#开发以及贡献代码到kuberentes-project的流程)
  - [建立你的开发环境，coding以及debugging](#建立你的开发环境coding以及debugging)

<!-- /code_chunk_output -->
# 相关链接

slack channel: http://slack.k8s.io/ 

google group: https://groups.google.com/forum/#!forum/kubernetes-dev

weekly community meeting: https://groups.google.com/forum/#!forum/kubernetes-community-video-chat 

官方的Meetup: 

https://www.meetup.com/topics/kubernetes/ 

https://www.meetup.com/Kubernetes-Cloud-Native-Online-Meetup/ 

Kubernetes API: https://kubernetes.io/docs/reference/ 

kuberntes.io　－－教程 

kubeweekly －－－案例分享 

design-proposal 设计方案说明（https://github.com/kubernetes/community/blob/master/contributors/design-proposals/），同样可以用来学习插件的开发． 

kubernets项目更好的参与 https://github.com/kubernetes/community/tree/master/contributors/devel

list of SIGs(罗列了主要的SIG以及Meetings时间) 
https://github.com/kubernetes/community/blob/master/sig-list.md

# SIGs

name | URL
-----|----
API Machinery | https://github.com/kubernetes/community/blob/master/sig-api-machinery/README.md
AWS | https://github.com/kubernetes/community/blob/master/sig-aws/README.md
Apps | https://github.com/kubernetes/community/blob/master/sig-apps/README.md
Architecture | https://github.com/kubernetes/community/blob/master/sig-architecture/README.md
Auth | https://github.com/kubernetes/community/blob/master/sig-auth/README.md
Autoscaling | https://github.com/kubernetes/community/blob/master/sig-autoscaling/README.md
Azure | https://github.com/kubernetes/community/blob/master/sig-azure/README.md
Big Data | https://github.com/kubernetes/community/blob/master/sig-big-data/README.md
CLI | https://github.com/kubernetes/community/blob/master/sig-cli/README.md
Cluster Lifecycle | https://github.com/kubernetes/community/blob/master/sig-cluster-lifecycle/README.md
Cluster Ops | https://github.com/kubernetes/community/blob/master/sig-cluster-ops/README.md
Contributor Experience | https://github.com/kubernetes/community/blob/master/sig-contributor-experience/README.md
Docs | https://github.com/kubernetes/community/blob/master/sig-docs/README.md
Federation | https://github.com/kubernetes/community/blob/master/sig-federation/README.md
Instrumentation | https://github.com/kubernetes/community/blob/master/sig-instrumentation/README.md
Network | https://github.com/kubernetes/community/blob/master/sig-network/README.md
Node | https://github.com/kubernetes/community/blob/master/sig-node/README.md
On Premise | https://github.com/kubernetes/community/blob/master/sig-on-premise/README.md
OpenStack | https://github.com/kubernetes/community/blob/master/sig-openstack/README.md
Product Management | https://github.com/kubernetes/community/blob/master/sig-product-management/README.md
Scalability | https://github.com/kubernetes/community/blob/master/sig-scalability/README.md
Scheduling | https://github.com/kubernetes/community/blob/master/sig-scheduling/README.md
Service Catalog | https://github.com/kubernetes/community/blob/master/sig-service-catalog/README.md
Storage | https://github.com/kubernetes/community/blob/master/sig-storage/README.md
Testing | https://github.com/kubernetes/community/blob/master/sig-testing/README.md
UI | https://github.com/kubernetes/community/blob/master/sig-ui/README.md
Windows | https://github.com/kubernetes/community/blob/master/sig-windows/README.md
Container Identity | https://github.com/kubernetes/community/blob/master/wg-container-identity/README.md
Resource Management | https://github.com/kubernetes/community/blob/master/wg-resource-management/README.md

# Kubernetes Developer Guide

https://github.com/kubernetes/community/blob/master/contributors/devel/README.md 

https://github.com/kubernetes/community/blob/master/contributors/guide/github-workflow.md 

有几篇强相关的文档可以read一下,包含的内容

## 开发以及贡献代码到Kuberentes project的流程

* pr的信息以及代码reviw
* github上提交Issues
* pr处理过程
* 怎么加速Pr的review
* ci最新编译的ｉ去那个看
* 自动化的工具

## 建立你的开发环境，coding以及debugging

* 建立开发环境
* 测试（unit, integration and e2e test）

```
unit测试
运行unit测试，下面是一些常用的例子
cd kubernetes
make test #Run all unit tests
make test WHAT=./pkg/api  #Run tests for pkg/api        
make test WHAT=”./pkg/api  ./pkg/kubelet”  # run tests for pkg/api and pkg/kubelet
指定需要运行的test方法

# Runs TestValidatePod in pkg/api/validation with the verbose flag set

make test WHAT=./pkg/api/validation GOFLAGS="-v" KUBE_TEST_ARGS='-run ^TestValidatePod$'

# Runs tests that match the regex ValidatePod|ValidateConfigMap in pkg/api/validation

make test WHAT=./pkg/api/validation GOFLAGS="-v" KUBE_TEST_ARGS="-run ValidatePod|ValidateConfigMap$"

压力测试
make test PARALLEL=2 ITERATION=5

生成覆盖率
make test PARALLEL=2 ITERATION=5

make test WHAT=./pkg/kubectl KUBE_COVER=y　　＃only one package-k8s-images

Benchmark unit tests

go test ./pkg/apiserver -benchmem -run=XXX -bench=BenchmarkWatch

集成测试Integration tests
End-to-End tests 
https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md
```

flake free tests

glog日志打印级别 
glog.Errorf() 
glog.Warningf() 
glog.Infof　info级别的日志又分成五个级别，范围依次变高 
glog.V(0) ＜glog.V(1)＜glog.V(２)＜glog.V(３) ＜glog.V(４) 
可以通过－ｖ＝X来设置X is the descired maximum level to log.
profiling kubernetes
add a new metrics to kubernetes code.
代码规范
文档规范
运行a fast and lightweight local cluster deployment for development
Kuberntes API的开发
REST API文档
Annotations：用于将任意的非识别元数据附加到对象。 自动化Kubernetes对象的程序可能会使用注释来存储少量的状态。
API conventions(约定)
插件开发
Authentication　认证插件　
Authorization Plugins　授权插件
Admission Control Plugins 准入插件
发布流程
具体流程