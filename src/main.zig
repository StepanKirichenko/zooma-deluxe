const std = @import("std");
const rl = @import("rl.zig");
const math = std.math;

const Ball = struct {
    offset: f32,
    color: rl.Color,
};

const Vec = rl.Vector2;

const BG_COLOR = rl.Color.fromInt(0x181818ff);

const BALL_SPEED: f32 = 100;
const BALL_RADIUS: f32 = 30;

const Path = union(enum) {
    line: LinePath,

    pub fn getPosition(self: Path, offset: f32) Vec {
        return switch (self) {
            Path.line => |line| line.getPosition(offset),
        };
    }
};

const LinePath = struct {
    start: Vec,
    end: Vec,

    length: f32,
    direction: Vec,

    pub fn getPosition(self: LinePath, offset: f32) Vec {
        const t = offset / self.length;
        const movement = self.direction.scale(t);
        const position = self.start.add(movement);
        return position;
    }

    pub fn new(start: Vec, end: Vec) Path {
        const length = start.distanceTo(end);
        const direction = end.subtract(start);
        return Path{ .line = LinePath{
            .start = start,
            .end = end,
            .length = length,
            .direction = direction,
        } };
    }
};

fn getCurvePosition(position: f32) Vec {
    const turns: f32 = 10 - (position / 360);
    const radians: f32 = turns * math.tau;
    const x = math.cos(radians) * turns * 30 + 400;
    const y = math.sin(radians) * turns * 30 + 300;
    return Vec{ .x = x, .y = y };
}

fn renderBall(ball: Ball, position: Vec) void {
    rl.drawCircleV(position, BALL_RADIUS, ball.color);
}

pub fn main() void {
    rl.initWindow(800, 600, "Raylib window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var balls = [_]Ball{
        Ball{ .offset = 0, .color = rl.Color.fromInt(0x32a852ff) },
        Ball{ .offset = 150, .color = rl.Color.fromInt(0xb8ac32ff) },
        Ball{ .offset = 300, .color = rl.Color.fromInt(0xa83832ff) },
        Ball{ .offset = 360, .color = rl.Color.fromInt(0x3242a8ff) },
    };

    // const path = LinePath.new{
    //     .start = Vec.new(50, 50),
    //     .end = Vec.new(600, 200),
    // };

    const path = LinePath.new(Vec.new(50, 50), Vec.new(600, 200));

    while (!rl.windowShouldClose()) {
        // Frame update
        const delta = rl.getFrameTime();

        balls[0].offset += BALL_SPEED * delta;
        for (1..balls.len) |i| {
            if (balls[i].offset - balls[i - 1].offset > BALL_RADIUS * 2) break;
            balls[i].offset = balls[i - 1].offset + BALL_RADIUS * 2;
        }

        // Rendering
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        for (balls) |ball| {
            const position = path.getPosition(ball.offset);
            renderBall(ball, position);
        }
    }
}
