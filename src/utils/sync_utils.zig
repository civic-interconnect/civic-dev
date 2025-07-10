//! src/utils/sync_utils.zig
//!
//! # Civic Interconnect: Sync Utilities
//!
//! Utilities for synchronizing Civic Interconnect shared files
//! into the current repository.
//!
//! ## Features
//!
//! - Sync root-level shared files like `.gitattributes`, `LICENSE`, etc.
//! - Sync all files from a specific shared project folder (e.g. `py`, `pwa`).
//! - Only overwrites files if contents differ.
//!
//! These utilities are used by the `civic-dev sync-files` command
//! and can also be reused in future tooling.
//!
//! ## Example
//!
//! ```zig
//! const sync_utils = @import("sync_utils");
//!
//! try sync_utils.syncRootFiles();         // Copies common root files
//! try sync_utils.syncProjectFolder("py"); // Copies Python-specific shared files
//! try sync_utils.syncProjectFolder("pwa");// Copies PWA-specific shared files
//! ```

const std = @import("std");
const embedded_root_files = @import("embedded_root_files");
const fs_utils = @import("fs_utils");

/// Copies a file only if its contents differ.
///
/// Returns:
/// - `true` if the file was written
/// - `false` if the file already matched the source
pub fn syncOneFile(cwd: std.fs.Dir, src_path: []const u8, dest_path: []const u8) !bool {
    const src_contents = try fs_utils.readEntireFile(src_path);

    const dest_exists = cwd.openFile(dest_path, .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };

    if (dest_exists) |file| {
        defer file.close();

        const dest_contents = try fs_utils.readEntireFileFromDir(cwd, dest_path);
        if (std.mem.eql(u8, src_contents, dest_contents)) {
            return false;
        }
    }

    try cwd.writeFile(.{
        .sub_path = dest_path,
        .data = src_contents,
    });

    return true;
}

/// Syncs all files from a specific shared folder (e.g. `"py"` or `"pwa"`)
/// into the target repo’s root.
/// Only updates files if contents differ.
///
/// Prints progress messages for each file synced or skipped.
pub fn syncProjectFolder(folder_name: []const u8) !void {
    var stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    const shared_root = "../shared_files";

    const project_folder = try std.fmt.allocPrint(allocator, "{s}/{s}", .{
        shared_root,
        folder_name,
    });
    defer allocator.free(project_folder);

    const exists = fs_utils.dirExists(project_folder);
    if (!exists) {
        try stdout.print("Shared folder for {s} does not exist.\n", .{folder_name});
        return;
    }

    var src_dir = try std.fs.cwd().openDir(project_folder, .{});
    defer src_dir.close();

    var it = src_dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind == .file) {
            const src_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{
                project_folder,
                entry.name,
            });
            defer allocator.free(src_path);

            const dest_path = entry.name;

            const updated = try syncOneFile(std.fs.cwd(), src_path, dest_path);
            if (updated) {
                try stdout.print("Synced {s}\n", .{entry.name});
            } else {
                try stdout.print("  {s} already up-to-date\n", .{entry.name});
            }
        }
    }
}

/// Syncs root-level shared files from the civic-dev executable
/// into the client repository root.
///
/// This reads embedded file contents (e.g. `.gitignore`,
/// `.gitattributes`) and writes them into the current repo,
/// overwriting only if contents differ.
/// 
/// Prints progress messages for each file synced or skipped.
pub fn syncRootFiles() !void {
    var stdout = std.io.getStdOut().writer();

    for (embedded_root_files.files) |f| {

        var overwrite = true;
        if (fs_utils.fileExists(f.path)) {
            const existing = try fs_utils.readEntireFile(f.path);
            if (std.mem.eql(u8, existing, f.contents)) {
                overwrite = false;
            }
        }

        if (overwrite) {
            try fs_utils.writeFile(f.path, f.contents);
            try stdout.print("Synced {s}\n", .{f.path});
        } else {
            try stdout.print("  {s} already up-to-date\n", .{f.path});
        }
    }
}
