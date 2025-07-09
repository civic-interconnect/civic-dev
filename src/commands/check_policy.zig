// src/commands/check_policy.zig
//
// Checks whether a Civic Interconnect project complies with the standard policy.
// Looks for required files and directories as defined in policy_defaults.zig.

const std = @import("std");
const fs_utils = @import("fs_utils");
const policy_defaults = @import("policy_defaults");

pub fn main(
    policy_file_loader_func: fn (allocator: std.mem.Allocator) anyerror!std.json.Parsed(std.json.Value),
    dir: std.fs.Dir,
    allocator: std.mem.Allocator,
) !u8 {
    var stdout = std.io.getStdOut().writer();
    try stdout.print("Checking Civic Interconnect policy...\n\n", .{});
    var policy_parse_result = try policy_file_loader_func(allocator);
    defer policy_parse_result.deinit();
    const policy = policy_parse_result.value;
    const result = try checkPolicyObject(policy.object, dir, allocator);
    return result.exit_code;
}

pub fn checkPolicyObject(
    policy_object: std.json.ObjectMap,
    dir: std.fs.Dir,
    allocator: std.mem.Allocator,
) !struct {
    exit_code: u8,
    issues: [][]const u8,
} {
    var issues = std.ArrayList([]const u8).init(allocator);
    defer issues.deinit();

    // Check required_files
    if (policy_object.get("required_files")) |files_array| {
        for (files_array.array.items) |item| {
            const filename = item.string;
            if (!fs_utils.fileExistsInDir(dir, filename)) {
                const msg = try std.fmt.allocPrint(
                    allocator,
                    "Missing required file: {s}",
                    .{filename},
                );
                try issues.append(msg);
            }
        }
    }

    // Check python_project_files
    if (policy_object.get("python_project_files")) |files_array| {
        for (files_array.array.items) |item| {
            const filename = item.string;
            if (!fs_utils.fileExistsInDir(dir, filename)) {
                const msg = try std.fmt.allocPrint(
                    allocator,
                    "Missing Python project file: {s}",
                    .{filename},
                );
                try issues.append(msg);
            }
        }
    }

    // Check python_project_dirs
    if (policy_object.get("python_project_dirs")) |dirs_array| {
        for (dirs_array.array.items) |item| {
            const dirname = item.string;
            if (!fs_utils.dirExistsInDir(dir, dirname)) {
                const msg = try std.fmt.allocPrint(
                    allocator,
                    "Missing Python project dir: {s}/",
                    .{dirname},
                );
                try issues.append(msg);
            }
        }
    }

    return .{
        .exit_code = if (issues.items.len > 0) 1 else 0,
        .issues = try issues.toOwnedSlice(),
    };
}
