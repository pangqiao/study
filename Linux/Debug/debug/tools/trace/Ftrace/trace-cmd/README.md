
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
     list - list the available events, plugins or options
     restore - restore a crashed record
     snapshot - take snapshot of running trace
     stack - output, enable or disable kernel stack tracing
     check-events - parse trace event formats
     dump - read out the meta data from a trace file
```