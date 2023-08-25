const std = @import("std");

/// Request
pub const Request = @import("request.zig").Request;

/// Response
pub const Response = @import("response.zig").Response;

/// jsonrpc2
pub const jsonrpc2 = @import("jsonrpc2.zig");

test "RPC call with positional parameters" {
    // Example data
    // --> {"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
    // <-- {"jsonrpc": "2.0", "result": 19, "id": 1}

    // Request
    var params = &[_]i8{ 42, 23 };
    var id = jsonrpc2.ID{ .num = 1, .str = undefined, .is_string = false };
    var request = Request([]const u8, []const i8).init("subtract", params, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "subtract");
    try std.testing.expectEqual(request.params, params);
    try std.testing.expectEqualStrings(request.id.?, "1");

    var request_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, request_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(request_buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"subtract\",\"params\":[42,23],\"id\":\"1\"}");

    // Response
    var response = Response(i8, []const i8).init(19, null, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, 19);
    try std.testing.expectEqual(response.err, null);
    try std.testing.expectEqualStrings(response.id, "1");

    var response_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, response_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(response_buffer.items, "{\"jsonrpc\":\"2.0\",\"result\":19,\"err\":null,\"id\":\"1\"}");
}

test "RPC call with named parameters" {
    // Example data
    // --> {"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}
    // <-- {"jsonrpc": "2.0", "result": 19, "id": 3}

    // Temp struct
    const T = struct {
        subtrahend: i8,
        minuend: i8,
    };

    // Request
    var params = T{ .subtrahend = 23, .minuend = 42 };
    var id = jsonrpc2.ID{ .num = 3, .str = undefined, .is_string = false };
    var request = Request([]const u8, T).init("subtract", params, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "subtract");
    try std.testing.expectEqual(request.params, params);
    try std.testing.expectEqualStrings(request.id.?, "3");

    var request_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, request_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(request_buffer.items, "{\"jsonrpc\":\"2.0\",\"method\":\"subtract\",\"params\":{\"subtrahend\":23,\"minuend\":42},\"id\":\"3\"}");

    // Response
    var response = Response(i8, []const i8).init(19, null, try id.serializeData(std.heap.page_allocator));

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, 19);
    try std.testing.expectEqual(response.err, null);
    try std.testing.expectEqualStrings(response.id, "3");

    var response_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, response_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(response_buffer.items, "{\"jsonrpc\":\"2.0\",\"result\":19,\"err\":null,\"id\":\"3\"}");
}
