//
// src/utils/fs_utils.zig
//
// Provides utility functions for reading and writing entire files,
// deleting files, listing directory contents, and checking file
// and directory existence.
//
// Features:
// - deleteFileIfExists(path)
//     Deletes the specified file if it exists. No error if not found.
//
// - dirExists(path)
//     Checks if a directory exists at a given path.
//
// - dirExistsInDir(dir, path)
//     Checks if a directory exists relative to an open directory handle.
//
// - fileExists(path)
//     Checks if a file exists at a given path.
//
// - fileExistsInDir(dir, path)
//     Checks if a file exists relative to an open directory handle.
//
// - listDir(dir, allocator)
//     Returns a list of file and folder names in a given directory.
//
// - readEntireFile(path)
//     Reads the entire contents of a file into a newly allocated buffer.
//     Returns a slice with the file’s bytes.
//
// - readEntireFileFromDir(dir, path)
//     Reads a file from a provided directory handle.
//
// - writeFile(path, contents)
//     Writes the given byte slice to a file at the specified path.
//     Overwrites the file if it exists.
//
// - writeFileToDir(dir, path, contents)
//     Writes data to a file relative to a provided directory handle.
//     Overwrites the file if it exists.
//
// WARNING:
// These functions are not suitable for reading very large files entirely
// into memory. Intended for config files, small data, or text files.
//
// Civic Interconnect — MIT License
//

const std = @import("std");

/// Deletes a file at the given path, if it exists.
pub fn deleteFileIfExists(path: []const u8) !void {
    const cwd = std.fs.cwd();
    _ = cwd.deleteFile(path) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
}

/// Checks if a directory exists at the given path.
pub fn dirExists(path: []const u8) bool {
    const cwd = std.fs.cwd();
    return dirExistsInDir(cwd, path);
}

/// Checks if a directory exists relative to an open directory handle.
pub fn dirExistsInDir(dir: std.fs.Dir, path: []const u8) bool {
    _ = dir.access(path, .{}) catch return false;
    return true;
}

/// Checks if a file exists at the given path.
pub fn fileExists(path: []const u8) bool {
    const cwd = std.fs.cwd();
    return fileExistsInDir(cwd, path);
}

/// Checks if a file exists relative to an open directory handle.
pub fn fileExistsInDir(dir: std.fs.Dir, path: []const u8) bool {
    _ = dir.access(path, .{}) catch return false;
    return true;
}

/// Returns all file and folder names in the given directory.
pub fn listDir(dir: std.fs.Dir, allocator: std.mem.Allocator) ![][]const u8 {
    var iter = dir.iterate();
    var list = std.ArrayList([]const u8).init(allocator);

    while (try iter.next()) |entry| {
        try list.append(entry.name);
    }

    return try list.toOwnedSlice();
}

/// Reads an entire file into memory.
/// Returns a newly allocated slice.
/// The caller owns the returned slice and must free it if using a custom allocator.
/// If the file is empty, returns an empty slice.
pub fn readEntireFile(path: []const u8) ![]u8 {
    return readEntireFileAlloc(std.heap.page_allocator, path);
}

/// Reads an entire file into memory using a specified allocator.
/// Returns a newly allocated slice.
/// The caller owns the returned slice and must free it if using a custom allocator.
/// If the file is empty, returns an empty slice.
pub fn readEntireFileAlloc(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const stat = try file.stat();

    if (stat.size == 0) {
        return &[_]u8{};
    }

    var buffer = try allocator.alloc(u8, stat.size);
    const read_bytes = try file.readAll(buffer);
    return buffer[0..read_bytes];
}

/// Reads an entire file from a provided directory handle,
/// using the specified allocator.
/// Returns a newly allocated slice.
/// The caller owns the returned slice and must free it if using a custom allocator.
/// If the file is empty, returns an empty slice.
pub fn readEntireFileFromDirAlloc(
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    path: []const u8,
) ![]u8 {
    var file = try dir.openFile(path, .{});
    defer file.close();

    const stat = try file.stat();

    if (stat.size == 0) {
        return &[_]u8{};
    }

    var buffer = try allocator.alloc(u8, stat.size);
    const read_bytes = try file.readAll(buffer);
    return buffer[0..read_bytes];
}

/// Reads an entire file from a provided directory handle
/// using the page allocator.
/// Returns a newly allocated slice.
/// The caller owns the returned slice.
/// If the file is empty, returns an empty slice.
pub fn readEntireFileFromDir(
    dir: std.fs.Dir,
    path: []const u8,
) ![]u8 {
    return readEntireFileFromDirAlloc(std.heap.page_allocator, dir, path);
}

/// Writes the given bytes to a file at the specified path.
/// Overwrites the file if it exists.
pub fn writeFile(path: []const u8, contents: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{
        .truncate = true,
    });
    defer file.close();

    try file.writeAll(contents);
}

/// Writes data to a file relative to a provided directory handle.
/// Overwrites the file if it exists.
pub fn writeFileToDir(dir: std.fs.Dir, path: []const u8, data: []const u8) !void {
    var file = try dir.createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(data);
}
