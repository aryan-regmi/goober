const std = @import("std");

// TODO: Add step that looks for sdl on system and installs it if not found!

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Lib
    // ========================================
    const lib = b.addStaticLibrary(.{
        .name = "goober",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Deps
    // ========================================
    const sdl = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    const mutt = b.dependency("mutt", .{
        .target = target,
        .optimize = optimize,
    }).module("mutt");

    // Install SDL dep
    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        lib.linkSystemLibrary("SDL2");
        lib.linkLibC();
    } else {
        lib.linkLibrary(sdl.artifact("SDL2"));
    }

    // Install mutt dep
    lib.root_module.addImport("mutt", mutt);

    // Install lib + create module
    // ========================================
    b.installArtifact(lib);
    _ = b.addModule("goober", .{ .root_source_file = b.path("src/lib.zig") });

    // Tests
    // ========================================
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Install SDL dep
    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        lib_unit_tests.linkSystemLibrary("SDL2");
        lib_unit_tests.linkLibC();
    } else {
        lib_unit_tests.linkLibrary(sdl.artifact("SDL2"));
    }

    // Install mutt dep
    lib_unit_tests.root_module.addImport("mutt", mutt);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
