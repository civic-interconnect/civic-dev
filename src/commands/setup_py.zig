//! src/commands/setup_py.zig
//!
//! # civic-dev: setup-py Command
//!
//! Rebuilds and sets up a Python virtual environment for Civic Interconnect projects.
//!
//! This command performs:
//! - Pulling the latest repo changes
//! - Cleaning caches and build folders
//! - Removing `.venv` if it exists
//! - Recreating the virtual environment using uv
//! - Installing dev dependencies in editable mode
//! - Running pre-commit hooks
//! - Running civic-dev layout and other checks
//!
//! This helps ensure a clean, reproducible Python environment for development.
//!
//! ## Example
//!
//! To rebuild the Python virtual environment and verify the project:
//!
//! ```bash
//! civic-dev setup-py
//! ```

const std = @import("std");
const subprocess = @import("subprocess");
const fs_utils = @import("fs_utils");

fn cleanBuildDirs() !void {
    const dirs = [_][]const u8{
        ".pytest_cache",
        ".ruff_cache",
        "build",
        "dist",
        "docs",
    };

    for (dirs) |d| {
        if (fs_utils.dirExists(d)) {
            try std.fs.cwd().deleteTree(d);
            var stdout = std.io.getStdOut().writer();
            try stdout.print("Deleted dir: {s}\n", .{d});
        }
    }
}

fn cleanPyCache() !void {
    try removeMatchingDirs("__pycache__");
    try removeMatchingDirs(".egg-info");
}

fn removeMatchingDirs(pattern: []const u8) !void {
    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind == .directory or entry.kind == .sym_link) {
            if (std.mem.endsWith(u8, entry.name, pattern)) {
                try std.fs.cwd().deleteTree(entry.name);
                var stdout = std.io.getStdOut().writer();
                try stdout.print("Removed dir: {s}\n", .{entry.name});
            }
        } else if (entry.kind == .file) {
            if (std.mem.endsWith(u8, entry.name, pattern)) {
                try std.fs.cwd().deleteFile(entry.name);
                var stdout = std.io.getStdOut().writer();
                try stdout.print("Removed file: {s}\n", .{entry.name});
            }
        }
    }
}

/// CLI entry point for civic-dev setup-py.
///
/// Sets up a fresh Python virtual environment for Civic Interconnect projects.
///
/// Steps performed:
/// - Pulls the latest git changes.
/// - Cleans build and cache directories.
/// - Removes the existing `.venv`.
/// - Creates a new virtual environment with `uv`.
/// - Installs dev dependencies.
/// - Verifies civic-dev configuration and pre-commit hooks.
/// - Runs layout and build checks.
///
/// Prints progress messages and confirms successful setup.
///
/// ## Example
///
/// ```bash
/// civic-dev setup-py
/// ```
pub fn main() !void {
    var stdout = std.io.getStdOut().writer();
    try stdout.print("Running civic-dev setup-py...\n", .{});
    try subprocess.run("git", &[_][]const u8{"pull"});
    try cleanPyCache();
    try cleanBuildDirs();
    try fs_utils.removeVenv();
    try subprocess.run("uv", &[_][]const u8{ "venv", ".venv" });
    try subprocess.run("uv", &[_][]const u8{ "self", "update" });

    try subprocess.run(
        "uv",
        &[_][]const u8{
            "pip",       "install",
            "--upgrade", "--no-cache-dir",
            "-e",        ".[dev]",
        },
    );

    try subprocess.run(
        "python",
        &[_][]const u8{
            "-c",
            "import civic_lib_core.cli.cli; print(civic_lib_core.cli.cli.__file__)",
        },
    );

    try subprocess.run("pre-commit", &[_][]const u8{"install"});
    try subprocess.run("pre-commit", &[_][]const u8{"autoupdate"});
    try subprocess.run("pre-commit", &[_][]const u8{ "run", "--all-files" });
    try subprocess.run("pre-commit", &[_][]const u8{ "run", "--all-files" });
    try subprocess.run("civic-dev", &[_][]const u8{"layout"});
    try subprocess.run("civic-dev", &[_][]const u8{"build-api"});
    try subprocess.run("civic-dev", &[_][]const u8{"prep-code"});
    try stdout.print("\nSetup completed successfully.\n", .{});
}
