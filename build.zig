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
        .{ .name = "run_cmd", .path = "src/commands/run_cmd.zig" },
        .{ .name = "setup_py", .path = "src/commands/setup_py.zig" },
        .{ .name = "start_py", .path = "src/commands/start_py.zig" },
        .{ .name = "sync_files", .path = "src/commands/sync_files.zig" },

        .{ .name = "embedded_root_files", .path = "src/utils/embedded_root_files.zig" },
        .{ .name = "fs_utils", .path = "src/utils/fs_utils.zig" },
        .{ .name = "policy_file_loader", .path = "src/utils/policy_file_loader.zig" },
        .{ .name = "policy_defaults", .path = "src/utils/policy_defaults.zig" },
        .{ .name = "repo_utils", .path = "src/utils/repo_utils.zig" },
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

    // List all util modules and add them to civic_dev
    const civic_deps = &[_][]const u8{
        "embedded_root_files",
        "fs_utils",
        "policy_defaults",
        "policy_file_loader",
        "repo_utils",
        "subprocess",
        "sync_utils",
        "toml_utils",
    };
    for (civic_deps) |dep| {
        mods.get("civic_dev").?.addImport(dep, mods.get(dep).?);
    }

    // add additional individual imports for each command module
    mods.get("bump_version").?.addImport("fs_utils", mods.get("fs_utils").?);

    mods.get("check_policy").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("check_policy").?.addImport("policy_defaults", mods.get("policy_defaults").?);
    mods.get("check_policy").?.addImport("repo_utils", mods.get("repo_utils").?);

    mods.get("layout").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("layout").?.addImport("policy_defaults", mods.get("policy_defaults").?);

    mods.get("release").?.addImport("bump_version", mods.get("bump_version").?);
    mods.get("release").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("release").?.addImport("subprocess", mods.get("subprocess").?);

    mods.get("run_cmd").?.addImport("fs_utils", mods.get("fs_utils").?);
    mods.get("run_cmd").?.addImport("repo_utils", mods.get("repo_utils").?);
    mods.get("run_cmd").?.addImport("subprocess", mods.get("subprocess").?);

    mods.get("setup_py").?.addImport("fs_utils", mods.get("fs_utils").?);

    mods.get("start_py").?.addImport("fs_utils", mods.get("fs_utils").?);

    mods.get("sync_files").?.addImport("repo_utils", mods.get("repo_utils").?);
    mods.get("sync_files").?.addImport("sync_utils", mods.get("sync_utils").?);

    // add additional individual imports for each utility module

    mods.get("repo_utils").?.addImport("fs_utils", mods.get("fs_utils").?);

    mods.get("sync_utils").?.addImport("embedded_root_files", mods.get("embedded_root_files").?);
    mods.get("sync_utils").?.addImport("fs_utils", mods.get("fs_utils").?);

    mods.get("toml_utils").?.addImport("fs_utils", mods.get("fs_utils").?);

    b.installArtifact(exe);

    //
    // === BUILD DOCS ===
    //

    // Generate docs into zig-out/docs
    const install_docs = b.addInstallDirectory(.{
        .source_dir = exe.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    // Run PowerShell script to clean ./docs
    const clean_docs_step = b.addSystemCommand(&.{
        "powershell",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "docs_clean.ps1",
    });

    // Define the docs build step
    const docs_step = b.step("docs", "Generate and install project documentation");
    docs_step.dependOn(&install_docs.step);
    docs_step.dependOn(&clean_docs_step.step);

    //
    // === BUILD TESTS ===
    //

    const test_exe = b.addTest(.{
        .root_source_file = b.path("src/tests/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    if (target.result.os.tag == .windows) {
        test_exe.linkSystemLibrary("advapi32");
    }

    // Add module imports as needed
    addImports(test_exe.root_module, mods);

    const run_tests = b.addRunArtifact(test_exe);

    // use either zig build test or zig build tests
    b.step("test", "Run all tests.").dependOn(&run_tests.step);
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
