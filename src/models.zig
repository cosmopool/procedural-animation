const std = @import("std");
const rl = @import("raylib.zig").raylib;

const Model = enum { spider };

pub var selected: ?*const rl.BoundingBox = null;

/// Max number of models that can be instantiated
pub const max = 1000;
pub var models: [max]?rl.Model = undefined;
var positions: [max * 3]f32 = undefined;
var bounds: [max]?rl.BoundingBox = undefined;
var paths: [max][:0]const u8 = undefined;

/// Load all models from disk
pub fn init() !void {
    paths[@intFromEnum(Model.spider)] = "resources/models/spider.obj";

    const modelsName = std.enums.values(Model);
    for (0..modelsName.len) |i| {
        const enumVal = modelsName[i];
        const idx = @intFromEnum(enumVal);
        models[idx] = rl.LoadModel(paths[idx]);
        models[idx].?.materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].color = rl.GRAY;
        bounds[idx] = rl.GetMeshBoundingBox(models[idx].?.meshes[0]);
    }
}

pub fn deinit() !void {
    for (0..max) |idx| {
        const model = models[idx];
        if (model == null) break;
        rl.UnloadModel(model.?);
    }
}

/// Select model on mouse click
pub fn selectOnClick(camera: *rl.Camera) !void {
    if (!rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) return;

    var collided = false;
    for (0..max) |idx| {
        if (bounds[idx] == null) break;

        // Check collision between ray and box
        collided = rl.GetRayCollisionBox(rl.GetScreenToWorldRay(rl.GetMousePosition(), camera.*), bounds[idx].?).hit;
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
        const position = rl.Vector3{
            .x = positions[positionIdx + 0],
            .y = positions[positionIdx + 1],
            .z = positions[positionIdx + 2],
        };
        rl.DrawModel(model.?, position, 1.0, rl.WHITE);
    }
    if (selected != null) rl.DrawBoundingBox(selected.?.*, rl.GREEN);
}
