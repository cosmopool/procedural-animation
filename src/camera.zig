const std = @import("std");
const rl = @import("raylib.zig").raylib;
const Screen = @import("screen.zig");

pub var current = rl.Camera{};

const cameraSensitivity = 10;

var tempBuff: []u8 = undefined;
var cameraPosString: []u8 = undefined;
var targetPosString: []u8 = undefined;

pub fn init(allocator: *const std.mem.Allocator) !void {
    tempBuff = try allocator.alloc(u8, 200);

    current.position = rl.Vector3{ .x = 3, .y = 4, .z = 3 };
    current.target = rl.Vector3{ .x = 0, .y = 0, .z = 0 };
    current.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    current.fovy = 45.0;
    current.projection = rl.CAMERA_PERSPECTIVE;
}

pub fn deinit(allocator: *const std.mem.Allocator) !void {
    _ = allocator; // autofix
    // allocator.destroy(&tempBuff);
}

pub fn update(dt: f32) !void {
    cameraPosString = try std.fmt.bufPrint(tempBuff, "camera | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ current.position.x, current.position.y, current.position.z });
    targetPosString = try std.fmt.bufPrint(tempBuff, "target | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ current.target.x, current.target.y, current.target.z });

    const mouseWheel = rl.GetMouseWheelMove();
    if (mouseWheel != 0) {
        const forward = rl.Vector3Normalize(rl.Vector3Subtract(current.target, current.position));
        const move = rl.Vector3Scale(forward, mouseWheel * dt * cameraSensitivity);

        current.position = rl.Vector3Add(current.position, move);
        current.target = rl.Vector3Add(current.target, move);

        return;
    }

    if (!rl.IsMouseButtonDown(rl.MOUSE_BUTTON_MIDDLE)) return;

    const mouseDelta = rl.GetMouseDelta();
    const displacementX = mouseDelta.x * dt * -1;
    const displacementY = mouseDelta.y * dt * -1;

    const up = rl.Vector3Normalize(current.up);
    const forward = rl.Vector3Normalize(rl.Vector3Subtract(current.target, current.position));
    const right = rl.Vector3Normalize(rl.Vector3CrossProduct(forward, up));

    if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT)) {
        // displacement in up and down, left and right direction

        const updatedUp = rl.Vector3Scale(up, displacementY * -1);
        const updatedRight = rl.Vector3Scale(right, displacementX);
        const move = rl.Vector3Add(updatedUp, updatedRight);

        current.position = rl.Vector3Add(current.position, move);
        current.target = rl.Vector3Add(current.target, move);
    } else {
        // rotation around target

        var targetPosition = rl.Vector3Subtract(current.target, current.position);
        targetPosition = rl.Vector3RotateByAxisAngle(targetPosition, up, displacementX * rl.DEG2RAD * cameraSensitivity);
        targetPosition = rl.Vector3RotateByAxisAngle(targetPosition, right, displacementY * rl.DEG2RAD * cameraSensitivity);

        current.position = rl.Vector3Subtract(current.target, targetPosition);
    }
}

pub fn draw() !void {
    rl.DrawText(cameraPosString.ptr, Screen.width - 160, Screen.height - 30, 10, rl.BLACK);
    rl.DrawText(targetPosString.ptr, Screen.width - 160, Screen.height - 20, 10, rl.BLACK);
}
