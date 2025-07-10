//! src/commands/release.zig
//!
//! # civic-dev: release Workflow
//!
//! Implements the release workflow for Civic Interconnect projects.
//!
//! This workflow automates:
//! - Pre-commit hook updates
//! - Development dependency installation
//! - Code formatting and linting
//! - Running pre-commit hooks multiple times to ensure clean commits
//! - Running tests (if present)
//! - Committing and pushing changes
//! - Creating and pushing a new git tag
//!
//! Designed to enforce consistent project standards and automate release processes.
//!
//! ## Example
//!
//! To run the release process:
//!
//! ```bash
//! civic-dev release
//! ```

const std = @import("std");
const subprocess = @import("subprocess");
const fs_utils = @import("fs_utils");

/// Runs a shell command in a real subprocess environment.
///
/// Used for production execution of CLI commands.
pub const ProductionRunner = struct {
    /// Executes a command.
    ///
    /// - `cmd`: The binary to run (e.g. `"git"`).
    /// - `args`: Arguments to pass to the command.
    pub fn run(self: ProductionRunner, cmd: []const u8, args: []const []const u8) !void {
        _ = self; // unused
        return subprocess.run(cmd, args);
    }
};

fn commitAndPush(runner: anytype) !void {
    try runner.run("git", &[_][]const u8{ "commit", "-m", "Release commit" });
    try runner.run("git", &[_][]const u8{ "push", "origin", "main" });
}

fn createAndPushTag(runner: anytype, tag: []const u8) !void {
    try runner.run("git", &[_][]const u8{ "tag", tag });
    try runner.run("git", &[_][]const u8{ "push", "origin", tag });
}

fn gitTagExists(tag: []const u8) !bool {
    var child = std.process.Child.init(
        &[_][]const u8{ "git", "tag", "--list", tag },
        std.heap.page_allocator,
    );

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;

    _ = try child.spawn();

    const reader = child.stdout.?;

    const contents = try reader.readToEndAlloc(
        std.heap.page_allocator,
        std.math.maxInt(usize),
    );
    defer std.heap.page_allocator.free(contents);

    return std.mem.containsAtLeast(u8, contents, 1, tag);
}

fn hasStagedChanges() !bool {
    var diff_child = std.process.Child.init(
        &[_][]const u8{
            "git", "diff", "--cached", "--quiet",
        },
        std.heap.page_allocator,
    );
    diff_child.stdin_behavior = .Inherit;
    diff_child.stdout_behavior = .Inherit;
    diff_child.stderr_behavior = .Inherit;

    const result = try diff_child.spawnAndWait();

    return switch (result) {
        .Exited => |code| code == 1,
        .Signal, .Stopped, .Unknown => return error.ChildProcessFailed,
    };
}

fn installDevDependencies(writer: anytype, runner: anytype) !void {
    if (fs_utils.fileExists("pyproject.toml")) {
        try runner.run(
            "uv",
            &[_][]const u8{
                "pip",       "install",
                "--upgrade", "--no-cache-dir",
                "-e",        ".[dev]",
            },
        );
    } else {
        try writer.print("File pyproject.toml not found — skipping install.\n", .{});
    }
}

fn readVersionFromPyproject() ![]const u8 {
    const allocator = std.heap.page_allocator;

    const contents = try std.fs.cwd().readFileAlloc(
        allocator,
        "pyproject.toml",
        std.math.maxInt(usize),
    );
    defer allocator.free(contents);

    var iter = std.mem.tokenizeScalar(u8, contents, '\n');
    while (iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "version")) {
            const eq_index = std.mem.indexOf(u8, trimmed, "=") orelse return error.VersionNotFound;

            const after_eq = std.mem.trim(u8, trimmed[eq_index + 1 ..], " \t");

            if (std.mem.startsWith(u8, after_eq, "\"")) {
                const without_quote = after_eq[1..];
                const quote_end = std.mem.indexOf(u8, without_quote, "\"") orelse return error.VersionNotFound;

                return without_quote[0..quote_end];
            } else {
                const space_end = std.mem.indexOfAny(u8, after_eq, " \t") orelse after_eq.len;
                return after_eq[0..space_end];
            }
        }
    }

    return error.VersionNotFound;
}

fn runLinting(writer: anytype, runner: anytype) !void {
    if (fs_utils.fileExists("pyproject.toml")) {
        try runner.run("ruff", &[_][]const u8{ "format", "." });
        try runner.run("ruff", &[_][]const u8{ "check", ".", "--fix" });
    } else {
        try writer.print("File pyproject.toml not found — skipping ruff checks.\n", .{});
    }
}

fn runPreCommitMultiple(runner: anytype) !void {
    try runner.run("pre-commit", &[_][]const u8{ "run", "--all-files" });
    try runner.run("git", &[_][]const u8{ "add", "." });

    try runner.run("pre-commit", &[_][]const u8{ "run", "--all-files" });
    try runner.run("git", &[_][]const u8{ "add", "." });

    try runner.run("pre-commit", &[_][]const u8{ "run", "--all-files" });
}

/// Runs the entire release workflow for Civic Interconnect projects.
///
/// The workflow includes:
/// - Updating pre-commit hooks
/// - Installing development dependencies
/// - Running code formatting and linting
/// - Running pre-commit multiple times to ensure all issues are fixed
/// - Running tests
/// - Committing and pushing changes if necessary
/// - Tagging and pushing a new version
///
/// Returns:
/// - Exit code `0` if the release was successful.
/// - Exit code `1` if the git tag already exists or an error occurs.
///
/// ## Example
///
/// ```zig
/// const stdout = std.io.getStdOut().writer();
/// const exit_code = try runReleaseWorkflow(stdout, ProductionRunner{});
/// if (exit_code == 0) {
///     std.debug.print("Release finished successfully!\n", .{});
/// }
/// ```
pub fn runReleaseWorkflow(writer: anytype, runner: anytype) !u8 {
    try writer.print("Starting release workflow...\n", .{});

    try updatePreCommit(runner);
    try installDevDependencies(writer, runner);
    try runLinting(writer, runner);
    try runPreCommitMultiple(runner);
    try runTests(writer, runner);

    const has_changes = try hasStagedChanges();
    if (has_changes) {
        try commitAndPush(runner);
    } else {
        try writer.print("No changes to commit.\n", .{});
    }

    const version = try readVersionFromPyproject();
    const tag = try std.fmt.allocPrint(std.heap.page_allocator, "v{s}", .{version});
    defer std.heap.page_allocator.free(tag);

    if (try gitTagExists(tag)) {
        try writer.print(
            "Tag {s} already exists. Please bump the version first.\n",
            .{tag},
        );
        return 1;
    }

    try createAndPushTag(runner, tag);
    try writer.print("Release {s} completed successfully.\n", .{tag});

    return 0;
}

fn runTests(writer: anytype, runner: anytype) !void {
    if (fs_utils.dirExists("tests") and fs_utils.fileExists("pyproject.toml")) {
        try runner.run("pytest", &[_][]const u8{"tests"});
    } else {
        try writer.print("No tests/ directory found. Skipping tests.\n", .{});
    }
}

fn updatePreCommit(runner: anytype) !void {
    try runner.run(
        "pre-commit",
        &[_][]const u8{
            "autoupdate",
            "--repo",
            "https://github.com/pre-commit/pre-commit-hooks",
        },
    );
}

/// CLI entry point for the release command.
///
/// Runs the full release workflow using `ProductionRunner`.
///
/// ## Example
///
/// ```bash
/// civic-dev release
/// ``
pub fn main() !u8 {
    const stdout = std.io.getStdOut().writer();
    return runReleaseWorkflow(stdout, ProductionRunner{});
}
