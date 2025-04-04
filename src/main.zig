const lib = @import("envfiles_lib");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const env = try lib.Env.init(".env", arena.allocator());
    const v1 = try env.getVal("KEY");
    std.debug.print("KF = {s}\n", .{v1});
}
