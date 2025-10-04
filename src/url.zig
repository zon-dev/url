const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const Uri = std.Uri;
const ParseError = std.Uri.ParseError;
const StringHashMap = @import("std").StringHashMap;

const Values = @import("values.zig").Values;

pub const URL = @This();

allocator: std.mem.Allocator,

uri: Uri = undefined,
scheme: ?[]const u8 = undefined,
host: ?[]const u8 = undefined,
path: []const u8 = "/",
fragment: ?[]const u8 = undefined,
query: ?[]const u8 = undefined,

// querymap: ?StringHashMap(std.ArrayList([]const u8))
values: ?std.StringHashMap(std.array_list.Managed([]const u8)) = undefined,

// https://developer.mozilla.org/en-US/docs/Learn/Common_questions/Web_mechanics/What_is_a_URL

pub fn init(self: URL) URL {
    return .{
        .allocator = self.allocator,
        .values = std.StringHashMap(std.array_list.Managed([]const u8)).init(self.allocator),
    };
}

pub fn deinit(self: *URL) void {
    if (self.values != null) {
        self.values.?.clearAndFree();
    }
    // self.allocator.destroy(self);
}

const SliceReader = struct {
    const Self = @This();

    slice: []const u8,
    offset: usize = 0,
    fn peek(self: Self) ?u8 {
        if (self.offset >= self.slice.len)
            return null;
        return self.slice[self.offset];
    }
    fn get(self: *Self) ?u8 {
        if (self.offset >= self.slice.len)
            return null;
        const c = self.slice[self.offset];
        self.offset += 1;
        return c;
    }

    fn readUntil(self: *Self, comptime predicate: fn (u8) bool) []const u8 {
        const start = self.offset;
        var end = start;
        while (end < self.slice.len) {
            if (predicate(self.slice[end])) {
                break;
            }
            end += 1;
        }
        self.offset = end;
        return self.slice[start..end];
    }

    fn readUntilEof(self: *Self) []const u8 {
        const start = self.offset;
        self.offset = self.slice.len;
        return self.slice[start..];
    }
};

pub fn parseUrl(self: *URL, text: []const u8) ParseError!*URL {
    var reader = SliceReader{ .slice = text };
    self.path = reader.readUntil(isPathSeparator);
    if ((reader.peek() orelse 0) == '?') { // query part
        std.debug.assert(reader.get().? == '?');
        self.query = reader.readUntil(isQuerySeparator);
        if (self.values == null) {
            self.values = std.StringHashMap(std.ArrayList([]const u8)).init(self.allocator);
        }
        try parseQuery(&self.values.?, self.query.?);
    }

    if ((reader.peek() orelse 0) == '#') { // fragment part
        std.debug.assert(reader.get().? == '#');
        self.fragment = reader.readUntilEof();
    }

    return self;
}

fn uriToUrl(self: *URL, uri: Uri) void {
    self.uri = uri;
    self.scheme = uri.scheme;
    if (uri.host != null) {
        if (!uri.host.?.isEmpty()) {
            self.host = uri.host.?.percent_encoded;
        }
    }
    self.path = uri.path.percent_encoded;

    if (uri.query != null) {
        self.query = @constCast(uri.query.?.percent_encoded);
        if (self.values != null) {
            try parseQuery(&self.values.?, @constCast(uri.query.?.percent_encoded));
        }
    }
    if (uri.fragment != null) {
        self.fragment = @constCast(uri.fragment.?.percent_encoded);
    }
    return;
}

pub fn parseUri(self: *URL, text: []const u8) ParseError!*URL {
    const uri = try Uri.parse(text);
    self.uriToUrl(uri);
    return self;
}

pub fn parseQuery(map: *std.StringHashMap(std.array_list.Managed([]const u8)), uri_query: []const u8) !void {
    const allocator = std.heap.page_allocator;

    var queryitmes = std.mem.splitSequence(u8, uri_query, "&");
    while (true) {
        const pair = queryitmes.next();
        if (pair == null) {
            break;
        }
        var kv = std.mem.splitSequence(u8, pair.?, "=");
        if (kv.buffer.len == 0) {
            continue;
        }
        const key = kv.next();
        if (key == null) {
            continue;
        }

        const value = kv.next();
        if (value == null) {
            continue;
        }

        var al: std.array_list.Managed([]const u8) = undefined;
        const v = map.get(key.?);
        if (v == null) {
            al = std.ArrayList([]const u8).initCapacity(allocator, 0) catch continue;
            al.append(allocator, value.?) catch continue;
            map.put(key.?, al) catch continue;
            continue;
        }

        al = v.?;
        al.append(allocator, value.?) catch continue;
        map.put(key.?, al) catch continue;
    }
}

fn isAuthoritySeparator(c: u8) bool {
    return switch (c) {
        '/', '?', '#' => true,
        else => false,
    };
}

fn isPathSeparator(c: u8) bool {
    return switch (c) {
        '?', '#' => true,
        else => false,
    };
}

fn isQuerySeparator(c: u8) bool {
    return switch (c) {
        '#' => true,
        else => false,
    };
}
