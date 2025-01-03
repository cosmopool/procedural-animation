const std = @import("std");
const rl = @import("raylib");

const Vector3 = rl.Vector3;
const Camera = rl.Camera;
const BoundingBox = rl.BoundingBox;
const Color = rl.Color;

const Model = enum { spider };

pub var selected: ?*const BoundingBox = null;

/// Max number of models that can be instantiated
pub const max = 1000;
pub var models: [max]?rl.Model = undefined;
var positions: [max * 3]f32 = undefined;
var bounds: [max]?BoundingBox = undefined;
var paths: [max][:0]const u8 = undefined;

/// Load all models from disk
pub fn init() !void {
    paths[@intFromEnum(Model.spider)] = "resources/models/spider.obj";

    const modelsName = std.enums.values(Model);
    for (0..modelsName.len) |i| {
        const enumVal = modelsName[i];
        const idx = @intFromEnum(enumVal);
        models[idx] = rl.loadModel(paths[idx]);
        models[idx].?.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.albedo)].color = Color.gray;
        bounds[idx] = rl.getMeshBoundingBox(models[idx].?.meshes[0]);
    }
}

pub fn deinit() !void {
    for (0..max) |idx| {
        const model = models[idx];
        if (model == null) break;
        rl.unloadModel(model.?);
    }
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
        rl.drawModel(model.?, position, 1.0, Color.white);
    }
    if (selected != null) rl.drawBoundingBox(selected.?.*, Color.green);
}
