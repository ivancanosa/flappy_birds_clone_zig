const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui.zig");

pub fn renderGUI() !void {
    const frame = rg.Frame{ .rec = .{ .x = 100, .y = 100, .width = 400, .height = 400 } };
    const frame2 = rg.Frame{ .rec = .{ .x = 60, .y = 10, .width = 50, .height = 50 } };

    try rg.pushStyleVarFloat(rg.StyleVarFloat.Rounding, 0.1);
    defer rg.popStyleVarFloat(rg.StyleVarFloat.Rounding);

    try frame.activate();
    defer frame.deactivate();

    try frame2.activate();
    defer frame2.deactivate();

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

    var myText = "This is a custom text with white color";
    rg.text(0, 40, myText);
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
        rl.ClearBackground(rl.Color{ .r = 33, .g = 33, .b = 33, .a = 255 });

        rl.DrawFPS(10, 10);
        rl.DrawText("hello world!", 100, 100, 20, rl.YELLOW);
        try renderGUI();
    }
}
