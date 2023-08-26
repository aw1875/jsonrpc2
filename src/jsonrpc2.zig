const std = @import("std");

const utils = @import("utils.zig");

/// A unique identifier for a resource
pub const ID = union(enum) {
    /// The id value as a number
    num: i64,

    /// The id value as a string
    str: []const u8,

    /// Include UnionParser functions
    pub usingnamespace utils.UnionParser(@This());
};

test "num as string" {
    var id = ID{ .num = 42 };
    try std.testing.expectEqual(id.num, 42);
}

test "string as string" {
    var id = ID{ .str = "42" };
    try std.testing.expectEqualStrings(id.str, "42");
}

test "deserialize data from num" {
    var data =
        \\ { "id": 1 }
    ;
    var root = try std.json.parseFromSliceLeaky(std.json.Value, std.heap.page_allocator, data, .{});
    const id = try std.json.parseFromValueLeaky(ID, std.heap.page_allocator, root.object.get("id").?, .{});

    try std.testing.expectEqual(id.num, 1);
}

test "deserialize data from string" {
    var data =
        \\ { "id": "1" }
    ;
    var root = try std.json.parseFromSliceLeaky(std.json.Value, std.heap.page_allocator, data, .{});
    const id = try std.json.parseFromValueLeaky(ID, std.heap.page_allocator, root.object.get("id").?, .{});

    try std.testing.expectEqual(id.num, 1);
}

/// RPC Error Object
/// {@link https://www.jsonrpc.org/specification#error_object}
pub const Error = struct {
    /// A Number that indicates the error type that occurred.
    /// This MUST be an integer.
    code: i64,

    /// A String providing a short description of the error.
    /// The message SHOULD be limited to a concise single sentence.
    message: []const u8,

    /// A Primitive or Structured value that contains additional information about the error.
    /// This may be omitted.
    /// The value of this member is defined by the Server (e.g. detailed error information, nested errors etc.).
    data: ?std.json.Value = null,

    /// Initializes a new error.
    pub fn init(code: i64, message: []const u8, data: std.json.Value) Error {
        return .{
            .code = code,
            .message = message,
            .data = data,
        };
    }

    /// Parse the error code
    /// Returns 0 if no errors, otherwise returns appropriate error
    pub fn parseError(self: Error) !u8 {
        switch (self.code) {
            -32700 => return error.ParseError,
            -32600 => return error.InvalidRequest,
            -32601 => return error.MethodNotFound,
            -32602 => return error.InvalidParams,
            -32603 => return error.InternalError,
            -32099...-32000 => return error.ServerError,
            else => return 0,
        }
    }
};

test "No Error" {
    var e = Error.init(0, undefined, undefined);
    try std.testing.expectEqual(try e.parseError(), 0);
}

test "ParseError" {
    var e = Error.init(-32700, undefined, undefined);
    try std.testing.expectEqual(e.parseError(), error.ParseError);
}

test "InvalidRequest" {
    var e = Error.init(-32600, undefined, undefined);
    try std.testing.expectEqual(e.parseError(), error.InvalidRequest);
}

test "MethodNotFound" {
    var e = Error.init(-32601, undefined, undefined);
    try std.testing.expectEqual(e.parseError(), error.MethodNotFound);
}

test "InvalidParams" {
    var e = Error.init(-32602, undefined, undefined);
    try std.testing.expectEqual(e.parseError(), error.InvalidParams);
}

test "InternalError" {
    var e = Error.init(-32603, undefined, undefined);
    try std.testing.expectEqual(e.parseError(), error.InternalError);
}

test "ServerError" {
    var e = Error.init(-32000, undefined, undefined);
    try std.testing.expectEqual(e.parseError(), error.ServerError);
}
