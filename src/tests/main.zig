//! src/tests/main.zig
//!
//! # civic-dev: Test Suite Entry Point
//!
//! Entry point for running all civic-dev tests.
//!
//! This file imports all test modules and runs them as a single
//! Zig test suite. Run this file to execute tests across all
//! civic-dev commands and utilities.
//!
//! ## Example
//!
//! To run the full civic-dev test suite:
//!
//! ```bash
//! zig build test
//! ```

const std = @import("std");

test "all civic-dev tests" {
    _ = @import("test_bump_version.zig");
    _ = @import("test_check_policy.zig");
    _ = @import("test_layout.zig");
    _ = @import("test_release.zig");
    _ = @import("test_run.zig");
    _ = @import("test_setup_py.zig");
    _ = @import("test_start_py.zig");
    _ = @import("test_sync_files.zig");
    _ = @import("utils/test_fs_utils.zig");
    _ = @import("utils/test_policy_defaults.zig");
    _ = @import("utils/test_policy_file_loader.zig");
    _ = @import("utils/test_repo_utils.zig");
    _ = @import("utils/test_subprocess.zig");
    _ = @import("utils/test_sync_utils.zig");
    _ = @import("utils/test_toml_utils.zig");
}
