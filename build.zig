// build.zig
//
// Civic Interconnect Project - civic-dev CLI
//
// This build script defines how to compile the civic-dev Zig application.
// It performs:
//   - registering all modules for the application
//   - wiring module dependencies
//   - building the CLI executable
//   - setting up automated tests for each test file
//

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //
    // === MODULE REGISTRATION ===
    //

    const mod_paths = [_]struct {
        name: []const u8,
        path: []const u8,
    }{
        .{ .name = "civic_dev", .path = "src/civic_dev.zig" },

        .{ .name = "bump_version", .path = "src/commands/bump_version.zig" },
        .{ .name = "check_policy", .path = "src/commands/check_policy.zig" },
        .{ .name = "layout", .path = "src/commands/layout.zig" },
        .{ .name = "release", .path = "src/commands/release.zig" },
        .{ .name = "run", .path = "src/commands/run.zig" },
        .{ .name = "setup_py", .path = "src/commands/setup_py.zig" },
        .{ .name = "start_py", .path = "src/commands/start_py.zig" },
        .{ .name = "sync_files", .path = "src/commands/sync_files.zig" },

        .{ .name = "fs_utils", .path = "src/utils/fs_utils.zig" },
        .{ .name = "policy_file_loader", .path = "src/utils/policy_file_loader.zig" },
        .{ .name = "policy_defaults", .path = "src/utils/policy_defaults.zig" },
        .{ .name = "subprocess", .path = "src/utils/subprocess.zig" },
        .{ .name = "sync_utils", .path = "src/utils/sync_utils.zig" },
        .{ .name = "toml_utils", .path = "src/utils/toml_utils.zig" },
    };

    // Map module name to *Module
    var mods = std.StringHashMap(*std.Build.Module).init(b.allocator);

    for (mod_paths) |m| {
        const mod = addModule(b, m.name, m.path);
        mods.put(m.name, mod) catch unreachable;
    }

    //
    // === BUILD EXECUTABLE ===
    //

    const exe = b.addExecutable(.{
        .name = "civic-dev",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Wire all modules as imports to the executable
    addImports(exe.root_module, mods);

    // Wire individual dependencies
    mods.get("run").?.addImport("fs_utils", mods.get("fs_utils").?);

    const civic_deps = &[_][]const u8{
        "fs_utils",
        "policy_file_loader",
        "policy_defaults",
        "subprocess",
        "sync_utils",
        "toml_utils",
    };
    for (civic_deps) |dep| {
        mods.get("civic_dev").?.addImport(dep, mods.get(dep).?);
    }

    mods.get("bump_version").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("check_policy").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("check_policy").?.addImport("policy_defaults", mods.get("policy_defaults").?);
    mods.get("layout").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("layout").?.addImport("policy_defaults", mods.get("policy_defaults").?);
    mods.get("release").?.addImport("bump_version", mods.get("bump_version").?);
    mods.get("release").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("release").?.addImport("subprocess", mods.get("subprocess").?);
    mods.get("setup_py").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("start_py").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("sync_files").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("sync_utils").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("toml_utils").?.addImport("fs_utils", mods.get("fs_utils").?);

    b.installArtifact(exe);

    //
    // === BUILD TESTS ===
    //

    const test_files = &[_][]const u8{
        "src/tests/test_bump_version.zig",
        "src/tests/test_check_policy.zig",
        "src/tests/test_layout.zig",
        "src/tests/test_release.zig",
        "src/tests/test_run.zig",
        "src/tests/test_setup_py.zig",
        "src/tests/test_start_py.zig",
        "src/tests/test_sync_files.zig",
        "src/tests/utils/test_fs_utils.zig",
        "src/tests/utils/test_policy_defaults.zig",
        "src/tests/utils/test_policy_file_loader.zig",
        "src/tests/utils/test_subprocess.zig",
        "src/tests/utils/test_sync_utils.zig",
        "src/tests/utils/test_toml_utils.zig",
    };

    var test_steps = std.ArrayList(*std.Build.Step).init(b.allocator);
    defer test_steps.deinit();

    for (test_files) |file_path| {
        const t = addTestForFile(b, file_path, target, optimize, mods);
        test_steps.append(t) catch unreachable;
    }

    const test_step = b.step("test", "Run all tests.");
    for (test_steps.items) |s| {
        test_step.dependOn(s);
    }
}

//
// === HELPER FUNCTIONS ===
//

// Adds a module to the build and returns a pointer to it.
fn addModule(
    b: *std.Build,
    name: []const u8,
    rel_path: []const u8,
) *std.Build.Module {
    return b.addModule(name, .{
        .root_source_file = b.path(rel_path),
    });
}

// Adds all modules as imports into another module.
fn addImports(
    mod: *std.Build.Module,
    mods: std.StringHashMap(*std.Build.Module),
) void {
    var it = mods.iterator();
    while (it.next()) |entry| {
        mod.addImport(entry.key_ptr.*, entry.value_ptr.*);
    }
}

fn addTestForFile(
    b: *std.Build,
    file_path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    mods: std.StringHashMap(*std.Build.Module),
) *std.Build.Step {
    const t = b.addTest(.{
        .root_source_file = b.path(file_path),
        .target = target,
        .optimize = optimize,
    });

    addImports(t.root_module, mods);

    const run_test = b.addRunArtifact(t);
    return &run_test.step;
}
