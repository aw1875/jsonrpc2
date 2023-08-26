const std = @import("std");

const jsonrpc2 = @import("jsonrpc2.zig");

/// RPC Request Object
/// https://www.jsonrpc.org/specification#request_object
pub fn Request(comptime TMethod: type, comptime TParam: type) type {
    return struct {
        /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
        jsonrpc: []const u8 = "2.0",

        /// A String containing the name of the method to be invoked. Method names that begin with the word rpc followed by a period character (U+002E or ASCII 46)
        method: TMethod,

        /// A Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.
        params: ?TParam,

        /// An identifier established by the Client that MUST contain a String, Number, or NULL value if included.
        /// If it is not included it is assumed to be a notification
        id: ?jsonrpc2.ID,

        /// Initializes a new request.
        pub fn init(method: TMethod, params: ?TParam, id: ?jsonrpc2.ID) @This() {
            return .{
                .method = method,
                .params = params,
                .id = id,
            };
        }

        /// Parses a request from a JSON string.
        pub fn parse(data: []const u8, allocator: std.mem.Allocator) !@This() {
            var root = try std.json.parseFromSliceLeaky(std.json.Value, allocator, data, .{});

            var method = try std.json.parseFromValueLeaky(TMethod, allocator, root.object.get("method").?, .{});
            var params: ?TParam = null;
            var id: ?jsonrpc2.ID = null;

            if (root.object.get("params")) |p| {
                params = try std.json.parseFromValueLeaky(?TParam, allocator, p, .{});
            }

            if (root.object.get("id")) |i| {
                id = try std.json.parseFromValueLeaky(?jsonrpc2.ID, allocator, i, .{});
            }

            return .{
                .method = method,
                .params = params,
                .id = id,
            };
        }
    };
}

test "simple string w/o id" {
    var expected =
        \\{"jsonrpc":"2.0","method":"test","params":null,"id":null}
    ;
    var request = Request([]const u8, ?u8).init("test", null, null);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqual(request.id, null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "simple string w/ id as number" {
    var expected =
        \\{"jsonrpc":"2.0","method":"test","params":null,"id":1}
    ;
    var request = Request([]const u8, ?u8).init("test", null, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqual(request.id.?.num, 1);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse simple request w/ id as number" {
    var data =
        \\{"jsonrpc":"2.0","method":"test","params":null,"id":1}
    ;
    var request = try Request([]const u8, ?u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqual(request.id.?.num, 1);
}

test "simple string w/ id as string" {
    var expected =
        \\{"jsonrpc":"2.0","method":"test","params":null,"id":"1"}
    ;
    var request = Request([]const u8, ?u8).init("test", null, jsonrpc2.ID{ .str = "1" });

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqualStrings(request.id.?.str, "1");

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse simple request w/ id as string" {
    var data =
        \\{"jsonrpc":"2.0","method":"test","params":null,"id":"1"}
    ;
    var request = try Request([]const u8, ?u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqual(request.id.?.num, 1);
}

test "full request w/o id" {
    var expected =
        \\{"jsonrpc":"2.0","method":"test","params":null,"id":null}
    ;
    var request = Request([]const u8, ?u8).init("test", null, null);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqual(request.id, null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "full request w/ id as number" {
    var expected =
        \\{"jsonrpc":"2.0","method":"number","params":1024,"id":1}
    ;
    var request = Request([]const u8, u16).init("number", 1024, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "number");
    try std.testing.expectEqual(request.params.?, 1024);
    try std.testing.expectEqual(request.id.?.num, 1);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse full request w/ id as number" {
    var data =
        \\{"jsonrpc":"2.0","method":"number","params":1024,"id":1}
    ;
    var request = try Request([]const u8, u16).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "number");
    try std.testing.expectEqual(request.params.?, 1024);
    try std.testing.expectEqual(request.id.?.num, 1);
}

test "full request w/ id as string" {
    var expected =
        \\{"jsonrpc":"2.0","method":"number","params":1024,"id":"1"}
    ;
    var request = Request([]const u8, u16).init("number", 1024, jsonrpc2.ID{ .str = "1" });

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "number");
    try std.testing.expectEqual(request.params.?, 1024);
    try std.testing.expectEqualStrings(request.id.?.str, "1");

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse full request w/ id as string" {
    var data =
        \\{"jsonrpc":"2.0","method":"number","params":1024,"id":"1"}
    ;
    var request = try Request([]const u8, u16).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "number");
    try std.testing.expectEqual(request.params.?, 1024);
    try std.testing.expectEqual(request.id.?.num, 1);
}
