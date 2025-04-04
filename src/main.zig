const std = @import("std");
const Location = enum { InKey, InVal };
const SyntaxError = error{ MalformedKey, MalformedVal };
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    var storage = std.StringHashMap([]const u8).init(arena.allocator());
    const file = try std.fs.cwd().openFile(".env", .{});
    const text = try file.readToEndAlloc(arena.allocator(), 1000);
    var loc = Location.InKey;
    var key_temp = std.ArrayList(u8).init(arena.allocator());
    var val_temp = std.ArrayList(u8).init(arena.allocator());
    for (text, 0..) |char, n| {
        if (char == '=') {
            if (loc == .InVal) {
                return SyntaxError.MalformedKey;
            }
            loc = Location.InVal;
            continue;
        }
        if ((char == '\n') or (n == text.len)) {
            if (loc == .InKey) {
                return SyntaxError.MalformedVal;
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
    var map_iterator = storage.iterator();
    while (map_iterator.next()) |entry| {
        std.debug.print("key = {s}, value = {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        arena.allocator().free(entry.key_ptr);
        arena.allocator().free(entry.value_ptr);
    }
}
