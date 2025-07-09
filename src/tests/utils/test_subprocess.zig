// tests/utils/test_subprocess.zig

const builtin = @import("builtin");
const std = @import("std");
const subprocess = @import("subprocess");

test "about" {
    std.debug.print("Testing: utils/subprocess.\n", .{});
}

test "zig version command runs silently" {
    var child = std.process.Child.init(
        &[_][]const u8{ "zig", "version" },
        std.heap.page_allocator,
    );
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;

    _ = try child.spawnAndWait();
}
