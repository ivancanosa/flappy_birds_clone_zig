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
    Alpha, // float     Alpha
    DisabledAlpha, // float     DisabledAlpha
    WindowRounding, // float     WindowRounding
    WindowBorderSize, // float     WindowBorderSize
    ChildRounding, // float     ChildRounding
    ChildBorderSize, // float     ChildBorderSize
    PopupRounding, // float     PopupRounding
    PopupBorderSize, // float     PopupBorderSize
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
    allocator: std.mem.Allocator,

    pub fn init(ally: std.mem.Allocator) Self {
        var result = Self{
            .styleColorArray = undefined,
            .styleVarFloatArray = undefined,
            .styleVarVec2Array = undefined,
            .allocator = ally,
        };

        for (0..styleColorCount) |i| {
            result.styleColorArray[i] = std.ArrayList(raylib.Color).init(result.allocator);
        }
        return result;
    }
};

pub var defaultContext = Context.init(std.heap.page_allocator);
pub var currentContext: *Context = &defaultContext;

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

// Push, pop, front functions

pub fn pushStyleColor(style: StyleColor, color: raylib.Color) !void {
    try currentContext.styleColorArray[@intFromEnum(style)].append(color);
}

pub fn popStyleColor(style: StyleColor) void {
    _ = currentContext.styleColorArray[@intFromEnum(style)].pop();
}

pub fn frontStyleColor(style: StyleColor) raylib.Color {
    return currentContext.styleColorArray[@intFromEnum(style)].getLast();
}

pub fn pushStyleVarFloat(style: StyleVarFloat, value: f32) !void {
    try currentContext.styleVarFloatArray[@intFromEnum(style)].append(value);
}

pub fn popStyleVarFloat(style: StyleVarFloat) void {
    _ = currentContext.styleVarFloatArray[@intFromEnum(style)].pop();
}

pub fn frontStyleVarFloat(style: StyleVarFloat) raylib.Color {
    return currentContext.styleVarFloatArray[@intFromEnum(style)].getLast();
}

pub fn pushStyleVarVec2(style: StyleVarVec2, value: raylib.Vector2) !void {
    try currentContext.styleVarVec2[@intFromEnum(style)].append(value);
}

pub fn popStyleVarVec2(style: StyleVarVec2) void {
    _ = currentContext.styleVarVec2[@intFromEnum(style)].pop();
}

pub fn frontStyleVarVec2(style: StyleVarVec2) raylib.Color {
    return currentContext.styleVarVec2[@intFromEnum(style)].getLast();
}
