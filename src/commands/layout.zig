//! src/commands/layout.zig
//!
//! # civic-dev: layout Command
//!
//! Prints a summary of the Civic Interconnect project layout.
//!
//! Displays:
//! - The project root directory
//! - Documentation directories (if configured)
//! - Python source directories (if configured)
//! - Detected packages within the `src` folder
//! - Policy source information
//!
//! This command helps developers quickly understand the
//! structure of a Civic Interconnect project.
//!
//! ## Example
//!
//! To print the layout to the terminal:
//!
//! ```bash
//! civic-dev layout
//! ```

const std = @import("std");
const policy_defaults = @import("policy_defaults");
const fs_utils = @import("fs_utils");

/// Prints a detailed Civic Interconnect project layout summary.
///
/// Accepts any writer, allowing use in CLI tools or testing scenarios.
///
/// Prints:
/// - Project root directory
/// - Documentation directories (if configured in policy)
/// - Python source directories (if configured in policy)
/// - Packages detected under `src`
/// - Organization name and policy source
///
/// ## Example
///
/// ```zig
/// var allocator = std.heap.page_allocator;
/// const stdout = std.io.getStdOut().writer();
/// try showLayoutWithWriter(allocator, stdout);
/// ```
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
            while (true) {
                const next_entry = it.next() catch |err| {
                    try writer.print("Error reading directory entries: {}\n", .{err});
                    break;
                };

                if (next_entry == null) break;

                const entry = next_entry.?;
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

/// CLI entry point for the layout command.
///
/// Prints the layout summary to standard output.
///
/// ## Example
///
/// ```bash
/// civic-dev layout
/// ```
pub fn main(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    try showLayoutWithWriter(allocator, stdout);
}
