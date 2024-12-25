const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const page_allocator = std.heap.page_allocator;

// Initialization
//--------------------------------------------------------------------------------------
const screenWidth = 800;
const screenHeight = 600;

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
    rl.InitWindow(screenWidth, screenHeight, "procedural animation test");
    rl.SetTargetFPS(60);
    rl.DisableCursor();
    try init();
    //--------------------------------------------------------------------------------------

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_C)) cameraMode = !cameraMode;
        try update();
        try draw();
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    for (0..maxNumModels) |idx| {
        const model = models[idx];
        if (model == null) break;
        rl.UnloadModel(model.?);
    }
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

    camera.position = rl.Vector3{ .x = 3, .y = 4, .z = 3 };
    camera.target = rl.Vector3{ .x = -0.5, .y = -0.8, .z = -1 };
    camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    camera.fovy = 45.0;
    camera.projection = rl.CAMERA_PERSPECTIVE;
}

fn update() !void {
    if (cameraMode) rl.UpdateCamera(&camera, rl.CAMERA_FREE);

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

    const cameraPos = try std.fmt.allocPrint(page_allocator, "camera | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ camera.position.x, camera.position.y, camera.position.z });
    const targetPos = try std.fmt.allocPrint(page_allocator, "target | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ camera.target.x, camera.target.y, camera.target.z });
    rl.DrawText(cameraPos.ptr, screenWidth - 160, screenHeight - 30, 10, rl.BLACK);
    rl.DrawText(targetPos.ptr, screenWidth - 160, screenHeight - 20, 10, rl.BLACK);
    rl.DrawText("Press 'C' to toggle camera mode", 10, screenHeight - 20, 10, rl.BLACK);
    rl.DrawFPS(10, 10);
    rl.EndDrawing();
}
