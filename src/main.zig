const std = @import("std");
const rl = @import("rl.zig");
const paths = @import("paths.zig");

const math = std.math;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

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

const Ball = struct {
    offset: f32,
    color: BallColor,
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
    player: Player,
    path: paths.Path,
    balls: std.ArrayList(Ball),
    projectiles: std.ArrayList(Projectile),
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
}

fn deinitGameState(state: *GameState) void {
    state.balls.deinit();
    state.path.deinit();
    state.projectiles.deinit();
}

const Vec = rl.Vector2;

const BG_COLOR = rl.Color.fromInt(0x181818ff);

const BALL_SPEED: f32 = 200;
const BALL_RADIUS: f32 = 20;

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

fn update(state: *GameState) void {
    const delta = rl.getFrameTime();
    const time = rl.getTime();

    const mouse_position = rl.getMousePosition();
    // const left_mb_down = rl.isMouseButtonDown(.left);
    const left_mb_pressed = rl.isMouseButtonPressed(.left);

    const aim_direction = mouse_position.subtract(state.player.position).normalize();

    const balls = state.balls.items;
    balls[0].offset += BALL_SPEED * delta;
    for (1..balls.len) |i| {
        if (balls[i].offset - balls[i - 1].offset > BALL_RADIUS * 2) break;
        balls[i].offset = balls[i - 1].offset + BALL_RADIUS * 2;
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
        const position = state.path.getPosition(ball.offset);
        renderBall(ball, position);
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
        update(&state);
        render(&state);
    }
}
