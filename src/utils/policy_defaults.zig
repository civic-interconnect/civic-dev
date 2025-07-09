//
// src/utils/policy_defaults.zig
//
// Embedded default policy definitions for Civic Interconnect.
//
// Provides:
// - Embedded JSON describing required project files, directories,
//   docs layout, and logging settings.
// - Function to parse the embedded JSON into a
//   std.json.Parsed(std.json.Value) object.
// - Helper to extract arrays of strings from the parsed policy.
//
// Civic Interconnect — MIT License
//

const std = @import("std");

/// Embedded JSON representing Civic Interconnect default policy.
pub const embedded_policy_json =
    \\{
    \\    "required_files": [
    \\        ".gitattributes",
    \\        ".gitignore",
    \\        ".pre-commit-config.yaml",
    \\        "DEVELOPER.md",
    \\        "LICENSE",
    \\        "README.md",
    \\        "runtime_config.yaml"
    \\    ],
    \\    "pwa_project_files": [
    \\        "index.html",
    \\        "manifest.json",
    \\        "sw.js"
    \\    ],
    \\    "node_project_files": [
    \\        "package.json"
    \\    ],
    \\    "python_project_files": [
    \\        "pyproject.toml"
    \\    ],
    \\    "python_project_dirs": [
    \\        "src"
    \\    ],
    \\    "max_python_file_length": 1000,
    \\    "docs": {
    \\        "docs_dir": "docs",
    \\        "docs_api_dir": "api"
    \\    },
    \\    "log_subdir": "logs",
    \\    "log_file_template": "{time:YYYY-MM-DD}.log",
    \\    "log_level": "INFO",
    \\    "log_retention_days": 7
    \\}
;

/// Retrieves an array of strings from a JSON object
/// for the given key.
/// Returns null if the key does not exist or is not an array
/// of strings.
/// Caller owns the returned slice and should free it if using
/// a custom allocator.
pub fn getArrayOfStrings(
    value: std.json.Value,
    key: []const u8,
) ?[][]const u8 {
    if (value.object.get(key)) |arr_val| {
        if (arr_val.tag == .array) {
            const items = arr_val.array.items;

            // Pre-allocate with correct length
            var result = std.ArrayList([]const u8).init(std.heap.page_allocator);

            for (items) |item| {
                if (item.tag == .string) {
                    result.append(item.string) catch {
                        // Return null if allocation fails
                        return null;
                    };
                }
            }

            return result.toOwnedSlice() catch null;
        }
    }
    return null;
}

/// Parses the embedded JSON policy into a
/// `std.json.Parsed(std.json.Value)` object.
/// Caller owns the returned object and must call `deinit()`.
pub fn loadEmbeddedPolicy(allocator: std.mem.Allocator) anyerror!std.json.Parsed(std.json.Value) {
    return std.json.parseFromSlice(std.json.Value, allocator, embedded_policy_json, .{});
}
