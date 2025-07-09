//tests/test_check_policy.zig

const std = @import("std");
const check_policy = @import("check_policy");
const policy_defaults = @import("policy_defaults");
const fs_utils = @import("fs_utils");

const policy_json =
    "{ \"required_files\": [\"README.md\"], \"python_project_files\": [\"pyproject.toml\", \"requirements.txt\"], \"python_project_dirs\": [\"src\"] }";

fn fakeLoadPolicy(allocator: std.mem.Allocator) !std.json.Parsed(std.json.Value) {
    var arena = std.heap.ArenaAllocator.init(allocator);
    const arena_allocator = arena.allocator();

    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        arena_allocator,
        policy_json,
        .{},
    );

    // Serialize dynamic value into a buffer
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try std.json.stringify(parsed.value, .{}, buffer.writer());

    // Now parse again with the real allocator
    const cloned = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        buffer.items,
        .{},
    );
    arena.deinit();

    return cloned;
}

test "about" {
    std.debug.print("Testing: check policy.\n", .{});
}

test "check_policy passes when required files/dirs exist" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makeDir("src");
    _ = try tmp.dir.createFile("README.md", .{});
    _ = try tmp.dir.createFile("pyproject.toml", .{});
    _ = try tmp.dir.createFile("requirements.txt", .{});

    var policy_data = try fakeLoadPolicy(std.heap.page_allocator);
    defer policy_data.deinit();

    const policy_value = policy_data.value;

    const result = try check_policy.checkPolicyObject(
        policy_value.object,
        tmp.dir,
        std.heap.page_allocator,
    );
    try std.testing.expect(result.exit_code == 0);
}

test "check_policy fails if files missing" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makeDir("src");

    var policy_data = try fakeLoadPolicy(std.heap.page_allocator);
    defer policy_data.deinit();

    const result = try check_policy.checkPolicyObject(
        policy_data.value.object,
        tmp.dir,
        std.heap.page_allocator,
    );

    try std.testing.expect(result.exit_code != 0);
}
