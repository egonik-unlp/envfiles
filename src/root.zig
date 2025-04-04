const std = @import("std");
const Location = enum { InKey, InVal };
const EnvFileSyntaxError = error{ MalformedKey, MalformedVal };
const EnvFileError = error{NonExistantKey};
fn getEnv(filepath: []const u8, allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var storage = std.StringHashMap([]const u8).init(allocator);
    const file = try std.fs.cwd().openFile(filepath, .{});
    const text = try file.readToEndAlloc(allocator, 1000);
    var loc = Location.InKey;
    var key_temp = std.ArrayList(u8).init(allocator);
    var val_temp = std.ArrayList(u8).init(allocator);
    for (text, 0..) |char, n| {
        if (char == '=') {
            if (loc == .InVal) {
                return EnvFileSyntaxError.MalformedKey;
            }
            loc = Location.InVal;
            continue;
        }
        if ((char == '\n') or (n == text.len)) {
            if (loc == .InKey) {
                return EnvFileSyntaxError.MalformedVal;
            }
            const key = try key_temp.toOwnedSlice();
            const val = try val_temp.toOwnedSlice();
            try storage.put(key, val);
            loc = .InKey;
            continue;
        }
        switch (loc) {
            .InKey => try key_temp.append(char),
            .InVal => try val_temp.append(char),
        }
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
    pub fn getVal(self: Env, key: []const u8) EnvFileError![]const u8 {
        const valquery = self.envs.get(key);
        if (valquery) |val| {
            return val;
        } else {
            return EnvFileError.NonExistantKey;
        }
    }
};
