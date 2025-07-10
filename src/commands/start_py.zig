//! src/commands/start_py.zig
//!
//! # civic-dev: start-py Command
//!
//! Starts a fresh Python development environment for Civic Interconnect projects.
//!
//! Performs:
//! - Pulling the latest code from git
//! - Removing any existing `.venv` virtual environment
//! - Creating a new `.venv` using uv
//! - Installing dev dependencies in editable mode
//! - Setting up pre-commit hooks and running them
//! - Running Python tests if the `tests/` directory exists
//!
//! This command is useful for quickly resetting your Python environment
//! to ensure clean installs and working tests.
//!
//! ## Example
//!
//! To start a fresh Python development environment:
//!
//! ```bash
//! civic-dev start-py
//! ```

const std = @import("std");
const subprocess = @import("subprocess");
const fs_utils = @import("fs_utils");

/// CLI entry point for civic-dev start-py.
///
/// Sets up a fresh Python development environment for Civic Interconnect.
///
/// Steps performed:
/// - Pulls latest git changes.
/// - Deletes the `.venv` folder if it exists.
/// - Creates a new virtual environment using `uv`.
/// - Installs dev dependencies in editable mode.
/// - Installs and runs pre-commit hooks.
/// - Runs tests if the `tests/` directory is present.
///
/// Prints progress messages and indicates success.
///
/// ## Example
///
/// ```bash
/// civic-dev start-py
/// ```
pub fn main() !void {
    var stdout = std.io.getStdOut().writer();
    try stdout.print("Starting Python Dev Environment...\n", .{});

    // Pull latest code
    try subprocess.run("git", &[_][]const u8{"pull"});

    // Remove old .venv if it exists
    try fs_utils.removeVenv();

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
