const std = @import("std");
const rl = @import("rl.zig");
const math = std.math;

const Ball = struct {
    position: f32,
    color: rl.Color,
};

const Vec = rl.Vector2;

const BG_COLOR = rl.Color.fromInt(0x181818ff);

const BALL_SPEED: f32 = 270;
const BALL_RADIUS: f32 = 30;

fn getCurvePosition(position: f32) Vec {
    const turns: f32 = 10 - (position / 360);
    const radians: f32 = turns * math.tau;
    const x = math.cos(radians) * turns * 30 + 400;
    const y = math.sin(radians) * turns * 30 + 300;
    return Vec{ .x = x, .y = y };
}

fn renderBall(ball: Ball) void {
    const pos = getCurvePosition(ball.position);
    rl.drawCircleV(pos, BALL_RADIUS, ball.color);
}

pub fn main() void {
    std.debug.print("Hello, world!\n", .{});

    rl.initWindow(800, 600, "Raylib window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var balls = [_]Ball{
        Ball{ .position = 90, .color = rl.Color.fromInt(0x32a852ff) },
        Ball{ .position = 130, .color = rl.Color.fromInt(0xb8ac32ff) },
        Ball{ .position = 170, .color = rl.Color.fromInt(0xa83832ff) },
        Ball{ .position = 210, .color = rl.Color.fromInt(0x3242a8ff) },
        Ball{ .position = 250, .color = rl.Color.fromInt(0x32a852ff) },
        Ball{ .position = 290, .color = rl.Color.fromInt(0xb8ac32ff) },
        Ball{ .position = 330, .color = rl.Color.fromInt(0xa83832ff) },
    };

    while (!rl.windowShouldClose()) {
        // Frame update
        const delta = rl.getFrameTime();

        for (balls, 0..) |ball, i| {
            balls[i].position = ball.position + BALL_SPEED * delta;
        }

        // Rendering
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        for (balls) |ball| {
            renderBall(ball);
        }
    }
}
