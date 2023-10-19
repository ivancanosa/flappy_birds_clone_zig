const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui.zig");
const RndGen = std.rand.DefaultPrng;

const EntityList = std.ArrayList(Entity);

var rnd = RndGen.init(0);

const windowSize: rl.Vector2 = rl.Vector2{ .x = 800, .y = 800 };
const gravity: f32 = 2000.0;
const upSpeed: f32 = -900;
const tubeSpeed: f32 = -345;
const tubeWindow: f32 = 150;
const playerSize: i32 = 50;
var birdTex: rl.Texture2D = undefined;
var tubeTex: rl.Texture2D = undefined;

const Player = struct {
    rotation: f32 = 0.0,
};

const Tube = struct {
    inverted: bool = false,
};

const Entity = struct {
    position: rl.Vector2 = rl.Vector2{},
    size: rl.Vector2 = rl.Vector2{},
    speed: rl.Vector2 = rl.Vector2{},

    player: ?Player = null,
    tube: ?Tube = null,
};

pub fn input(entities: EntityList) void {
    for (entities.items) |*entity| {
        if (entity.player) |*player| {
            _ = player;
            if (rl.IsKeyPressed(rl.KeyboardKey.KEY_SPACE)) {
                entity.speed.y = upSpeed;
            }
        }
    }
}

var accTime: f32 = 0;
pub fn systemTubeSpawn(entities: *EntityList) void {
    const dt = rl.GetFrameTime();
    accTime += dt;
    var removePos: ?usize = null;
    if (accTime > 1) {
        var newTube = Entity{ .size = .{ .x = 100, .y = 100 }, .tube = Tube{} };
        const module: i32 = @intFromFloat(windowSize.y);
        const tubeWindow_int: i32 = @intFromFloat(tubeWindow);
        var newY: f32 = @floatFromInt(@mod(rnd.random().int(i32), module - tubeWindow_int));
        newY += tubeWindow / 2;
        newTube.position = .{ .x = windowSize.x + 10 };
        newTube.size.y = newY - tubeWindow;
        newTube.speed.x = tubeSpeed;
        entities.append(newTube) catch unreachable;

        newTube.position.y = newY + tubeWindow;
        newTube.size.y = windowSize.y - newTube.position.y + 10;
        newTube.tube.?.inverted = true;
        entities.append(newTube) catch unreachable;

        accTime = 0;
    }
    for (entities.items, 0..) |*entity, i| {
        if (entity.tube) |*tube| {
            _ = tube;
            entity.position.x += entity.speed.x * dt;
            if (entity.position.x <= -200) {
                removePos = i;
            }
        }
    }
    if (removePos) |i| {
        _ = entities.swapRemove(i);
    }
}

pub fn systemPlayer(entities: EntityList) void {
    const dt = rl.GetFrameTime();
    for (entities.items) |*entity| {
        if (entity.player) |*player| {
            _ = player;
            entity.speed.y += gravity * dt;
            entity.position.y += entity.speed.y * dt;
        }
    }
}

pub fn systemCollision(entities: EntityList) void {
    var playerEnt: Entity = undefined;
    for (entities.items) |entity| {
        if (entity.player) |_| {
            playerEnt = entity;
        }
    }

    var recPlayer = rl.Rectangle{
        .x = playerEnt.position.x, //
        .y = playerEnt.position.y, //
        .width = playerEnt.size.x, //
        .height = playerEnt.size.y,
    };
    for (entities.items) |entity| {
        if (entity.tube) |_| {
            var recTube = rl.Rectangle{
                .x = entity.position.x, //
                .y = entity.position.y, //
                .width = entity.size.x, //
                .height = entity.size.y,
            };
            if (rl.CheckCollisionRecs(recPlayer, recTube)) {
                std.debug.print("Collision\n", .{});
            }
        }
    }
}

pub fn render(entities: EntityList) void {
    for (entities.items) |entity| {
        if (entity.player != null) {
            rl.DrawTextureEx(birdTex, entity.position, 0, 1.0, rl.WHITE);
        } else if (entity.tube) |tube| {
            var scale: f32 = 1.0;
            if (tube.inverted) {
                scale = 1.0;
            }
            rl.DrawTextureEx(tubeTex, entity.position, 0, scale, rl.WHITE);
            rl.DrawRectangleLines(@intFromFloat(entity.position.x), //
                @intFromFloat(entity.position.y), //
                @intFromFloat(entity.size.x), //
                @intFromFloat(entity.size.y), //
                rl.RED);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.detectLeaks();
    const allocator = gpa.allocator();

    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = false });
    rl.InitWindow(windowSize.x, windowSize.y, "hello world!");
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    var entities = EntityList.init(allocator);
    defer entities.deinit();

    try entities.append(Entity{ .size = .{ .x = playerSize, .y = playerSize }, .player = Player{} });

    // Setup style context
    var ctx = try rg.Context.init(std.heap.page_allocator);
    defer ctx.deinit();
    rg.activeContext = &ctx;

    birdTex = rl.LoadTexture("data/flappy-bird-assets/sprites/redbird-downflap.png");
    tubeTex = rl.LoadTexture("data/flappy-bird-assets/sprites/pipe-green.png");
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.Color{ .r = 33, .g = 33, .b = 33, .a = 255 });

        input(entities);

        systemTubeSpawn(&entities);
        systemPlayer(entities);
        systemCollision(entities);
        render(entities);
    }
}
