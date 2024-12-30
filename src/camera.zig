const std = @import("std");
const Screen = @import("screen.zig");

const rl = @import("raylib");
const rlmath = rl.math;
const Vector3 = rl.Vector3;
const Camera = rl.Camera;
const Color = rl.Color;

pub var current = Camera{
    .position = Vector3{ .x = 3, .y = 4, .z = 3 },
    .target = Vector3{ .x = 0, .y = 0, .z = 0 },
    .up = Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
    .fovy = 45.0,
    .projection = .perspective,
};

const cameraSensitivity = 10;

var tempBuffA: []u8 = undefined;
var tempBuffB: []u8 = undefined;
var cameraPosString: [:0]u8 = undefined;
var targetPosString: [:0]u8 = undefined;

pub fn init(allocator: *const std.mem.Allocator) !void {
    tempBuffA = try allocator.alloc(u8, 200);
    tempBuffB = try allocator.alloc(u8, 200);
}

pub fn deinit(allocator: *const std.mem.Allocator) !void {
    allocator.free(tempBuffA);
    allocator.free(tempBuffB);
}

pub fn update(dt: f32) !void {
    cameraPosString = try std.fmt.bufPrintZ(tempBuffA, "camera | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ current.position.x, current.position.y, current.position.z });
    targetPosString = try std.fmt.bufPrintZ(tempBuffB, "target | x: {d:.1}, y: {d:.1}, z: {d:.1}", .{ current.target.x, current.target.y, current.target.z });

    const mouseWheel = rl.getMouseWheelMove();
    if (mouseWheel != 0) {
        const forward = rlmath.vector3Normalize(rlmath.vector3Subtract(current.target, current.position));
        const move = rlmath.vector3Scale(forward, mouseWheel * dt * cameraSensitivity);

        current.position = rlmath.vector3Add(current.position, move);
        current.target = rlmath.vector3Add(current.target, move);

        return;
    }

    if (!rl.isMouseButtonDown(.middle)) return;

    const mouseDelta = rl.getMouseDelta();
    const displacementX = mouseDelta.x * dt * -1;
    const displacementY = mouseDelta.y * dt * -1;

    const up = rlmath.vector3Normalize(current.up);
    const forward = rlmath.vector3Normalize(rlmath.vector3Subtract(current.target, current.position));
    const right = rlmath.vector3Normalize(rlmath.vector3CrossProduct(forward, up));

    if (rl.isKeyDown(.left_shift)) {
        // displacement in up and down, left and right direction

        const updatedUp = rlmath.vector3Scale(up, displacementY * -1);
        const updatedRight = rlmath.vector3Scale(right, displacementX);
        const move = rlmath.vector3Add(updatedUp, updatedRight);

        current.position = rlmath.vector3Add(current.position, move);
        current.target = rlmath.vector3Add(current.target, move);
    } else {
        // rotation around target

        var targetPosition = rlmath.vector3Subtract(current.target, current.position);
        targetPosition = rlmath.vector3RotateByAxisAngle(targetPosition, up, std.math.degreesToRadians(displacementX * cameraSensitivity));
        targetPosition = rlmath.vector3RotateByAxisAngle(targetPosition, right, std.math.degreesToRadians(displacementY * cameraSensitivity));

        current.position = rlmath.vector3Subtract(current.target, targetPosition);
    }
}

pub fn draw() !void {
    rl.drawText(cameraPosString, Screen.width - 160, Screen.height - 30, 10, Color.black);
    rl.drawText(targetPosString, Screen.width - 160, Screen.height - 20, 10, Color.black);
}
