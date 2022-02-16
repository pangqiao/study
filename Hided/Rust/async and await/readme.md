

Cargo.toml

```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
```

代码:

```rust
async fn say_world() {
    println!("hello world");
}

#[tokio::main]
async fn main() {
    let op = say_world();

    op.await;
}
```


使用 nightly 的 rust

```
rustup default nightly
```

编译

```
cargo rustc -- -Z unpretty=hir
```

```rust

```



# Reference

Rust async/await 内部是怎么实现的: http://liubin.org/blog/2021/04/15/async-slash-await-internal/