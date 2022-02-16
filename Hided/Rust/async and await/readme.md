

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
tokio::runtime::Builder::new_multi_thread().enable_all().build().unwrap().block_on(#[lang = "from_generator"](|mut _task_context|
{
    let op = say_world();
    match op
        {
        mut pinned => loop {
            match unsafe
                  {
                      #[lang = "poll"](#[lang = "new_unchecked"](&mut pinned),
                                       #[lang = "get_context"](_task_context))
                  }
                {
                    #[lang = "Ready"] {
                    0: result
                    } =>
                    break result,
                    #[lang = "Pending"] { } =>
                    {
                    }
                }

            _task_context = (yield());
        },
    };
}))
```

抛去那么多 attribute ，大概流程就是不挺的 loop ，查看 Future（这里的 op） 是否 ready。如果已经是 ready 的状态，那么就会对该结果进行处理，然后退出；否则（Pending的状态）就继续等待，让 runtime 调度其他 task 。

Future 在 tokio 里就“是”一个 task（确切说是 future.await？），tokio runtime 负责调度 task ，task 有些像 goroutine，不过 Rust 本身不自带 runtime 的实现。

根据[这里](https://rust-lang.github.io/rfcs/2394-async_await.html#the-expansion-of-await)对 `await!` 宏的说明：

```rust
let mut future = IntoFuture::into_future($expression);
let mut pin = unsafe { Pin::new_unchecked(&mut future) };
loop {
    match Future::poll(Pin::borrow(&mut pin), &mut ctx) {
          Poll::Ready(item) => break item,
          Poll::Pending     => yield,
    }
}
```

以及[这里](https://rust-lang.github.io/rfcs/2033-experimental-coroutines.html)

```rust
#[async]
fn print_lines() -> io::Result<()> {
    let addr = "127.0.0.1:8080".parse().unwrap();
    let tcp = await!(TcpStream::connect(&addr))?;
    let io = BufReader::new(tcp);

    #[async]
    for line in io.lines() {
        println!("{}", line);
    }

    Ok(())
}
```


# Reference

Rust async/await 内部是怎么实现的: http://liubin.org/blog/2021/04/15/async-slash-await-internal/