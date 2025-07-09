// src/tests/test_bump_version.zig

const std = @import("std");
const bump_version = @import("bump_version");
const fs_utils = @import("fs_utils");

test "about" {
    std.debug.print("Testing: bump version.\n", .{});
}

test "bumpVersionInFile replaces version string" {
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const test_path = "test_file.txt";

    var file = try tmp_dir.dir.createFile(test_path, .{});
    defer file.close();

    try file.writeAll("Version: 0.1.0\n");

    // Run bumpVersionInFile on relative path
    const changed = try bump_version.bumpVersionInFileFromDir(
        tmp_dir.dir,
        test_path,
        "0.1.0",
        "0.2.0",
    );
    try std.testing.expect(changed);

    const contents = try fs_utils.readEntireFileFromDir(tmp_dir.dir, test_path);
    const expected = "Version: 0.2.0\n";
    try std.testing.expectEqualStrings(expected, contents);
}

test "bumpVersionInFile does nothing if old version not present" {
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const test_path = "test_file.txt";

    var file = try tmp_dir.dir.createFile(test_path, .{});
    defer file.close();

    try file.writeAll("Version: 9.9.9\n");

    const changed = try bump_version.bumpVersionInFileFromDir(
        tmp_dir.dir,
        test_path,
        "0.1.0",
        "0.2.0",
    );
    try std.testing.expect(!changed);
}

test "bumpVersionInFile replaces multiple occurrences" {
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const test_path = "test_file.txt";
    var file = try tmp_dir.dir.createFile(test_path, .{});
    defer file.close();

    try file.writeAll("Version: 0.1.0\nAnother Version: 0.1.0\n");

    const changed = try bump_version.bumpVersionInFileFromDir(
        tmp_dir.dir,
        test_path,
        "0.1.0",
        "0.2.0",
    );
    try std.testing.expect(changed);

    const contents = try fs_utils.readEntireFileFromDir(tmp_dir.dir, test_path);
    try std.testing.expect(!std.mem.containsAtLeast(u8, contents, 1, "0.1.0"));
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "0.2.0"));
}

test "bumpVersionInFile returns false if file does not exist" {
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();
    const changed = try bump_version.bumpVersionInFileFromDir(
        tmp_dir.dir,
        "does_not_exist.txt",
        "0.1.0",
        "0.2.0",
    );
    try std.testing.expect(!changed);
}
