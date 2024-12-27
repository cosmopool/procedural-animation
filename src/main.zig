const std = @import("std");
const rl = @import("raylib.zig").raylib;
const Camera = @import("camera.zig");
const Screen = @import("screen.zig");

const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const page_allocator = std.heap.page_allocator;

// Initialization
//--------------------------------------------------------------------------------------
var camera = rl.Camera{};

const maxNumModels = 1000;
var models: [maxNumModels]?rl.Model = undefined;
var bounds: [maxNumModels]?rl.BoundingBox = undefined;

const position = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
var selected: ?*const rl.BoundingBox = null;
var cameraMode: bool = false;
var cursorEnabled: bool = true;
//--------------------------------------------------------------------------------------

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.InitWindow(Screen.width, Screen.height, "procedural animation test");
    rl.SetTargetFPS(60);
    try init();
    try Camera.init(&page_allocator, &camera);
    //--------------------------------------------------------------------------------------

    // Game loop
    //--------------------------------------------------------------------------------------
    while (!rl.WindowShouldClose()) {
        const dt = rl.GetFrameTime();
        try update(dt);
        try draw();
    }
    //--------------------------------------------------------------------------------------

    // De-Initialization
    //--------------------------------------------------------------------------------------
    try Camera.deinit(&page_allocator);
    rl.CloseWindow();
    //--------------------------------------------------------------------------------------
}

fn init() !void {
    var dir = try std.fs.cwd().openDir("resources/models/", .{ .iterate = true });
    var walker = try dir.walk(page_allocator);
    defer walker.deinit();

    var idx: usize = 0;
    // load all models
    while (try walker.next()) |entry| {
        const p_: []u8 = undefined;
        const path = try dir.realpath(entry.path, p_);
        models[idx] = rl.LoadModel(path.ptr);
        models[idx].?.materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].color = rl.GRAY;
        bounds[idx] = rl.GetMeshBoundingBox(models[idx].?.meshes[0]);
        idx += 1;
    }
}

fn update(dt: f32) !void {
    if (rl.IsKeyPressed(rl.KEY_C)) cameraMode = !cameraMode;
    try Camera.updateCamera(&camera, dt);

    // Select model on mouse click
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        var collided = false;
        for (0..maxNumModels) |idx| {
            if (bounds[idx] == null) break;
            const boundingBox = &bounds[idx].?;

            // Check collision between ray and box
            collided = rl.GetRayCollisionBox(rl.GetScreenToWorldRay(rl.GetMousePosition(), camera), boundingBox.*).hit;
            if (collided) {
                selected = boundingBox;
                break;
            }
        }

        if (!collided) selected = null;
    }
}

fn draw() !void {
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    rl.BeginMode3D(camera);
    rl.DrawGrid(5, 1);
    for (0..maxNumModels) |idx| {
        const model = models[idx];
        if (model == null) break;
        rl.DrawModel(model.?, position, 1.0, rl.WHITE);
    }
    if (selected != null) rl.DrawBoundingBox(selected.?.*, rl.GREEN);
    rl.EndMode3D();

    try Camera.draw();
    rl.DrawFPS(10, 10);
    rl.EndDrawing();
}
