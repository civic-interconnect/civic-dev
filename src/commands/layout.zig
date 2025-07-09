// src/commands/layout.zig
//
// Prints a summary of the Civic Interconnect project layout,
// including docs directories, source directories, and detected packages.

const std = @import("std");
const policy_defaults = @import("policy_defaults");
const fs_utils = @import("fs_utils");

pub fn main(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    try showLayoutWithWriter(allocator, stdout);
}

pub fn showLayoutWithWriter(
    allocator: std.mem.Allocator,
    writer: anytype,
) !void {
    try writer.print("Civic Interconnect Project Layout\n", .{});
    try writer.print("-------------------------------------\n", .{});

    var parsed = try policy_defaults.loadEmbeddedPolicy(allocator);
    defer parsed.deinit();

    const policy_value = parsed.value;

    const root_dir = ".";
    try writer.print("Root Directory: {s}\n", .{root_dir});

    if (policy_value.object.get("docs")) |docs_val| {
        const docs_dir = docs_val.object.get("docs_dir").?.string;
        const docs_api_dir = docs_val.object.get("docs_api_dir").?.string;

        try writer.print("Docs Dir:      {s}\n", .{docs_dir});
        try writer.print("Docs API Dir:  {s}\n", .{docs_api_dir});

        if (!fs_utils.dirExists(docs_dir)) {
            try writer.print("Docs dir {s} not found.\n", .{docs_dir});
        }
        if (!fs_utils.dirExists(docs_api_dir)) {
            try writer.print("Docs API dir {s} not found.\n", .{docs_api_dir});
        }
    }

    var has_src = false;
    if (policy_value.object.get("python_project_dirs")) |dirs_val| {
        for (dirs_val.array.items) |dir_item| {
            const dir = dir_item.string;
            try writer.print("Source Dir:    {s}\n", .{dir});
            if (fs_utils.dirExists(dir)) {
                has_src = true;
            } else {
                try writer.print("Missing source dir {s}\n", .{dir});
            }
        }
    }

    if (has_src) {
        try writer.print("Packages:\n", .{});
        if (fs_utils.dirExists("src")) {
            var dir = try std.fs.cwd().openDir("src", .{});
            defer dir.close();

            var it = dir.iterate();
            while (try it.next()) |entry| {
                if (entry.kind == .directory) {
                    try writer.print("  - {s}\n", .{entry.name});
                }
            }
        } else {
            try writer.print("  (No src directory found)\n", .{});
        }
    }

    try writer.print("Org Name:      unknown\n", .{});
    try writer.print("Policy Source: embedded JSON\n", .{});
}
