const std = @import("std");

/// A unique identifier for a resource
pub const ID = struct {
    /// The id value as a number
    num: u64,

    /// The id value as a string
    str: []const u8,

    /// Is the id value a string
    is_string: bool,

    /// Convert the id to a string representation
    pub fn asString(self: ID, allocator: std.mem.Allocator) []const u8 {
        if (self.is_string) {
            return self.str;
        }

        return std.fmt.allocPrint(allocator, "{d}", .{self.num}) catch "0";
    }

    /// Serialize the `ID` to a JSON string
    pub fn serializeData(self: ID, allocator: std.mem.Allocator) ![]const u8 {
        var buffer = std.ArrayListUnmanaged(u8){};

        if (self.is_string) {
            try std.json.stringify(self.str, .{}, buffer.writer(allocator));
        } else {
            try std.json.stringify(self.num, .{}, buffer.writer(allocator));
        }

        return buffer.items;
    }

    /// Deserialize JSON string into `ID` struct
    pub fn deserializeData(data: []const u8, allocator: std.mem.Allocator) !ID {
        var parsed_data = try std.json.parseFromSlice(ID, allocator, data, .{});

        return .{
            .num = parsed_data.value.num,
            .str = parsed_data.value.str,
            .is_string = parsed_data.value.is_string,
        };
    }
};

test "num as string" {
    var id = ID{ .num = 42, .str = undefined, .is_string = false };
    try std.testing.expectEqualStrings(id.asString(std.heap.page_allocator), "42");
}

test "string as string" {
    var id = ID{ .num = 0, .str = "42", .is_string = true };
    try std.testing.expectEqualStrings(id.asString(std.heap.page_allocator), "42");
}

test "serialize num" {
    var id = ID{ .num = 42, .str = undefined, .is_string = false };
    var serialized_id = try id.serializeData(std.heap.page_allocator);
    try std.testing.expectEqualStrings(serialized_id, "42");
}

test "serialize string" {
    var id = ID{ .num = 0, .str = "42", .is_string = true };
    var serialized_id = try id.serializeData(std.heap.page_allocator);
    try std.testing.expectEqualStrings(serialized_id, "\"42\"");
}

test "deserialize data w/ num" {
    var data =
        \\{
        \\    "num": 1,
        \\    "str": "",
        \\    "is_string": false
        \\}
    ;
    var id = try ID.deserializeData(data, std.heap.page_allocator);

    try std.testing.expectEqual(id.num, 1);
    try std.testing.expectEqualStrings(id.str, "");
}

test "deserialize data w/ string" {
    var data =
        \\{
        \\    "num": 0,
        \\    "str": "1",
        \\    "is_string": true
        \\}
    ;
    var id = try ID.deserializeData(data, std.heap.page_allocator);

    try std.testing.expectEqual(id.num, 0);
    try std.testing.expectEqualStrings(id.str, "1");
}

/// RPC Error Object
/// https://www.jsonrpc.org/specification#error_object
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
    data: ?std.json.Value,

    /// Initializes a new error.
    pub fn init(code: i64, message: []const u8, data: ?std.json.Value) Error {
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
