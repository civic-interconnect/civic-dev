//!
//! # Civic Dev CLI Wrapper Module
//!
//! This module serves as the **central import hub** for the civic-dev CLI.
//!
//! ## Responsibilities
//!
//! - Imports and re-exports all CLI commands.
//! - Provides unified public functions for each subcommand.
//! - Keeps CLI wiring clean and centralized.
//!
//! ## Usage
//!
//! Each public function in this module represents a civic-dev CLI command.
//!
//! ```zig
//! const civic_dev = @import("civic_dev");
//! try civic_dev.bumpVersion("1.0.0", "1.0.1");
//! ```

const std = @import("std");

const bump_version = @import("commands/bump_version.zig");
const check_policy = @import("commands/check_policy.zig");
const layout = @import("commands/layout.zig");
const release = @import("commands/release.zig");
const run_cmd = @import("commands/run_cmd.zig");
const setup_py = @import("commands/setup_py.zig");
const start_py = @import("commands/start_py.zig");
const sync_files = @import("commands/sync_files.zig");

/// Bumps version numbers in all configured project files.
///
/// Scans project files for the old version string and replaces it
/// with the new version string. Prints a summary of changes.
///
/// Wraps `commands/bump_version.zig`.
///
/// - `old_version`: the string to replace (e.g. `"1.0.0"`).
/// - `new_version`: the string to replace it with (e.g. `"1.0.1"`).
///
/// ## Example
///
/// ```zig
/// try civic_dev.bumpVersion("1.0.0", "1.0.1");
/// ```
pub fn bumpVersion(old_version: []const u8, new_version: []const u8) !void {
    return bump_version.bumpVersion(old_version, new_version);
}

/// Checks whether a Civic Interconnect project complies with the
/// standard repository policy.
///
/// Loads the policy definition from JSON using the provided loader function.
/// Verifies that all required files and directories exist.
///
/// Returns an exit code:
/// - `0` → policy compliance
/// - `1` → policy issues detected
///
/// Wraps `commands/check_policy.zig`.
///
/// ## Example
///
/// ```zig
/// const exit_code = try civic_dev.checkPolicy(
///     policy_defaults.loadEmbeddedPolicy,
///     try std.fs.cwd().openDir(".", .{}),
///     std.heap.page_allocator,
/// );
///
/// if (exit_code == 0) {
///     std.debug.print("Project is compliant.\n", .{});
/// } else {
///     std.debug.print("Policy issues detected.\n", .{});
/// }
/// ```
pub fn checkPolicy(
    policy_file_loader_func: fn (allocator: std.mem.Allocator) anyerror!std.json.Parsed(std.json.Value),
    dir: std.fs.Dir,
    allocator: std.mem.Allocator,
) !u8 {
    return check_policy.main(policy_file_loader_func, dir, allocator);
}

/// Prints a summary of the Civic Interconnect project layout.
///
/// Displays important files and directories, helping users understand
/// the repo structure.
///
/// Wraps `commands/layout.zig`.
///
/// ## Example
///
/// ```zig
/// try civic_dev.showLayout(std.heap.page_allocator);
/// ```
pub fn showLayout(allocator: std.mem.Allocator) !void {
    return layout.main(allocator);
}

/// Prepares the repo for a release and bumps the version number.
///
/// Executes pre-release checks and updates relevant files.
///
/// Wraps `commands/release.zig`.
///
/// ## Example
///
/// ```zig
/// const exit_code = try civic_dev.releaseProject();
/// if (exit_code == 0) {
///     std.debug.print("Release completed successfully.\n", .{});
/// }
/// ```
pub fn releaseProject() !u8 {
    return release.main();
}

/// Automatically detects the repo type (Python or PWA)
/// and runs the appropriate environment setup commands.
///
/// For Python projects, automatically starts the Python environment.
/// For PWA projects, prints manual instructions.
///
/// Wraps `commands/run_cmd.zig`.
///
/// ## Example
///
/// ```zig
/// try civic_dev.runAuto();
/// ```
pub fn runAuto() !void {
    return run_cmd.main();
}

/// Prepares the Python environment for Civic Interconnect projects.
///
/// Sets up necessary virtual environments or dependencies.
///
/// Wraps `commands/setup_py.zig`.
///
/// ## Example
///
/// ```zig
/// try civic_dev.setupPy();
/// ```
pub fn setupPy() !void {
    return setup_py.main();
}

/// Starts the Python development environment for Civic Interconnect projects.
///
/// Activates virtual environments or launches Python processes as needed.
///
/// Wraps `commands/start_py.zig`.
///
/// ## Example
///
/// ```zig
/// try civic_dev.startPy();
/// ```
pub fn startPy() !void {
    return start_py.main();
}

/// Synchronizes shared Civic Interconnect files into the current repository.
///
/// Copies root-level files (like `.gitignore`) and
/// project-specific files for Python or PWA projects.
/// Only overwrites files if content differs.
///
/// Wraps `commands/sync_files.zig`.
///
/// ## Example
///
/// ```zig
/// try civic_dev.syncFiles();
/// ```
pub fn syncFiles() !void {
    return sync_files.main();
}
