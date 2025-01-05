const std = @import("std");
const rl = @import("raylib");
const Camera = @import("camera.zig");
const Model = @import("models.zig");
const Screen = @import("screen.zig");

const print = std.debug.print;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const page_allocator = std.heap.page_allocator;

pub fn main() !void {
    //--------------------------------------------------------------------------------------
    // Initialization
    rl.initWindow(Screen.width, Screen.height, "procedural animation test");
    rl.setTargetFPS(60);
    try Model.init();
    try Camera.init(&page_allocator);
    //--------------------------------------------------------------------------------------

    //--------------------------------------------------------------------------------------
    // Game loop
    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        try update(dt);
        try draw();
    }
    //--------------------------------------------------------------------------------------

    //--------------------------------------------------------------------------------------
    // De-Initialization
    try Model.deinit();
    try Camera.deinit(&page_allocator);
    rl.closeWindow();
    //--------------------------------------------------------------------------------------
}

fn update(dt: f32) !void {
    try Camera.update(dt);
    try Model.selectOnClick(&Camera.current);
}

fn draw() !void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.ray_white);

    rl.beginMode3D(Camera.current);
    rl.drawGrid(120, 1);
    try Model.draw();
    rl.endMode3D();

    try Camera.draw();
    rl.drawFPS(10, 10);
    rl.endDrawing();
}
