

官方文档: `Documentation/dev-tools/kselftest.rst`

```
yum install libcap-devel -y

yum install libmount-devel -y

yum install libcap-ng-devel -y

yum install libmnl-devel -y



```

`tools/testing/selftests/kvm`

make -C tools/testing/selftests TARGETS=kvm

make -C tools/testing/selftests TARGETS=kvm run_tests

