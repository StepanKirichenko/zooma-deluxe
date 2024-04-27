const std = @import("std");

const BuildError = error{
    RaypathNotSpecified,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "raylib-exp",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const raypath = std.os.getenv("RAYPATH") orelse {
        std.debug.print("{s}", .{"Error: environment variable RAYPATH should contain the path to libraylib.a\n"});
        return BuildError.RaypathNotSpecified;
    };

    exe.addObjectFile(std.Build.LazyPath{ .path = raypath });
    exe.linkLibC();
    exe.linkFramework("OpenGL");
    exe.linkFramework("Cocoa");
    exe.linkFramework("IOKit");
    exe.linkFramework("CoreAudio");
    exe.linkFramework("CoreVideo");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
