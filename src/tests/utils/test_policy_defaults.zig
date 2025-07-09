const std = @import("std");
const policy_defaults = @import("policy_defaults");

test "about" {
    std.debug.print("Testing: utils/policy_defaults.\n", .{});
}

test "loadEmbeddedPolicy returns valid JSON" {
    var parsed = try policy_defaults.loadEmbeddedPolicy(std.heap.page_allocator);
    defer parsed.deinit();

    try std.testing.expect(parsed.value != .null);

    // Check the JSON value is an object
    switch (parsed.value) {
        .object => |obj| {
            // Check that the object contains the key
            const entry = obj.get("required_files");
            try std.testing.expect(entry != null);
        },
        else => {
            std.debug.print("Expected JSON object at top level.\n", .{});
            return error.UnexpectedJsonType;
        },
    }
}
