const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui.zig");

pub fn renderGUI() !void {
    try rg.pushStyleColor(rg.StyleColor.Text, rl.WHITE);
    defer rg.popStyleColor(rg.StyleColor.Text);

    try rg.pushStyleColor(rg.StyleColor.Button, rl.RED);
    try rg.pushStyleColor(rg.StyleColor.ButtonActive, rl.WHITE);
    try rg.pushStyleColor(rg.StyleColor.ButtonHovered, rl.YELLOW);
    try rg.pushStyleVarFloat(rg.StyleVarFloat.Rounding, 0.3);
    defer rg.popStyleColor(rg.StyleColor.Button);
    defer rg.popStyleColor(rg.StyleColor.ButtonActive);
    defer rg.popStyleColor(rg.StyleColor.ButtonHovered);
    defer rg.popStyleVarFloat(rg.StyleVarFloat.Rounding);

    const rec = rl.Rectangle{ .x = 10, .y = 10, .width = 200, .height = 100 };
    if (rg.button(rec)) {
        std.debug.print("\nPressed button", .{});
    }
    rg.text(400, 400, "This is a custom text with white color");
}

pub fn main() !void {
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = false });
    rl.InitWindow(800, 800, "hello world!");
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    // Setup style context
    var ctx = try rg.Context.init(std.heap.page_allocator);
    defer ctx.deinit();
    rg.activeContext = &ctx;

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.BLACK);

        rl.DrawFPS(10, 10);
        rl.DrawText("hello world!", 100, 100, 20, rl.YELLOW);
        try renderGUI();
    }
}
