const std = @import("std");

const ID = @import("jsonrpc2.zig").ID;

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
        id: ?[]const u8,

        /// Initializes a new request.
        pub fn init(method: TMethod, params: ?TParam, id: ?[]const u8) @This() {
            return .{
                .method = method,
                .params = params,
                .id = id,
            };
        }
    };
}

test "simple string w/o id" {
    var request = Request([]const u8, ?u8).init("test", null, null);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params, null);
    try std.testing.expectEqual(request.id, null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"test\",\"params\":null,\"id\":null}");
}

test "simple string w/ id as number" {
    var id = ID{ .num = 1, .str = undefined, .is_string = false };
    var request = Request([]const u8, ?u8).init("test", null, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"test\",\"params\":null,\"id\":\"1\"}");
}

test "simple string w/ id as string" {
    var id = ID{ .num = 0, .str = "1", .is_string = true };
    var request = Request([]const u8, ?u8).init("test", null, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"test\",\"params\":null,\"id\":\"\\\"1\\\"\"}");
}

test "full request w/o id" {
    var request = Request([]const u8, u16).init("test", 1024, null);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "test");
    try std.testing.expectEqual(request.params.?, 1024);
    try std.testing.expectEqual(request.id, null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"test\",\"params\":1024,\"id\":null}");
}

test "full request w/ id as number" {
    var id = ID{ .num = 1, .str = undefined, .is_string = false };
    var request = Request([]const u8, u16).init("number", 1024, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqual(request.params.?, 1024);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"number\",\"params\":1024,\"id\":\"1\"}");
}

test "full request w/ id as string" {
    var id = ID{ .num = 0, .str = "1", .is_string = true };
    var request = Request([]const u8, u16).init("number", 1024, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqual(request.params.?, 1024);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"number\",\"params\":1024,\"id\":\"\\\"1\\\"\"}");
}
