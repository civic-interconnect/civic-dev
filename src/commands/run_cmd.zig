//! src/commands/run_cmd.zig
//!
//! # civic-dev: run Command
//!
//! Auto-detects the repository type (Python or PWA) and runs the appropriate
//! environment setup commands.
//!
//! - For Python repos, executes `civic-dev start-py` after a brief pause.
//! - For PWA repos, prints guidance on manual steps.
//! - Falls back to a message if the repo type cannot be detected.
//!
//! Note:
//! This file was renamed to `run_cmd.zig` to avoid confusion with
//! the keyword `run` in Zig or with other process-running functions.

const std = @import("std");
const fs_utils = @import("fs_utils");
const repo_utils = @import("repo_utils");
const subprocess = @import("subprocess");

/// Prints a summary of recommended steps for a PWA repo.
///
/// Informs the user that no automated command currently exists for
/// starting a PWA environment and suggests opening the docs manually
/// or using Live Server.
fn displayPWARunSummary(writer: anytype) !void {
    try writer.print(
        \\Detected PWA repo.
        \\
        \\There is currently no automated `civic-dev start-pwa` command.
        \\Typical next steps:
        \\- Open the docs start page in your browser
        \\- Or run it via VS Code Live Server.
        \\
        \\No actions taken automatically.\n
    ,
        .{},
    );
}

/// Prints a summary of what `start-py` will execute for Python repos.
///
/// Summarizes the steps the CLI will run, including:
/// - installing dev dependencies
/// - running linters and checks
/// - executing tests
fn displayPythonRunSummary(writer: anytype) !void {
    try writer.print(
        \\Detected Python repo.
        \\
        \\civic-dev start-py will:
        \\- Install dev dependencies:
        \\    uv pip install --upgrade --no-cache-dir -e .[dev]
        \\- Run linting and checks:
        \\    ruff format .
        \\    ruff check . --fix
        \\- Run tests:
        \\    pytest tests/
        \\
        \\Proceeding in 2 seconds... Press Ctrl+C to cancel.\n
    ,
        .{},
    );
}

/// CLI entry point for `civic-dev run`.
///
/// Detects the repo type and either runs the Python dev environment,
/// prints instructions for a PWA repo, or reports inability to detect
/// the repo type.
pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    const repo_type = try repo_utils.detectRepoType();

    if (std.mem.eql(u8, repo_type, "python")) {
        try displayPythonRunSummary(stdout);
        std.time.sleep(2_000_000_000);
        try subprocess.run("civic-dev", &[_][]const u8{"start-py"});
    } else if (std.mem.eql(u8, repo_type, "pwa")) {
        try displayPWARunSummary(stdout);
    } else {
        try stdout.print(
            "Could not detect repo type. Please specify manually.\n",
            .{},
        );
    }
}
