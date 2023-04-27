const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("kw-policy-zig", "src/main.zig", b.version(1, 0, 0));
    lib.setTarget(CrossTarget{ .cpu_arch = .wasm32, .os_tag = .wasi });
    lib.setBuildMode(mode);
    lib.addPackagePath("wapc", "deps/wapc-guest-zig/wapc.zig");
    lib.install();

    const main_tests = b.addTest("src/test.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
