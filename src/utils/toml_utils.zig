// src/utils/toml_utils.zig
//
// Utilities for merging TOML fragments into existing TOML files.
// Civic Interconnect — MIT License

const std = @import("std");
const fs_utils = @import("fs_utils");

/// Reads, merges, and writes a TOML fragment into an existing TOML file.
/// Only writes to disk if the fragment is not already present.
pub fn mergeAndWrite(
    allocator: std.mem.Allocator,
    existingFile: []const u8,
    fragment: []const u8,
) !void {
    const merged = try mergeTomlFragment(allocator, existingFile, fragment);
    try fs_utils.writeFile(existingFile, merged);
}

/// Merges a TOML fragment into an existing TOML file.
/// Returns newly allocated content if changes are needed.
/// Otherwise returns the original contents.
pub fn mergeTomlFragment(
    allocator: std.mem.Allocator,
    existingFile: []const u8,
    fragment: []const u8,
) ![]u8 {
    const existing = try fs_utils.readEntireFile(existingFile);

    if (std.mem.containsAtLeast(u8, existing, 1, fragment)) {
        // Always allocate a copy so the caller can safely free it
        return try allocator.dupe(u8, existing);
    }

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    if (existing.len > 0) {
        try buffer.appendSlice(existing);

        if (!std.mem.endsWith(u8, existing, "\n")) {
            try buffer.append('\n');
        }
    }

    try buffer.appendSlice(fragment);

    return try buffer.toOwnedSlice();
}
