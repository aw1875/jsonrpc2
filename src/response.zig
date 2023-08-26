const std = @import("std");

const jsonrpc2 = @import("jsonrpc2.zig");

/// RPC Response Object.
/// https://www.jsonrpc.org/specification#response_object
pub fn Response(comptime T: type) type {
    return struct {
        /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
        jsonrpc: []const u8 = "2.0",

        /// This member is REQUIRED on success.
        /// This member MUST NOT exist if there was an error invoking the method.
        /// The value of this member is determined by the method invoked on the Server.
        result: ?T,

        /// This member is REQUIRED on error.
        /// This member MUST NOT exist if there was no error triggered during invocation.
        /// The value for this member MUST be an Object as defined in section 5.1.
        @"error": ?jsonrpc2.Error,

        /// This member is REQUIRED.
        /// It MUST be the same as the value of the id member in the Request Object.
        /// If there was an error in detecting the id in the Request object (e.g. Parse error/Invalid Request), it MUST be Null.
        id: jsonrpc2.ID,

        /// Initializes a new response.
        pub fn init(result: ?T, err: ?jsonrpc2.Error, id: jsonrpc2.ID) @This() {
            return .{
                .result = result,
                .@"error" = err,
                .id = id,
            };
        }

        /// Parses a response from a JSON string.
        pub fn parse(data: []const u8, allocator: std.mem.Allocator) !@This() {
            var root = try std.json.parseFromSliceLeaky(std.json.Value, allocator, data, .{});

            var result: ?T = null;
            var err: ?jsonrpc2.Error = null;

            if (root.object.get("result")) |res| {
                result = try std.json.parseFromValueLeaky(T, allocator, res, .{});
            } else if (root.object.get("error")) |e| {
                err = try std.json.parseFromValueLeaky(jsonrpc2.Error, allocator, e, .{});
            }

            var id = try std.json.parseFromValueLeaky(jsonrpc2.ID, allocator, root.object.get("id").?, .{});

            return .{
                .result = result,
                .@"error" = err,
                .id = id,
            };
        }
    };
}

test "simple string w/ id as number" {
    var expected =
        \\{"jsonrpc":"2.0","result":"test","error":null,"id":1}
    ;
    var response = Response([]const u8).init("test", null, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "test");
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse simple response w/ id as number" {
    var data =
        \\{"jsonrpc":"2.0","result":"test","error":null,"id":1}
    ;
    var response = try Response([]const u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "test");
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);
}

test "simple string w/ id as string" {
    var expected =
        \\{"jsonrpc":"2.0","result":"test","error":null,"id":"1"}
    ;
    var response = Response([]const u8).init("test", null, jsonrpc2.ID{ .str = "1" });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "test");
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqualStrings(response.id.str, "1");

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse simple response w/ id as string" {
    var data =
        \\{"jsonrpc":"2.0","result":"test","error":null,"id":"1"}
    ;
    var response = try Response([]const u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "test");
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);
}

test "full response w/ id as number" {
    var expected =
        \\{"jsonrpc":"2.0","result":"number","error":null,"id":1}
    ;
    var response = Response([]const u8).init("number", null, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "number");
    try std.testing.expectEqual(response.@"error", null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse full response w/ id as number" {
    var data =
        \\{"jsonrpc":"2.0","result":"number","error":null,"id":1}
    ;
    var response = try Response([]const u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "number");
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);
}

test "full response w/ id as number + error" {
    var expected =
        \\{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":1}
    ;
    var response = Response([]const u8).init(null, jsonrpc2.Error{ .code = -32601, .message = "Method not found" }, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, null);
    try std.testing.expectEqualStrings(response.@"error".?.message, "Method not found");
    try std.testing.expectEqual(response.@"error".?.code, -32601);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{ .emit_null_optional_fields = false }, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse full response w/id as number + error" {
    var data =
        \\{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":1}
    ;
    var response = try Response([]const u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, null);
    try std.testing.expectEqualStrings(response.@"error".?.message, "Method not found");
    try std.testing.expectEqual(response.@"error".?.code, -32601);
    try std.testing.expectEqual(response.id.num, 1);
}

test "full response w/ id as string" {
    var expected =
        \\{"jsonrpc":"2.0","result":"number","error":null,"id":"1"}
    ;
    var response = Response([]const u8).init("number", null, jsonrpc2.ID{ .str = "1" });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "number");
    try std.testing.expectEqual(response.@"error", null);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse full response w/ id as string" {
    var data =
        \\{"jsonrpc":"2.0","result":"number","error":null,"id":"1"}
    ;
    var response = try Response([]const u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(response.result.?, "number");
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);
}

test "full response w/ id as string + error" {
    var expected =
        \\{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":"1"}
    ;
    var response = Response([]const u8).init(null, jsonrpc2.Error{ .code = -32601, .message = "Method not found" }, jsonrpc2.ID{ .str = "1" });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, null);
    try std.testing.expectEqualStrings(response.@"error".?.message, "Method not found");
    try std.testing.expectEqual(response.@"error".?.code, -32601);

    var buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{ .emit_null_optional_fields = false }, buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "parse full response w/id as string + error" {
    var data =
        \\{"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":"1"}
    ;
    var response = try Response([]const u8).parse(data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, null);
    try std.testing.expectEqualStrings(response.@"error".?.message, "Method not found");
    try std.testing.expectEqual(response.@"error".?.code, -32601);
    try std.testing.expectEqual(response.id.num, 1);
}
