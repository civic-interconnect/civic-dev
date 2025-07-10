//! src/commands/bump_version.zig
//!
//! # civic-dev: bump-version Command
//!
//! Bumps version numbers in key project files.
//!
//! Scans each file listed in `files_to_update` for the old version string
//! and replaces it with the new version string.
//!
//! - Uses file utilities for reading and writing files.
//! - Prints a summary of changes.
//! - Supports replacing versions either from the current working directory
//!   or from a given `std.fs.Dir` handle.
//!
//! ## Example
//!
//! To bump all references of version `1.0.0` to `1.0.1`:
//!
//! ```bash
//! civic-dev bump-version 1.0.0 1.0.1
//! ```

const std = @import("std");
const fs_utils = @import("fs_utils");

/// Bumps version numbers in all configured project files.
///
/// Iterates over a list of common project files (e.g. `pyproject.toml`,
/// `README.md`, etc.) and replaces all instances of the old version string
/// with the new version string.
///
/// Prints output indicating which files were changed.
///
/// - `old_version`: the string to replace (e.g. `"1.0.0"`).
/// - `new_version`: the string to replace it with (e.g. `"1.0.1"`).
///
/// ## Example
///
/// ```zig
/// try bumpVersion("1.0.0", "1.0.1");
/// ```
pub fn bumpVersion(old_version: []const u8, new_version: []const u8) !void {
    const files_to_update = [_][]const u8{
        "build.zig.zon",
        "pyproject.toml",
        "README.md",
        "package.json",
    };

    var stdout = std.io.getStdOut().writer();

    var updated_count: usize = 0;

    for (files_to_update) |filename| {
        if (try bumpVersionInFile(filename, old_version, new_version)) {
            try stdout.print("Updated {s}\n", .{filename});
            updated_count += 1;
        } else {
            try stdout.print("No changes needed in {s}\n", .{filename});
        }
    }

    if (updated_count > 0) {
        try stdout.print("Version updated in {} file(s).\n", .{updated_count});
    } else {
        try stdout.print("Nothing changed.\n", .{});
    }
}

/// Replaces all occurrences of `old` with `new` in the file at `path`.
///
/// Returns `true` if the file was modified, otherwise `false`.
///
/// If the file does not exist, returns `false`.
///
/// ## Example
///
/// ```zig
/// const changed = try bumpVersionInFile("README.md", "1.0.0", "1.0.1");
/// if (changed) {
///     std.debug.print("README.md updated\n", .{});
/// }
/// ```
pub fn bumpVersionInFile(path: []const u8, old: []const u8, new: []const u8) !bool {
    if (!fs_utils.fileExists(path)) {
        return false;
    }

    const contents = try fs_utils.readEntireFile(path);

    if (!std.mem.containsAtLeast(u8, contents, 1, old)) {
        return false;
    }

    const allocator = std.heap.page_allocator;
    const updated = try std.mem.replaceOwned(u8, allocator, contents, old, new);
    defer allocator.free(updated);

    try fs_utils.writeFile(path, updated);
    return true;
}

/// Replaces all occurrences of `old` with `new` in a file inside the given directory.
///
/// Returns `true` if the file was modified, otherwise `false`.
///
/// If the file does not exist in the directory, returns `false`.
///
/// ## Example
///
/// ```zig
/// var dir = try std.fs.cwd().openDir(".", .{});
/// defer dir.close();
///
/// const changed = try bumpVersionInFileFromDir(dir, "README.md", "1.0.0", "1.0.1");
/// if (changed) {
///     std.debug.print("README.md updated in dir\n", .{});
/// }
/// ```
pub fn bumpVersionInFileFromDir(
    dir: std.fs.Dir,
    path: []const u8,
    old: []const u8,
    new: []const u8,
) !bool {
    if (!fs_utils.fileExistsInDir(dir, path)) {
        return false;
    }

    const contents = try fs_utils.readEntireFileFromDir(dir, path);

    if (!std.mem.containsAtLeast(u8, contents, 1, old)) {
        return false;
    }

    const allocator = std.heap.page_allocator;
    const updated = try std.mem.replaceOwned(u8, allocator, contents, old, new);
    defer allocator.free(updated);

    try fs_utils.writeFileToDir(dir, path, updated);
    return true;
}

/// CLI entry point for the bump-version command.
///
/// Expects:
/// - `args[2]`: old version string
/// - `args[3]`: new version string
///
/// Prints usage instructions if arguments are missing.
///
/// ## Example
///
/// ```bash
/// civic-dev bump-version 1.0.0 1.0.1
/// ```
pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len != 4) {
        try stdout.print("Usage:\n", .{});
        try stdout.print("  civic-dev bump-version OLD_VERSION NEW_VERSION\n", .{});
        return;
    }

    const old_version = args[2];
    const new_version = args[3];

    try bumpVersion(old_version, new_version);
}
