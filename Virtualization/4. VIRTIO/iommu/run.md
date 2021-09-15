
git submodule update --init --recursive

./configure --target-list=x86_64-softmmu --enable-debug

make -j8