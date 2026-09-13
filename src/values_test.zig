const std = @import("std");
const testing = std.testing;
const allocator = testing.allocator;

const URL = @import("url.zig");
const Values = @import("values.zig");

test "sample1" {
    var values: std.StringHashMap(std.ArrayList([]const u8)) = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer values.deinit();
    var name = std.ArrayList([]const u8).initCapacity(allocator, 0) catch return;
    defer name.deinit(allocator);
    try name.append(allocator, "Ava");

    var friend = std.ArrayList([]const u8).initCapacity(allocator, 0) catch return;
    defer friend.deinit(allocator);
    try friend.append(allocator, "Jess");
    try friend.append(allocator, "Sarah");
    try friend.append(allocator, "Zoe");

    try values.put("name", name);
    try values.put("friend", friend);

    try std.testing.expectEqualStrings("Ava", name.getLast());

    const friend1 = values.get("friend").?.items[0];
    const friend2 = values.get("friend").?.items[1];
    const friend3 = values.get("friend").?.items[2];
    try std.testing.expectEqualStrings("Jess", friend1);
    try std.testing.expectEqualStrings("Sarah", friend2);
    try std.testing.expectEqualStrings("Zoe", friend3);

    values.clearAndFree();
}

test "sample2" {
    const text = "name=Ava&friend=Jess&friend=Sarah&friend=Zoe";
    var values: std.StringHashMap(std.ArrayList([]const u8)) = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer values.deinit();
    try URL.parseQuery(&values, text);
    try std.testing.expectEqualStrings("Ava", values.get("name").?.items[0]);
    try std.testing.expectEqualStrings("Jess", values.get("friend").?.items[0]);
    try std.testing.expectEqualStrings("Sarah", values.get("friend").?.items[1]);
    try std.testing.expectEqualStrings("Zoe", values.get("friend").?.items[2]);
}

test "sample3" {
    const text = "https://example.org/?a=1&a=2&b=&=3&&&&";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    const result = try url.parseUri(text);

    var values = result.values.?;
    defer values.deinit();

    const a1 = values.get("a").?.items[0];
    const a2 = values.get("a").?.items[1];
    try std.testing.expectEqual(2, values.get("a").?.items.len);
    try std.testing.expectEqualStrings("1", a1);
    try std.testing.expectEqualStrings("2", a2);

    try std.testing.expectEqualStrings("", values.get("b").?.items[0]);
    const v3 = values.get("").?;
    try std.testing.expectEqual(1, v3.items.len);
    try std.testing.expectEqualStrings("3", v3.items[0]);
}

test "encode" {
    var name = std.ArrayList([]const u8).initCapacity(allocator, 0) catch return;
    defer name.deinit(allocator);
    try name.append(allocator, "Ava");

    var friend = std.ArrayList([]const u8).initCapacity(allocator, 0) catch return;
    defer friend.deinit(allocator);
    try friend.append(allocator, "Jess");
    try friend.append(allocator, "Sarah");
    try friend.append(allocator, "Zoe");

    var values: std.StringHashMap(std.ArrayList([]const u8)) = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer values.deinit();

    try values.put("name", name);
    try values.put("friend", friend);
    const url_values = try Values.encode(allocator, values);
    defer allocator.free(url_values);
    // const expected = "name=Ava&friend=Jess&friend=Sarah&friend=Zoe";
    // std.debug.print("url_values: {s}\n", .{url_values});
    // try testing.expectEqualStrings(expected, url_values);
}
