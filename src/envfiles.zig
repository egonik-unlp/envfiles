const std = @import("std");
const Location = enum { InKey, InVal };
const EnvFileSyntaxError = error{ MalformedKey, MalformedVal, QuotationError };
const EnvFileError = error{NonExistantKey};
const quotations: [2]u8 = .{ '\x22', '\x27' };
const Sorrounded = enum { Blank, Quotes };

fn sorrounded_by_quotations(haystack: []const u8) EnvFileSyntaxError!bool {
    const first = haystack[0];
    const last = haystack[haystack.len - 1];
    if (std.mem.containsAtLeastScalar(u8, &quotations, 1, first)) {
        if (std.mem.containsAtLeastScalar(u8, &quotations, 1, last)) {
            return true;
        } else {
            return EnvFileSyntaxError.QuotationError;
        }
    } else {
        return false;
    }
}
fn getEnvFromString(string: []const u8, allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var storage = std.StringHashMap([]const u8).init(allocator);

    var iter = std.mem.splitScalar(u8, string, '\n');
    while (iter.next()) |val_key| {
        if (std.mem.eql(u8, val_key, "")) {
            std.debug.print("last", .{});
            continue;
        }
        var split = std.mem.splitScalar(u8, val_key, '=');
        const key = split.next().?;
        var val = split.next().?;
        if (split.next() != null) {
            return EnvFileSyntaxError.MalformedKey;
        }
        const quotes = try sorrounded_by_quotations(val);
        if (quotes) {
            val = val[1 .. val.len - 1];
        }
        try storage.put(key, val);
    }

    return storage;
}
fn getEnv(filepath: []const u8, allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var storage = std.StringHashMap([]const u8).init(allocator);
    const dir = std.fs.cwd();
    const file = try dir.openFile(filepath, .{});
    const path = try dir.realpathAlloc(allocator, ".");
    defer file.close();
    std.debug.print("Folder path being read = {s}\n", .{path});
    var buffer: [4096]u8 = undefined;
    const filepath_string = try std.os.getFdPath(file.handle, &buffer);
    std.debug.print("filepath = {s}\n", .{filepath_string});
    const text = try file.readToEndAlloc(allocator, 1000);
    var iter = std.mem.splitScalar(u8, text, '\n');
    while (iter.next()) |val_key| {
        if (std.mem.eql(u8, val_key, "")) {
            std.debug.print("last", .{});
            continue;
        }
        var split = std.mem.splitScalar(u8, val_key, '=');
        const key = split.next().?;
        var val = split.next().?;
        if (split.next() != null) {
            return EnvFileSyntaxError.MalformedKey;
        }
        const quotes = try sorrounded_by_quotations(val);
        if (quotes) {
            val = val[1 .. val.len - 1];
        }
        try storage.put(key, val);
    }

    return storage;
}

pub const Env = struct {
    allocator: std.mem.Allocator,
    envs: std.StringHashMap([]const u8),
    pub fn init(filepath: []const u8, allocator: std.mem.Allocator) !Env {
        const env = try getEnv(filepath, allocator);
        return Env{ .allocator = allocator, .envs = env };
    }
    pub fn init_string(string: []const u8, allocator: std.mem.Allocator) !Env {
        const env = try getEnvFromString(string, allocator);
        return Env{ .allocator = allocator, .envs = env };
    }
    pub fn getVal(self: Env, key: []const u8) EnvFileError![]const u8 {
        const valquery = self.envs.get(key);
        if (valquery) |val| {
            return val;
        } else {
            return EnvFileError.NonExistantKey;
        }
    }
    pub fn format(
        self: @This(),
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Env {{", .{});
        var iter = self.envs.iterator();
        while (iter.next()) |entry| {
            try writer.print(" {s} = {s},", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
        try writer.print("}}\n", .{});
    }
};
