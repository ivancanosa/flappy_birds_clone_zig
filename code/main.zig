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
var backTex: rl.Texture2D = undefined;
var jumpSound: rl.Sound = undefined;
var score: u32 = 0;

const ScoreHitbox = struct {
    used: bool = false,
};

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
    scoreHitbox: ?ScoreHitbox = null,
};

pub fn input(entities: EntityList) void {
    for (entities.items) |*entity| {
        if (entity.player) |*player| {
            _ = player;
            if (rl.IsKeyPressed(rl.KeyboardKey.KEY_SPACE)) {
                rl.PlaySound(jumpSound);
                entity.speed.y = upSpeed;
            }
        }
    }
}

pub fn resetGame(entities: *EntityList) !void {
    entities.clearRetainingCapacity();
    score = 0;
    try entities.append(Entity{ .size = .{ .x = playerSize, .y = playerSize }, .player = Player{} });
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

        var hitbox = Entity{ .size = .{ .x = 10, .y = 1800 }, .scoreHitbox = .{} };
        hitbox.position = .{ .x = windowSize.x + 60, .y = 0 };
        hitbox.speed.x = tubeSpeed;
        entities.append(hitbox) catch unreachable;

        accTime = 0;
    }
    for (entities.items, 0..) |*entity, i| {
        if (entity.tube) |*tube| {
            _ = tube;
            entity.position.x += entity.speed.x * dt;
        } else if (entity.scoreHitbox) |*scoreHitbox| {
            _ = scoreHitbox;
            entity.position.x += entity.speed.x * dt;
        }

        if (entity.position.x <= -200) {
            removePos = i;
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

pub fn systemCollision(entities: *EntityList) !void {
    var playerEnt: Entity = undefined;
    var reset = false;
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
    for (entities.items) |*entity| {
        var recEntity = rl.Rectangle{
            .x = entity.position.x, //
            .y = entity.position.y, //
            .width = entity.size.x, //
            .height = entity.size.y,
        };

        if (entity.tube) |_| {
            if (rl.CheckCollisionRecs(recPlayer, recEntity)) {
                reset = true;
            }
        }
        if (entity.scoreHitbox) |*s_hitbox| {
            if (s_hitbox.used) {
                continue;
            }
            if (rl.CheckCollisionRecs(recPlayer, recEntity)) {
                s_hitbox.used = true;
                score += 1;
            }
        }
    }
    if (reset) {
        try resetGame(entities);
    }
}

pub fn render(entities: EntityList) !void {
    {
        const patch = rl.NPatchInfo{
            .source = .{ .x = 0, .y = 0, .width = @floatFromInt(backTex.width), .height = @floatFromInt(backTex.height) }, //
            .left = 0, //
            .top = 0, //
            .right = 0, //
            .bottom = 0, //
            .layout = 0,
        };
        const destRec = rl.Rectangle{
            .x = 0, //
            .y = 0, //
            .width = windowSize.x, //
            .height = windowSize.y,
        };
        rl.DrawTextureNPatch(backTex, patch, destRec, .{}, 0, rl.WHITE);
    }

    for (entities.items) |entity| {
        if (entity.player != null) {
            rl.DrawTextureEx(birdTex, entity.position, 0, 1.0, rl.WHITE);
        } else if (entity.tube) |tube| {
            var scale: f32 = -1.0;
            if (tube.inverted) {
                scale = 1.0;
            }
            const patch = rl.NPatchInfo{
                .source = .{ .x = 0, .y = 0, .width = 52, .height = scale * 320 }, //
                .left = 0, //
                .top = 0, //
                .right = 0, //
                .bottom = 0, //
                .layout = 0,
            };
            const destRec = rl.Rectangle{
                .x = entity.position.x, //
                .y = entity.position.y, //
                .width = entity.size.x, //
                .height = entity.size.y,
            };
            rl.DrawTextureNPatch(tubeTex, patch, destRec, .{}, 0, rl.WHITE);
        }
    }

    var ally = std.heap.page_allocator;
    var str = try std.fmt.allocPrintZ(ally, "{}", .{score});
    rl.DrawText(str, 50, 50, 26, rl.WHITE);
    ally.free(str);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.detectLeaks();
    const allocator = gpa.allocator();

    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = false });
    rl.InitWindow(windowSize.x, windowSize.y, "hello world!");
    defer rl.CloseWindow();

    rl.InitAudioDevice();
    rl.SetTargetFPS(60);

    var entities = EntityList.init(allocator);
    defer entities.deinit();

    try entities.append(Entity{ .size = .{ .x = playerSize, .y = playerSize }, .player = Player{} });

    // Setup style context
    var ctx = try rg.Context.init(std.heap.page_allocator);
    defer ctx.deinit();
    rg.activeContext = &ctx;

    birdTex = rl.LoadTexture("data/flappy-bird-assets/sprites/redbird-downflap.png");
    tubeTex = rl.LoadTexture("data/flappy-bird-assets/sprites/pipe-green.png");
    backTex = rl.LoadTexture("data/flappy-bird-assets/sprites/background-day.png");
    //    jumpSound = rl.LoadSound("data/flappy-bird-assets/audio/wing.wav");

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.Color{ .r = 33, .g = 33, .b = 33, .a = 255 });

        input(entities);

        systemTubeSpawn(&entities);
        systemPlayer(entities);
        try systemCollision(&entities);
        try render(entities);
    }
}
