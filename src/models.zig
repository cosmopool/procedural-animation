const std = @import("std");
const rl = @import("raylib");
const zgltf = @import("zgltf");

const Vector3 = rl.Vector3;
const Camera = rl.Camera;
const BoundingBox = rl.BoundingBox;
const Color = rl.Color;

const ModelType = enum { spider, floor };

pub var selected: ?*const BoundingBox = null;

var alloc: std.mem.Allocator = undefined;

/// Max number of models that can be instantiated
pub const max = 1000;
pub var models: [max]?zgltf.Data = undefined;
var positions: [max * 3]f32 = undefined;
var bounds: [max]?BoundingBox = undefined;
var paths: [max][:0]const u8 = undefined;

/// Load all models from disk
pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;
    paths[@intFromEnum(ModelType.spider)] = "resources/models/spider.gltf";

    const modelsEnumValues = std.enums.values(ModelType);
    for (0..modelsEnumValues.len) |i| {
        const modelType = modelsEnumValues[i];
        const idx = @intFromEnum(modelType);
        if (modelType == .floor) continue;
        const model: zgltf.Data = try loadModel(allocator, paths[idx]);
        models[idx] = model;
        // models[idx] = try loadModel(allocator, paths[idx]);
    }
}

pub fn deinit() !void {
    for (0..max) |idx| {
        const model = models[idx];
        if (model == null) break;
        alloc.free(model.?);
    }
}

fn loadModel(allocator: std.mem.Allocator, path: []const u8) !zgltf.Data {
    const modelJSON = try std.fs.cwd().readFileAllocOptions(
        allocator,
        path,
        512_000,
        null,
        4,
        null,
    );
    defer allocator.free(modelJSON);

    var gltf = zgltf.init(allocator);
    defer gltf.deinit();

    try gltf.parse(modelJSON);
    const model = gltf.data;

    var bufferMap = try allocator.alloc([]align(4) const u8, gltf.data.buffers.items.len);
    defer {
        for (bufferMap) |buffer| allocator.free(buffer);
        allocator.free(bufferMap);
    }

    for (gltf.data.buffers.items, 0..) |buffer, i| {
        const uri = buffer.uri.?;
        const DATA_URI_PREFIX_1 = "data:application/octet-stream;base64,";
        const DATA_URI_PREFIX_2 = "data:application/gltf-buffer;base64,";
        const isBase64 = std.mem.startsWith(u8, uri, DATA_URI_PREFIX_1) or std.mem.startsWith(u8, uri, DATA_URI_PREFIX_2);

        if (!isBase64) @panic("Loading models with separated .bin files is not implemented. Can only load .glTF files with encoded binary data.");

        // find the offset to the begining of the actual base64 encoded string
        var DATA_URI_PREFIX_IDX: usize = undefined;
        for (uri, 0..) |char, idx| {
            if (char != ';') continue;
            // if (!std.mem.startsWith(u8, uri[idx..], ";")) continue;
            DATA_URI_PREFIX_IDX = idx;
            break;
        }
        const encodedData = uri[DATA_URI_PREFIX_IDX..];

        const decoder = std.base64.standard.Decoder;
        const upperBound = try decoder.calcSizeUpperBound(encodedData.len);
        const bin = try allocator.allocWithOptions(u8, upperBound, 4, null);
        try decoder.decode(bin, encodedData);

        bufferMap[i] = bin;
    }

    return model;
}

/// Select model on mouse click
pub fn selectOnClick(camera: *Camera) !void {
    if (!rl.isMouseButtonPressed(.left)) return;

    var collided = false;
    for (0..max) |idx| {
        if (bounds[idx] == null) break;

        // Check collision between ray and box
        collided = rl.getRayCollisionBox(rl.getScreenToWorldRay(rl.getMousePosition(), camera.*), bounds[idx].?).hit;
        if (!collided) continue;

        selected = &bounds[idx].?;
    }
    if (!collided) selected = null;
}

pub fn draw() !void {
    for (0..max) |idx| {
        const model = models[idx];
        if (model == null) break;
        const positionIdx = idx * 3;
        const position = Vector3{
            .x = positions[positionIdx + 0],
            .y = positions[positionIdx + 1],
            .z = positions[positionIdx + 2],
        };
        _ = position; // autofix
        // rl.drawModel(model.?, position, 1.0, Color.white);
    }
    // const floor: rl.Model = models[@intFromEnum(ModelType.floor)] orelse unreachable;
    // rl.drawMesh(floor.meshes[0], floor.materials[0], rl.Matrix.identity());
    if (selected != null) rl.drawBoundingBox(selected.?.*, Color.green);
}
