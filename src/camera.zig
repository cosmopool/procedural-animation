const std = @import("std");
const rl = @import("raylib.zig").raylib;
const Screen = @import("screen.zig");

const cameraSensitivity = 10;

var tempBuff: []u8 = undefined;
var cameraPosString: []u8 = undefined;
var targetPosString: []u8 = undefined;

pub fn init(allocator: *const std.mem.Allocator, camera: *rl.Camera) !void {
    tempBuff = try allocator.alloc(u8, 200);

    camera.position = rl.Vector3{ .x = 3, .y = 4, .z = 3 };
    camera.target = rl.Vector3{ .x = 0, .y = 0, .z = 0 };
    camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    camera.fovy = 45.0;
    camera.projection = rl.CAMERA_PERSPECTIVE;
}

pub fn deinit(allocator: *const std.mem.Allocator) !void {
    _ = allocator; // autofix
    // allocator.destroy(&tempBuff);
}

pub fn updateCamera(camera: *rl.Camera, dt: f32) !void {
    cameraPosString = try std.fmt.bufPrint(tempBuff, "camera | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ camera.position.x, camera.position.y, camera.position.z });
    targetPosString = try std.fmt.bufPrint(tempBuff, "target | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ camera.target.x, camera.target.y, camera.target.z });

    const mouseWheel = rl.GetMouseWheelMove();
    if (mouseWheel != 0) {
        const forward = rl.Vector3Normalize(rl.Vector3Subtract(camera.target, camera.position));
        const move = rl.Vector3Scale(forward, mouseWheel * dt * cameraSensitivity);

        camera.position = rl.Vector3Add(camera.position, move);
        camera.target = rl.Vector3Add(camera.target, move);

        return;
    }

    if (!rl.IsMouseButtonDown(rl.MOUSE_BUTTON_MIDDLE)) return;

    const mouseDelta = rl.GetMouseDelta();
    const displacementX = mouseDelta.x * dt * -1;
    const displacementY = mouseDelta.y * dt * -1;

    const up = rl.Vector3Normalize(camera.up);
    const forward = rl.Vector3Normalize(rl.Vector3Subtract(camera.target, camera.position));
    const right = rl.Vector3Normalize(rl.Vector3CrossProduct(forward, up));

    if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT)) {
        // displacement in up and down, left and right direction

        const updatedUp = rl.Vector3Scale(up, displacementY * -1);
        const updatedRight = rl.Vector3Scale(right, displacementX);
        const move = rl.Vector3Add(updatedUp, updatedRight);

        camera.position = rl.Vector3Add(camera.position, move);
        camera.target = rl.Vector3Add(camera.target, move);
    } else {
        // rotation around target

        var targetPosition = rl.Vector3Subtract(camera.target, camera.position);
        targetPosition = rl.Vector3RotateByAxisAngle(targetPosition, up, displacementX * rl.DEG2RAD * cameraSensitivity);
        targetPosition = rl.Vector3RotateByAxisAngle(targetPosition, right, displacementY * rl.DEG2RAD * cameraSensitivity);

        camera.position = rl.Vector3Subtract(camera.target, targetPosition);
    }
}

pub fn draw() !void {
    rl.DrawText(cameraPosString.ptr, Screen.width - 160, Screen.height - 30, 10, rl.BLACK);
    rl.DrawText(targetPosString.ptr, Screen.width - 160, Screen.height - 20, 10, rl.BLACK);
}
