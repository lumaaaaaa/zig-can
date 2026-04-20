# zig-can

A minimal Linux SocketCAN raw socket wrapper for Zig.

In development, read-only at the moment.

## Usage

1. Add `can` to your `build.zig.zon`:

```sh
zig fetch --save "git+https://github.com/lumaaaaaa/zig-can#master"
```

2. Use the `can` module. In `build.zig`'s `build()`, add the dependency and import the module:

```zig
pub fn build(b: *std.Build) void {
  // ...

  const can = b.dependency("can", .{
    .target = target,
    .optimize = optimize,
  });

  // and import
  exe.root_module.addImport("can", protobuf_dep.module("can"));

  // ...
```

3. Import and use the library:

```zig
const std = @import("std");
const can = @import("can");

pub fn main(init: std.process.Init) !void {
  var can_sock = try can.Socket.open(io, interface_name);
  defer can_sock.deinit();

  var frame: can.Frame = undefined;
  try can_sock.readFrame(&frame);

  // do something with the frame
}
```
