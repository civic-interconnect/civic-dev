// src/commands/run.zig
//
// Auto-detects repo type (Python or PWA) and starts the appropriate environment.
// Falls back to prompting the user if type cannot be determined.

const std = @import("std");
const subprocess = @import("subprocess");
const fs_utils = @import("fs_utils");

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    const repo_type = try detectRepoType();

    if (std.mem.eql(u8, repo_type, "python")) {
        try stdout.print("Detected Python repo.\n", .{});
        try subprocess.run("civic-dev", &[_][]const u8{"start-py"});
    } else if (std.mem.eql(u8, repo_type, "pwa")) {
        try stdout.print("Detected PWA repo.\n", .{});
        try subprocess.run("civic-dev", &[_][]const u8{"start-pwa"});
    } else {
        try stdout.print("Could not detect repo type. Please specify manually.\n", .{});
    }
}

pub fn detectRepoType() ![]const u8 {
    if (fs_utils.fileExists("pyproject.toml")) {
        return "python";
    }
    if (fs_utils.fileExists("package.json")) {
        return "pwa";
    }
    return "unknown";
}
