//! src/commands/check_policy.zig
//!
//! # civic-dev: check-policy Command
//!
//! Checks whether a Civic Interconnect project complies with the standard
//! repository policy.
//!
//! Loads the policy definition from JSON (using a provided loader function),
//! then verifies the presence of required files and directories defined in
//! `policy_defaults.zig`.
//!
//! - Reports missing files or directories.
//! - Returns an exit code indicating success (0) or failure (1).
//! - Designed for integration into the civic-dev CLI toolkit.
//!
//! ## Example
//!
//! To check policy compliance for the current directory:
//!
//! ```bash
//! civic-dev check-policy
//! ```

const std = @import("std");
const fs_utils = @import("fs_utils");
const policy_defaults = @import("policy_defaults");

/// Checks a policy JSON object for compliance in the given directory.
///
/// Inspects the following policy keys, if present:
/// - `required_files`
/// - `python_project_files`
/// - `python_project_dirs`
///
/// For each required file or directory, verifies its existence. Any missing
/// items are recorded as issues.
///
/// Returns:
/// - A struct with:
///     - `exit_code`: `0` if compliant, `1` if issues were found.
///     - `issues`: a list of messages describing any missing files or directories.
///
/// ## Example
///
/// ```zig
/// var allocator = std.heap.page_allocator;
/// var dir = try std.fs.cwd().openDir(".", .{});
/// defer dir.close();
///
/// var policy_parse_result = try policy_defaults.loadEmbeddedPolicy(allocator);
/// defer policy_parse_result.deinit();
///
/// const result = try checkPolicyObject(
///     policy_parse_result.value.object,
///     dir,
///     allocator,
/// );
///
/// if (result.exit_code == 0) {
///     std.debug.print("Project is compliant.\n", .{});
/// } else {
///     for (result.issues) |msg| {
///         std.debug.print("{s}\n", .{msg});
///     }
/// }
/// ```
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

/// Entry point for the check-policy CLI command.
///
/// - `policy_file_loader_func`: A function that loads the JSON policy
///   as a parsed `std.json.Value`.
/// - `dir`: The directory to check for required files and directories.
/// - `allocator`: Allocator used for all allocations.
///
/// Returns:
/// - An 8-bit exit code:
///     - `0` → policy compliance
///     - `1` → policy issues found
///
/// ## Example
///
/// ```zig
/// const result = try main(
///     policy_defaults.loadEmbeddedPolicy,
///     try std.fs.cwd().openDir(".", .{}),
///     std.heap.page_allocator,
/// );
///
/// if (result == 0) {
///     std.debug.print("Project is compliant.\n", .{});
/// } else {
///     std.debug.print("Policy issues detected.\n", .{});
/// }
/// ```
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
