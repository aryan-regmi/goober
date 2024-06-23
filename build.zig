const std = @import("std");
const sdl = @import("./vendor/sdl/SDL.zig/build.zig");

// TODO: Add step that looks for sdl on system and installs it if not found!

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Deps
    const sdl_sdk = sdl.init(b, null);

    // Lib
    const lib = b.addStaticLibrary(.{
        .name = "goober",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    sdl_sdk.link(lib, .dynamic);
    lib.root_module.addImport("sdl2", sdl_sdk.getNativeModule());
    b.installArtifact(lib);

    // Tests
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    sdl_sdk.link(lib_unit_tests, .dynamic);
    lib_unit_tests.root_module.addImport("sdl2", sdl_sdk.getNativeModule());
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
