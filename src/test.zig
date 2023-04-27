const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const json = std.json;
const policy = @import("policy.zig");
const k8s = @import("k8s.zig");

test "return valid true = for valid settings" {
    var allocator = std.heap.page_allocator;

    var invalid_names = [_][]const u8{ "foo", "bar" };
    var settings = policy.Settings{ .invalid_names = &invalid_names };
    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(settings, .{}, buffer.writer());

    var response_payload = try policy.validateSettings(allocator, buffer.items);
    var stream = json.TokenStream.init(response_payload.?);
    const parse_options = .{ .allocator = allocator };
    const response = try json.parse(policy.SettingsValidationResponse, &stream, parse_options);

    try testing.expect(response.valid == true);
}

test "return valid = false for invalid settings" {
    var allocator = std.heap.page_allocator;

    var invalid_names = [_][]const u8{};
    var settings = policy.Settings{ .invalid_names = &invalid_names };
    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(settings, .{}, buffer.writer());

    var response_payload = try policy.validateSettings(allocator, buffer.items);
    var stream = json.TokenStream.init(response_payload.?);
    const parse_options = .{ .allocator = allocator };
    const response = try json.parse(policy.SettingsValidationResponse, &stream, parse_options);

    try testing.expect(response.valid == false);
}

test "accept pod with valid name" {
    var allocator = std.heap.page_allocator;

    const request = policy.ValidationRequest{
        .settings = .{
            .invalid_names = &[_][]const u8{ "foo", "bar" },
        },
        .request = .{
            .kind = .{
                .group = "core",
                .version = "v1",
                .kind = "Pod",
            },
            .object = .{
                .metadata = .{ .name = "baz" },
            },
        },
    };

    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(request, .{}, buffer.writer());

    var response_payload = try policy.validate(allocator, buffer.items);
    var stream = json.TokenStream.init(response_payload.?);
    const parse_options = .{ .allocator = allocator };
    const response = try json.parse(policy.ValidationResponse, &stream, parse_options);

    try testing.expect(response.accepted == true);
}

test "reject pod with invalid name" {
    var allocator = std.heap.page_allocator;

    const request = policy.ValidationRequest{
        .settings = .{
            .invalid_names = &[_][]const u8{ "foo", "bar" },
        },
        .request = .{
            .kind = .{
                .group = "core",
                .version = "v1",
                .kind = "Pod",
            },
            .object = .{
                .metadata = .{ .name = "foo" },
            },
        },
    };

    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(request, .{}, buffer.writer());

    var response_payload = try policy.validate(allocator, buffer.items);
    var stream = json.TokenStream.init(response_payload.?);
    const parse_options = .{ .allocator = allocator };
    const response = try json.parse(policy.ValidationResponse, &stream, parse_options);

    try testing.expect(response.accepted == false);
}

test "accept request with non pod resource" {
    var allocator = std.heap.page_allocator;

    const request = policy.ValidationRequest{
        .settings = .{
            .invalid_names = &[_][]const u8{ "foo", "bar" },
        },
        .request = .{
            .kind = .{
                .group = "core",
                .version = "v1",
                .kind = "Service",
            },
            .object = .{
                .metadata = .{ .name = "bar" },
            },
        },
    };

    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(request, .{}, buffer.writer());

    var response_payload = try policy.validate(allocator, buffer.items);
    var stream = json.TokenStream.init(response_payload.?);
    const parse_options = .{ .allocator = allocator };
    const response = try json.parse(policy.ValidationResponse, &stream, parse_options);

    try testing.expect(response.accepted == true);
}
