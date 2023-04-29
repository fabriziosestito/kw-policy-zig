// Structs used to deserialize the request object
pub const KubernetesAdmissionRequest = struct { kind: GroupVersionKind, object: Object };
pub const GroupVersionKind = struct { group: []const u8, version: []const u8, kind: []const u8 };
pub const Object = struct { metadata: Metadata };
pub const Metadata = struct { name: []const u8 };
