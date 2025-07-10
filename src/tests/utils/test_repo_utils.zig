// tests/utils/test_repo_utils.zig

const std = @import("std");
const repo_utils = @import("repo_utils");

test "about" {
    std.debug.print("Testing: utils/repo_utils.\n", .{});
}

test "detectRepoType returns unknown in empty environment" {
    const repo_type = try repo_utils.detectRepoType();

    try std.testing.expectEqualStrings("unknown", repo_type);
}
