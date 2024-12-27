const rl = @import("raylib.zig").raylib;

const cameraSensitivity = 10;

pub fn updateCamera(camera: *rl.Camera, dt: f32) !void {
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
