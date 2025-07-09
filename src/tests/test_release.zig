// tests/test_release.zig

const std = @import("std");
const release = @import("release");

test "about" {
    std.debug.print("Testing: release.\n", .{});
}

/// A fake runner for testing that logs commands instead of executing them.
const FakeRunner = struct {
    pub fn run(_: FakeRunner, cmd: []const u8, args: []const []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        const joined = try std.mem.join(
            gpa.allocator(),
            " ",
            args,
        );
        defer gpa.allocator().free(joined);

        std.debug.print("[FAKE-RUN] {s} {s}\n", .{
            cmd,
            joined,
        });
    }
};
