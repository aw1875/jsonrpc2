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
    var expected_request =
        \\{"jsonrpc":"2.0","method":"subtract","params":[42,23],"id":1}
    ;
    var params = &[_]i8{ 42, 23 };
    var request = Request([]const u8, []const i8).init("subtract", params, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "subtract");
    try std.testing.expectEqual(request.params.?, params);
    try std.testing.expectEqual(request.id.?.num, 1);

    var request_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, request_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected_request, request_buffer.items);

    // Response
    var expected_response =
        \\{"jsonrpc":"2.0","result":19,"error":null,"id":1}
    ;
    var response = Response(i8).init(19, null, jsonrpc2.ID{ .num = 1 });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, 19);
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);

    var response_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, response_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected_response, response_buffer.items);
}

test "RPC call with positional parameters (parse)" {
    // Request
    var request_data =
        \\ {"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
    ;
    var request = try Request([]const u8, []const i8).parse(request_data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "subtract");
    try std.testing.expectEqualSlices(i8, request.params.?, &[_]i8{ 42, 23 });
    try std.testing.expectEqual(request.id.?.num, 1);

    // Response
    var response_data =
        \\ {"jsonrpc": "2.0", "result": 19, "id": 1}
    ;

    var response = try Response(i8).parse(response_data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, 19);
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 1);
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
    var expected_request =
        \\{"jsonrpc":"2.0","method":"subtract","params":{"subtrahend":23,"minuend":42},"id":3}
    ;
    var params = T{ .subtrahend = 23, .minuend = 42 };
    var request = Request([]const u8, T).init("subtract", params, jsonrpc2.ID{ .num = 3 });

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "subtract");
    try std.testing.expectEqual(request.params.?, params);
    try std.testing.expectEqual(request.id.?.num, 3);

    var request_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(request, .{}, request_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected_request, request_buffer.items);

    // Response
    var expected_response =
        \\{"jsonrpc":"2.0","result":19,"error":null,"id":3}
    ;
    var response = Response(i8).init(19, null, jsonrpc2.ID{ .num = 3 });

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, 19);
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 3);

    var response_buffer = std.ArrayListUnmanaged(u8){};
    try std.json.stringify(response, .{}, response_buffer.writer(std.heap.page_allocator));
    try std.testing.expectEqualStrings(expected_response, response_buffer.items);
}

test "RPC call with named parameters (parse)" {
    // Temp struct
    const T = struct {
        subtrahend: i8,
        minuend: i8,
    };

    // Request
    var request_data =
        \\ {"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}
    ;
    var request = try Request([]const u8, T).parse(request_data, std.heap.page_allocator);

    try std.testing.expectEqualStrings(request.jsonrpc, "2.0");
    try std.testing.expectEqualStrings(request.method, "subtract");
    try std.testing.expectEqual(request.params.?, T{ .subtrahend = 23, .minuend = 42 });
    try std.testing.expectEqual(request.id.?.num, 3);

    // Response
    var expected_response =
        \\ {"jsonrpc": "2.0", "result": 19, "id": 3}
    ;
    var response = try Response(i8).parse(expected_response, std.heap.page_allocator);

    try std.testing.expectEqualStrings(response.jsonrpc, "2.0");
    try std.testing.expectEqual(response.result, 19);
    try std.testing.expectEqual(response.@"error", null);
    try std.testing.expectEqual(response.id.num, 3);
}
