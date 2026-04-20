const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("can", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // check step for zls
    const check_exe = b.addObject(.{
        .name = "check",
        .root_module = mod,
    });
    const check_step = b.step("check", "Check if can compiles");
    check_step.dependOn(&check_exe.step);
}
