const std = @import("std");
const rl = @import("rl.zig");
const paths = @import("paths.zig");

const math = std.math;

var prng = std.rand.DefaultPrng.init(10);
const rand = prng.random();

const BallColor = enum(u32) {
    red = 0xa83832ff,
    yellow = 0xb8ac32ff,
    green = 0x32a852ff,
    blue = 0x3242a8ff,

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
        const time = rl.getTime() - player.state.shooting.start_time;
        const half_time = Player.shooting_time * 0.5;
        const t = 1 - 2 * @abs(half_time - time);
        center = player.position.subtract(player.state.shooting.direction.scale(@floatCast(t * 25)));
    }
    rl.drawCircleV(center, Player.radius, rl.Color.fromInt(0x444444FF));
    if (player.state == .idle) {
        rl.drawCircleV(player.getShotOrigin(), BALL_RADIUS, player.state.idle.ball_color.getColor());
    }
}

pub fn main() void {
    rl.initWindow(800, 600, "Raylib window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    // Init level
    var balls = [_]Ball{
        Ball{ .offset = 0, .color = .red },
        Ball{ .offset = 400, .color = .yellow },
        Ball{ .offset = 460, .color = .green },
        Ball{ .offset = 700, .color = .blue },
        Ball{ .offset = 800, .color = .red },
        Ball{ .offset = 860, .color = .yellow },
        Ball{ .offset = 1200, .color = .green },
        Ball{ .offset = 1380, .color = .blue },
    };

    const segments = [_]paths.Path{
        paths.LinePath.new(Vec.new(50, 50), Vec.new(500, 50)),
        paths.ArcPath.new(Vec.new(500, 50), Vec.new(500, 200), 0, .Clockwise),
        paths.LinePath.new(Vec.new(500, 200), Vec.new(300, 150)),
        paths.ArcPath.new(Vec.new(300, 150), Vec.new(150, 300), -100, .Counterclockwise),
        paths.ArcPath.new(Vec.new(150, 300), Vec.new(200, 500), 300, .Clockwise),
        paths.ArcPath.new(Vec.new(200, 500), Vec.new(300, 500), 0, .Counterclockwise),
        paths.ArcPath.new(Vec.new(300, 500), Vec.new(380, 420), 0, .Clockwise),
        paths.LinePath.new(Vec.new(380, 420), Vec.new(800, 420)),
    };

    var projectiles = [5]Projectile{
        Projectile{},
        Projectile{},
        Projectile{},
        Projectile{},
        Projectile{},
    };

    const path = paths.MultiSegmentPath.new(&segments);

    var player = Player{
        .position = Vec.new(400, 300),
        .state = .{ .idle = .{
            .direction = Vec.zero,
            .ball_color = BallColor.random(),
        } },
    };
    const player_position = Vec.new(400, 300);

    while (!rl.windowShouldClose()) {
        // Frame update
        const delta = rl.getFrameTime();
        const time = rl.getTime();

        const mouse_position = rl.getMousePosition();
        // const left_mb_down = rl.isMouseButtonDown(.left);
        const left_mb_pressed = rl.isMouseButtonPressed(.left);

        const aim_direction = mouse_position.subtract(player_position).normalize();

        balls[0].offset += BALL_SPEED * delta;
        for (1..balls.len) |i| {
            if (balls[i].offset - balls[i - 1].offset > BALL_RADIUS * 2) break;
            balls[i].offset = balls[i - 1].offset + BALL_RADIUS * 2;
        }

        if (left_mb_pressed and player.state != .shooting) {
            for (&projectiles) |*projectile| {
                if (!projectile.is_active) {
                    projectile.position = player.getShotOrigin();
                    projectile.direction = aim_direction;
                    projectile.color = player.state.idle.ball_color;
                    projectile.is_active = true;
                    projectile.lifetime = 0;
                    player.state = .{ .shooting = .{
                        .direction = aim_direction,
                        .start_time = rl.getTime(),
                    } };
                    break;
                }
            }
        }

        for (&projectiles) |*projectile| {
            if (!projectile.is_active) continue;
            const movement = projectile.direction.scale(PROJECTILE_SPEED * delta);
            projectile.position = projectile.position.add(movement);
            projectile.lifetime += delta;
            if (projectile.lifetime > 1) {
                projectile.is_active = false;
            }
        }

        switch (player.state) {
            .shooting => {
                if (time - player.state.shooting.start_time > Player.shooting_time) {
                    player.state = .{ .idle = .{
                        .direction = aim_direction,
                        .ball_color = BallColor.random(),
                    } };
                }
            },
            else => {
                player.state = .{ .idle = .{
                    .direction = aim_direction,
                    .ball_color = player.state.idle.ball_color,
                } };
            },
        }

        // Rendering
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        visualizePath(path, 20, rl.Color.red);

        for (balls) |ball| {
            const position = path.getPosition(ball.offset);
            renderBall(ball, position);
        }

        renderPlayer(player);

        for (projectiles) |projectile| {
            if (projectile.is_active) {
                rl.drawCircleV(projectile.position, BALL_RADIUS, projectile.color.getColor());
            }
        }
    }
}
