//! src/utils/subprocess.zig
//!
//! # Civic Interconnect: Subprocess Utilities
//!
//! Provides utilities for running external commands from Zig.
//!
//! ## Features
//!
//! - `run(prog, args)`
//!     Executes an external command with arguments.
//!     Prints the command line to stdout.
//!     Fails if the command exits with a non-zero code
//!     or is terminated by a signal.
//!
//! ## Example
//!
//! ```zig
//! const subprocess = @import("subprocess");
//!
//! try subprocess.run("echo", &[_][]const u8{"hello, world"});
//! ```

const std = @import("std");

/// Returned if the external command fails for any reason.
pub const CommandFailed = error{CommandFailed};

/// Runs an external command with arguments.
/// Prints the command to stdout and checks its exit status.
///
/// Returns:
/// - `void` if the command succeeded (exit code 0)
/// - `CommandFailed` if the command failed or was terminated
pub fn run(prog: []const u8, args: []const []const u8) !void {
    var stdout = std.io.getStdOut().writer();

    try stdout.print("Running: {s}", .{prog});
    for (args) |arg| {
        try stdout.print(" {s}", .{arg});
    }
    try stdout.print("\n", .{});

    const allocator = std.heap.page_allocator;

    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();

    try argv.append(prog);
    for (args) |arg| {
        try argv.append(arg);
    }

    var child = std.process.Child.init(argv.items, allocator);

    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const result = try child.spawnAndWait();

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                try stdout.print("ERROR: Command failed with exit code {}\n", .{code});
                return error.CommandFailed;
            }
        },
        .Signal => |sig| {
            try stdout.print("ERROR: Command terminated by signal {}\n", .{sig});
            return error.CommandFailed;
        },
        .Stopped => |sig| {
            try stdout.print("ERROR: Command stopped by signal {}\n", .{sig});
            return error.CommandFailed;
        },
        .Unknown => |value| {
            try stdout.print("ERROR: Command ended with unknown result {}\n", .{value});
            return error.CommandFailed;
        },
    }
}
