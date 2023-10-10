const std = @import("std");
const raylib = @import("submodules/raylib.zig/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig",
        .root_source_file = .{ .path = "code/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    raylib.addTo(b, exe, target, optimize);

    b.installArtifact(exe);

    // ====== Steps

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ====== Tests

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "code/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
