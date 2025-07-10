//! src/utils/embedded_root_files.zig
//!
//! # Civic Interconnect: Embedded Root Files
//!
//! Contains embedded copies of root-level shared files,
//! intended for syncing into client repositories.
//!
//! These files are identical across all
//! Civic Interconnect projects and are embedded directly
//! into the civic-dev executable during build.
//!
//! Files included:
//! - `.gitattributes`
//! - `.gitignore`
//! - `.pre-commit-config.yaml`
//! - `LICENSE`
//! - `log_config.json`
//!
//! ## Example Usage
//!
//! ```zig
//! const embedded_root_files = @import("embedded_root_files");
//!
//! for (embedded_root_files.files) |f| {
//!     // Write f.contents to f.path
//! }
//! ```

pub const std = @import("std");

pub const EmbeddedFile = struct {
    path: []const u8,
    contents: []const u8,
};

pub const files = [_]EmbeddedFile{
    .{ .path = ".gitattributes", .contents = @embedFile("shared_files/.gitattributes") },
    .{ .path = ".gitignore", .contents = @embedFile("shared_files/.gitignore") },
    .{ .path = ".pre-commit-config.yaml", .contents = @embedFile("shared_files/.pre-commit-config.yaml") },
    .{ .path = "config_log.json", .contents = @embedFile("shared_files/config_log.json") },
    .{ .path = "LICENSE", .contents = @embedFile("shared_files/LICENSE") },
};
