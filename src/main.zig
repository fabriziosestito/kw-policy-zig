const std = @import("std");
const wapc = @import("wapc");
const policy = @import("policy.zig");

export fn __guest_call(operation_size: usize, payload_size: usize) bool {
    return wapc.handleCall(std.heap.page_allocator, operation_size, payload_size, &functions);
}

// Exported waPC guest functions
const functions = [_]wapc.Function{
    wapc.Function{ .name = "protocol_version", .invoke = policy.protocolVersion },
    wapc.Function{ .name = "validate_settings", .invoke = policy.validateSettings },
    wapc.Function{ .name = "validate", .invoke = policy.validate },
};
