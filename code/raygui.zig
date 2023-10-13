const std = @import("std");
const rl = @import("raylib");

const styleStackSize = 16;

pub const StyleColor = enum {
    Text,
    Button,
    ButtonHovered,
    ButtonActive,
    Border,

    FrameBg,
    FrameBgHovered,
    FrameBgActive,
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
    FramePos, // ImVec2    FramePadding
    FrameSize, // ImVec2    FramePadding
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

    styleColorArray: [styleColorCount]std.ArrayList(rl.Color),
    styleVarFloatArray: [styleVarFloatCount]std.ArrayList(f32),
    styleVarVec2Array: [styleVarVec2Count]std.ArrayList(rl.Vector2),
    fontArray: std.ArrayList(*rl.Font),
    cursorPos: rl.Vector2,

    allocator: std.mem.Allocator,

    pub fn init(ally: std.mem.Allocator) !Self {
        var result = Self{
            .styleColorArray = undefined,
            .styleVarFloatArray = undefined,
            .styleVarVec2Array = undefined,
            .fontArray = undefined,
            .allocator = ally,
            .cursorPos = .{ .x = 0, .y = 0 },
        };

        for (0..styleColorCount) |i| {
            result.styleColorArray[i] = std.ArrayList(rl.Color).init(result.allocator);
        }
        for (0..styleVarFloatCount) |i| {
            result.styleVarFloatArray[i] = std.ArrayList(f32).init(result.allocator);
        }
        for (0..styleVarVec2Count) |i| {
            result.styleVarVec2Array[i] = std.ArrayList(rl.Vector2).init(result.allocator);
        }

        result.fontArray = std.ArrayList(*rl.Font).init(result.allocator);
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

pub const Frame = struct {
    const Self = @This();

    rec: rl.Rectangle,

    pub fn activate(self: *const Self) !void {
        var frame = frontStyleVarVec2(StyleVarVec2.FramePos);
        const newRec = rl.Rectangle{ .x = self.rec.x + frame.x, .y = self.rec.y + frame.y, .width = self.rec.width, .height = self.rec.height };
        try pushStyleVarVec2(StyleVarVec2.FramePos, .{ .x = newRec.x, .y = newRec.y });
        try pushStyleVarVec2(StyleVarVec2.FrameSize, .{ .x = newRec.width, .y = newRec.height });
        rl.DrawRectangleRounded(newRec, //
            frontStyleVarFloat(StyleVarFloat.Rounding), //
            0, //
            frontStyleColor(StyleColor.FrameBg));
        rl.DrawRectangleRoundedLines(newRec, //
            frontStyleVarFloat(StyleVarFloat.Rounding), //
            0, //
            frontStyleVarFloat(StyleVarFloat.BorderSize), //
            frontStyleColor(StyleColor.Border)); //
        activeContext.cursorPos = rl.Vector2{ .x = newRec.x, .y = newRec.y };
    }

    pub fn deactivate(self: *const Self) void {
        _ = self;
        popStyleVarVec2(StyleVarVec2.FrameSize);
        popStyleVarVec2(StyleVarVec2.FramePos);
    }
};

pub var activeContext: *Context = undefined;

// Auxiliary functions

pub fn getAvailableSpace() rl.Vector2 {
    return frontStyleVarVec2(StyleVarVec2.FrameSize);
}

// Widgets

pub fn text(x: i32, y: i32, str: [*:0]const u8) void {
    const fontSize: i32 = @intFromFloat(frontStyleVarFloat(StyleVarFloat.TextSize));
    const pos = frontStyleVarVec2(StyleVarVec2.FramePos);
    var fx: i32 = @intFromFloat(pos.x);
    fx += x;
    var fy: i32 = @intFromFloat(pos.y);
    fy += y;
    rl.DrawText(str, fx, fy, fontSize, frontStyleColor(StyleColor.Text));
    activeContext.cursorPos.y += @floatFromInt(fontSize);
}

pub fn button(relativeRec: rl.Rectangle) bool {
    const point = rl.GetMousePosition();
    var color: rl.Color = undefined;
    var isPressed: bool = false;
    const pos = frontStyleVarVec2(StyleVarVec2.FramePos);
    const absoluteRec = rl.Rectangle{ .x = relativeRec.x + pos.x, .y = relativeRec.y + pos.y, .width = relativeRec.width, .height = relativeRec.height };

    if (rl.CheckCollisionPointRec(point, absoluteRec)) {
        if (rl.IsMouseButtonReleased(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
            color = frontStyleColor(StyleColor.ButtonActive);
            isPressed = true;
        } else if (rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
            color = frontStyleColor(StyleColor.ButtonActive);
        } else {
            color = frontStyleColor(StyleColor.ButtonHovered);
        }
    } else {
        color = frontStyleColor(StyleColor.Button);
    }

    rl.DrawRectangleRounded(absoluteRec, frontStyleVarFloat(StyleVarFloat.Rounding), 0, color);

    activeContext.cursorPos.y += relativeRec.height;

    return isPressed;
}

// Auxiliary functions
pub fn getCurrentFrame() rl.Rectangle {
    const pos = frontStyleVarVec2(StyleVarVec2.FramePos);
    const size = frontStyleVarVec2(StyleVarVec2.FrameSize);
    return rl.Rectangle{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };
}

// Push, pop, front functions

pub fn pushStyleColor(style: StyleColor, color: rl.Color) !void {
    try activeContext.styleColorArray[@intFromEnum(style)].append(color);
}

pub fn popStyleColor(style: StyleColor) void {
    _ = activeContext.styleColorArray[@intFromEnum(style)].pop();
}

pub fn frontStyleColor(style: StyleColor) rl.Color {
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

pub fn pushStyleVarVec2(style: StyleVarVec2, value: rl.Vector2) !void {
    try activeContext.styleVarVec2Array[@intFromEnum(style)].append(value);
}

pub fn popStyleVarVec2(style: StyleVarVec2) void {
    _ = activeContext.styleVarVec2Array[@intFromEnum(style)].pop();
}

pub fn frontStyleVarVec2(style: StyleVarVec2) rl.Vector2 {
    return activeContext.styleVarVec2Array[@intFromEnum(style)].getLast();
}

fn initializeContext(ctx: *Context) !void {
    try ctx.styleColorArray[@intFromEnum(StyleColor.Text)].append(rl.WHITE);
    try ctx.styleColorArray[@intFromEnum(StyleColor.Button)].append(rl.RED);
    try ctx.styleColorArray[@intFromEnum(StyleColor.ButtonHovered)].append(rl.WHITE);
    try ctx.styleColorArray[@intFromEnum(StyleColor.ButtonActive)].append(rl.YELLOW);
    try ctx.styleColorArray[@intFromEnum(StyleColor.Border)].append(rl.RED);
    try ctx.styleColorArray[@intFromEnum(StyleColor.FrameBg)].append(rl.BLACK);
    try ctx.styleColorArray[@intFromEnum(StyleColor.FrameBgActive)].append(rl.BLACK);
    try ctx.styleColorArray[@intFromEnum(StyleColor.FrameBgHovered)].append(rl.BLACK);

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

    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.WindowPadding)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.WindowMinSize)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.WindowTitleAlign)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.FramePadding)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.FramePos)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.FrameSize)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.ItemSpacing)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.ItemInnerSpacing)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.CellPadding)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.ButtonTextAlign)].append(rl.Vector2{});
    try ctx.styleVarVec2Array[@intFromEnum(StyleVarVec2.SelectableTextAlign)].append(rl.Vector2{});
}
