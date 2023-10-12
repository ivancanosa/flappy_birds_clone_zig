const std = @import("std");
const raylib = @import("raylib");

const styleStackSize = 16;

pub const StyleColor = enum {
    Text,
    Button,
    ButtonHovered,
    ButtonActive,
};

pub const StyleVarFloat = enum {
    TextSize,
    TextSpacing,
    Alpha, // float     Alpha
    DisabledAlpha, // float     DisabledAlpha
    Rounding, // float     ChildRounding
    BorderSize, // float     ChildBorderSize
    FrameRounding, // float     FrameRounding
    FrameBorderSize, // float     FrameBorderSize
    IndentSpacing, // float     IndentSpacing
    ScrollbarSize, // float     ScrollbarSize
    ScrollbarRounding, // float     ScrollbarRounding
    GrabMinSize, // float     GrabMinSize
    GrabRounding, // float     GrabRounding
    TabRounding, // float     TabRounding
};

pub const StyleVarVec2 = enum {
    WindowPadding, // ImVec2    WindowPadding
    WindowMinSize, // ImVec2    WindowMinSize
    WindowTitleAlign, // ImVec2    WindowTitleAlign
    FramePadding, // ImVec2    FramePadding
    ItemSpacing, // ImVec2    ItemSpacing
    ItemInnerSpacing, // ImVec2    ItemInnerSpacing
    CellPadding, // ImVec2    CellPadding
    ButtonTextAlign, // ImVec2    ButtonTextAlign
    SelectableTextAlign, // ImVec2    SelectableTextAlign
};

pub const Context = struct {
    const Self = @This();

    const styleColorCount = @typeInfo(StyleColor).Enum.fields.len;
    const styleVarFloatCount = @typeInfo(StyleVarFloat).Enum.fields.len;
    const styleVarVec2Count = @typeInfo(StyleVarVec2).Enum.fields.len;

    styleColorArray: [styleColorCount]std.ArrayList(raylib.Color),
    styleVarFloatArray: [styleVarFloatCount]std.ArrayList(f32),
    styleVarVec2Array: [styleVarVec2Count]std.ArrayList(raylib.Vector2),
    fontArray: std.ArrayList(*raylib.Font),

    allocator: std.mem.Allocator,

    pub fn init(ally: std.mem.Allocator) !Self {
        var result = Self{
            .styleColorArray = undefined,
            .styleVarFloatArray = undefined,
            .styleVarVec2Array = undefined,
            .fontArray = undefined,
            .allocator = ally,
        };

        for (0..styleColorCount) |i| {
            result.styleColorArray[i] = std.ArrayList(raylib.Color).init(result.allocator);
        }
        for (0..styleVarFloatCount) |i| {
            result.styleVarFloatArray[i] = std.ArrayList(f32).init(result.allocator);
        }
        for (0..styleVarVec2Count) |i| {
            result.styleVarVec2Array[i] = std.ArrayList(raylib.Vector2).init(result.allocator);
        }

        result.fontArray = std.ArrayList(*raylib.Font).init(result.allocator);
        try initializeContext(&result);
        return result;
    }

    pub fn deinit(self: *Self) void {
        for (0..styleColorCount) |i| {
            self.styleColorArray[i].deinit();
        }
        for (0..styleVarFloatCount) |i| {
            self.styleVarFloatArray[i].deinit();
        }
        for (0..styleVarVec2Count) |i| {
            self.styleVarVec2Array[i].deinit();
        }
    }
};

pub var activeContext: *Context = undefined;

pub fn text(x: i32, y: i32, str: [*:0]const u8) void {
    const fontSize: i32 = @intFromFloat(frontStyleVarFloat(StyleVarFloat.TextSize));
    raylib.DrawText(str, x, y, fontSize, frontStyleColor(StyleColor.Text));
}

pub fn button(rec: raylib.Rectangle) bool {
    const point = raylib.GetMousePosition();
    var color: raylib.Color = undefined;
    var isPressed: bool = false;

    if (raylib.CheckCollisionPointRec(point, rec)) {
        if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            color = frontStyleColor(StyleColor.ButtonActive);
            isPressed = true;
        } else if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            color = frontStyleColor(StyleColor.ButtonActive);
        } else {
            color = frontStyleColor(StyleColor.ButtonHovered);
        }
    } else {
        color = frontStyleColor(StyleColor.Button);
    }

    raylib.DrawRectangleRounded(rec, frontStyleVarFloat(StyleVarFloat.Rounding), 0, color);

    return isPressed;
}

// Push, pop, front functions

pub fn pushStyleColor(style: StyleColor, color: raylib.Color) !void {
    try activeContext.styleColorArray[@intFromEnum(style)].append(color);
}

pub fn popStyleColor(style: StyleColor) void {
    _ = activeContext.styleColorArray[@intFromEnum(style)].pop();
}

pub fn frontStyleColor(style: StyleColor) raylib.Color {
    return activeContext.styleColorArray[@intFromEnum(style)].getLast();
}

pub fn pushStyleVarFloat(style: StyleVarFloat, value: f32) !void {
    try activeContext.styleVarFloatArray[@intFromEnum(style)].append(value);
}

pub fn popStyleVarFloat(style: StyleVarFloat) void {
    _ = activeContext.styleVarFloatArray[@intFromEnum(style)].pop();
}

pub fn frontStyleVarFloat(style: StyleVarFloat) f32 {
    return activeContext.styleVarFloatArray[@intFromEnum(style)].getLast();
}

pub fn pushStyleVarVec2(style: StyleVarVec2, value: raylib.Vector2) !void {
    try activeContext.styleVarVec2[@intFromEnum(style)].append(value);
}

pub fn popStyleVarVec2(style: StyleVarVec2) void {
    _ = activeContext.styleVarVec2[@intFromEnum(style)].pop();
}

pub fn frontStyleVarVec2(style: StyleVarVec2) raylib.Vector2 {
    return activeContext.styleVarVec2[@intFromEnum(style)].getLast();
}

fn initializeContext(ctx: *Context) !void {
    try ctx.styleColorArray[@intFromEnum(StyleColor.Text)].append(raylib.WHITE);
    try ctx.styleColorArray[@intFromEnum(StyleColor.Button)].append(raylib.RED);
    try ctx.styleColorArray[@intFromEnum(StyleColor.ButtonHovered)].append(raylib.WHITE);
    try ctx.styleColorArray[@intFromEnum(StyleColor.ButtonActive)].append(raylib.YELLOW);

    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.TextSize)].append(16);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.TextSpacing)].append(1);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.Alpha)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.DisabledAlpha)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.Rounding)].append(0.2);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.BorderSize)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.FrameRounding)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.FrameBorderSize)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.IndentSpacing)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.ScrollbarSize)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.ScrollbarRounding)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.GrabMinSize)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.GrabRounding)].append(0);
    try ctx.styleVarFloatArray[@intFromEnum(StyleVarFloat.TabRounding)].append(0);

    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.WindowPadding)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.WindowMinSize)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.WindowTitleAlign)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.FramePadding)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.ItemSpacing)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.ItemInnerSpacing)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.CellPadding)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.ButtonTextAlign)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.SelectableTextAlign)].append(raylib.Vector2{ .x = 0.0, .y = 0.0 });
}
