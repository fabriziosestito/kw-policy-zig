const std = @import("std");
const json = std.json;
const mem = std.mem;
const k8s = @import("k8s.zig");

pub const Settings = struct { invalid_names: []const []const u8 };
pub const SettingsValidationResponse = struct { valid: bool, message: ?[]const u8 = null };

pub const ValidationRequest = struct { request: k8s.KubernetesAdmissionRequest, settings: Settings };
pub const ValidationResponse = struct { accepted: bool, message: ?[]const u8 = null };

/// Return the protocol version
pub fn protocolVersion(allocator: mem.Allocator, _: []u8) !?[]u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify("v1", .{}, buffer.writer());

    return buffer.items;
}

/// Validate the settings payload
/// Returns a SettingsValidationResponse with valid set to true if the settings are valid
pub fn validateSettings(allocator: mem.Allocator, payload: []u8) !?[]u8 {
    var stream = json.TokenStream.init(payload);
    const parse_options = .{ .allocator = allocator };
    const settings = try json.parse(Settings, &stream, parse_options);

    var response = SettingsValidationResponse{ .valid = true };
    if (settings.invalid_names.len == 0) {
        response.valid = false;
        response.message = "No invalid name specified. Specify at least one invalid name to match.";
    }

    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(response, .{}, buffer.writer());

    return buffer.items;
}

/// Validate theKubernetesAdmissionRequest payload
/// Returns a ValidationResponse with accepted set to true if the request is accepted
pub fn validate(allocator: mem.Allocator, payload: []u8) !?[]u8 {
    var response = ValidationResponse{ .accepted = true };
    var stream = json.TokenStream.init(payload);
    const parse_options = .{ .allocator = allocator, .ignore_unknown_fields = true };
    const request = try json.parse(ValidationRequest, &stream, parse_options);
    defer json.parseFree(ValidationRequest, request, parse_options);

    if (std.mem.eql(u8, request.request.kind.version, "v1") and std.mem.eql(u8, request.request.kind.kind, "Pod")) {
        for (request.settings.invalid_names) |invalid_name| {
            if (std.mem.eql(u8, request.request.object.metadata.name, invalid_name)) {
                response.accepted = false;
                response.message = try std.fmt.allocPrint(allocator, "Pod name: {s} is not accepted.", .{invalid_name});
                break;
            }
        }
    }

    var buffer = std.ArrayList(u8).init(allocator);
    try json.stringify(response, .{}, buffer.writer());

    return buffer.items;
}
