const std = @import("std");
const StringArrayHashMap = std.StringArrayHashMap;
const ArrayList = std.ArrayList;

// pub fn has(list: ArrayList([]const u8), value: []const u8) bool {
//     for (list.items) |item| {
//         if (std.mem.eql(u8, item, value)) {
//             return true;
//         }
//     }
//     return false;
// }

pub fn encode(allocator: std.mem.Allocator, values: std.StringHashMap(ArrayList([]const u8))) anyerror![]const u8 {
    // name=Ava&friend=Jess&friend=Sarah&friend=Zoe
    // var result: []const u8 = undefined;
    var it = values.iterator();
    while (it.next()) |entry| {

        // if (result.len > 0) {
        // }

        // result = try std.mem.join(allocator, "&", result);

        const key: []const u8 = entry.key_ptr.*;
        const value: ArrayList([]const u8) = entry.value_ptr.*;

        const keypair = try std.fmt.allocPrint(allocator, "{s}=", .{key});
        defer allocator.free(keypair);

        for (value.items) |item| {
            const valuepair = try std.fmt.allocPrint(allocator, "{s}", .{item});
            defer allocator.free(valuepair);
        }
        // result = keypair;
    }

    return "";
}
