//
// src/policy_file_loader.zig
//
// Loads a Civic Interconnect policy JSON file from disk,
// instead of using the embedded default.
//
// Features:
// - loadPolicyFromFile()
//     Reads a JSON policy file (default "policy.json").
//     Returns a std.json.Parsed(std.json.Value) object for querying.
//
// Why both embedded and file-based policy?
// ----------------------------------------
// Civic Interconnect supports:
//   • Embedded policy (policy_defaults.zig) for fixed internal checks.
//   • File-based policy (this module) for custom policies
//     that differ across projects without needing a rebuild.
//
// This design enables:
//   - flexible runtime-driven policy enforcement
//   - easy adoption across diverse projects
//   - future extensibility without modifying binaries
//
// Civic Interconnect — MIT License
//

const std = @import("std");

/// Loads a JSON policy file from disk and parses it.
/// Caller owns the returned object and must call `deinit()`.
///
/// Example:
/// ```zig
/// var parsed = try policy_file_loader.loadPolicyFromFile(
///     allocator,
///     "policy.json"
/// );
/// defer parsed.deinit();
/// ```
///
/// Returns:
/// - A successfully parsed JSON policy as `std.json.Parsed(std.json.Value)`.
/// - An error if reading or parsing fails.
pub fn loadPolicyFromFile(
    allocator: std.mem.Allocator,
    file_path: []const u8,
) anyerror!std.json.Parsed(std.json.Value) {
    const bytes = try std.fs.cwd().readFileAlloc(
        allocator,
        file_path,
        10 * 1024, // 10 KiB safety limit
    );

    return std.json.parseFromSlice(std.json.Value, allocator, bytes, .{});
}
