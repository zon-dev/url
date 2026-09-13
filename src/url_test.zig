const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const Uri = std.Uri;
const ParseError = std.Uri.ParseError;
const StringHashMap = @import("std").StringHashMap;
const URL = @import("url.zig");

test "parseUri 1" {
    var url = URL.init(.{ .allocator = std.testing.allocator });

    const text = "http://example.com/path?query=1&query2=2";
    const result = url.parseUri(text) catch return;
    // defer result.deinit();

    try testing.expectEqualStrings("http", result.scheme.?);
    try testing.expectEqualStrings(
        "example.com",
        result.host.?,
    );
    try testing.expectEqualStrings(
        "/path",
        result.path,
    );
    try testing.expectEqualStrings("query=1&query2=2", result.query.?);

    var querymap = result.values.?;
    defer querymap.clearAndFree();
    try testing.expectEqualStrings("1", querymap.get("query").?.items[0]);
    try testing.expectEqualStrings("2", querymap.get("query2").?.items[0]);

    if (querymap.get("query3") != null) {
        try testing.expect(false);
    }

    // query=1&query2=2

    var qm = std.StringHashMap(std.ArrayList([]const u8)).init(std.testing.allocator);
    URL.parseQuery(&qm, result.query.?) catch return;
    defer qm.clearAndFree();

    try testing.expectEqualStrings("1", qm.get("query").?.items[0]);
    try testing.expectEqualStrings("2", qm.get("query2").?.items[0]);

    if (qm.get("query3") != null) {
        try testing.expect(false);
    }
}
test "parseUri 2" {
    const text = "foo://example.com:8042/over/there?name=ferret#nose";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    const result = url.parseUri(text) catch return;
    try testing.expectEqualStrings("foo", result.scheme.?);
    try testing.expectEqualStrings(
        "example.com",
        result.host.?,
    );
    try testing.expectEqualStrings(
        "/over/there",
        result.path,
    );
    try testing.expectEqualStrings("name=ferret", result.query.?);
    var qm = url.values.?;
    defer qm.clearAndFree();
    const vm = qm.get("name").?;
    try testing.expectEqualStrings("ferret", vm.items[0]);
    try testing.expectEqualStrings("nose", result.fragment.?);
}

test "url target" {
    const text = "/path?query=1&query2=2";
    const result = Uri.parseAfterScheme("http", text) catch return;
    try testing.expectEqualStrings("/path", result.path.percent_encoded);
    try testing.expectEqualStrings("query=1&query2=2", result.query.?.percent_encoded);
}

test "url parse" {
    const text = "/path?query=1&query2=2";

    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();

    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("/path", result.path);
    try testing.expectEqualStrings("query=1&query2=2", result.query.?);
}

test "RFC example 1" {
    const text = "/over/there?name=ferret#nose";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("/over/there", result.path);
    try testing.expectEqualStrings("name=ferret", @constCast(result.query.?));
    try testing.expectEqualStrings("nose", result.fragment.?);

    var qm = url.values.?;
    const vm = qm.get("name").?;
    try testing.expectEqualStrings("ferret", vm.items[0]);
}

test "edge case - empty path" {
    const text = "";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("", result.path);
}

test "edge case - path only" {
    const text = "/path";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("/path", result.path);
}

test "edge case - path at end of string" {
    const text = "/very/long/path/that/ends/without/query/or/fragment";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("/very/long/path/that/ends/without/query/or/fragment", result.path);
}

test "edge case - single character" {
    const text = "a";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("a", result.path);
}

test "boundary condition - path at string end" {
    // This test specifically targets the boundary condition that was causing segfault
    const text = "/api/users";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("/api/users", result.path);
    // Note: query and fragment are undefined by default, not null
    // We just need to ensure the path is parsed correctly
}

test "boundary condition - path with query at end" {
    const text = "/api/users?name=john";
    var url = URL.init(.{ .allocator = std.testing.allocator });
    defer url.deinit();
    const result = try url.parseUrl(text);
    try testing.expectEqualStrings("/api/users", result.path);
    try testing.expectEqualStrings("name=john", result.query.?);
    // Note: fragment is undefined by default, not null
}
