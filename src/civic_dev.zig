// civic-dev/src/civic_dev.zig
//!
//! Civic Interconnect CLI wrapper module.
//!
//! This module serves as a central import hub for civic-dev. It:
//!   - Imports and re-exports CLI commands.
//!   - Provides unified public functions for each subcommand.
//!   - Keeps CLI wiring clean and centralized.

const std = @import("std");

const bump_version = @import("commands/bump_version.zig");
const check_policy = @import("commands/check_policy.zig");
const layout = @import("commands/layout.zig");
const release = @import("commands/release.zig");
const run = @import("commands/run.zig");
const setup_py = @import("commands/setup_py.zig");
const start_py = @import("commands/start_py.zig");
const sync_files = @import("commands/sync_files.zig");

pub fn bumpVersion(old_version: []const u8, new_version: []const u8) !void {
    return bump_version.bumpVersion(old_version, new_version);
}

pub fn checkPolicy(
    policy_file_loader_func: fn (allocator: std.mem.Allocator) anyerror!std.json.Parsed(std.json.Value),
    dir: std.fs.Dir,
    allocator: std.mem.Allocator,
) !u8 {
    return check_policy.main(policy_file_loader_func, dir, allocator);
}

pub fn showLayout(allocator: std.mem.Allocator) !void {
    return layout.main(allocator);
}

pub fn releaseProject() !u8 {
    return release.main();
}

pub fn runAuto() !void {
    return run.main();
}

pub fn setupPy() !void {
    return setup_py.main();
}

pub fn startPy() !void {
    return start_py.main();
}

pub fn syncFiles() !void {
    return sync_files.main();
}
