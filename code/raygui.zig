const std = @import("std");
const raylib = @import("raylib");

pub fn button(rec: raylib.Rectangle) bool {
    const point = raylib.GetMousePosition();
    raylib.DrawRectangleRounded(rec, 0.2, 0, raylib.RED);
    if (raylib.CheckCollisionPointRec(point, rec)) {
        if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            return true;
        }
    }
    return false;
}
