const std = @import("std");

const ID = @import("jsonrpc2.zig").ID;

/// RPC Response Object.
/// https://www.jsonrpc.org/specification#response_object
pub fn Response(comptime TResult: type, comptime TErrorData: type) type {
    return struct {
        /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
        jsonrpc: []const u8 = "2.0",

        /// This member is REQUIRED on success.
        /// This member MUST NOT exist if there was an error invoking the method.
        /// The value of this member is determined by the method invoked on the Server.
        result: ?TResult,

        /// This member is REQUIRED on error.
        /// This member MUST NOT exist if there was no error triggered during invocation.
        /// The value for this member MUST be an Object as defined in section 5.1.
        err: ?TErrorData,

        /// This member is REQUIRED.
        /// It MUST be the same as the value of the id member in the Request Object.
        /// If there was an error in detecting the id in the Request object (e.g. Parse error/Invalid Request), it MUST be Null.
        id: []const u8,

        /// Initializes a new response.
        pub fn init(result: ?TResult, err: ?TErrorData, id: []const u8) @This() {
            return .{
                .result = result,
                .err = err,
                .id = id,
            };
        }
    };
}

test "simple string w/ id as number" {
    var id = ID{ .num = 1, .str = undefined, .is_string = false };
    var response = Response([]const u8, ?u8).init("test", null, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "test");
    try std.testing.expectEqual(response.err, null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"result\":\"test\",\"err\":null,\"id\":\"1\"}");
}

test "simple string w/ id as string" {
    var id = ID{ .num = 0, .str = "1", .is_string = true };
    var response = Response([]const u8, ?u8).init("test", null, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "test");
    try std.testing.expectEqual(response.err, null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"result\":\"test\",\"err\":null,\"id\":\"\\\"1\\\"\"}");
}

test "full request w/ id as number" {
    var id = ID{ .num = 1, .str = undefined, .is_string = false };
    var response = Response([]const u8, u16).init("number", 1024, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.err.?, 1024);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"result\":\"number\",\"err\":1024,\"id\":\"1\"}");
}

test "full request w/ id as string" {
    var id = ID{ .num = 0, .str = "1", .is_string = true };
    var response = Response([]const u8, u16).init("number", 1024, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.err.?, 1024);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(buffer.items, "{\"jsonrpc\":\"2.0\",\"result\":\"number\",\"err\":1024,\"id\":\"\\\"1\\\"\"}");
}
