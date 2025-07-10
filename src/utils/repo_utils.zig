

const std = @import("std");
const fs_utils = @import("fs_utils");

/// Attempts to auto-detect the type of Civic Interconnect repository.
///
/// Returns:
/// - `"python"` if `pyproject.toml` is found
/// - `"pwa"` if `package.json` is found
/// - `"unknown"` if no known indicators are found
pub fn detectRepoType() ![]const u8 {
    if (fs_utils.fileExists("pyproject.toml")) {
        return "python";
    }
    if (fs_utils.fileExists("package.json")) {
        return "pwa";
    }
    return "unknown";
}