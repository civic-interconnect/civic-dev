//! src/policy_file_loader.zig
//!
//! # Civic Interconnect: Policy File Loader
//!
//! Loads a Civic Interconnect policy JSON file from disk instead of
//! using the embedded default.
//!
//! ## Why both embedded and file-based policy?
//!
//! Civic Interconnect supports:
//!
//! - **Embedded policy** (see `policy_defaults.zig`)
//!     - For fixed internal checks.
//!
//! - **File-based policy** (this module)
//!     - For custom policies that differ across projects without needing a rebuild.
//!
//! This design enables:
//! - Flexible runtime-driven policy enforcement
//! - Easy adoption across diverse projects
//! - Future extensibility without modifying binaries
//!
//! ## Example
//!
//! ```zig
//! const policy_file_loader = @import("policy_file_loader");
//!
//! var parsed = try policy_file_loader.loadPolicyFromFile(
//!     allocator,
//!     "policy.json",
//! );
//! defer parsed.deinit();
//!
//! const policy = parsed.value;
//! // Use policy object here...
//! ```

const std = @import("std");

/// Loads a JSON policy file from disk and parses it.
///
/// Caller owns the returned object and must call `deinit()`
/// to free allocated memory.
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
