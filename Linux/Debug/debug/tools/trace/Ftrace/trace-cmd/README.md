
# trace-cmd -h

```
# trace-cmd -h

trace-cmd version 2.9.dev (a000c8831054acf53ec7348e0a7edf8d828187d7)

usage:
  trace-cmd [COMMAND] ...

  commands:
     将系统当前的trace保存到trace.dat中
     record - record a trace into a trace.dat file
     start和stop配置使用，用于开始停止录制
     start - start tracing without recording into a file
     extract - extract a trace from the kernel
     stop - stop the kernel from recording trace data
     restart - restart the kernel trace data recording
     读取 /sys/kernel/debug/tracing/trace
     show - show the contents of the kernel tracing buffer
     重置所有ftrace的设置和ring buffer复位
     reset - disable all kernel tracing and clear the trace buffers
     clear - clear the trace buffers
     report - read out the trace stored in a trace.dat file
     实时在shell中显式ftrace结果
     stream - Start tracing and read the output directly
     profile - Start profiling and read the output directly
     对trace.dat显式统计信息
     hist - show a histogram of the trace.dat information
     显示当前ftrace的events、ring buffer等情况
     stat - show the status of the running tracing (ftrace) system
     split - parse a trace.dat file into smaller file(s)
     options - list the plugin options available for trace-cmd report
     listen - listen on a network socket for trace clients
     显示当前ftrace支持的events、tracers、options
     list - list the available events, plugins or options
     restore - restore a crashed record
     snapshot - take snapshot of running trace
     echo 1 > /proc/sys/kernel/stack_tracer_enabled打开stack_tracer，然后trace-cmd stack查看
     stack - output, enable or disable kernel stack tracing
     check-events - parse trace event formats
     dump - read out the meta data from a trace file
```

trace-cmd record开始记录，ctrl+c停止记录并保存到trace.dat中。

还可以通过trace-cmd reset对各种设置进行复位，然后trace-cmd start进行录制，trace-cmd stop停止录制，trace-cmd extract将数据保存到trace.dat中。

# trace-cmd record

trace-cmd record用于录制ftrace信息，通过如下选项可以指定只跟踪**特定traceevents**，或者跟踪**特定pid**、或者跟踪**特定funtion/function_graph函数**。

还可以设置cpumask、ringbuffer大小等等。

```
# trace-cmd record -h

trace-cmd version 2.9.dev (a000c8831054acf53ec7348e0a7edf8d828187d7)

usage:
 trace-cmd record [-v][-e event [-f filter]][-p plugin][-F][-d][-D][-o file] \
           [-q][-s usecs][-O option ][-l func][-g func][-n func] \
           [-P pid][-N host:port][-t][-r prio][-b size][-B buf][command ...]
           [-m max][-C clock]
          指定只抓取某一事件或者某一类型事件
          -e run command with event enabled
          -f filter for previous -e event
          -R trigger for previous -e event
          -p run command with plugin enabled
          -F filter only on the given process
          只跟踪某一个pid
          -P trace the given pid like -F for the command
          -c also trace the children of -F (or -P if kernel supports it)
          -C set the trace clock
          -T do a stacktrace on all events
          下面这5个选项对应ftrace的设置set_ftrace_filter、set_graph_function、set_ftrace_notrace、buffer_size_kb、tracing_cpumask
          -l filter function name
          -g set graph function
          -n do not trace function
          -m max size per CPU in kilobytes
          -M set CPU mask to trace
          -v will negate all -e after it (disable those events)
          -d disable function tracer when running
          -D Full disable of function tracing (for all users)
          指定输出文件名
          -o data output file [default trace.dat]
          -O option to enable (or disable)
          -r real time priority to run the capture threads
          默认1ms保存一次数据，加大有利于将此操作频率。1000000变成1s写一次数据。
          -s sleep interval between recording (in usecs) [default: 1000]
          -S used with --profile, to enable only events in command line
          -N host:port to connect to (see listen)
          -t used with -N, forces use of tcp in live trace
          改变ring buffer大小
          -b change kernel buffersize (in kilobytes per CPU)
          -B create sub buffer and following events will be enabled here
          -k do not reset the buffers after tracing.
          -i do not fail if an event is not found
          -q print no output to the screen
          --quiet print no output to the screen
          --module filter module name
          --by-comm used with --profile, merge events for related comms
          --profile enable tracing options needed for report --profile
          --func-stack perform a stack trace for function tracer
             (use with caution)
          --max-graph-depth limit function_graph depth
          --cmdlines-size change kernel saved_cmdlines_size
          --no-filter include trace-cmd threads in the trace
          --proc-map save the traced processes address map into the trace.dat file
          --user execute the specified [command ...] as given user
```

如下表示只记录`sched_switch`和s`ched_wakeup`两个事件，每1s写入一次数据。

```
trace-cmd record -e sched_switch -e sched_wakeup -s 1000000
```

# 正确发送ctrl+c

在使用trace-cmd record记录事件的时候，通过ctrl+c可以停止记录。

但是如果在adb shell中，ctrl+c可能优先退出了shell，而没有正常停止trace-cmd record。

最终在目录下只有trace.dat.cpuX的文件，这些文件是中间文件，kernelshark是无法解析的

解决方法有两种，一是在串口console中ctrl+c，另一种是通过kill发送SIGINT信号kill -2 pid。