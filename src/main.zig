const std = @import("std");
const rl = @import("raylib.zig").raylib;
const Camera = @import("camera.zig");
const Model = @import("models.zig");
const Screen = @import("screen.zig");

const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const page_allocator = std.heap.page_allocator;

// Initialization
//--------------------------------------------------------------------------------------
var camera = rl.Camera{};

var cameraMode: bool = false;
var cursorEnabled: bool = true;
//--------------------------------------------------------------------------------------

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.InitWindow(Screen.width, Screen.height, "procedural animation test");
    rl.SetTargetFPS(60);
    try Model.init();
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
    try Model.deinit();
    try Camera.deinit(&page_allocator);
    rl.CloseWindow();
    //--------------------------------------------------------------------------------------
}

fn update(dt: f32) !void {
    if (rl.IsKeyPressed(rl.KEY_C)) cameraMode = !cameraMode;
    try Camera.updateCamera(&camera, dt);
    try Model.selectOnClick(&camera);
}

fn draw() !void {
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    rl.BeginMode3D(camera);
    rl.DrawGrid(5, 1);
    try Model.draw();
    rl.EndMode3D();

    try Camera.draw();
    rl.DrawFPS(10, 10);
    rl.EndDrawing();
}
