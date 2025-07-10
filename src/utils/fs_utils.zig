//! src/utils/fs_utils.zig
//!
//! # Civic Interconnect: File System Utilities
//!
//! Provides utility functions for working with the file system.
//!
//! Features:
//! - Check if files or directories exist
//! - Delete files and directories safely
//! - List directory contents
//! - Read entire files into memory
//! - Write files to disk
//! - Remove Python virtual environments (.venv)
//!
//! Suitable for config files, small data, or text files.
//! Not intended for reading very large files entirely into memory.
//! 
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

/// Removes the `.venv` folder if it exists.
/// Prints a message if deleted.
pub fn removeVenv() !void {
    if (dirExists(".venv")) {
        try std.fs.cwd().deleteTree(".venv");
        var stdout = std.io.getStdOut().writer();
        try stdout.print("Removed .venv\n", .{});
    }
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
