const std = @import("std");
const rl = @import("rl.zig");
const paths = @import("paths.zig");

const math = std.math;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const temp_allocator = arena.allocator();

var prng = std.rand.DefaultPrng.init(10);
const rand = prng.random();

const BallColor = enum(u32) {
    red = rl.Color.red.toInt(),
    yellow = rl.Color.yellow.toInt(),
    green = rl.Color.green.toInt(),
    blue = rl.Color.blue.toInt(),

    pub fn getColor(self: BallColor) rl.Color {
        return rl.Color.fromInt(@intFromEnum(self));
    }

    pub fn random() BallColor {
        const colors = [_]BallColor{ .red, .yellow, .green, .blue };
        const i = rand.uintLessThan(usize, colors.len);
        return colors[i];
    }
};

const BallState = union(enum) {
    moving: void,
    inserting: struct {
        start_position: Vec,
        progress: f32,
    },
};

const Ball = struct {
    offset: f32,
    color: BallColor,
    state: BallState = .moving,
};

const BallExplosionEffect = struct {
    lifetime: f32 = 0,
    is_active: bool = false,
    position: Vec = Vec.zero,
    color: BallColor = BallColor.red,
};

const Projectile = struct {
    position: Vec = Vec.zero,
    direction: Vec = Vec.zero,
    color: BallColor = .red,
    lifetime: f32 = 0,
    is_active: bool = false,
};

const Player = struct {
    position: Vec,
    state: State,

    pub const State = union(enum) {
        idle: struct {
            direction: Vec,
            ball_color: BallColor,
        },
        shooting: struct {
            direction: Vec,
            start_time: f64,
        },
    };

    pub fn getShotOrigin(self: Player) Vec {
        if (self.state != .idle) return Vec.zero;
        return self.position.add(self.state.idle.direction.scale(30));
    }

    pub const radius: f32 = 60;
    pub const shooting_time: f32 = 0.15;
};

const GameState = struct {
    delta: f32 = 0,
    player: Player,
    path: paths.Path,
    balls: std.ArrayList(Ball),
    projectiles: std.ArrayList(Projectile),
    explosion_effects: std.ArrayList(BallExplosionEffect),
};

fn initGameState(state: *GameState) !void {
    state.player = Player{
        .position = Vec.new(400, 300),
        .state = .{ .idle = .{
            .direction = Vec.zero,
            .ball_color = BallColor.random(),
        } },
    };

    const init_balls = [_]Ball{
        Ball{ .offset = 0, .color = .red },
        Ball{ .offset = 400, .color = .yellow },
        Ball{ .offset = 460, .color = .green },
        Ball{ .offset = 700, .color = .blue },
        Ball{ .offset = 800, .color = .red },
        Ball{ .offset = 860, .color = .yellow },
        Ball{ .offset = 1200, .color = .green },
        Ball{ .offset = 1380, .color = .blue },
    };

    state.balls = std.ArrayList(Ball).init(allocator);
    try state.balls.appendSlice(&init_balls);

    const init_segments = [_]paths.Segment{
        paths.LineSegment.new(Vec.new(50, 50), Vec.new(500, 50)),
        paths.ArcSegment.new(Vec.new(500, 50), Vec.new(500, 200), 0, .Clockwise),
        paths.LineSegment.new(Vec.new(500, 200), Vec.new(300, 150)),
        paths.ArcSegment.new(Vec.new(300, 150), Vec.new(150, 300), -100, .Counterclockwise),
        paths.ArcSegment.new(Vec.new(150, 300), Vec.new(200, 500), 300, .Clockwise),
        paths.ArcSegment.new(Vec.new(200, 500), Vec.new(300, 500), 0, .Counterclockwise),
        paths.ArcSegment.new(Vec.new(300, 500), Vec.new(380, 420), 0, .Clockwise),
        paths.LineSegment.new(Vec.new(380, 420), Vec.new(800, 420)),
    };

    var segments = paths.Path.SegmentList.init(allocator);
    try segments.appendSlice(&init_segments);

    state.path = paths.Path.new(segments);

    state.projectiles = std.ArrayList(Projectile).init(allocator);
    try state.projectiles.appendNTimes(Projectile{}, 10);

    state.explosion_effects = std.ArrayList(BallExplosionEffect).init(allocator);
    try state.explosion_effects.appendNTimes(.{}, 10);
}

fn deinitGameState(state: *GameState) void {
    state.balls.deinit();
    state.path.deinit();
    state.projectiles.deinit();
    state.explosion_effects.deinit();
}

const Vec = rl.Vector2;

const BG_COLOR = rl.Color.fromInt(0x181818ff);

const BALL_SPEED: f32 = 150;
const BALL_RADIUS: f32 = 20;

const EXPLOSION_EFFECT_LIFETIME: f32 = 0.2;

const PROJECTILE_SPEED: f32 = 1000;

fn renderBall(ball: Ball, position: Vec) void {
    rl.drawCircleV(position, BALL_RADIUS, ball.color.getColor());
}

fn visualizePath(path: paths.Path, step: f32, color: rl.Color) void {
    var offset: f32 = 0;
    const path_length = path.getLength();
    while (offset < path_length) : (offset += step) {
        rl.drawCircleV(path.getPosition(offset), 3, color);
    }
}

fn renderPlayer(player: Player) void {
    var center = player.position;
    if (player.state == .shooting) {
        const time = (rl.getTime() - player.state.shooting.start_time) / Player.shooting_time;
        const half_time = Player.shooting_time * 0.5;
        const t = 1 - 2 * @abs(half_time - time);
        center = player.position.subtract(player.state.shooting.direction.scale(@floatCast(t * 25)));
    }
    rl.drawCircleV(center, Player.radius, rl.Color.fromInt(0x444444FF));
    if (player.state == .idle) {
        rl.drawCircleV(player.getShotOrigin(), BALL_RADIUS, player.state.idle.ball_color.getColor());
    }
}

const ProjectileBallCollision = struct {
    insertion_index: ?usize,
    insertion_offset: f32 = 0,
};

fn getProjectileBallCollision(state: *GameState, projectile: Projectile) ProjectileBallCollision {
    const balls = state.balls.items;
    for (balls, 0..) |ball, i| {
        const ball_position = state.path.getPosition(ball.offset);
        const distance = rl.vector2Distance(ball_position, projectile.position);
        if (distance > 2 * BALL_RADIUS) continue;
        const ball_direction = state.path.getDirection(ball.offset).scale(BALL_RADIUS);
        const front = ball_position.add(ball_direction);
        const back = ball_position.subtract(ball_direction);
        const front_distance = projectile.position.distance(front);
        const back_distance = projectile.position.distance(back);
        const insertion_index = if (front_distance < back_distance) i + 1 else i;
        const insertion_offset = if (front_distance < back_distance) ball.offset + BALL_RADIUS * 2 else ball.offset;
        return .{ .insertion_index = insertion_index, .insertion_offset = insertion_offset };
    }
    return .{ .insertion_index = null };
}

const Range = struct {
    start: usize,
    end: usize,
};

fn areBallsTouching(ball1: Ball, ball2: Ball) bool {
    return @abs(ball2.offset - ball1.offset) - BALL_RADIUS * 2 <= 1;
}

fn getSameColorRange(state: *GameState, ball_index: usize) Range {
    const current_ball = state.balls.items[ball_index];
    var start: usize = ball_index;
    while (start > 0) {
        const ball = state.balls.items[start - 1];
        const prev_ball = state.balls.items[start];
        if (!areBallsTouching(prev_ball, ball)) break;
        if (current_ball.color != ball.color) break;
        start -= 1;
    }
    var end = ball_index + 1;
    while (end < state.balls.items.len) {
        const ball = state.balls.items[end];
        const prev_ball = state.balls.items[end - 1];
        if (!areBallsTouching(prev_ball, ball)) break;
        if (current_ball.color != ball.color) break;
        end += 1;
    }

    return .{ .start = start, .end = end };
}

fn createExplosionEffect(state: *GameState, position: Vec, color: BallColor) void {
    var inactive_effect: ?*BallExplosionEffect = null;
    for (state.explosion_effects.items) |*effect| {
        if (!effect.is_active) {
            inactive_effect = effect;
            break;
        }
    }

    const effect = inactive_effect orelse return;
    effect.* = .{
        .is_active = true,
        .lifetime = 0,
        .position = position,
        .color = color,
    };
}

fn updateBalls(state: *GameState) !void {
    const delta = state.delta;
    // Ball movement
    const balls = state.balls.items;
    if (balls.len == 0) {
        return;
    }

    balls[0].offset += BALL_SPEED * delta;
    for (1..balls.len) |i| {
        var new_offset = balls[i].offset;
        const prev_ball = balls[i - 1];
        const offset_forced = switch (prev_ball.state) {
            .moving => prev_ball.offset + BALL_RADIUS * 2,
            .inserting => |s| prev_ball.offset + BALL_RADIUS * 2 * s.progress,
        };
        if (offset_forced > new_offset) new_offset = offset_forced;
        balls[i].offset = new_offset;
    }

    // Ball state change
    {
        var i: usize = 0;
        while (i < state.balls.items.len) {
            var should_increment = true;
            switch (balls[i].state) {
                .inserting => |s| {
                    if (s.progress >= 1) {
                        balls[i].state = .moving;
                        const same_color_range = getSameColorRange(state, i);
                        const range_lenght = same_color_range.end - same_color_range.start;
                        std.debug.print("Range len: {}\n", .{range_lenght});
                        if (range_lenght >= 3) {
                            should_increment = false;
                            for (state.balls.items[same_color_range.start..same_color_range.end]) |ball| {
                                createExplosionEffect(
                                    state,
                                    state.path.getPosition(ball.offset),
                                    ball.color,
                                );
                            }
                            try state.balls.replaceRange(same_color_range.start, range_lenght, &.{});
                            i = same_color_range.start;
                        }
                    } else {
                        balls[i].state.inserting.progress += delta * 10;
                    }
                },
                else => {},
            }
            if (should_increment) {
                i += 1;
            }
        }
    }
}

fn update(state: *GameState) !void {
    const delta = rl.getFrameTime();
    const time = rl.getTime();

    state.delta = delta;

    // Input
    const mouse_position = rl.getMousePosition();
    // const left_mb_down = rl.isMouseButtonDown(.left);
    const left_mb_pressed = rl.isMouseButtonPressed(.left);

    const aim_direction = mouse_position.subtract(state.player.position).normalize();

    try updateBalls(state);

    // Explosion effects
    for (state.explosion_effects.items) |*effect| {
        if (!effect.is_active) continue;
        effect.lifetime += delta;
        if (effect.lifetime > EXPLOSION_EFFECT_LIFETIME) {
            effect.is_active = false;
        }
    }

    if (left_mb_pressed and state.player.state != .shooting) {
        for (state.projectiles.items) |*projectile| {
            if (!projectile.is_active) {
                projectile.position = state.player.getShotOrigin();
                projectile.direction = aim_direction;
                projectile.color = state.player.state.idle.ball_color;
                projectile.is_active = true;
                projectile.lifetime = 0;
                state.player.state = .{ .shooting = .{
                    .direction = aim_direction,
                    .start_time = rl.getTime(),
                } };
                break;
            }
        }
    }

    for (state.projectiles.items) |*projectile| {
        if (!projectile.is_active) continue;
        const movement = projectile.direction.scale(PROJECTILE_SPEED * delta);
        projectile.position = projectile.position.add(movement);
        projectile.lifetime += delta;
        if (projectile.lifetime > 1) {
            projectile.is_active = false;
        }
        const collision = getProjectileBallCollision(state, projectile.*);
        if (collision.insertion_index) |i| {
            const new_ball = Ball{
                .offset = collision.insertion_offset,
                .color = projectile.color,
                .state = .{ .inserting = .{ .progress = 0, .start_position = projectile.position } },
            };
            try state.balls.insert(i, new_ball);
            projectile.is_active = false;
        }
    }

    switch (state.player.state) {
        .shooting => {
            if (time - state.player.state.shooting.start_time > Player.shooting_time) {
                state.player.state = .{ .idle = .{
                    .direction = aim_direction,
                    .ball_color = BallColor.random(),
                } };
            }
        },
        else => {
            state.player.state = .{ .idle = .{
                .direction = aim_direction,
                .ball_color = state.player.state.idle.ball_color,
            } };
        },
    }
}

fn render(state: *GameState) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(BG_COLOR);

    visualizePath(state.path, 20, rl.Color.red);

    for (state.balls.items) |ball| {
        const position = switch (ball.state) {
            .moving => state.path.getPosition(ball.offset),
            .inserting => |s| blk: {
                const final_pos = state.path.getPosition(ball.offset);
                break :blk rl.vector2Lerp(s.start_position, final_pos, s.progress);
            },
        };
        renderBall(ball, position);
    }

    for (state.explosion_effects.items) |explosion| {
        if (!explosion.is_active) continue;
        const t = explosion.lifetime / EXPLOSION_EFFECT_LIFETIME;
        const radius = BALL_RADIUS * 2 * (0.5 + t * 0.7);
        const color = rl.colorAlpha(explosion.color.getColor(), 1 - t);
        rl.drawRing(explosion.position, radius, radius + 5, 0, 360, 90, color);
    }

    renderPlayer(state.player);

    for (state.projectiles.items) |projectile| {
        if (projectile.is_active) {
            rl.drawCircleV(projectile.position, BALL_RADIUS, projectile.color.getColor());
        }
    }
}

pub fn main() !void {
    defer {
        if (gpa.deinit() == .leak) {
            @panic("Memory leak!!!");
        }
    }

    rl.initWindow(800, 600, "Raylib window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var state: GameState = undefined;
    try initGameState(&state);
    defer deinitGameState(&state);

    while (!rl.windowShouldClose()) {
        try update(&state);
        render(&state);
        _ = arena.reset(.retain_capacity);
    }
}
