// src/commands/start_py.zig
//
// Starts a fresh Python dev environment for Civic Interconnect.
//
// Removes any existing virtualenv, re-creates it with uv,
// installs dev dependencies in editable mode,
// verifies pre-commit hooks, and runs tests.
//
// Cross-platform safe for Windows and UNIX environments.

const std = @import("std");
const subprocess = @import("subprocess");
const fs_utils = @import("fs_utils");

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();
    try stdout.print("Starting Python Dev Environment...\n", .{});

    // Pull latest code
    try subprocess.run("git", &[_][]const u8{"pull"});

    // Remove old .venv if it exists
    try removeVenv();

    // Create new .venv
    try subprocess.run("uv", &[_][]const u8{ "venv", ".venv" });

    // Update uv itself
    try subprocess.run("uv", &[_][]const u8{ "self", "update" });

    // Install dev dependencies in editable mode
    try subprocess.run(
        "uv",
        &[_][]const u8{
            "pip",
            "install",
            "--upgrade",
            "--no-cache-dir",
            "-e",
            ".[dev]",
        },
    );

    // Pre-commit setup
    try subprocess.run("pre-commit", &[_][]const u8{"install"});
    try subprocess.run("pre-commit", &[_][]const u8{"autoupdate"});
    try subprocess.run("pre-commit", &[_][]const u8{ "run", "--all-files" });

    // Run tests if tests dir exists
    if (fs_utils.dirExists("tests")) {
        try subprocess.run("pytest", &[_][]const u8{"tests"});
    } else {
        try stdout.print("No tests/ directory found. Skipping tests.\n", .{});
    }

    try stdout.print("\nPython environment ready!\n", .{});
}

fn removeVenv() !void {
    if (fs_utils.dirExists(".venv")) {
        try std.fs.cwd().deleteTree(".venv");
        var stdout = std.io.getStdOut().writer();
        try stdout.print("Removed old .venv\n", .{});
    }
}
