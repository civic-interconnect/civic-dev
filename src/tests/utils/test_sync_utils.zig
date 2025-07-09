// tests/utils/test_sync_utils.zig

const std = @import("std");
const sync_utils = @import("sync_utils");
const fs_utils = @import("fs_utils");

test "about" {
    std.debug.print("Testing: utils/sync_utils.\n", .{});
}

test "syncOneFile writes new file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{
        .sub_path = "source.txt",
        .data = "Hello World!",
    });

    const src_path = try tmp.dir.realpathAlloc(
        std.testing.allocator,
        "source.txt",
    );
    defer std.testing.allocator.free(src_path);

    const updated = try sync_utils.syncOneFile(
        tmp.dir,
        src_path,
        "dest.txt",
    );

    try std.testing.expect(updated);
    const contents = try fs_utils.readEntireFileFromDir(tmp.dir, "dest.txt");
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "Hello"));
}

test "syncOneFile skips identical files" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const filename = "dest.txt";

    try tmp.dir.writeFile(.{
        .sub_path = filename,
        .data = "Hello World!",
    });

    try tmp.dir.writeFile(.{
        .sub_path = "source.txt",
        .data = "Hello World!",
    });

    const src_path = try tmp.dir.realpathAlloc(
        std.testing.allocator,
        "source.txt",
    );
    defer std.testing.allocator.free(src_path);

    const updated = try sync_utils.syncOneFile(
        tmp.dir,
        src_path,
        filename,
    );

    try std.testing.expect(!updated);
}

test "syncOneFile overwrites differing file" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{
        .sub_path = "source.txt",
        .data = "NEW content",
    });

    try tmp.dir.writeFile(.{
        .sub_path = "dest.txt",
        .data = "OLD content",
    });

    const src_path = try tmp.dir.realpathAlloc(
        std.testing.allocator,
        "source.txt",
    );
    defer std.testing.allocator.free(src_path);

    const updated = try sync_utils.syncOneFile(
        tmp.dir,
        src_path,
        "dest.txt",
    );

    try std.testing.expect(updated);
    const contents = try fs_utils.readEntireFileFromDir(tmp.dir, "dest.txt");
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "NEW"));
}
