//
// src/utils/sync_utils.zig
//
// Utilities to sync Civic Interconnect shared files
// into the current repository.
//
// Features:
// - Sync root-level shared files like .gitattributes, LICENSE, etc.
// - Sync all files from a specific shared project folder (e.g. py, pwa).
// - Only overwrites files if content differs.
//
// Typical usage:
//     syncRootFiles();                   // Copies common root files
//     syncProjectFolder("py");           // Copies Python-specific shared files
//     syncProjectFolder("pwa");          // Copies PWA-specific shared files
//
// These utilities are used by the civic-dev sync-files command
// and can also be reused in future tooling.
//
// Civic Interconnect — MIT License
//

const std = @import("std");
const fs_utils = @import("fs_utils");

/// Copies a file only if its contents differ.
/// Returns true if the file was written, false otherwise.
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

/// Syncs all files from a specific shared folder (e.g. "py" or "pwa")
/// into the target repo’s root.
/// Only updates files if contents differ.
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
                try stdout.print("✔️  {s} already up-to-date\n", .{entry.name});
            }
        }
    }
}

/// Sync root-level shared files into the current repo.
/// Only updates files if contents differ.
pub fn syncRootFiles() !void {
    var stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    const shared_root = "../shared_files";

    const shared_files = [_][]const u8{
        ".gitattributes",
        ".gitignore",
        "LICENSE",
        "README.md",
        "runtime_config.yaml",
    };

    const cwd = std.fs.cwd();

    for (shared_files) |filename| {
        const src_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{
            shared_root,
            filename,
        });
        defer allocator.free(src_path);

        const updated = try syncOneFile(cwd, src_path, filename);
        if (updated) {
            try stdout.print("Synced {s}\n", .{filename});
        } else {
            try stdout.print("✔️  {s} already up-to-date\n", .{filename});
        }
    }
}
