//! src/commands/sync_files.zig
//!
//! # civic-dev: sync-files Command
//!
//! Synchronizes shared Civic Interconnect files into the current repo.
//!
//! By default, this command copies:
//! - Shared root-level files (e.g. .gitignore, LICENSE)
//! - Project-specific files (e.g. Python or PWA configs)
//!
//! Only overwrites files if content differs.
//!
//! ## Flags
//!
//! - `--root`
//!     Sync only root-level shared files.
//!
//! - `--project`
//!     Sync only project-specific files (auto-detects project type).
//!
//! - `--project py`
//!     Sync only Python-specific files.
//!
//! - `--project pwa`
//!     Sync only PWA-specific files.
//!
//! ## Examples
//!
//! ```bash
//! civic-dev sync-files
//! civic-dev sync-files --root
//! civic-dev sync-files --project py
//! ```

const std = @import("std");
const sync_utils = @import("sync_utils");
const repo_utils = @import("repo_utils");

/// Prints usage instructions for civic-dev sync-files.
fn printUsage() !void {
    var stdout = std.io.getStdOut().writer();
    try stdout.print(
        \\Usage: civic-dev sync-files [--root] [--project [py|pwa]]
        \\
        \\Options:
        \\  --root             Only sync root shared files
        \\  --project          Only sync project-specific files (auto-detect project type)
        \\  --project py       Force sync Python project files
        \\  --project pwa      Force sync PWA project files
        \\
    , .{});
}

/// CLI entry point for civic-dev sync-files.
///
/// Synchronizes shared Civic Interconnect files into the current repo,
/// based on the provided flags:
/// - Root-level shared files
/// - Project-specific files (auto-detected or explicitly specified)
///
/// Prints progress and warnings as needed.
///
/// ## Example
///
/// ```bash
/// civic-dev sync-files --project py
/// ```
pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var do_root = true;
    var do_project = true;
    var forced_project: ?[]const u8 = null;

    // Parse flags
    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--root")) {
            do_project = false;
        } else if (std.mem.eql(u8, arg, "--project")) {
            do_root = false;
            if (i + 1 < args.len and !std.mem.startsWith(u8, args[i + 1], "--")) {
                forced_project = args[i + 1];
                i += 1;
            }
        } else {
            try stdout.print("Unknown option: {s}\n", .{arg});
            try printUsage();
            return;
        }
    }

    try stdout.print("Running civic-dev sync-files...\n", .{});

    if (do_root) {
        try sync_utils.syncRootFiles();
    }

    if (do_project) {
        var repo_type: []const u8 = "unknown";

        if (forced_project) |proj| {
            repo_type = proj;
        } else {
            repo_type = try repo_utils.detectRepoType();
        }

        if (std.mem.eql(u8, repo_type, "python")) {
            try stdout.print("Syncing Python project files...\n", .{});
            try sync_utils.syncProjectFolder("py");
        } else if (std.mem.eql(u8, repo_type, "pwa")) {
            try stdout.print("Syncing PWA project files...\n", .{});
            try sync_utils.syncProjectFolder("pwa");
        } else {
            try stdout.print("Could not detect project type. Skipping project-specific sync.\n", .{});
        }
    }
}
