// tests/utils/test_toml_utils.zig

const std = @import("std");
const toml_utils = @import("toml_utils");

test "about" {
    std.debug.print("Testing: utils/toml_utils.\n", .{});
}

test "mergeTomlFragment appends when fragment missing" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const filename = "pyproject.toml";
    const initial = "name = \"my-project\"\n";
    const fragment = "[tool.poetry]\nversion = \"0.1.0\"\n";

    // Write initial file
    try tmp.dir.writeFile(.{
        .sub_path = filename,
        .data = initial,
    });

    const full_path = try tmp.dir.realpathAlloc(
        std.testing.allocator,
        filename,
    );
    defer std.testing.allocator.free(full_path);

    const merged = try toml_utils.mergeTomlFragment(
        std.testing.allocator,
        full_path,
        fragment,
    );
    defer std.testing.allocator.free(merged);

    try std.testing.expect(std.mem.containsAtLeast(u8, merged, 1, fragment));
}

test "mergeTomlFragment returns original if fragment present" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const filename = "pyproject.toml";
    const initial = "name = \"my-project\"\n[tool.poetry]\nversion = \"0.1.0\"\n";
    const fragment = "[tool.poetry]\nversion = \"0.1.0\"\n";

    try tmp.dir.writeFile(.{
        .sub_path = filename,
        .data = initial,
    });

    const full_path = try tmp.dir.realpathAlloc(
        std.testing.allocator,
        filename,
    );
    defer std.testing.allocator.free(full_path);

    const merged = try toml_utils.mergeTomlFragment(
        std.testing.allocator,
        full_path,
        fragment,
    );
    defer std.testing.allocator.free(merged);

    try std.testing.expect(std.mem.eql(u8, merged, initial));
}
