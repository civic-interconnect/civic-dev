// src/commands/bump_version.zig
//
// Bumps version numbers in key project files.
//
// Scans the files listed in `files_to_update` for occurrences of
// the old version string, replacing them with the new version.
// Uses file utilities for reading and writing.
// Prints a summary of changes.

const std = @import("std");
const fs_utils = @import("fs_utils");

/// Replace all occurrences of `old` with `new` in the file at `path`.
/// Returns `true` if the file was changed.
pub fn bumpVersion(old_version: []const u8, new_version: []const u8) !void {
    const files_to_update = [_][]const u8{
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

/// CLI entry point for bump-version command.
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

/// Replaces all occurrences of `old` with `new` in the file at `path`.
/// Returns true if the file was changed.
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
