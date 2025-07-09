// civic-dev/src/main.zig
//
// Civic Interconnect Project - civic-dev CLI
//
// Entry point for the civic-dev Zig application.
//
// Features:
//   - Handles command-line arguments
//   - Dispatches to CLI commands
//   - Designed for extensibility
//
// Available commands:
//   - sync-files
//   - start-py
//   - setup-py
//   - run
//   - release
//   - layout
//   - check-policy
//   - bump-version

const std = @import("std");
const civic_dev = @import("civic_dev");
const policy_file_loader = @import("policy_file_loader");
const policy_defaults = @import("policy_defaults");

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    // Create a general-purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip program name

    const cmd = args.next() orelse {
        try printUsage(stdout);
        return;
    };

    // Table of commands
    const Command = struct {
        name: []const u8,
        handler: *const fn (std.mem.Allocator, *std.process.ArgIterator) anyerror!void,
    };

    const commands = [_]Command{
        .{ .name = "sync-files", .handler = runSyncFiles },
        .{ .name = "start-py", .handler = runStartPy },
        .{ .name = "setup-py", .handler = runSetupPy },
        .{ .name = "run", .handler = runAuto },
        .{ .name = "release", .handler = runRelease },
        .{ .name = "layout", .handler = runLayout },
        .{ .name = "check-policy", .handler = runCheckPolicy },
        .{ .name = "bump-version", .handler = runBumpVersion },
    };

    var handled = false;
    for (commands) |entry| {
        if (std.mem.eql(u8, cmd, entry.name)) {
            try entry.handler(allocator, &args);
            handled = true;
            break;
        }
    }

    if (!handled) {
        try stdout.print("Unknown command: {s}\n", .{cmd});
        try printUsage(stdout);
        std.process.exit(1);
    }
}

fn printUsage(stdout: anytype) !void {
    try stdout.print(
        \\Usage: civic-dev <command> [arguments...]
        \\
        \\Available commands:
        \\  sync-files        Sync standard files into a repo
        \\  start-py          Start Python environment
        \\  setup-py          Set up Python environment
        \\  run               Auto-detect and run correct environment
        \\  release           Run release process
        \\  layout            Print project layout info
        \\  check-policy      Check repo files against policy
        \\  bump-version      Update version numbers in files
        \\
    , .{});
}

// Each CLI command has its own function:

fn runAuto(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    _ = args;
    try civic_dev.runAuto();
}

fn runBumpVersion(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;

    const old_version = args.next() orelse {
        std.debug.print("Missing OLD_VERSION.\n", .{});
        std.process.exit(1);
    };

    const new_version = args.next() orelse {
        std.debug.print("Missing NEW_VERSION.\n", .{});
        std.process.exit(1);
    };

    try civic_dev.bumpVersion(old_version, new_version);
}

fn runCheckPolicy(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = args;
    var current_dir = std.fs.cwd();
    defer current_dir.close();

    const exit_code = try civic_dev.checkPolicy(
        policy_defaults.loadEmbeddedPolicy,
        current_dir,
        allocator,
    );

    std.process.exit(exit_code);
}

fn runLayout(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = args;
    try civic_dev.showLayout(allocator);
}

fn runRelease(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    _ = args;
    const exit_code = try civic_dev.releaseProject();
    std.process.exit(exit_code);
}

fn runSetupPy(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    _ = args;
    try civic_dev.setupPy();
}
fn runStartPy(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    _ = args;
    try civic_dev.startPy();
}

fn runSyncFiles(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    _ = args;
    try civic_dev.syncFiles();
}
