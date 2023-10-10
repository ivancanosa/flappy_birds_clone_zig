const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui.zig");

pub fn renderGUI() void {
    const rec = raylib.Rectangle{ .x = 10, .y = 10, .width = 200, .height = 100 };
    if (raygui.button(rec)) {
        std.debug.print("\nPressed button", .{});
    }
}

pub fn main() void {
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = false });
    raylib.InitWindow(800, 800, "hello world!");
    raylib.SetTargetFPS(60);

    defer raylib.CloseWindow();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);

        raylib.DrawFPS(10, 10);
        raylib.DrawText("hello world!", 100, 100, 20, raylib.YELLOW);
        renderGUI();
    }
}
